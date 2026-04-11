# source exports
source ~/.zsh_exports

# path
export PATH="/opt/homebrew/opt/python@3/libexec/bin:$PATH"  # for python
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH" # for gnu-sed
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH" # for gnu-grep
export PATH="/opt/homebrew/share/git-core/contrib/diff-highlight:$PATH" # for git diff-highlight
export PATH="/Users/grojas/.local/bin:$PATH" # for pipx
export PATH="$GOPATH/bin:$PATH"; # for go
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH" # for mysql-client
export PATH="$HOME/.pub-cache/bin:$PATH" # melos
# export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";

# source aliases
source ~/.zsh_aliases

# glcoud
# source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
# source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

# extend history
setopt EXTENDED_HISTORY

# to keep keybindings in tmux
bindkey -e

# Re-activate inherited virtualenv in new tmux panes/shells when PATH
# has not already been updated for the active environment.
if [[ -n "$TMUX" && -n "$VIRTUAL_ENV" && -f "$VIRTUAL_ENV/bin/activate" && ":$PATH:" != *":$VIRTUAL_ENV/bin:"* ]]; then
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

# logcli completion
eval "$(logcli --completion-script-zsh)"

# codex completion
eval "$(codex completion zsh)"

# sdkman
export SDKMAN_DIR='/opt/homebrew/opt/sdkman-cli/libexec'
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# prompt
## Enabling and setting git info var to be used in prompt config.
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
## This line obtains information from the vcs.
zstyle ':vcs_info:git*' formats "%F{3}%b%f "
## Enable substitution in the prompt.
setopt prompt_subst
export PS1='%n %F{1}::%f %F{2}%~%f ${vcs_info_msg_0_}%F{1}%(?..%? )%f%F{4}'$'\U00BB''%f '

# source functions
source ~/.zsh_functions

ensure_op_env SSH_PRIVATE_KEY 'op://Employee/id_ed25519/private key'
ensure_op_env GITHUB_REGISTRY_READ_TOKEN 'op://Employee/GitHub Personal Access Token/token'
ensure_op_env GITHUB_REGISTRY_WRITE_TOKEN 'op://Employee/GitHub Personal Access Token/token'

autoload -Uz add-zsh-hook

add-zsh-hook precmd vcs_info
add-zsh-hook precmd _tmux_update_virtual_env

# BEGIN VT 1PASSWORD INTEGRATION
export VT_VAULT_qa_TOKEN="op://p3cej3nz64dcu7ownprpdadjie/VT-VAULT-qa/token"
export VT_VAULT_prod_TOKEN="op://p3cej3nz64dcu7ownprpdadjie/VT-VAULT-prod/token"
export VT_DB_monolith_db_prod_USER="op://p3cej3nz64dcu7ownprpdadjie/VT-DB-monolith-db-prod/username"
export VT_DB_monolith_db_qa_USER="op://p3cej3nz64dcu7ownprpdadjie/VT-DB-monolith-db-qa/username"
export VT_DB_monolith_db_qa_TOKEN="op://p3cej3nz64dcu7ownprpdadjie/VT-DB-monolith-db-qa/password"
export VT_VAULT_stag_TOKEN="op://p3cej3nz64dcu7ownprpdadjie/VT-VAULT-stag/token"
export VT_DB_monolith_db_stag_USER="op://p3cej3nz64dcu7ownprpdadjie/VT-DB-monolith-db-stag/username"
export VT_DB_monolith_db_stag_TOKEN="op://p3cej3nz64dcu7ownprpdadjie/VT-DB-monolith-db-stag/password"
export VT_DB_monolith_db_prod_TOKEN="op://p3cej3nz64dcu7ownprpdadjie/VT-DB-monolith-db-prod/password"
# END VT 1PASSWORD INTEGRATION

