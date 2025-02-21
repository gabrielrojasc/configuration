defaults write com.apple.dock "tilesize" -int 56
defaults write com.apple.dock "mru-spaces" -bool "false"
defaults write com.apple.dock "show-recents" -bool "false"
defaults write com.apple.dock "show-recents" -bool "false"
defaults write com.apple.dock "mineffect" -string "scale"
defaults write com.apple.Dock "autohide" -bool "true"

defaults write com.apple.screencapture "location" ~/Downloads

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE

defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

defaults write -g ApplePressAndHoldEnabled -bool false

defaults write com.apple.screencapture "location" -string "$HOME/Downloads"

defaults write com.apple.finder "ShowPathbar" -bool "true"
defaults write com.apple.finder "FXPreferredViewStyle" -string "clmv"
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"
defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"

defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool "false"
defaults write NSGlobalDomain KeyRepeat -int 1.8
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# https://github.com/jorgelbg/pinentry-touchid
defaults write org.gpgtools.common DisableKeychain -bool yes

for app in "Dock" \
	"SystemUIServer" \
	"Finder"; do
	killall "${app}" &>/dev/null
done

echo "Done. Note that some of these changes require a logout/restart to take effect."
