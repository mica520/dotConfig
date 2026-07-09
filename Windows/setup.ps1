#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Windows Dotfiles Setup — deploy configuration files via symbolic links.

.DESCRIPTION
    One-command deployment of all dotfiles on a Windows machine. Existing
    configurations are backed up before being replaced by symlinks pointing
    into this repository.

    PowerShell 5.0+ is required. Administrator rights are NOT required when
    Windows Developer Mode is enabled (which allows unprivileged symlinks).

.PARAMETER Command
    install    – Back up existing configs, then create symlinks.
    uninstall  – Remove all symlinks created by this script.
    reinstall  – Uninstall then install (clean restart).
    help       – Show this usage text.

.PARAMETER DryRun
    Preview what would be changed without actually modifying the filesystem.

.EXAMPLE
    .\setup.ps1 install
    .\setup.ps1 install -DryRun
    .\setup.ps1 uninstall
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "uninstall", "reinstall", "help")]
    [string]$Command,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# ---------- Colors ----------
$C_Red    = "Red"
$C_Green  = "Green"
$C_Yellow = "Yellow"
$C_Blue   = "Blue"
$C_Cyan   = "Cyan"

# ---------- Backup root ----------
$BackupDir = Join-Path $HOME "dotfiles_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ===================================================================
# Package Definitions
# ===================================================================
# Each package has:
#   Name       – Human-readable label (used in log messages).
#   Type       – "File"      : symlink a single file.
#                "Directory" : symlink an entire directory (replaces target).
#                "Contents"  : symlink each item INSIDE Source into TargetDir.
#                              Use this when the target directory must not be
#                              replaced (e.g. $HOME).
#   SourceRoot – Relative path from $ScriptDir to the parent of Source.
#   Source     – File or directory name under SourceRoot.
#   TargetDir  – Directory where the symlink(s) will be created.
#   TargetName – (Optional) Override the leaf name; defaults to Source leaf.
# ===================================================================
$Packages = @(
    @{
        Name       = "nvim"
        Type       = "Directory"
        SourceRoot = "."
        Source     = "nvim"
        TargetDir  = "$env:LOCALAPPDATA"
        TargetName = "nvim"
    },
    @{
        Name       = "yazi-config"
        Type       = "Directory"
        SourceRoot = "yazi"
        Source     = "config"
        TargetDir  = "$env:APPDATA\yazi"
        TargetName = "config"
    },
    @{
        Name       = "starship"
        Type       = "Contents"
        SourceRoot = "."
        Source     = "starship"
        TargetDir  = "$env:USERPROFILE\.config"
    },
    @{
        Name       = "home"
        Type       = "Contents"
        SourceRoot = "."
        Source     = "home"
        TargetDir  = "$env:USERPROFILE"
    },
    @{
        Name       = "vscode-user"
        Type       = "Directory"
        SourceRoot = "vscode"
        Source     = "User"
        TargetDir  = "$env:APPDATA\Code"
        TargetName = "User"
    },
    @{
        Name       = "vscode-extensions"
        Type       = "File"
        SourceRoot = "vscode"
        Source     = ".vscode\extensions.json"
        TargetDir  = "$env:USERPROFILE\.vscode\extensions"
        TargetName = "extensions.json"
    },
    @{
        Name       = "powershell-profile"
        Type       = "File"
        SourceRoot = "."
        Source     = "powershell\Microsoft.PowerShell_profile.ps1"
        TargetDir  = Split-Path $PROFILE -Parent
        TargetName = Split-Path $PROFILE -Leaf
    },
    @{
        Name       = "glazewm"
        Type       = "Contents"
        SourceRoot = "."
        Source     = "glazewm"
        TargetDir  = "$env:USERPROFILE"
    },
    @{
        Name       = "yasb"
        Type       = "Directory"
        SourceRoot = "."
        Source     = "yasb"
        TargetDir  = "$env:USERPROFILE\.config"
        TargetName = "yasb"
    }
)

