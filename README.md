# dotConfig

个人跨平台配置文件仓库，覆盖 **Windows** 和 **Linux / WSL2** 两大环境。通过符号链接实现一键部署，换机即用。

## 设计理念

- **代码化管理** — 所有配置纳入 Git 版本控制，可追溯、可回滚
- **符号链接部署** — 配置源文件留在仓库中，通过符号链接映射到系统路径，修改仓库即生效
- **自动发现** — Linux 端新增配置目录无需修改脚本，约定优于配置
- **安全备份** — 每次安装自动将旧配置备份到带时间戳的目录，放心迁移

---

## 目录结构

```
dotConfig/
├── README.md                  # 本文件
├── .gitignore
├── Linux/                     # Linux / WSL2 配置
│   ├── setup.sh               # 一键部署脚本（bash）
│   ├── manual-packages.list   # apt 手动安装的软件包清单
│   ├── home/                  # 家目录点文件 → 链接到 ~/
│   │   ├── .bashrc            # Shell 核心配置 + 补全
│   │   ├── .bash_aliases      # 别名定义
│   │   ├── .bash_functions    # 自定义函数（y, apt, conda, pandoc-cn, uv）
│   │   ├── .bash_env          # 环境初始化（Cargo, NVM, Starship, Claude Code）
│   │   ├── .gitconfig         # Git 全局配置
│   │   └── .condarc           # Conda 镜像源配置
│   ├── nvim/                  # → ~/.config/nvim（LazyVim）
│   ├── tmux/                  # → ~/.tmux.conf（基于 gpakosz/.tmux）
│   ├── starship/              # → ~/.config/starship.toml（Catppuccin Mocha 主题）
│   ├── yazi/                  # → ~/.config/yazi（终端文件管理器）
│   └── lazygit/               # → ~/.config/lazygit（Git TUI）
│
└── Windows/                   # Windows 配置
    ├── setup.ps1              # 一键部署脚本（PowerShell）
    ├── packages.winget.json   # Winget 包列表（自动导出）
    ├── home/                  # 用户目录点文件 → 链接到 %USERPROFILE%
    │   ├── .gitconfig         # Git 全局配置
    │   ├── .wslconfig         # WSL2 资源限制
    │   └── .ssh/              # SSH 配置
    ├── powershell/            # PowerShell 配置文件
    │   ├── Microsoft.PowerShell_profile.ps1  # 主 Profile
    │   ├── conda_init.ps1     # Conda 初始化
    │   ├── conda_lazy.ps1     # Conda 懒加载
    │   ├── starship_init.ps1  # Starship 初始化
    │   └── keymaps.reg        # 键位映射注册表
    ├── nvim/                  # → %LOCALAPPDATA%\nvim（LazyVim）
    ├── starship/              # → ~/.config/starship.toml
    ├── vscode/                # VS Code 配置
    │   ├── User/              # → %APPDATA%\Code\User（settings / keybindings）
    │   └── .vscode/           # 推荐扩展列表
    ├── glazewm/               # GlazeWM 平铺窗口管理器
    ├── yasb/                  # YASB 状态栏（Catppuccin 风格）
    ├── yazi/                  # Yazi 文件管理器 + 插件
    └── environments/          # 环境变量参考
```

---

## Linux / WSL2

### 前置要求

- Bash 环境
- Git

### 快速开始

```bash
cd Linux
./setup.sh install     # 备份旧配置 + 创建符号链接
./setup.sh uninstall   # 移除所有符号链接
./setup.sh reinstall   # 先卸载再安装
./setup.sh help        # 查看帮助
```

### 约定

在 `Linux/` 目录下新增任意子目录（如 `kitty/`），`setup.sh` 会**自动**将其链接到 `~/.config/<目录名>`，无需手动修改脚本。

| 目录 | 特殊处理 |
| --- | --- |
| `starship/` | 链接单个文件 `starship.toml` → `~/.config/starship.toml` |
| `tmux/` | 链接 `.tmux.conf` → `~/.tmux.conf` |
| `home/` | 逐个链接目录内的点文件到 `~` |
| 其他目录 | 整个目录链接到 `~/.config/<目录名>` |

