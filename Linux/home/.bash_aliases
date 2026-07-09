# ----------------------------------------------------------------------
# 别名 (Aliases)
# ----------------------------------------------------------------------

# 启用颜色支持（ls, grep 等）
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
  alias c='clear'
fi

# lolcat 染色
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
alias t='tmux new-session' # 启动新的 tmux 会话

# 长命令提醒（alert）
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Windows Python 环境快捷方式（可选）
alias winpy='/mnt/c/Users/Administrator/miniconda3/envs/pyqt/python.exe'

# 加载用户自定义别名（若存在）
[ -f ~/.bash_aliases_local ] && . ~/.bash_aliases_local
