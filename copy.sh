cd "$(dirname "$0")" || exit 1

# dump brew bundle
brew bundle dump --force &

# files
cp ~/.zprofile . &
cp ~/.bash_profile . &
cp ~/.gitconfig . &
cp ~/.screenrc . &
cp ~/.tmux.conf . &
cp ~/.vimrc . &
cp ~/.zshrc . &
cp ~/.zsh_aliases . &
cp ~/.zsh_exports . &
cp ~/Library/Application\ Support/Code/User/settings.json Library/Application\ Support/Code/User/ &
cp ~/Library/Application\ Support/Code/User/keybindings.json Library/Application\ Support/Code/User/ &

# directories
cp -r ~/.vim . &
cp -r ~/.config/nvim .config/ &
cp -r ~/.config/direnv .config/ &
cp -r ~/.config/htop .config/ &

# dcc
cp ~/dcc/justfile dcc/ &
cp -r ~/dcc/scripts dcc/ &

# magnet
cp ~/magnet/.gitconfig magnet/ &
cp ~/magnet/justfile magnet/ &
cp -r ~/magnet/scripts magnet/ &

wait