### 管理的配置

| 工具 | 说明 |
| --- | --- |
| **Bash** | `.bashrc`（核心配置 + 补全）、`.bash_aliases`（别名）、`.bash_functions`（自定义函数）、`.bash_env`（环境初始化） |
| **Neovim** | 基于 LazyVim 发行版，含代码补全、Markdown 预览、LaTeX 等插件 |
| **Tmux** | 基于 gpakosz/.tmux 配置，含鼠标支持、状态栏美化 |
| **Starship** | Catppuccin Mocha 主题，跨 Shell 提示符 |
| **Yazi** | 终端文件管理器，含 Catppuccin 主题和按键映射 |
| **Lazygit** | Git 终端 UI |

### 软件包清单

`manual-packages.list` 记录了通过 apt 手动安装的软件包，可用于新机批量安装：

```bash
xargs -a manual-packages.list sudo apt install -y
```

---

## Windows

### 前置要求

- **PowerShell 5.0+**（Windows 10/11 内置）
- **开发人员模式**已启用（设置 → 隐私和安全性 → 开发者选项）— 允许非管理员创建符号链接

### 快速开始

```powershell
cd Windows

# 预览变更（安全，不修改任何文件）
.\setup.ps1 install -DryRun

# 一键部署
.\setup.ps1 install

# 移除所有符号链接
.\setup.ps1 uninstall

# 重新部署
.\setup.ps1 reinstall
```

### 管理的配置

| 配置项 | 目标路径 | 说明 |
| --- | --- | --- |
| **Neovim** | `%LOCALAPPDATA%\nvim` | LazyVim 发行版，含 LaTeX / Markdown / Python 支持 |
| **Yazi** | `%APPDATA%\yazi\config` | 终端文件管理器 + 全套插件 |
| **Starship** | `%USERPROFILE%\.config` | Catppuccin Mocha 主题提示符 |
| **Home** | `%USERPROFILE%` | Git 全局配置、WSL 配置、SSH 配置 |
| **VS Code** | `%APPDATA%\Code\User` | settings.json / keybindings.json / AI Chat 模型配置 |
| **VS Code 扩展** | `%USERPROFILE%\.vscode\extensions` | 推荐扩展列表 |
| **PowerShell Profile** | `$PROFILE` | 含 Winget 自动导出、Conda 懒加载、Starship 初始化 |
| **GlazeWM** | `%USERPROFILE%` | 平铺窗口管理器配置 |
| **YASB** | `%USERPROFILE%\.config\yasb` | Catppuccin 风格状态栏 |

### Winget 自动导出

PowerShell Profile 内置了 `winget` 包装函数：每次执行 `winget install` / `upgrade` / `uninstall` 后，自动将当前包列表导出到 `packages.winget.json`，确保软件清单始终与系统同步。

恢复安装：

```powershell
winget import -i packages.winget.json
```

---

## 备份与恢复

每次执行 `install` 都会在用户目录下生成带时间戳的备份：

- **Linux**: `~/dotfiles_backup_YYYYMMDD_HHMMSS/`
- **Windows**: `%USERPROFILE%\dotfiles_backup_YYYYMMDD_HHMMSS\`

如需回滚，将备份目录中的文件手动复制回原位即可。多次安装生成多个备份目录，旧备份不会被覆盖。

---

## 新机上手流程

### Linux / WSL2

```bash
git clone https://github.com/mica520/dotConfig ~/dotConfig
cd ~/dotConfig/Linux
xargs -a manual-packages.list sudo apt install -y   # 安装软件包
./setup.sh install                                   # 部署配置
```

### Windows

```powershell
git clone https://github.com/mica520/dotConfig $env:USERPROFILE\dotConfig
cd $env:USERPROFILE\dotConfig\Windows
winget import -i packages.winget.json                # 安装软件包
.\setup.ps1 install                                   # 部署配置
```
