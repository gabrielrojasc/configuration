alias ls='ls -Gh'
alias ll='ls -l'
alias la='ls -la'
alias l='ls -CF'
alias pip-upgrade-outdated='pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U'

export PS1='%n %F{1}::%f %F{2}%~%f %F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '
export PATH=/usr/local/sbin:/usr/local/opt/python@3.9/libexec/bin:/usr/local/opt/openjdk/bin:$PATH
export EDITOR='vim'

autoload -U compinit
compinit

alias brewlist="brew leaves | xargs brew deps --include-build --tree"
