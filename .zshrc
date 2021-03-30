alias ls='ls -Gh'
alias la='ls -la'
export PS1='%n %F{1}::%f %F{2}%~%f %F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '
export EDITOR='vim'
export PATH=/usr/local/sbin:/usr/local/opt/python@3.9/libexec/bin:$PATH
autoload bashcompinit && bashcompinit
setopt no_list_ambiguous
