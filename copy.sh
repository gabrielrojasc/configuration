#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

# dump brew bundle
brew bundle dump --force &

# files
cp -a ~/.zprofile . &
cp -a ~/.bash_profile . &
cp -a ~/.gitconfig . &
cp -a ~/.config/btop/btop.conf .config/btop/ &
cp -a ~/.config/git/ignore .config/git/ &
cp -a ~/.screenrc . &
cp -a ~/.tmux.conf . &
cp -a ~/.vimrc . &
cp -a ~/.zshrc . &
cp -a ~/.zsh_aliases . &
cp -a ~/.zsh_functions . &
cp -a ~/.zsh_exports . &
cp -a ~/Library/Application\ Support/Code/User/settings.json Library/Application\ Support/Code/User/ &
cp -a ~/Library/Application\ Support/Code/User/keybindings.json Library/Application\ Support/Code/User/ &
cp -a ~/Library/LaunchAgents/loadsshkeys.plist Library/LaunchAgents/loadsshkeys.plist &
cp -a ~/Library/Scripts/loadsshkeys Library/Scripts/loadsshkeys &
## Codex
(
    config_tmp="$(mktemp .codex/config.toml.XXXXXX)"
    trap 'rm -f "$config_tmp"' EXIT
    # Keep user settings while dropping project and generated runtime state.
    awk '
    function normalized_header(line, header) {
      header = line
      sub(/^[[:space:]]*/, "", header)
      sub(/\][[:space:]]*#.*$/, "]", header)
      sub(/[[:space:]]*$/, "", header)
      return header
    }

    function is_header(line) {
      return line ~ /^[[:space:]]*\[\[[^]]+\]\][[:space:]]*(#.*)?$/ ||
        line ~ /^[[:space:]]*\[[^[][^]]*\][[:space:]]*(#.*)?$/
    }

    function is_dropped_section(line, header) {
      header = normalized_header(line)
      return header ~ /^\[projects\."/ ||
        header == "[notice]" ||
        header == "[tui.model_availability_nux]" ||
        header ~ /^\[marketplaces\./ ||
        header ~ /^\[\[?mcp_servers[[:space:]]*\.[[:space:]]*([A-Za-z0-9_-]+|"([^"\\]|\\.)*"|\047[^\047]*\047)[[:space:]]*\./
    }

    is_header($0) {
      section = normalized_header($0)
      drop_section = is_dropped_section($0)
      pending_environment = ""

      if (section == "[shell_environment_policy.set]") {
        pending_environment = $0 ORS
        next
      }

      if (!drop_section) {
        print
      }
      next
    }

    !drop_section &&
      !(section == "[shell_environment_policy.set]" &&
        $0 ~ /^[[:space:]]*NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S[[:space:]]*=/) {
      # Emit this table only when a retained environment override needs it.
      if (pending_environment != "") {
        pending_environment = pending_environment $0 ORS
        if ($0 ~ /^[[:space:]]*(#.*)?$/) {
          next
        }
        printf "%s", pending_environment
        pending_environment = ""
        next
      }
      print
    }

  ' ~/.codex/config.toml >"$config_tmp"
    cp "$config_tmp" .codex/config.toml
) &
cp -a ~/.codex/AGENTS.md .codex/ &
rsync --recursive --archive --delete ~/.codex/agents .codex/ &
## Claude
cp -a ~/.claude/settings.json .claude/ &
cp -a ~/.claude/statusline.sh .claude/ &
cp -a ~/.claude/CLAUDE.md .claude/ &
rsync --recursive --archive --delete ~/.claude/agents .claude/ &

cp -a ~/dcc/justfile dcc/ &

# directories
rsync --recursive --archive --delete ~/.vim . &
rsync --recursive --archive --delete ~/.config/nvim .config/ &
rsync --recursive --archive --delete ~/.config/direnv .config/ &
rsync --recursive --archive --delete --exclude '/htop_history' ~/.config/htop .config/ &

rsync --recursive --archive --delete ~/dcc/scripts dcc/ &

wait
