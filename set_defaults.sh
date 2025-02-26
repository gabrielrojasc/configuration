# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Disable the sound effects on boot
sudo nvram StartupMute=%01

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Disable press and hold
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool "false"

# Disable press and hold for VSCode
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

# Don't write .DS_Store on external drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE

# Key repeat
defaults write NSGlobalDomain KeyRepeat -int 1.8
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Increase sound quality for Bluetooth headphones/headsets
defaults write bluetoothaudiod "Enable AptX codec" -bool true
defaults write bluetoothaudiod "Enable AAC codec" -bool true

# https://github.com/jorgelbg/pinentry-touchid
defaults write org.gpgtools.common DisableKeychain -bool yes

# https://macos-defaults.com/
## Dock
defaults write com.apple.dock "tilesize" -int 56
defaults write com.apple.dock "show-recents" -bool "false"
defaults write com.apple.dock "mineffect" -string "scale"
defaults write com.apple.Dock "autohide" -bool "true"

## Screenshots
defaults write com.apple.screencapture "location" -string "$HOME/Downloads"

## Finder
defaults write com.apple.finder "ShowPathbar" -bool "true"
defaults write com.apple.finder "FXPreferredViewStyle" -string "clmv"
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"
defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"

## Menu bar
defaults write com.apple.menuextra.clock "DateFormat" -string "\"EEE d MMM HH:mm\""

## Mission control
defaults write com.apple.dock "mru-spaces" -bool "false"

for app in "Dock" \
	"SystemUIServer" \
	"Finder"; do
	killall "${app}" &>/dev/null
done

echo "Done. Note that some of these changes require a logout/restart to take effect."
