if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

export PS1='\u@\h:\[\e[01;32m\]\w\[\e[0m\]\$ '
export EDITOR='vim'

# ls aliases
alias ls='ls --color'
alias ll='ls -lhF'
alias la='ls -lha'
alias l='ls -CF'

# keep env if using tmux
if [ "$TMUX" ] && [ "$VIRTUAL_ENV" ]; then
	. "$VIRTUAL_ENV/bin/activate"
fi