# ===================================================================
# Helper Functions
# ===================================================================

function Get-SourcePath {
    param($Pkg)
    return Join-Path $ScriptDir $Pkg.SourceRoot $Pkg.Source
}

function Get-TargetPath {
    param($Pkg)
    if ($Pkg.TargetName) {
        return Join-Path $Pkg.TargetDir $Pkg.TargetName
    }
    return $Pkg.TargetDir
}

function Backup-One {
    param(
        [string]$Target,
        [string]$BackupSubPath
    )
    if (Test-Path $Target) {
        $dest = Join-Path $BackupDir $BackupSubPath
        $destParent = Split-Path $dest -Parent
        if (!(Test-Path $destParent)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $destParent -Force | Out-Null
            }
        }
        Write-Host "  ← Backing up: $Target" -ForegroundColor $C_Yellow
        Write-Host "           -> $dest" -ForegroundColor $C_Yellow
        if (-not $DryRun) {
            Move-Item -Path $Target -Destination $dest -Force
        }
    }
}

function Ensure-ParentDir {
    param([string]$Path)
    $parent = Split-Path $Path -Parent
    if ($parent -and !(Test-Path $parent)) {
        Write-Host "  + Creating directory: $parent" -ForegroundColor $C_Yellow
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }
}

function Link-One {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label
    )
    # Remove existing target (file or directory)
    if (Test-Path $Target) {
        Write-Host "  ✕ Removing existing: $Target" -ForegroundColor $C_Yellow
        if (-not $DryRun) {
            Remove-Item -Path $Target -Force -Recurse
        }
    }

    if (!(Test-Path $Source)) {
        Write-Warning "  ! Source missing: $Source — skipping $Label."
        return
    }

    Write-Host "  → Linking $Label" -ForegroundColor $C_Green
    Write-Host "        $Target  -->  $Source" -ForegroundColor $C_Cyan
    if (-not $DryRun) {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
    }
}

# ===================================================================
# Operations
# ===================================================================

function Do-Uninstall {
    Write-Host "Removing all symlinks..." -ForegroundColor $C_Blue

    foreach ($pkg in $Packages) {
        $source = Get-SourcePath $pkg

        if ($pkg.Type -eq "Contents") {
            if (!(Test-Path $source)) { continue }
            Get-ChildItem -Path $source -Force | ForEach-Object {
                $target = Join-Path $pkg.TargetDir $_.Name
                if (Test-Path $target) {
                    Write-Host "  ✕ $($pkg.Name)/$($_.Name)" -ForegroundColor $C_Green
                    if (-not $DryRun) {
                        Remove-Item -Path $target -Force -Recurse
                    }
                }
            }
        } else {
            $target = Get-TargetPath $pkg
            if (Test-Path $target) {
                Write-Host "  ✕ $($pkg.Name)" -ForegroundColor $C_Green
                if (-not $DryRun) {
                    Remove-Item -Path $target -Force -Recurse
                }
            } else {
                Write-Host "  - $($pkg.Name) not found, skipping." -ForegroundColor $C_Yellow
            }
        }
    }

    Write-Host "Uninstall complete." -ForegroundColor $C_Green
}

