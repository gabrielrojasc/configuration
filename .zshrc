# ls aliases
alias ls='ls -Gh'
alias ll='ls -l'
alias la='ls -la'
alias l='ls -CF'

# git aliases
function gl() { git log --oneline -n "${1:-5}"; }
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'

# django
alias dj="poetry run python3 manage.py"
alias drs="poetry run python3 manage.py runserver"
alias dsp="poetry run python3 manage.py shell_plus"
alias dcm="poetry run python3 manage.py makemigrations --check --dry-run"
alias dmm="poetry run python3 manage.py makemigrations"
alias dt="poetry run python3 manage.py test"

# other aliases
alias pip-upgrade-outdated="pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U"
alias brewlist="brew leaves | xargs brew deps --include-build --tree"
alias reset="source ~/.zshrc"

export PS1='%n %F{1}::%f %F{2}%~%f %F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '
export PATH=/usr/local/sbin:/usr/local/opt/python@3.9/libexec/bin:$PATH
export EDITOR='vim'
export GPG_TTY=$(tty)

autoload -Uz compinit
compinit

