#!/usr/bin/env bash

# Restart web camera without rebooting
alias camera-restart="sudo killall VDCAssistant"

# Show and hide files
alias files-show="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app"
alias files-hide="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app"

# Reset audio; run with sudo
alias audio-reset="kill -9 `ps ax | grep 'coreaudio[a-z]' | awk '{print $1}'`"
