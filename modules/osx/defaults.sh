#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Sets osx preferences and defaults.
#
# Resources:
#   - https://mths.be/osx
#   - https://gist.github.com/cowboy/3118588
# ------------------------------------------------------------------------------

# Might as well ask for password up-front, right?
sudo -v

# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ------------------------------------------------------------------------------
# General
# ------------------------------------------------------------------------------

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# ------------------------------------------------------------------------------
# SSD
# ------------------------------------------------------------------------------

# Disable local Time Machine snapshots
sudo tmutil disablelocal

# ------------------------------------------------------------------------------
# Keyboard
# ------------------------------------------------------------------------------

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -float 0.5

# Set a shorter delay until key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Enable repeat on keydown
defaults write ApplePressAndHoldEnabled -bool false

# ------------------------------------------------------------------------------
# Mouse
# ------------------------------------------------------------------------------

# Set faster mouse tracking speed
defaults write com.apple.mouse.scaling -float 3.0

# Enable secondary click on multitouch mouse
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode TwoButton

# ------------------------------------------------------------------------------
# Finder
# ------------------------------------------------------------------------------

# Finder: disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Finder: set $HOME as default finder location
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Finder: show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Finder: show hidden files by default
#defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Finder: when performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Finder: disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Finder: enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Finder: remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Finder: avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Finder: show the ~/Library folder
chflags nohidden ~/Library

# ------------------------------------------------------------------------------
# Restart applications                                                  
# ------------------------------------------------------------------------------

for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" \
    "Dock" "Finder" "Google Chrome" "Google Chrome Canary" "Mail" "Messages" \
    "Opera" "Safari" "SystemUIServer" "Terminal"; do
    killall "${app}" &> /dev/null
done

echo "Done. Some of these changes require a logout/restart to take effect."
