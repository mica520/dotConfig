#!/usr/bin/env bash

# 出错即停止（避免雪崩）
set -e

# 获取脚本所在目录（即 dotConfig 仓库根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------- 核心改动：备份目录带时间戳 ----------
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# ---------- 工具函数 ----------

# 备份单个文件或目录（如果存在）
# 参数1: 目标路径 (如 ~/.config/nvim)
# 参数2: 在备份目录中的相对路径 (如 nvim)
backup_path() {
  local target="$1"
  local rel_path="$2"

  # 如果目标不存在，直接跳过
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  # 构造备份目标路径
  local backup_target="$BACKUP_DIR/$rel_path"
  mkdir -p "$(dirname "$backup_target")"

  echo -e "  ${YELLOW}📦 备份: $target${NC}"
  echo -e "     -> $backup_target"

  # 执行移动（备份），由于目标目录是新建的，不会冲突
  mv "$target" "$backup_target"
}

# 卸载功能（保持不变）
do_uninstall() {
  echo -e "${BLUE}🧹 开始移除所有创建的软链接...${NC}"

  # 使用 stow -D 删除各个包的链接
  if [ -d "$HOME/.config/nvim" ]; then
    stow -D -t "$HOME/.config/nvim" nvim 2>/dev/null || true
  fi

  if [ -d "$HOME/.config/yazi" ]; then
    stow -D -t "$HOME/.config/yazi" yazi 2>/dev/null || true
  fi

  if [ -d "$HOME/.config" ]; then
    stow -D -t "$HOME/.config" starship 2>/dev/null || true
  fi

  stow -D -t "$HOME" home 2>/dev/null || true

  if [ -L "$HOME/.tmux.conf" ]; then
    rm -f "$HOME/.tmux.conf"
    echo -e "  ${GREEN}->${NC} 移除 ~/.tmux.conf"
  fi

  echo -e "${GREEN}✅ 卸载完成${NC}"
}

# ---------- 安装核心 ----------

do_install() {
  echo -e "${GREEN}🚀 开始部署 / 更新 Dotfiles ...${NC}"

  # 创建带时间戳的备份目录
  mkdir -p "$BACKUP_DIR"
  echo -e "${YELLOW}📁 备份目录: $BACKUP_DIR${NC}"

  # 询问是否继续
  read -p "是否继续? (y/N) " -n 2 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}已取消操作。${NC}"
    exit 2
  fi

  echo -e "\n${BLUE}开始备份现有配置...${NC}"

  backup_path "$HOME/.config/nvim" "nvim"
  backup_path "$HOME/.config/yazi" "yazi"
  backup_path "$HOME/.config/tmux" "tmux"
  backup_path "$HOME/.config/starship.toml" "starship/starship.toml"
  backup_path "$HOME/.bashrc" "home/.bashrc"
  backup_path "$HOME/.gitconfig" "home/.gitconfig"
  backup_path "$HOME/.tmux.conf" "home/.tmux.conf"

  echo -e "${GREEN}✅ 备份完成${NC}\n"

  mkdir -p "$HOME/.config"

  echo -e "${BLUE}开始创建软链接...${NC}"

  echo -e "  ${GREEN}->${NC} 链接 nvim ..."
  mkdir -p "$HOME/.config/nvim"
  stow -t "$HOME/.config/nvim" nvim

  echo -e "  ${GREEN}->${NC} 链接 yazi ..."
  mkdir -p "$HOME/.config/yazi"
  stow -t "$HOME/.config/yazi" yazi

  if [ -d "tmux" ] && [ -f "tmux/.tmux.conf" ]; then
    echo -e "  ${GREEN}->${NC} 链接 tmux ..."
    ln -sf "$SCRIPT_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
  else
    echo -e "  ${YELLOW}-> 跳过 tmux（未找到配置文件）${NC}"
  fi

  echo -e "  ${GREEN}->${NC} 链接 starship ..."
  mkdir -p "$HOME/.config"
  stow -t "$HOME/.config" starship

  echo -e "  ${GREEN}->${NC} 链接 home 包到 ~/ ..."
  stow -R -t "$HOME" home

  # 重新加载 bash 配置
  echo -e "\n${BLUE}重新加载 ~/.bashrc 以使新配置生效...${NC}"
  if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
    echo -e "${GREEN}✅ ~/.bashrc 已重新加载${NC}"
  else
    echo -e "${YELLOW}⚠ ~/.bashrc 不存在，跳过${NC}"
  fi

  echo -e "\n${GREEN}✅ 所有配置已链接完成！${NC}"
  echo -e "📦 旧配置已备份至: ${YELLOW}$BACKUP_DIR${NC}"
  echo -e "   （每次运行都会生成新的备份目录，旧备份不会丢失）"
}

# ---------- 帮助信息 ----------

show_help() {
  cat <<EOF
用法: $0 [命令]

命令:
  install   (或 -i)   安装/更新所有配置（含自动备份，每次生成新目录）
  uninstall (或 -u)   移除所有已创建的软链接
  reinstall (或 -r)   先卸载再重新安装
  help      (或 -h)   显示此帮助信息

示例:
  ./setup.sh install    # 一键部署（旧配置备份到带时间戳的新目录）
  ./setup.sh uninstall  # 清除所有软链接
EOF
}

# ---------- 主入口 ----------

case "$1" in
install | --install | -i)
  do_install
  ;;
uninstall | --uninstall | -u)
  do_uninstall
  ;;
reinstall | --reinstall | -r)
  do_uninstall
  do_install
  ;;
help | --help | -h | '')
  show_help
  ;;
*)
  echo -e "${RED}❌ 未知命令: $1${NC}"
  show_help
  exit 1
  ;;
esac
