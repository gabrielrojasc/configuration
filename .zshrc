export PS1='%n %F{1}::%f %F{2}%~%f %F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH  # for python
export EDITOR="nvim"
export GPG_TTY=$(tty)

# source aliases
source ~/.zsh_aliases

# keep env if using tmux
if [ "$TMUX" ] && [ "$VIRTUAL_ENV" ];then
  . "$VIRTUAL_ENV/bin/activate"
fi

# Colors
export CLICOLOR=1
export LSCOLORS="ExFxCxDxBxegedabagacad"
# Linux LS_COLORS for zsh completion
export LS_COLORS="di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

# Highlight the current autocomplete option
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Tab complete hosts from ssh config
zstyle ':completion:*:ssh:*' hosts

# autocompletion 
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  autoload -Uz compinit
  compinit
fi

# direnv
eval "$(direnv hook zsh)"

# fnm
eval "$(fnm env --use-on-cd)"
