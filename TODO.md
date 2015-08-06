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

## Installer

Support automatically symlinking and copying templates on install.  Either
update or remove the `script/install` command.  Ideally I should use the same
command to install/uninstall or update/backup.

When copying templates, prompt for sensitive data.  For templates and symlinks
add optional `!-- TEMPLATE_DEST:` and `!-- SYMLINK_DEST:` keywords to define
a destination other than the default $HOME directory.

## Bootstrap

Add function that spits out the module load order, then use that inside
bootstrap and also provide a utility executable that prints the order
to help with debugging and whatnot.

## Vim

Either add my vim configs or delete the directory from `modules/`.

## Sublime

Add script to backup and update sublime.