function Do-Install {
    if ($DryRun) {
        Write-Host "*** DRY RUN — no changes will be made. ***`n" -ForegroundColor $C_Yellow
    }

    Write-Host "Deploying Windows configurations..." -ForegroundColor $C_Green

    # Create backup directory (dry-run skips this)
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    Write-Host "Backup directory: $BackupDir" -ForegroundColor $C_Yellow

    $response = Read-Host "Continue? (y/N)"
    if ($response -notmatch '^[Yy]$') {
        Write-Host "Cancelled." -ForegroundColor $C_Red
        exit 2
    }

    # Pre-create common target directories
    $dirsToCreate = @(
        (Join-Path $HOME ".config"),
        (Join-Path $HOME ".vscode\extensions"),
        (Split-Path $PROFILE -Parent)
    )
    foreach ($d in $dirsToCreate) {
        if ($d -and !(Test-Path $d)) {
            Write-Host "  + Creating directory: $d" -ForegroundColor $C_Yellow
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $d -Force | Out-Null
            }
        }
    }

    # ---- Phase 1: Backup ----
    Write-Host "`n[Phase 1/2] Backing up existing configurations..." -ForegroundColor $C_Blue
    foreach ($pkg in $Packages) {
        $source = Get-SourcePath $pkg
        if (!(Test-Path $source)) { continue }

        if ($pkg.Type -eq "Contents") {
            Get-ChildItem -Path $source -Force | ForEach-Object {
                $target = Join-Path $pkg.TargetDir $_.Name
                $sub    = Join-Path $pkg.Name $_.Name
                Backup-One -Target $target -BackupSubPath $sub
            }
        } else {
            $target = Get-TargetPath $pkg
            $leaf   = Split-Path $target -Leaf
            $sub    = Join-Path $pkg.Name $leaf
            Backup-One -Target $target -BackupSubPath $sub
        }
    }
    Write-Host "Backup phase complete.`n" -ForegroundColor $C_Green

    # ---- Phase 2: Link ----
    Write-Host "[Phase 2/2] Creating symbolic links..." -ForegroundColor $C_Blue
    $failed = @()

    foreach ($pkg in $Packages) {
        $source = Get-SourcePath $pkg

        if (!(Test-Path $source)) {
            Write-Warning "  ! Source missing: $source — skipping $($pkg.Name)."
            $failed += $pkg.Name
            continue
        }

        try {
            if ($pkg.Type -eq "Contents") {
                Get-ChildItem -Path $source -Force | ForEach-Object {
                    $itemSource = $_.FullName
                    $targetPath = Join-Path $pkg.TargetDir $_.Name
                    Ensure-ParentDir $targetPath
                    Link-One -Source $itemSource -Target $targetPath -Label "$($pkg.Name)/$($_.Name)"
                }
            } else {
                $targetPath = Get-TargetPath $pkg
                Ensure-ParentDir $targetPath
                Link-One -Source $source -Target $targetPath -Label $pkg.Name
            }
        } catch {
            Write-Warning "  ! Failed to link $($pkg.Name): $_"
            $failed += $pkg.Name
        }
    }

    # ---- Summary ----
    Write-Host ""
    if ($failed.Count -eq 0) {
        Write-Host "All configurations deployed successfully!" -ForegroundColor $C_Green
    } else {
        Write-Host "Done with $($failed.Count) failure(s): $($failed -join ', ')" -ForegroundColor $C_Yellow
    }
    if (-not $DryRun) {
        Write-Host "Backup stored at: $BackupDir" -ForegroundColor $C_Yellow
    } else {
        Write-Host "[Dry run — no changes were made.]" -ForegroundColor $C_Cyan
    }
}

# ===================================================================
# Main Entry Point
# ===================================================================

# Support both named -Command and positional first argument
if (-not $Command) { $Command = $args[0] }

switch ($Command) {
    "install"   { Do-Install }
    "uninstall" { Do-Uninstall }
    "reinstall" { Do-Uninstall; Do-Install }
    "help"      { Get-Help $MyInvocation.MyCommand.Path -Detailed }
    default {
        Write-Host @"
Windows Dotfiles Setup

Usage:
  .\setup.ps1 <command> [-DryRun]

Commands:
  install      Deploy configurations (backup existing, then symlink)
  uninstall    Remove all managed symlinks
  reinstall    Uninstall + install (clean restart)
  help         Show detailed help

Options:
  -DryRun      Preview all changes without touching the filesystem

Examples:
  .\setup.ps1 install
  .\setup.ps1 install -DryRun
  .\setup.ps1 reinstall
"@
    }
}
