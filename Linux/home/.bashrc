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

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
  else
    color_prompt=
  fi
fi

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
# 3. 加载拆分配置
# ----------------------------------------------------------------------
[ -f ~/.bash_aliases   ] && . ~/.bash_aliases
[ -f ~/.bash_functions ] && . ~/.bash_functions
[ -f ~/.bash_env       ] && . ~/.bash_env

# ----------------------------------------------------------------------
# 4. 补全功能 (Completion)
# ----------------------------------------------------------------------
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
