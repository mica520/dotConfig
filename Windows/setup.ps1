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

# Backup directory with timestamp
$BackupDir = Join-Path $HOME "dotfiles_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

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

    # Create backup directory
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
    Write-Host "Backup complete.`n" -ForegroundColor $Green

    Write-Host "Creating symlinks..." -ForegroundColor $Blue

    # Packages that use direct symbolic links (instead of winstow)
    $directPackages = @("nvim", "vscode-extensions", "powershell-profile")

    foreach ($pkg in $Packages) {
        $target = $pkg.Target
        $package = $pkg.Package
        $sourceRoot = $pkg.SourceRoot

        if ($pkg.Name -in $directPackages) {
            $sourcePath = [System.IO.Path]::Combine($ScriptDir, $sourceRoot, $package)
            $targetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target)

            if ($pkg.Name -eq "powershell-profile") {
                # Ensure target directory exists
                if (!(Test-Path $targetPath)) {
                    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                    Write-Host "  Created directory: $targetPath" -ForegroundColor $Yellow
                }

                # Link each item inside the powershell directory to the target
                Get-ChildItem -Path $sourcePath -Force | ForEach-Object {
                    $linkName = $_.Name
                    $targetLink = Join-Path $targetPath $linkName
                    # Remove existing (backup already done)
                    if (Test-Path $targetLink) {
                        Remove-Item -Path $targetLink -Force
                        Write-Host "  Removed existing: $targetLink" -ForegroundColor $Yellow
                    }
                    # Create symbolic link
                    New-Item -ItemType SymbolicLink -Path $targetLink -Target $_.FullName -Force | Out-Null
                    Write-Host "  Linked $linkName to $targetLink" -ForegroundColor $Green
                }
            } else {
                # For nvim and vscode-extensions: link single file/directory
                # Ensure parent directory exists
                $parent = Split-Path $targetPath -Parent
                if (!(Test-Path $parent)) {
                    New-Item -ItemType Directory -Path $parent -Force | Out-Null
                    Write-Host "  Created directory: $parent" -ForegroundColor $Yellow
                }

                # Remove existing target
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
            }
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
    default {
        Write-Host @"
Usage: setup.ps1 [command]

Commands:
  install      Install/update all configurations (with auto backup)
  uninstall    Remove all symlinks
  reinstall    Uninstall then reinstall
  help         Show this help

Example:
  .\setup.ps1 install
"@
    }
}
