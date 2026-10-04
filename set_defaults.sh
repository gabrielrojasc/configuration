# shellcheck shell=bash
# macOS defaults. Sourced by install.sh, which sets $apply and color_print.
# In a dry run, prints each setting whose current value differs.

defaults_changed=0

# pref [-currentHost] <domain> <key> <-bool|-int|-float|-string> <value>
function pref() {
    local host=()
    if [[ "$1" == -currentHost ]]; then
        host=(-currentHost)
        shift
    fi
    local domain=$1 key=$2 type=$3 value=$4 current wanted=$4
    # ${host[@]+...} because bash 3.2 (a fresh Mac) treats an empty array as unset.
    current=$(defaults ${host[@]+"${host[@]}"} read "$domain" "$key" 2>/dev/null || echo '(unset)')
    # defaults read prints booleans as 1/0.
    if [[ "$type" == -bool ]]; then
        case "$value" in true | TRUE | yes) wanted=1 ;; *) wanted=0 ;; esac
    fi
    [[ "$current" == "$wanted" ]] && return 0
    defaults_changed=1
    if ((apply)); then
        defaults ${host[@]+"${host[@]}"} write "$domain" "$key" "$type" "$value"
    else
        color_print "$blue" "Would set ${host[*]+${host[*]} }$domain $key: $current -> $wanted"
    fi
}

if ((apply)); then
    # Close any open System Settings panes, to prevent them from overriding
    # settings we're about to change
    osascript -e 'if application "System Settings" is running then tell application "System Settings" to quit'
fi

# Disable the sound effects on boot
if [[ "$(nvram StartupMute 2>/dev/null | cut -f2)" != "%01" ]]; then
    defaults_changed=1
    if ((apply)); then
        sudo nvram StartupMute=%01
    else
        color_print "$blue" 'Would set nvram StartupMute=%01 (mute the boot chime)'
    fi
fi

# Show battery percentage on control center
pref -currentHost com.apple.controlcenter BatteryShowPercentage -bool true

# Trackpad: enable tap to click for this user and for the login screen
pref com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
pref -currentHost NSGlobalDomain com.apple.mouse.tapBehavior -int 1
pref NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Disable press and hold
pref NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable press and hold for VSCode
pref com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

# Don't write .DS_Store on external drives
pref com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Key repeat
pref NSGlobalDomain KeyRepeat -int 1
pref NSGlobalDomain InitialKeyRepeat -int 10

# Increase sound quality for Bluetooth headphones/headsets
pref bluetoothaudiod "Enable AptX codec" -bool true
pref bluetoothaudiod "Enable AAC codec" -bool true

# https://github.com/jorgelbg/pinentry-touchid
pref org.gpgtools.common DisableKeychain -bool true

# https://macos-defaults.com/
## Dock
pref com.apple.dock tilesize -int 56
pref com.apple.dock show-recents -bool false
pref com.apple.dock mineffect -string scale
pref com.apple.dock autohide -bool true

## Screenshots
pref com.apple.screencapture location -string "$HOME/Downloads"

## Finder
pref com.apple.finder ShowPathbar -bool true
pref com.apple.finder FXPreferredViewStyle -string clmv
pref com.apple.finder _FXSortFoldersFirst -bool true
pref com.apple.finder FXDefaultSearchScope -string SCcf
pref com.apple.finder FXRemoveOldTrashItems -bool true

## Menu bar
### ShowDate: 0 = when space allows, 1 = always, 2 = never
pref com.apple.menuextra.clock Show24Hour -bool true
pref com.apple.menuextra.clock ShowDayOfWeek -bool true
pref com.apple.menuextra.clock ShowDate -int 0

## Mission control
pref com.apple.dock mru-spaces -bool false

if ((defaults_changed == 0)); then
    color_print "$green" 'macOS defaults already match'
elif ((apply)); then
    for app in Dock SystemUIServer Finder; do
        killall "$app" &>/dev/null || true
    done
    color_print "$green" 'Set macOS defaults'
fi
