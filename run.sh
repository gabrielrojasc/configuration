cp ~/.bashrc .
cp ~/.gitconfig .
cp ~/.pylintrc .
cp ~/.screenrc .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.zshrc .
cp -r ~/.vim .
cp -r ~/.config/nvim .config/
cp -r ~/.local/bin .local/
git submodule foreach git pull origin HEAD
