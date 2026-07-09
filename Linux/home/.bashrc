# ~/.bashrc: 由 bash 为非登录 shell 执行
# 参考: /usr/share/doc/bash/examples/startup-files

# ----------------------------------------------------------------------
# 1. 基础 Shell 选项
# ----------------------------------------------------------------------
# 非交互式 shell 直接返回
case $- in *i*) ;; *) return ;; esac

# 历史记录控制
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# 窗口大小自适应
shopt -s checkwinsize

# 如需要可启用 globstar（** 匹配）
# shopt -s globstar

# less 友好（非文本文件）
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ----------------------------------------------------------------------
# 2. 提示符 (PS1) 设置
# ----------------------------------------------------------------------
# 检测颜色支持
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# 若强制开启颜色，则检查 tput
if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
  else
    color_prompt=
  fi
fi

# 构建基本 PS1
if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# 针对 xterm 设置窗口标题
case "$TERM" in
xterm* | rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  ;;
esac

# Debian chroot 支持
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# ----------------------------------------------------------------------
# 3. 别名 (Aliases)
# ----------------------------------------------------------------------
# 启用颜色支持（ls, grep 等）
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
  alias c='clear'
fi

# 常用别名
# alias la='ls -A'
# alias l='ls -CF'

# 将输出通过 lolcat 染色（使用反斜杠避免别名循环）
# alias ls='\ls | lolcat'
# alias ll='\ls -l | lolcat'
alias cat='\cat "$@" | lolcat'
alias whoami='\whoami | lolcat'
alias f='fastfetch | lolcat'

# 系统工具别名（WSL 下使用 Windows 原生 OpenSSH）
alias ssh='ssh.exe'
alias ssh-add='ssh-add.exe'
alias scp='scp.exe'
alias sftp='sftp.exe'

# 其他工具
alias m='musicfox.exe'     # 网易云音乐终端版
alias n='nvim'             # Neovim
alias t='tmux new-session' # 启动新的 tmux 会话（修正原错误）

# 长命令提醒（alert）
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Windows Python 环境快捷方式（可选）
alias winpy='/mnt/c/Users/Administrator/miniconda3/envs/pyqt/python.exe'

# 加载用户自定义别名（若存在）
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# ----------------------------------------------------------------------
# 4. 函数 (Functions)
# ----------------------------------------------------------------------

# Yazi 目录跳转（退出 yazi 时自动 cd 到所选目录）
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

# 增强 apt：安装/卸载后自动更新手动安装列表
apt() {
  local sudo_cmd="sudo"
  # 若用户已是 root，则不加 sudo
  [ "$EUID" -eq 0 ] && sudo_cmd=""
  case "$1" in
  install | remove | purge | autoremove)
    $sudo_cmd apt "$@"
    apt-mark showmanual >~/dotConfig/Linux/manual-packages.list
    ;;
  *)
    $sudo_cmd apt "$@"
    ;;
  esac
}

# ----------------------------------------------------------------------
# 5. 环境初始化 (Conda, NVM, Cargo, Starship)
# ----------------------------------------------------------------------

# Conda (延迟加载：首次调用时初始化)
conda() {
  local CONDA_ROOT="$HOME/miniconda3"
  if [ -d "$CONDA_ROOT" ]; then
    unset -f conda # 移除自身函数，防止递归
    if [ -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]; then
      . "$CONDA_ROOT/etc/profile.d/conda.sh"
    else
      export PATH="$CONDA_ROOT/bin:$PATH"
    fi
    conda "$@" # 执行真正的 conda
  else
    echo "Error: Conda not found at $CONDA_ROOT" >&2
    return 1
  fi
}
# 注意：这里不自动调用 conda，仅定义函数

# Cargo (Rust)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Starship 提示符（放在最后，覆盖 PS1）
export name=mica
eval "$(starship init bash)"

# ----------------------------------------------------------------------
# 6. 补全功能 (Completion)
# ----------------------------------------------------------------------
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi

fi

# 自定义 Pandoc 转中文 PDF 函数
pandoc-cn() {
  if [ $# -eq 0 ]; then
    echo "用法: pandoc-cn <输入.md> [输出.pdf] [字号]"
    echo "示例: pandoc-cn 复习.md 复习.pdf 17pt"
    echo "提示: 字号默认 12pt，支持 10pt/11pt/12pt(标准) 或 14pt/17pt/20pt(extarticle)"
    return 1
  fi

  local input="$1"
  local output="${2:-${input%.md}.pdf}" # 若不指定输出，自动将 .md 替换为 .pdf
  local size="${3:-12pt}"               # 默认字号 12pt

  # 智能选择文档类：若字号大于12pt，自动启用 extarticle 以支持大字号
  local doc_class="article"
  if [[ "$size" == "14pt" || "$size" == "17pt" || "$size" == "20pt" ]]; then
    doc_class="extarticle"
    echo "检测到大字号 ($size)，自动切换至 extarticle 文档类。"
  fi

  # 执行转换命令（请根据你的字体情况修改下面的字体名称）
  pandoc "$input" -o "$output" --pdf-engine=xelatex \
    -V documentclass="$doc_class" \
    -V CJKmainfont="Yozai Font" \
    -V mainfont="FiraCode Nerd Font" \
    -V fontsize="$size"

  # 检查上一条命令是否执行成功
  if [ $? -eq 0 ]; then
    echo "✅ 转换成功！文件生成于: $output"
  else
    echo "❌ 转换失败，请检查字体名称或 Markdown 语法。"
  fi
}

# ============================================================
#  覆盖 uv 命令，使得 uv init 自动添加 [tool.pyright]
#  用法：与原 uv 命令完全相同
#  示例：uv init my_project
#        uv init .
#        uv add requests
# ============================================================
uv() {
  # 检查是否执行的是 init 子命令
  if [[ "$1" == "init" ]]; then
    # 移除第一个参数 "init"，保留其余参数
    shift
    local init_args=("$@")

    # 执行原始的 uv init，传递所有参数
    echo "🚀 执行: uv init ${init_args[*]}"
    if ! command uv init "${init_args[@]}"; then
      echo "❌ uv init 执行失败"
      return 1
    fi

    # --- 以下是自动添加 pyright 配置的逻辑 ---

    # 确定项目目录（第一个非选项参数）
    local project_dir="."
    for arg in "${init_args[@]}"; do
      # 跳过以 '-' 开头的选项
      if [[ "$arg" != -* ]]; then
        project_dir="$arg"
        break
      fi
    done

    # 如果项目目录不存在，跳过
    if [[ ! -d "$project_dir" ]]; then
      echo "⚠️ 警告: 项目目录 '$project_dir' 不存在，跳过 pyright 配置"
      return 0
    fi

    local toml_path="$project_dir/pyproject.toml"
    if [[ ! -f "$toml_path" ]]; then
      echo "⚠️ 警告: 未找到 $toml_path，跳过 pyright 配置"
      return 0
    fi

    # 检查是否已经包含 [tool.pyright]
    if grep -q "^\[tool\.pyright\]" "$toml_path"; then
      echo "ℹ️ pyright 配置已存在，无需重复添加"
      return 0
    fi

    # 追加配置到文件末尾
    {
      echo ""
      echo "[tool.pyright]"
      echo "venvPath = \".\""
      echo "venv = \".venv\""
    } >>"$toml_path"

    echo "✅ 已自动添加 pyright 配置到 $toml_path"

  else
    # 不是 init 子命令，直接透传
    command uv "$@"
  fi
}
