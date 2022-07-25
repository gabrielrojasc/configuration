export PS1='%n %F{1}::%f %F{2}%~%f %F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '
export PATH=/usr/local/sbin:/usr/local/opt/python@3.9/libexec/bin:$HOME/.local/bin:$PATH
export EDITOR='vim'
export GPG_TTY=$(tty)
export PRE_COMMIT_COLOR=always

# source aliases
source ~/.zsh_aliases

# keep env if using tmux
if [ "$TMUX" ] && [ "$VIRTUAL_ENV" ];then
  source "$VIRTUAL_ENV/bin/activate"
fi

autoload -Uz compinit && compinit
