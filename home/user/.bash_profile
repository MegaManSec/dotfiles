if [[ "$OSTYPE" == "darwin"* ]]; then
  chflags uappnd ~/.bash_history
  BASH_SILENCE_DEPRECATION_WARNING=1
  HISTTIMEFORMAT='%F %T '

  eval "$(/opt/homebrew/bin/brew shellenv)"
  GRC_ALIASES=true
  PATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
  PATH="$HOMEBREW_PREFIX/opt/gawk/libexec/gnubin:$PATH"
  PATH="$HOMEBREW_PREFIX/opt/grep/libexec/gnubin:$PATH"
  PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"
  PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
  source "$HOMEBREW_PREFIX/etc/grc.sh"
  source "$HOMEBREW_PREFIX/etc/bash_completion"
  source "$HOMEBREW_PREFIX/etc/bash_completion.d/brew"

  complete -W "NSGlobalDomain" defaults
  shopt -u nocaseglob
  shopt -u cdspell
  shopt -s cmdhist
  shopt -s dirspell 2> /dev/null
  shopt -s globstar 2> /dev/null

  GREP_COLORS='mt=1;35;40'

  LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
  LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
  LESS_TERMCAP_me=$'\E[0m'           # end mode
  LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
  LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
  LESS_TERMCAP_ue=$'\E[0m'           # end underline
  LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

  CLICOLOR=1
  LSCOLORS=exfxcxdxbxegedabagacad

  alias copy=pbcopy

fi

HISTCONTROL=ignoreboth
shopt -s histappend
shopt -s checkwinsize
HISTSIZE=100000
HISTFILESIZE=200000
EDITOR=nano
VISUAL=nano
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

force_color_prompt=yes
color_prompt=yes

if [[ "$OSTYPE" == "darwin"* ]]; then
  LC_COLLATE=C # LC_ALL=C?
  LC_CTYPE=en_US.UTF-8
  PS1="\[\e[32m\][\[\e[m\]\[\e[31m\]\u\[\e[m\]\[\e[33m\]@\[\e[m\]\[\e[32m\]\h\[\e[m\]:\[\e[36m\]\w\[\e[m\]\[\e[32m\]]\[\e[m\]\[\e[32m\]\\$\[\e[m\] "
elif [[ "$OSTYPE" == "freebsd"* ]]; then
  LC_ALL=C.UTF-8 # LC_ALL=C?
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if [[ "$OSTYPE" == "freebsd"* ]]; then
  alias ipgrep='grep -E '\''[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'\'''
elif [[ "$OSTYPE" == "darwin"* ]]; then
  alias ipgrep='grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"'
fi


alias ls='ls -GF'

[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && \
	source /usr/local/share/bash-completion/bash_completion.sh

alias cp='cp -p'

if [[ "$OSTYPE" == "freebsd"* ]]; then
  alias psf='ps -d'
elif [[ "$OSTYPE" == "darwin"* ]]; then
  alias psf='pstree'
fi

export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOSTNAME.sock
ssh-add -l 2>/dev/null >/dev/null
if [ $? -ge 2 ]; then
  rm "$SSH_AUTH_SOCK" &>/dev/null
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
fi

alias hcurl="curl -sS -D - $1 -o /dev/null"

if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

urlencode() {
  if [ -p /dev/stdin ]; then
    jq -sRr @uri
  else
    printf "$1"| jq -sRr @uri
  fi
}
