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
        [string]$Target,          # The path to back up (e.g., %APPDATA%\yazi\config)
        [string]$BackupSubPath    # Relative path inside the backup directory (e.g., yazi\config)
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

# Check if winstow is available (only needed for non-vscode-extensions packages)
function Test-WinStow {
    if (!(Get-Command winstow -ErrorAction SilentlyContinue)) {
        Write-Error "winstow not found. Please install it via: winget install winstow"
        exit 1
    }
}

# Uninstall all symlinks
function Do-Uninstall {
    Write-Host "Removing all symlinks..." -ForegroundColor $Blue
    foreach ($pkg in $Packages) {
        if ($pkg.Name -eq "vscode-extensions") {
            # Remove the symbolic link (just delete the target file/link)
            $targetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($pkg.Target)
            if (Test-Path $targetPath) {
                Remove-Item -Path $targetPath -Force
                Write-Host "  Removed $($pkg.Name)" -ForegroundColor $Green
            } else {
                Write-Host "  $($pkg.Name) not found, skipping." -ForegroundColor $Yellow
            }
        } else {
            $target = $pkg.Target
            $package = $pkg.Package
            $sourceRoot = $pkg.SourceRoot
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
    Test-WinStow  # winstow is still used for other packages

    # Create backup directory
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "Backup directory: $BackupDir" -ForegroundColor $Yellow

    # Ask for confirmation
    $response = Read-Host "Continue? (y/N)"
    if ($response -notmatch '^[Yy]$') {
        Write-Host "Operation cancelled." -ForegroundColor $Red
        exit 2
    }

    # Ensure required directories exist
    $configDir = Join-Path $HOME ".config"
    if (!(Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Host "Created $configDir" -ForegroundColor $Yellow
    }

    $vscodeDir = Join-Path $HOME ".vscode"
    if (!(Test-Path $vscodeDir)) {
        New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
        Write-Host "Created $vscodeDir" -ForegroundColor $Yellow
    }

    Write-Host "`nBacking up existing configurations..." -ForegroundColor $Blue
    foreach ($pkg in $Packages) {
        $pkgName = $pkg.Name

        # Special handling for packages that might target busy directories
        if ($pkgName -in @("home", "glazewm", "starship", "yasb")) {
            $pkgDir = Join-Path $pkg.SourceRoot $pkg.Package
            if (Test-Path $pkgDir) {
                if ($pkgName -eq "starship") {
                    # Only backup ~/.config/starship.toml
                    $targetFile = Join-Path $HOME ".config\starship.toml"
                    $backupSubPath = "starship\starship.toml"
                    Backup-Target -Target $targetFile -BackupSubPath $backupSubPath
                } elseif ($pkgName -eq "yasb") {
                    # Backup entire ~/.config/yasb directory
                    $targetDir = Join-Path $HOME ".config\yasb"
                    $backupSubPath = "yasb"
                    Backup-Target -Target $targetDir -BackupSubPath $backupSubPath
                } else {
                    # For home, glazewm: backup each item individually
                    Get-ChildItem -Path $pkgDir -Force | ForEach-Object {
                        $itemName = $_.Name
                        $targetPath = Join-Path $pkg.Target $itemName
                        $backupSubPath = Join-Path $pkg.BackupSubPath $itemName
                        Backup-Target -Target $targetPath -BackupSubPath $backupSubPath
                    }
                }
            }
        } else {
            # For other packages (nvim, yazi-config, vscode-*), backup the whole target path
            Backup-Target -Target $pkg.Target -BackupSubPath $pkg.BackupSubPath
        }
    }
    Write-Host "Backup complete.`n" -ForegroundColor $Green

    Write-Host "Creating symlinks..." -ForegroundColor $Blue
    foreach ($pkg in $Packages) {
        $target = $pkg.Target
        $package = $pkg.Package
        $sourceRoot = $pkg.SourceRoot

        if ($pkg.Name -eq "vscode-extensions") {
            # ---- Special handling: create symbolic link (avoids VSCode atomic save breaking the link) ----
            $relativeSource = Join-Path $sourceRoot $package
            $sourcePath = Join-Path $ScriptDir $relativeSource

            $targetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target)
            # Ensure parent directory exists
            $parent = Split-Path $targetPath -Parent
            if (!(Test-Path $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                Write-Host "  Created directory: $parent" -ForegroundColor $Yellow
            }
            # Remove existing target if present (file or directory)
            if (Test-Path $targetPath) {
                Remove-Item -Path $targetPath -Force
                Write-Host "  Removed existing: $targetPath" -ForegroundColor $Yellow
            }
            # Check source file exists
            if (!(Test-Path $sourcePath)) {
                Write-Warning "Source file not found: $sourcePath. Skipping link for $($pkg.Name)."
                continue
            }
            # Create symbolic link (requires admin rights or Developer Mode enabled)
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
            Write-Host "  Linked $($pkg.Name) (symbolic link) to $targetPath" -ForegroundColor $Green
        } else {
            # ---- All other packages use winstow ----
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
# Each package has:
#   Name           - Display name
#   SourceRoot     - Directory containing the package (relative to script root)
#   Package        - The package directory name or file path inside SourceRoot
#   Target         - Absolute target path to symlink to
#   BackupSubPath  - Relative path inside the backup directory for this package
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
    # ---------- Modified package: vscode-extensions ----------
    @{
        Name = "vscode-extensions"
        SourceRoot = "vscode"
        Package = ".vscode/extensions.json"                     # 源文件（注意单数）
        Target = "$env:USERPROFILE/.vscode/extensions/extensions.json"  # 目标路径
        BackupSubPath = ".vscode/extensions.json"
    },
    # ---------------------------------------------------------
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
