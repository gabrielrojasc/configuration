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

# directories
cp -r ~/.vim . &
cp -r ~/.config/nvim .config/ &
cp -r ~/.config/direnv .config/ &
cp -r ~/.config/htop .config/ &

# magnet
cp ~/magnet/.gitconfig magnet/ &
cp ~/magnet/justfile magnet/ &
cp -r ~/magnet/scripts magnet/ &

# dump brew bundle
brew bundle dump --force &

wait
