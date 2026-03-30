#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

model="$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")"
cwd="$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$input")"
used_pct="$(jq -r '(.context_window.used_percentage // 0) | floor' <<<"$input")"
cost_usd="$(jq -r '.cost.total_cost_usd // 0' <<<"$input")"

sep=" · "
dir_icon="📁"
branch_icon="🌿"

reset=$'\033[0m'
bold=$'\033[1m'
dim=$'\033[2m'

fg_model=$'\033[38;5;111m'
fg_dir=$'\033[38;5;223m'
fg_branch=$'\033[38;5;180m'
fg_added=$'\033[38;5;78m'
fg_removed=$'\033[38;5;203m'
fg_changed=$'\033[38;5;220m'
fg_money=$'\033[38;5;221m'

if [ "$used_pct" -ge 90 ]; then
  fg_ctx=$'\033[38;5;203m'
elif [ "$used_pct" -ge 70 ]; then
  fg_ctx=$'\033[38;5;220m'
else
  fg_ctx=$'\033[38;5;78m'
fi

display_cwd="$cwd"
if [ -n "${HOME:-}" ]; then
  display_cwd="${display_cwd/#$HOME/\~}"
fi

git_part=""
if command -v git >/dev/null 2>&1 && [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")"

  added=0
  removed=0
  changed=0

  while IFS=$'\t' read -r a r _; do
    [ "${a:-0}" = "-" ] || added=$((added + a))
    [ "${r:-0}" = "-" ] || removed=$((removed + r))
  done < <(
    {
      git -C "$cwd" diff --numstat 2>/dev/null || true
      git -C "$cwd" diff --cached --numstat 2>/dev/null || true
    }
  )

  changed="$(git -C "$cwd" status --porcelain 2>/dev/null | awk '
    $1 ~ /M/ || $2 ~ /M/ { c++ }
    END { print c+0 }
  ')"

  git_part="${dim}|${reset} ${fg_branch}${branch_icon} ${branch}${reset} "
  git_part+="${fg_added}+${added}${reset} "
  git_part+="${fg_removed}-${removed}${reset} "
  git_part+="${fg_changed}~${changed}${reset}"
fi

# Shorter context bar
bar_width=10
filled=$((used_pct * bar_width / 100))
empty=$((bar_width - filled))

filled_bar=""
empty_bar=""
for ((i = 0; i < filled; i++)); do filled_bar+="█"; done
for ((i = 0; i < empty; i++)); do empty_bar+="░"; done

cost_fmt="$(printf '$%.2f' "$cost_usd")"

# Line 1
printf "%s%s%s%s%b%s%s %s%s%s\n" \
  "$bold" "$fg_model" "$model" "$reset" \
  " ${dim}${sep}${reset} " \
  "$fg_dir" "$dir_icon" "$reset" \
  " $display_cwd${git_part:+ $git_part}"

# Line 2
printf "%sctx %3d%% [%s%s%s]%s%s%s%s%s\n" \
  "$fg_ctx" "$used_pct" \
  "$filled_bar" "$dim" "$empty_bar" \
  "$reset" \
  "$dim" "$sep" "$reset" \
  "${fg_money}${cost_fmt}${reset}"