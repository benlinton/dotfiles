# Dotfiles

These are my versioned configuration files for bash, git, screen, and etc.


## Environments

This repository attempts to support:

* OS X
* Linux (primarily Debian / CentOS)
* Unix
* Windows XP (using Cygwin; minimal support)


## Install

#### Clone dotfiles

In terminal:

    git clone https://github.com/benlinton/dotfiles.git ~/.dotfiles

#### Install symlinks

    ~/.dotfiles/script/symlinks-install

#### Install template files

Some files require templates (instead of symlinks) because they contain sensitive data.

    ~/.dotfiles/script/gitconfig-restore

#### Configure sensitive git settings

Update .gitconfig with your personal credentials:

    git config --global user.name "Firstname Lastname"
    git config --global user.email "your_email@example.com"
    git config --global github.user "your_github_username"
    git config --global github.token "1234567890abcdefghijklmnop"


## Uninstall

    ~/.dotfiles/script/symlinks-uninstall
    rm -rf ~/.dotfiles


## Architecture

#### Directory structure

* `bash/` - contains core bash files required to load bash
* `bin/` - executables available via $PATH
* `modules/` - config files grouped by library/feature/package
* `script/` - utility executables not available via $PATH (e.g. dotfiles installer)


## File extension magic

#### `.symlink`

Files or directories ending with `.symlink` will get automatically symlinked
into the `$HOME` directly when you run the dotfiles installer.

The symlink source should not start with a dot, and the symlink installer will
automatically add a preceeding dot to the symlink destination for you. For
example, `~/.bashrc@ -> ~/.dotfiles/bash/bashrc.symlink`

NOTE: This functionality is not fully supported yet.

#### `.template`

Files or directories ending with `.template` will get copied into the `$HOME`
directory when you run the dotfiles installer.

NOTE: This functionality is not fully supported yet.

#### `.bash.sh`

The `bash/bootstrap.sh` will look for all files that end in `.bash.sh` and load
them using the built-in `source` command.  Since it's important for certain
files to load before or after all others, we've provided `.bash.first.sh` and
`.bash.last.sh` to fine tune load order.

The bootstrap will take three passes, loading `.bash.first.sh`, then `.bash.sh`,
and finally `.bash.last.sh`.  During each pass, files will load in alphabetical
order of directory names, then alphabetical order of file names.

NOTE: This functionality does not currently support filenames with spaces.


## Bin commands

* `crashplan-remote` - helps start crashplan on a remote headless server
* `e` - shortcut to current editor
* `git-wtf` - displays state of your git repository
* `shell-restart` - reloads the shell without exiting
* `slugify` - convert filenames into a web friendly format


## Useful commands cheatsheet

* `alias` - List loaded aliases
