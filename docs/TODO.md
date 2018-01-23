# TODO

Move all TODOs into github issues.

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

## Pow

    .pow -> /Users/warden/Library/Application Support/Pow/Hosts
