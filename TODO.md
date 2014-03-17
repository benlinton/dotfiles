# TODO

## iTerm 2

To use my iTerm 2 settings, copy com.googlecode.iterm2.plist into ~/Library/Preferences.

## Crashplan

### For Mac

Add the following crashplan aliases for Mac only:

    sudo launchctl unload /Library/LaunchDaemons/com.crashplan.engine.plist # unload engine daemon
    sudo launchctl load /Library/LaunchDaemons/com.crashplan.engine.plist # load engine daemon
    ps auxww | grep -i CrashPlanService # check if the service is running

## Node

* Only load nvm if it exists

