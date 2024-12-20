autoload colors; colors

# Git prompt configuration
git_prompt_info() {
  local dirstatus=""
  local dirty="%{$fg_bold[red]%} X%{$reset_color%}"

  if [[ ! -z $(git status --porcelain 2> /dev/null) ]]; then
    dirstatus=$dirty
  fi

  ref=$(git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(git rev-parse --short HEAD 2> /dev/null) || return
  echo " %{$fg_bold[green]%}[${ref#refs/heads/}]$dirstatus%{$reset_color%}"
}

# Prompt styling
local dir_info_color="%F{#B2BEB5}"
local dir_info="%{$dir_info_color%}%(5~|%-1~/.../%2~|%4~)%{$reset_color%}"
local promptnormal="$ %{$reset_color%}"
local promptjobs="%{$fg_bold[red]%}$ %{$reset_color%}"

# Set up prompt with git info and directory status
setopt PROMPT_SUBST
PROMPT='${dir_info}$(git_prompt_info) %(1j.$promptjobs.$promptnormal)'

HISTSIZE=50000
SAVEHIST=50000

# Language
# https://askubuntu.com/questions/1219271/im-having-a-problem-with-locale-and-locale-gen-in-ubuntu
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

if hash nvim 2>/dev/null; then
  export EDITOR=nvim
  export VISUAL=nvim
  export GIT_EDITOR=nvim
  export MANPAGER='nvim +Man!'
else
  export EDITOR=vim
  export VISUAL=vim
  export GIT_EDITOR=vim
fi

# Java
if [[ "$OSTYPE" == "darwin"* ]]; then
  export JAVA_HOME=$(/usr/libexec/java_home)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
else
  return 1
fi

export PATH=$JAVA_HOME/bin:$PATH

# Node
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Python
# curl https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

bindkey -v
export KEYTIMEOUT=1

bindkey -M vicmd v edit-command-line
bindkey "^Q" push-input

bindkey "\eOA" up-line-or-history
bindkey "\eOB" down-line-or-history
bindkey "\eOC" forward-char
bindkey "\eOD" backward-char

bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char

bindkey -s ^f "~/.dotfiles/scripts/sessionizer\n"

setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
unsetopt HIST_VERIFY

unsetopt flowcontrol

autoload -Uz compinit
compinit

setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_PUSHD

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

alias ..="cd .."
alias ...="cd ../.."

alias ls="ls --color=auto"
alias ll="ls -lh"
alias la="ls -lah"

alias vim="nvim"

alias gi="git init"
alias gs="git status"
alias gc="git commit"
alias gco="git checkout"
alias glg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all"
alias ga="git add"
alias gb="git branch"
alias gba="git branch --all"
alias gd="git difftool"
alias gds="git diff -w --staged"
alias grs="git restore --staged"
alias grd="git fetch origin && git rebase origin/master"
alias gp="git push -u origin"

# Conda
__conda_setup="$($HOME/anaconda3/bin/conda 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/anaconda3/etc/profile.d/conda.sh"
  else
    export PATH="$HOME/anaconda3/bin:$PATH"
  fi
fi
unset __conda_setup
