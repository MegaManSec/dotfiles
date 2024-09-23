HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=100000
HISTFILESIZE=200000
EDITOR=nano

export EDITOR
export LC_ALL=C.UTF-8

shopt -s checkwinsize
force_color_prompt=yes
color_prompt=yes

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias ipgrep='grep -E '\''[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'\'''

alias ls='ls -GF'

[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && \
	source /usr/local/share/bash-completion/bash_completion.sh
#[[ -f ~/scripts/bash-preexec.sh ]] && source ~/scripts/bash-preexec.sh

#stitle() {
#	echo -ne "\033]0;$1\007"
#}
#precmd () { echo -ne "\a" ; history -a; history -c; history -r; stitle "${USER}@${HOSTNAME}: ${PWD}" "${PROMPT_COMMAND}"; }

#preexec () {
#	stitle "${USER}@${HOSTNAME}: ${PWD} - $1"
#}

#preexec_install
#export HISTFILE=/dev/null
alias cp='cp -p'
alias psf='ps -d'

#eval $(ssh-agent -s)
#ssh-add ~/.ssh/id_ecdsa
#export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOSTNAME.sock
#ssh-add -l &>/dev/null
#if [ $? -ge 2 ]; then
#  ssh-agent -a "$SSH_AUTH_SOCK" &>/dev/null
#fi

#if [ "$?" == 2 ]; then
#  [ -r "${SSH_AUTH_SOCK}" ] && \
#    eval "$(<${SSH_AUTH_SOCK})" >/dev/null

#  ssh-add -l &>/dev/null
#  if [ "$?" == 2 ]; then
#    (umask 066; ssh-agent > "${SSH_AUTH_SOCK}")
#    eval "$(<${SSH_AUTH_SOCK})" >/dev/null
#    ssh-add
#  fi
#fi

export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOSTNAME.sock
ssh-add -l 2>/dev/null >/dev/null
if [ $? -ge 2 ]; then
  rm "$SSH_AUTH_SOCK" &>/dev/null
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
fi
