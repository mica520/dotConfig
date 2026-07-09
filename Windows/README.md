# Windows Dotfiles

Personal Windows configuration managed as code and deployed via symbolic links.

## Quick Start

```powershell
# Preview what will happen (safe, no changes)
.\setup.ps1 install -DryRun

# Deploy everything
.\setup.ps1 install
```

## Prerequisites

- **PowerShell 5.0+** (built into Windows 10/11)
- **Developer Mode** enabled (Settings → Privacy & security → For developers) — allows creating symlinks without Administrator rights

## Usage

| Command | What it does |
|---|---|
| `install` | Back up existing configs, then create symlinks pointing into this repo |
| `uninstall` | Remove all symlinks managed by this script |
| `reinstall` | Uninstall then install (clean restart) |
| `help` | Show detailed help |

Add `-DryRun` to any command to preview without making changes:

```powershell
.\setup.ps1 uninstall -DryRun
```

## What's Managed

| Package | Target | What it configures |
|---|---|---|
| `nvim` | `%LOCALAPPDATA%\nvim` | Neovim (LazyVim-based) |
| `yazi-config` | `%APPDATA%\yazi\config` | Yazi terminal file manager |
| `starship` | `%USERPROFILE%\.config` | Starship prompt |
| `home` | `%USERPROFILE%` | Git global config, WSL config |
| `vscode-user` | `%APPDATA%\Code\User` | VS Code settings & keybindings |
| `vscode-extensions` | `%USERPROFILE%\.vscode\extensions` | Recommended VS Code extensions |
| `powershell-profile` | `$PROFILE` | PowerShell profile |
| `glazewm` | `%USERPROFILE%` | GlazeWM tiling window manager |
| `yasb` | `%USERPROFILE%\.config\yasb` | YASB status bar |

## Directory Structure

```
Windows/
├── setup.ps1              # Main deployment script
├── packages.winget.json   # Winget package list (auto-exported)
├── powershell/            # PowerShell profile scripts
├── home/                  # Dotfiles placed in $HOME
├── nvim/                  # Neovim (LazyVim) configuration
├── starship/              # Starship prompt configuration
├── vscode/                # VS Code settings & extensions
├── yasb/                  # YASB status bar
├── glazewm/               # GlazeWM tiling WM
├── yazi/                  # Yazi file manager
└── environments/          # Environment variable reference
```

## Winget Auto-Export

The PowerShell profile includes a `winget` wrapper that automatically exports the package list to `packages.winget.json` after every `install`, `upgrade`, or `uninstall` operation. The export path is derived from `$PROFILE` location — just make sure your profile points into this repository.

## Restoring from Backup

The `install` command creates a timestamped backup at:
```
%USERPROFILE%\dotfiles_backup_YYYYMMDD_HHmmss\
```
To restore, simply move the files back from the backup directory to their original locations.
