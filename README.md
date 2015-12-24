# Dotfiles

These are my versioned configuration files for bash, git, screen, and etc.


## Environments

This repository attempts to support:

* OS X
* Linux (primarily Debian / CentOS)
* Unix
* Windows XP (using Cygwin; minimal support)


## Architecture

#### Overview

* `bin/` - executables available via $PATH
* `docs/` - help files, tutorials, cheatsheets, etc.
* `functions/` - autoloaded global functions
* `modules/` - autoloaded config files grouped by library/feature/package
* `script/` - utility executables not available via $PATH (e.g. installers)
* `bootstrap.sh` - core script that loads all functions and modules

#### Bootstrap

The `bootstrap.sh` exports global shell variables, loads functions, loads
modules, etc. It is the core script that all other dotfiles activity gets
routed through.

The bootstrap file is sourced by very thin `.bashrc` and `.bash_profile` that
are symlinked via the `modules/bash/` module.  Once the symlink installer has
been ran then the bootstrap script will begin working it's magic.

#### Functions

The `bootstrap.sh` loader will `source` functions before any modules load so
all functions are available to all modules.

Functions will load by alphabetic order of filename. Ideally, each file should
contain one function.

#### Autoload `*.bash.sh`

After loading functions, the `bootstrap.sh` loader will find all files appended
with `.bash.sh` and load them using the built-in `source` command. The
bootstrap loader will take multiple passes to load bash files:

1. first loading files ending in `.bash.first.sh`
2. then `.bash.sh`
3. and finally `.bash.last.sh`

During each pass, files will load in alphabetical order of directory name
followed by filename.

#### Auto-install `*.symlink`

Files or directories ending with `.symlink` will get automatically symlinked
into the `$HOME` directly when you run the dotfiles installer.

NOTE: The symlink source should not start with a dot, and the symlink installer
will automatically add a preceeding dot to the symlink destination for you. For
example, `~/.bashrc -> ~/.dotfiles/bash/bashrc.symlink`

After running the symlink installer, your $HOME folder will look something like:

    $ ls -l `find ~ -maxdepth 1 -type l -print`
    lrwxr-xr-x  1 myuser  staff  57 Aug 11 11:28 /Users/myuser/.bash_profile@ -> /Users/myuser/.dotfiles/modules/bash/bash_profile.symlink
    lrwxr-xr-x  1 myuser  staff  51 Aug 11 11:28 /Users/myuser/.bashrc@ -> /Users/myuser/.dotfiles/modules/bash/bashrc.symlink
    lrwxr-xr-x  1 myuser  staff  51 Aug 11 11:28 /Users/myuser/.bundle@ -> /Users/myuser/.dotfiles/modules/ruby/bundle.symlink
    lrwxr-xr-x  1 myuser  staff  50 Aug 11 11:28 /Users/myuser/.gemrc@ -> /Users/myuser/.dotfiles/modules/ruby/gemrc.symlink
    lrwxr-xr-x  1 myuser  staff  53 Aug 11 11:28 /Users/myuser/.gitignore@ -> /Users/myuser/.dotfiles/modules/git/gitignore.symlink
    lrwxr-xr-x  1 myuser  staff  52 Aug 11 11:28 /Users/myuser/.inputrc@ -> /Users/myuser/.dotfiles/modules/bash/inputrc.symlink
    lrwxr-xr-x  1 myuser  staff  50 Aug 11 11:28 /Users/myuser/.irbrc@ -> /Users/myuser/.dotfiles/modules/ruby/irbrc.symlink
    lrwxr-xr-x  1 myuser  staff  50 Aug 11 11:28 /Users/myuser/.npmrc@ -> /Users/myuser/.dotfiles/modules/node/npmrc.symlink
    lrwxr-xr-x  1 myuser  staff  51 Oct 17  2014 /Users/myuser/.pow@ -> /Users/myuser/Library/Application Support/Pow/Hosts
    lrwxr-xr-x  1 myuser  staff  50 Aug 11 11:28 /Users/myuser/.pryrc@ -> /Users/myuser/.dotfiles/modules/ruby/pryrc.symlink
    lrwxr-xr-x  1 myuser  staff  50 Aug 11 11:28 /Users/myuser/.rspec@ -> /Users/myuser/.dotfiles/modules/ruby/rspec.symlink
    lrwxr-xr-x  1 myuser  staff  55 Aug 11 11:28 /Users/myuser/.screenrc@ -> /Users/myuser/.dotfiles/modules/screen/screenrc.symlink
    lrwxr-xr-x  1 myuser  staff  47 Aug 11 11:28 /Users/myuser/.vim@ -> /Users/myuser/.dotfiles/modules/vim/vim.symlink
    lrwxr-xr-x  1 myuser  staff  49 Aug 11 11:28 /Users/myuser/.vimrc@ -> /Users/myuser/.dotfiles/modules/vim/vimrc.symlink

#### Auto-install `*.template`

Files or directories ending with `.template` will get copied into the `$HOME`
directory when you run the dotfiles installer.

NOTE: This functionality is not fully supported yet.

#### Bin commands

The bin commands will be made available by adding the `bin/` directory to
`$PATH` via the `bash` module.

* `crashplan-remote` - helps start crashplan on a remote headless server
* `git-wtf` - displays state of your git repository
* `reload` - reloads the shell without exiting
* `slugify` - convert filenames into a web friendly format


## Install

#### Clone dotfiles

    git clone https://github.com/benlinton/dotfiles.git ~/.dotfiles

#### Install symlinks

Find dotfiles ending with `.symlink` and symlink in `$HOME`:

    ~/.dotfiles/bin/dotfiles --install

#### Print dotfiles help

    dotfiles --help

#### Install template files

Some files require templates (instead of symlinks) because they contain
sensitive data.

    ~/.dotfiles/script/gitconfig-restore

#### Configure sensitive git settings

Update `~/.gitconfig` with your secret credentials:

    git config --global user.name "Firstname Lastname"
    git config --global user.email "your_email@example.com"
    git config --global github.user "your_github_username"
    git config --global github.token "1234567890abcdefghijklmnop"

#### Run optional installers

    ~/.dotfiles/script/sublime-install
    ~/.dotfiles/script/sublime-restore
    ~/.dotfiles/script/iterm2-restore


## Uninstall

    dotfiles --uninstall
    rm -rf ~/.dotfiles


## Testing

Tests are written with [bats](https://github.com/sstephenson/bats).

#### Install bats

Assuming OS X with homebrew installed (otherwise see the bats documentation):

    brew install bats

#### Run tests

    bats $DOTFILES_HOME/bin/tests
