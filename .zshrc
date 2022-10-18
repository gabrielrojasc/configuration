export PS1='%n %F{1}::%f %F{2}%~%f %F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '
export PATH=/usr/local/sbin:$PATH  # for brew
export PATH=/usr/local/opt/python@3.9/libexec/bin:$PATH  # for python
export EDITOR="nvim"
export GPG_TTY=$(tty)

# source aliases
source ~/.zsh_aliases

# keep env if using tmux
if [ "$TMUX" ] && [ "$VIRTUAL_ENV" ];then
  source "$VIRTUAL_ENV/bin/activate"
fi

# load auto completion
autoload -Uz compinit && compinit

# direnv
eval "$(direnv hook zsh)"

# nvm
export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
