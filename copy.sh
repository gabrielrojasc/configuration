#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
source ./utils.sh

# dump brew bundle
brew bundle dump --force &

# files and directories from the shared list in utils.sh
for path in "${config_files[@]}"; do
  mkdir -p "$(dirname "$path")"
  cp -a "$HOME/$path" "$path" &
done
for path in "${config_dirs[@]}"; do
  mkdir -p "$path"
  rsync --archive --delete "$HOME/$path/" "$path/" &
done

# special cases
## npm: drop auth lines (//registry/:_authToken=...)
grep -vE '^//' ~/.npmrc >.npmrc &
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
## pnpm globals; run from ~ so a repo's pinned pnpm can't change the global dir
pnpm -C ~ ls -g --json | jq -r '.[0].dependencies // {} | keys[]' >pnpm-globals.txt &
## key remap app (lives outside $HOME)
mkdir -p Applications
rsync --archive --delete "$keyboard_remap_app" Applications/ &

wait_all
