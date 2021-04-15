alias ls='ls -Gh'
alias ll='ls -l'
alias la='ls -la'

export PS1='%n %F{1}::%f %F{2}%~%f %F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '
export PATH=/usr/local/sbin:/usr/local/opt/python@3.9/libexec/bin:$PATH
export EDITOR='vim'

autoload -U compinit
compinit
