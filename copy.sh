# files
cp ~/.bashrc .
cp ~/.gitconfig .
cp ~/.pylintrc .
cp ~/.screenrc .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.zshrc .
cp ~/.zsh_aliases .

# directories
cp -r ~/.vim .
cp -r ~/.config/nvim .config/
cp -r ~/magnet/.gitconfig magnet/

# dump brew leaves and casks
brew leaves >brew/leaves
brew list --cask >brew/casks

# update submodules
git submodule foreach git pull origin HEAD
