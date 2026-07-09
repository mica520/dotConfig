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

# ---------- 备份目录（带时间戳） ----------
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# ---------- 配置发现 ----------
# 遍历根目录下的子目录，生成 (源路径, 目标路径) 链接对。
# 新增配置只需在仓库根目录创建目录，无需手动修改此脚本。
#
# 约定：
#   <dir>/              → ~/.config/<dir>   （除以下特殊目录）
#   starship/           → ~/.config/starship.toml（单文件链接）
#   tmux/               → ~/.tmux.conf          （链接到 $HOME）
#   home/               → ~/<每个文件>          （点文件逐个链接）
#   lazygit/            → ~/.config/lazygit     （自动发现）

# 需要跳过的目录名（不是配置目录）
SKIP_DIRS=("home" ".git" "trash")

discover_links() {
  # 遍历仓库根目录下的每个子目录
  for dir in "$SCRIPT_DIR"/*/; do
    [ -d "$dir" ] || continue
    dir="${dir%/}"  # 去掉尾部斜杠
    local name
    name="$(basename "$dir")"

    # 跳过非配置目录
    local skip=false
    for s in "${SKIP_DIRS[@]}"; do
      [[ "$name" == "$s" ]] && skip=true && break
    done
    $skip && continue

    case "$name" in
      starship)
        # 特殊处理：链接单个 toml 文件到 ~/.config/
        if [ -f "$dir/starship.toml" ]; then
          echo "$dir/starship.toml|$HOME/.config/starship.toml"
        fi
        ;;
      tmux)
        # 特殊处理：链接 .tmux.conf 到 $HOME
        if [ -f "$dir/.tmux.conf" ]; then
          echo "$dir/.tmux.conf|$HOME/.tmux.conf"
        fi
        ;;
      *)
        # 默认：整个目录链接到 ~/.config/<name>
        echo "$dir|$HOME/.config/$name"
        ;;
    esac
  done

  # home/ 目录：每个文件/目录链接到 $HOME
  local home_dir="$SCRIPT_DIR/home"
  if [ -d "$home_dir" ]; then
    for file in "$home_dir"/.*; do
      local base
      base="$(basename "$file")"
      [ "$base" = "." ] || [ "$base" = ".." ] && continue
      [ -e "$file" ] && echo "$file|$HOME/$base"
    done
  fi
}

# ---------- 工具函数 ----------

# 备份单个文件或目录（如果存在）
backup_path() {
  local target="$1"
  local rel_path="$2"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  local backup_target="$BACKUP_DIR/$rel_path"
  mkdir -p "$(dirname "$backup_target")"

  echo -e "  ${YELLOW}📦 备份: $target${NC}"
  echo -e "     -> $backup_target"
  mv "$target" "$backup_target"
}

# 根据目标路径生成备份用的相对路径
target_to_relpath() {
  local target="$1"
  # ~/.config/xxx → xxx
  # ~/.xxx       → home/.xxx
  if [[ "$target" == "$HOME/.config/"* ]]; then
    echo "${target#$HOME/.config/}"
  else
    echo "home/${target#$HOME/}"
  fi
}

# ---------- 安装 ----------
do_install() {
  echo -e "${GREEN}🚀 开始部署 / 更新 Dotfiles ...${NC}"

  mkdir -p "$BACKUP_DIR"
  echo -e "${YELLOW}📁 备份目录: $BACKUP_DIR${NC}"

  read -p "是否继续? (y/N) " -n 2 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}已取消操作。${NC}"
    exit 2
  fi

  echo -e "\n${BLUE}开始备份现有配置...${NC}"

  # 备份所有将要被覆盖的路径（使用自动发现）
  while IFS='|' read -r src target; do
    [ -z "$src" ] && continue
    local rel_path
    rel_path="$(target_to_relpath "$target")"
    backup_path "$target" "$rel_path"
  done < <(discover_links)

  echo -e "${GREEN}✅ 备份完成${NC}\n"

  # 确保 ~/.config 存在
  mkdir -p "$HOME/.config"

  echo -e "${BLUE}开始创建符号链接...${NC}"

  while IFS='|' read -r src target; do
    [ -z "$src" ] && continue
    # 确保目标父目录存在
    mkdir -p "$(dirname "$target")"
    echo -e "  ${GREEN}->${NC} 链接: $target"
    ln -sfn "$src" "$target"
  done < <(discover_links)

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

# ---------- 卸载 ----------
do_uninstall() {
  echo -e "${BLUE}🧹 开始移除所有创建的符号链接...${NC}"

  local removed=0
  while IFS='|' read -r src target; do
    [ -z "$src" ] && continue
    if [ -L "$target" ]; then
      rm -f "$target"
      echo -e "  ${GREEN}->${NC} 移除 $target"
      ((removed++))
    fi
  done < <(discover_links)

  echo -e "${GREEN}✅ 卸载完成（移除 $removed 个链接）${NC}"
}

# ---------- 帮助信息 ----------
show_help() {
  cat <<EOF
用法: $0 [命令]

命令:
  install   (或 -i)   安装/更新所有配置（含自动备份，每次生成新目录）
  uninstall (或 -u)   移除所有已创建的符号链接
  reinstall (或 -r)   先卸载再重新安装
  help      (或 -h)   显示此帮助信息

约定：
  在仓库根目录新增一个目录（如 kitty/），setup.sh 会自动
  将其链接到 ~/.config/<目录名>，无需手动修改脚本。

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
