# source exports
source ~/.zsh_exports

# path
export PATH="/opt/homebrew/opt/python3/libexec/bin:$PATH"  # for python
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH" # for gnu-sed
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH" # for gnu-grep
export PATH="/opt/homebrew/share/git-core/contrib/diff-highlight:$PATH" # for git diff-highlight
export PATH="/Users/grojas/.local/bin:$PATH" # for pipx
export PATH="$GOPATH/bin:$PATH"; # for go
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH" # for mysql-client

# source aliases
source ~/.zsh_aliases

# glcoud
# source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
# source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

# extend history
setopt EXTENDED_HISTORY

# to keep keybindings in tmux
bindkey -e

# keep env if using tmux
if [ "$TMUX" ] && [ "$VIRTUAL_ENV" ];then
    source "$VIRTUAL_ENV/bin/activate"
fi

# Highlight the current autocomplete option
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Tab complete hosts from ssh config
zstyle ':completion:*:ssh:*' hosts

# autocompletion
if type brew &>/dev/null
then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"

    autoload -Uz compinit
    compinit

    autoload -Uz compdump
    compdump
fi

# direnv
eval "$(direnv hook zsh)"

# fnm
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"

# fzf
eval "$(fzf --zsh)"

# sdkman
export SDKMAN_DIR='/opt/homebrew/opt/sdkman-cli/libexec'
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# prompt
## Enabling and setting git info var to be used in prompt config.
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
## This line obtains information from the vcs.
zstyle ':vcs_info:git*' formats "%F{3}%b%f "
precmd() {
    vcs_info
}
## Enable substitution in the prompt.
setopt prompt_subst
export PS1='%n %F{1}::%f %F{2}%~%f ${vcs_info_msg_0_}%F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '

# source functions
source ~/.zsh_functions
