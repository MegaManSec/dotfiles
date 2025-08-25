# Enable history settings
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
HISTSIZE=1000000
HISTFILESIZE=2000000
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
#export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND

# Enable colorful prompt
color_prompt=yes
force_color_prompt=yes

# Default editor
export EDITOR=nano
export VISUAL=nano

# Prompt and locale settings
case "$OSTYPE" in
  darwin*)
    chflags uappnd ~/.bash_history
    complete -W "NSGlobalDomain" defaults
    shopt -s histappend checkwinsize cmdhist dirspell globstar histappend
    shopt -u cdspell nocaseglob
    export LC_COLLATE=C
    export LC_CTYPE=en_US.UTF-8
    export BASH_SILENCE_DEPRECATION_WARNING=1
    export GREP_COLORS='mt=1;35;40'
    export CLICOLOR=1
    export LSCOLORS=exfxcxdxbxegedabagacad

    # History format
    export HISTTIMEFORMAT='%F %T '

    # Homebrew and GNU utilities
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      if [[ "$HOMEBREW_PREFIX" ]]; then
        PATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
        PATH="$HOMEBREW_PREFIX/opt/gawk/libexec/gnubin:$PATH"
        PATH="$HOMEBREW_PREFIX/opt/grep/libexec/gnubin:$PATH"
        PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"
        PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"

        # Load GRC and Bash completion
        export GRC_ALIASES=true
        [[ -r "$HOMEBREW_PREFIX/etc/grc.sh" ]] && source "$HOMEBREW_PREFIX/etc/grc.sh"
        [[ -r "$HOMEBREW_PREFIX/etc/bash_completion" ]] && source "$HOMEBREW_PREFIX/etc/bash_completion"
        [[ -r "$HOMEBREW_PREFIX/etc/bash_completion.d/brew" ]] && source "$HOMEBREW_PREFIX/etc/bash_completion.d/brew"
        [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
      fi
    fi

    # Less colors
    LESS_TERMCAP_mb=$'\E[01;31m'       # blinking
    LESS_TERMCAP_md=$'\E[01;38;5;74m'  # bold
    LESS_TERMCAP_me=$'\E[0m'
    LESS_TERMCAP_se=$'\E[0m'
    LESS_TERMCAP_so=$'\E[38;5;246m'
    LESS_TERMCAP_ue=$'\E[0m'
    LESS_TERMCAP_us=$'\E[04;38;5;146m'

    # Terminal prompt
    PS1="\[\e[32m\][\[\e[m\]\[\e[31m\]\u\[\e[m\]\[\e[33m\]@\[\e[m\]\[\e[32m\]\h\[\e[m\]:\[\e[36m\]\w\[\e[m\]\[\e[32m\]]\[\e[m\]\[\e[32m\]\\$\[\e[m\] "

    # CodeQL scans. XXX: Should standardize these and add Golang and Python (at least), and double check whether githubsecuritylab/codeql-java-queries is needed.

    codeql-scan-build() {
      mkdir /tmp/cql/ 2>/dev/null || true
      codeql database create /tmp/cql/"$(basename "$PWD")" --language=javascript --overwrite
    }
    codeql-scan-custom() {
      codeql database analyze --rerun /tmp/cql/"$(basename "$PWD")" ~/work/CodeQL-Custom-Queries/ --format=sarifv2.1.0 --output=/tmp/cql/"scan-$(basename "$PWD")-$(date +%s).sarif"
    }
    codeql-scan-large() {
      codeql database analyze --rerun /tmp/cql/"$(basename "$PWD")" ~/work/codeql-repo/javascript/ql/src/codeql-suites/java* --format=sarifv2.1.0 --output=/tmp/cql/"scan-$(basename "$PWD")-$(date +%s).sarif"
    }
    codeql-scan-java() {
      mkdir /tmp/cql/ 2>/dev/null || true
      export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" # XXX: Change version
      export JAVA_HOME=/opt/homebrew/opt/openjdk@21 # XXX: Change version
      codeql database create /tmp/cql/"$(basename "$PWD")" --language=java --overwrite
      codeql database analyze --rerun /tmp/cql/"$(basename "$PWD")" --ram=28000 ~/work/codeql-repo/java/ql/src/codeql-suites/java* --format=sarifv2.1.0 --output=/tmp/cql/"scan-$(basename "$PWD")-$(date +%s).sarif"
      codeql database analyze --rerun /tmp/cql/"$(basename "$PWD")" --ram=28000 --download githubsecuritylab/codeql-java-queries ~/work/CodeQL-Community-Packs/java/src/suites/* --format=sarifv2.1.0  --output=/tmp/cql/"scan-$(basename "$PWD")-$(date +%s)-gls.sarif"
    }
    copy() {
      if [ -p /dev/stdin ]; then
        pbcopy
      else
        cat -- "$1" | pbcopy
      fi
    }
    ;;
  freebsd*)
    export LC_ALL=C.UTF-8
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    [[ -f /usr/local/share/bash-completion/bash_completion.sh ]] && \
      source /usr/local/share/bash-completion/bash_completion.sh
    ;;
esac

# Aliases
alias ls='ls -GFh --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cp='cp -p'
alias grep='grep --color=auto'

# OS-specific aliases
case "$OSTYPE" in
  darwin*)
    alias psf='pstree'
    alias ipgrep='grep -E "\b((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b"' ;;
  freebsd*)
    alias psf='ps -d'
    alias ipgrep='grep -E '\''[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'\''' ;;
esac

# SSH agent management
export SSH_AUTH_SOCK=~/.ssh/agent/ssh-agent.$HOSTNAME.sock
ssh-add -l 2>/dev/null >/dev/null
if [ $? -ge 2 ]; then
  rm "$SSH_AUTH_SOCK" &>/dev/null
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
fi

# URL encode function
urlencode() {
  if [ -p /dev/stdin ]; then
    jq -sRr @uri
  else
    printf "%s" "$1" | jq -sRr @uri
  fi
}

# URL decode function
urldecode() {
  if [ -p /dev/stdin ]; then
    jq -sRr @urid
  else
    printf -- "%s" "$1"| jq -sRr @urid # https://github.com/jqlang/jq/milestone/12 urldecode will be in jq 1.8
  fi
}

# hcurl alias for header inspection
alias hcurl='curl -sS -D - $1 -o /dev/null'

# Ngrok completion
if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

enter_directory() {
  if [[ "$PWD" == "$PREV_PWD" ]]; then
    return
  fi
  PREV_PWD="$PWD"
  if [[ -r ".git/config" ]] && grep -qi 'git@github.com:MegaManSec' .git/config; then
    git_email="MegaManSec@users.noreply.github.com"
    grep -q -- "$git_email" ".git/config" && return
    git config --local commit.gpgsign false
    git config user.email "$git_email" && echo "Set git email address to $git_email!"
  fi

}
export PROMPT_COMMAND="enter_directory"
