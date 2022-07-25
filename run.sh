cp ~/.bashrc .
cp ~/.gitconfig .
cp ~/.pylintrc .
cp ~/.screenrc .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.zshrc .
cp ~/.zsh_aliases .
cp -r ~/.vim .
cp -r ~/.config/nvim .config/
git submodule foreach git pull origin HEAD
