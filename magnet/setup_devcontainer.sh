#!/usr/bin/env bash

set -euo pipefail

# Change directory to the root of this repo
cd "$(dirname "$0")/.."

# Function for error handling
handle_error() {
	echo "Error occurred on line $1"
	exit 1
}

# Trap errors and call the error handling function
trap 'handle_error $LINENO' ERR

# Copy vimrc
echo 'Copying vimrc'
cp .vimrc ~

# Copy gitconfig
echo 'Copying gitconfig'
cp .gitconfig ~

# Ensure necessary directories exist
mkdir -p ~/magnet/

# Copy magnet gitconfig
echo 'Copying magnet gitconfig'
cp ./magnet/.gitconfig ~/magnet/

# Setup git conflict style to diff3 as zdiff3 is not yet available
git config --global merge.conflictStyle 'diff3'

# Set git editor to vim
git config --global core.editor "vim"

# Set usr/src/app as git safe directory
git config --global safe.directory /usr/src/app

# Make diff-highlight
echo 'Making diff-highlight'
diff_highlight_dir='/usr/share/doc/git/contrib/diff-highlight/'
cd "$diff_highlight_dir" && sudo make

# Verify diff-highlight exists
if [ ! -f "$diff_highlight_dir/diff-highlight" ]; then
	echo "Error: diff-highlight not found"
	exit 1
fi

# Setup diff-highlight
echo 'Setting diff-highlight in gitconfig'
diff_highlight_cmd="$diff_highlight_dir/diff-highlight | less -FX"
git config --global pager.log "$diff_highlight_cmd"
git config --global pager.show "$diff_highlight_cmd"
git config --global pager.diff "$diff_highlight_cmd"
