#!/usr/bin/env pwsh

# Stop on errors
$ErrorActionPreference = "Stop"

# Get the script directory (repository root)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Color definitions
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

# ---------- Global Variables ----------
# Backup directory with timestamp (used by install)
$BackupDir = $null

# ---------- Helper Functions ----------

# Backup a single target (file or directory)
function Backup-Target {
    param(
        [string]$Target,
        [string]$BackupSubPath
    )
    if (Test-Path $Target) {
        $backupTarget = Join-Path $BackupDir $BackupSubPath
        $backupParent = Split-Path $backupTarget -Parent
        if (!(Test-Path $backupParent)) {
            New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
        }
        Write-Host "  Backing up: $Target" -ForegroundColor $Yellow
        Write-Host "     -> $backupTarget" -ForegroundColor $Yellow
        Move-Item -Path $Target -Destination $backupTarget -Force
    }
}

# Check if winstow is available (only needed for packages using winstow)
function Test-WinStow {
    if (!(Get-Command winstow -ErrorAction SilentlyContinue)) {
        Write-Error "winstow not found. Please install it via: winget install winstow"
        exit 1
    }
}

# ---------- NEW: Environment Variable Functions ----------

# Export current environment variables (User and Machine) to a JSON file
function Export-Environment {
    param(
        [string]$Path
    )
    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Join-Path $PWD "environment.json"
    }
    Write-Host "Exporting environment variables to $Path ..." -ForegroundColor $Blue
    $envData = @{
        User = [Environment]::GetEnvironmentVariables('User')
        Machine = [Environment]::GetEnvironmentVariables('Machine')
    }
    $json = $envData | ConvertTo-Json -Depth 1
    # Ensure directory exists
    $parent = Split-Path $Path -Parent
    if (!(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $json | Out-File -FilePath $Path -Encoding UTF8
    Write-Host "Export complete." -ForegroundColor $Green
}

# Import environment variables from a JSON file (requires admin for Machine variables)
function Import-Environment {
    param(
        [string]$Path
    )
    if (!(Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return
    }
    Write-Host "Importing environment variables from $Path ..." -ForegroundColor $Blue
    $data = Get-Content $Path -Raw | ConvertFrom-Json

    # Check admin rights for Machine variables
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($data.PSObject.Properties.Name -contains 'Machine' -and !$isAdmin) {
        Write-Warning "System (Machine) variables require administrator privileges. Please run as Administrator to import them."
    }

    # Import User variables
    if ($data.User) {
        foreach ($key in $data.User.PSObject.Properties) {
            $name = $key.Name
            $value = $key.Value
            try {
                [Environment]::SetEnvironmentVariable($name, $value, 'User')
                Write-Host "  Set user variable: $name = $value" -ForegroundColor $Green
            } catch {
                Write-Warning "Failed to set user variable $name : $_"
            }
        }
    }

    # Import Machine variables (if admin)
    if ($data.Machine -and $isAdmin) {
        foreach ($key in $data.Machine.PSObject.Properties) {
            $name = $key.Name
            $value = $key.Value
            try {
                [Environment]::SetEnvironmentVariable($name, $value, 'Machine')
                Write-Host "  Set system variable: $name = $value" -ForegroundColor $Green
            } catch {
                Write-Warning "Failed to set system variable $name : $_"
            }
        }
    }
    Write-Host "Import complete. Please restart your session or computer for changes to take effect." -ForegroundColor $Yellow
}

# Backup environment variables to a timestamped directory (useful for snapshot)
function Backup-Environment {
    $backupDir = Join-Path $HOME "env_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $envFile = Join-Path $backupDir "environment.json"
    Export-Environment -Path $envFile
    Write-Host "Environment variables backed up to: $envFile" -ForegroundColor $Green
}

# ---------- END NEW ----------

# Uninstall all symlinks
function Do-Uninstall {
    Write-Host "Removing all symlinks..." -ForegroundColor $Blue

    # Packages that use direct symbolic links
    $directPackages = @("nvim", "vscode-extensions", "powershell-profile")

    foreach ($pkg in $Packages) {
        $target = $pkg.Target
        $package = $pkg.Package
        $sourceRoot = $pkg.SourceRoot
        $targetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target)

        if ($pkg.Name -in $directPackages) {
            if ($pkg.Name -eq "powershell-profile") {
                # Unlink each item inside the powershell directory
                $sourceDir = [System.IO.Path]::Combine($ScriptDir, $sourceRoot, $package)
                if (Test-Path $sourceDir) {
                    Get-ChildItem -Path $sourceDir -Force | ForEach-Object {
                        $linkPath = Join-Path $targetPath $_.Name
                        if (Test-Path $linkPath) {
                            Remove-Item -Path $linkPath -Force
                            Write-Host "  Removed $($_.Name) from $targetPath" -ForegroundColor $Green
                        }
                    }
                }
            } else {
                # Direct single-target removal (nvim or extensions.json)
                if (Test-Path $targetPath) {
                    Remove-Item -Path $targetPath -Force
                    Write-Host "  Removed $($pkg.Name)" -ForegroundColor $Green
                } else {
                    Write-Host "  $($pkg.Name) not found, skipping." -ForegroundColor $Yellow
                }
            }
        } else {
            # Use winstow for other packages
            Push-Location $sourceRoot
            winstow -D -t $target $package 2>$null
            Pop-Location
            Write-Host "  Removed $($pkg.Name)" -ForegroundColor $Green
        }
    }
    Write-Host "Uninstall complete." -ForegroundColor $Green
}

# Main installation function
function Do-Install {
    Write-Host "Deploying Windows configurations..." -ForegroundColor $Green
    Test-WinStow

    # Create backup directory (global variable used by Backup-Target)
    $script:BackupDir = Join-Path $HOME "dotfiles_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "Backup directory: $BackupDir" -ForegroundColor $Yellow

    $response = Read-Host "Continue? (y/N)"
    if ($response -notmatch '^[Yy]$') {
        Write-Host "Operation cancelled." -ForegroundColor $Red
        exit 2
    }

    # Ensure required directories exist
    $configDir = Join-Path $HOME ".config"
    if (!(Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null; Write-Host "Created $configDir" -ForegroundColor $Yellow }
    $vscodeDir = Join-Path $HOME ".vscode"
    if (!(Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null; Write-Host "Created $vscodeDir" -ForegroundColor $Yellow }

    Write-Host "`nBacking up existing configurations..." -ForegroundColor $Blue
    foreach ($pkg in $Packages) {
        $pkgName = $pkg.Name

        # Special backup handling for packages that may target busy directories
        if ($pkgName -in @("home", "glazewm", "starship", "yasb")) {
            $pkgDir = Join-Path $pkg.SourceRoot $pkg.Package
            if (Test-Path $pkgDir) {
                if ($pkgName -eq "starship") {
                    $targetFile = Join-Path $HOME ".config\starship.toml"
                    Backup-Target -Target $targetFile -BackupSubPath "starship\starship.toml"
                } elseif ($pkgName -eq "yasb") {
                    $targetDir = Join-Path $HOME ".config\yasb"
                    Backup-Target -Target $targetDir -BackupSubPath "yasb"
                } else {
                    Get-ChildItem -Path $pkgDir -Force | ForEach-Object {
                        $itemName = $_.Name
                        $targetPath = Join-Path $pkg.Target $itemName
                        $backupSubPath = Join-Path $pkg.BackupSubPath $itemName
                        Backup-Target -Target $targetPath -BackupSubPath $backupSubPath
                    }
                }
            }
        } elseif ($pkgName -eq "powershell-profile") {
            # Backup the specific profile file
            Backup-Target -Target $PROFILE -BackupSubPath $pkg.BackupSubPath
        } else {
            # Generic backup for other packages (including nvim)
            Backup-Target -Target $pkg.Target -BackupSubPath $pkg.BackupSubPath
        }
    }
    Write-Host "Backup of configurations complete." -ForegroundColor $Green

    # ---------- NEW: Backup environment variables ----------
    Write-Host "`nBacking up current environment variables..." -ForegroundColor $Blue
    $envBackupFile = Join-Path $BackupDir "environment.json"
    Export-Environment -Path $envBackupFile
    Write-Host "Environment variables backed up to $envBackupFile" -ForegroundColor $Green
    # ---------- END NEW ----------

    Write-Host "`nCreating symlinks..." -ForegroundColor $Blue

    # Packages that use direct symbolic links (instead of winstow)
    $directPackages = @("nvim", "vscode-extensions", "powershell-profile")

    foreach ($pkg in $Packages) {
        $target = $pkg.Target
        $package = $pkg.Package
        $sourceRoot = $pkg.SourceRoot

        if ($pkg.Name -in $directPackages) {
            # Direct symbolic link (avoids winstow)
            $relativeSource = Join-Path $sourceRoot $package
            $sourcePath = Join-Path $ScriptDir $relativeSource
            $targetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target)

            # Ensure parent directory exists
            $parent = Split-Path $targetPath -Parent
            if (!(Test-Path $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                Write-Host "  Created directory: $parent" -ForegroundColor $Yellow
            }

            # Remove existing target (file or directory)
            if (Test-Path $targetPath) {
                Remove-Item -Path $targetPath -Force
                Write-Host "  Removed existing: $targetPath" -ForegroundColor $Yellow
            }

            # Check source exists
            if (!(Test-Path $sourcePath)) {
                Write-Warning "Source file not found: $sourcePath. Skipping link for $($pkg.Name)."
                continue
            }

            # Create symbolic link
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
            Write-Host "  Linked $($pkg.Name) (symbolic link) to $targetPath" -ForegroundColor $Green
        } else {
            # Use winstow for other packages
            Write-Host "  Linking $($pkg.Name) to $target" -ForegroundColor $Green
            Push-Location $sourceRoot
            winstow -D -t $target $package 2>$null
            winstow -t $target $package
            Pop-Location
        }
    }

    Write-Host "`nAll configurations linked successfully!" -ForegroundColor $Green
    Write-Host "Backup stored at: $BackupDir" -ForegroundColor $Yellow
}

# ---------- Package Definitions ----------
$Packages = @(
    @{
        Name = "nvim"
        SourceRoot = "."
        Package = "nvim"
        Target = "$env:LOCALAPPDATA/nvim"
        BackupSubPath = "nvim"
    },
    @{
        Name = "yazi-config"
        SourceRoot = "yazi"
        Package = "config"
        Target = "$env:APPDATA/yazi/config"
        BackupSubPath = "yazi/config"
    },
    @{
        Name = "starship"
        SourceRoot = "."
        Package = "starship"
        Target = "$env:USERPROFILE/.config"
        BackupSubPath = "starship"
    },
    @{
        Name = "home"
        SourceRoot = "."
        Package = "home"
        Target = "$env:USERPROFILE"
        BackupSubPath = "home"
    },
    @{
        Name = "vscode-user"
        SourceRoot = "vscode"
        Package = "User"
        Target = "$env:APPDATA/Code/User"
        BackupSubPath = "vscode/User"
    },
    @{
        Name = "vscode-extensions"
        SourceRoot = "vscode"
        Package = ".vscode/extensions.json"
        Target = "$env:USERPROFILE/.vscode/extensions/extensions.json"
        BackupSubPath = ".vscode/extensions.json"
    },
    @{
        Name = "powershell-profile"
        SourceRoot = "."
        Package = "powershell"
        Target = Split-Path $PROFILE          # parent directory of $PROFILE
        BackupSubPath = "powershell/Microsoft.PowerShell_profile.ps1"
    },
    @{
        Name = "glazewm"
        SourceRoot = "."
        Package = "glazewm"
        Target = "$env:USERPROFILE"
        BackupSubPath = "glazewm"
    },
    @{
        Name = "yasb"
        SourceRoot = "."
        Package = "yasb"
        Target = "$env:USERPROFILE/.config/yasb"
        BackupSubPath = "yasb"
    }
)

# ---------- Main Entry Point ----------
switch ($args[0]) {
    "install" { Do-Install }
    "uninstall" { Do-Uninstall }
    "reinstall" { Do-Uninstall; Do-Install }
    "backup-env" { Backup-Environment }
    "export-env" {
        if ($args[1]) {
            Export-Environment -Path $args[1]
        } else {
            Export-Environment -Path (Join-Path $PWD "environment.json")
        }
    }
    "import-env" {
        if ($args[1]) {
            Import-Environment -Path $args[1]
        } else {
            Write-Host "Usage: setup.ps1 import-env <file>" -ForegroundColor $Red
        }
    }
    default {
        Write-Host @"
Usage: setup.ps1 [command]

Commands:
  install      Install/update all configurations (with auto backup of configs AND environment variables)
  uninstall    Remove all symlinks
  reinstall    Uninstall then reinstall
  backup-env   Backup current environment variables to a timestamped directory
  export-env   Export environment variables to a JSON file (default: ./environment.json)
               Usage: export-env [<path>]
  import-env   Import environment variables from a JSON file (requires admin for system vars)
               Usage: import-env <path>
  help         Show this help

Example:
  .\setup.ps1 install
  .\setup.ps1 export-env D:\dotfiles\env.json
  .\setup.ps1 import-env D:\dotfiles\env.json
"@
    }
}
