# Dotfiles

These are my versioned configuration files for bash, git, and etc.


## Environments

This repository attempts to support:

* OS X
* Linux (primarily Debian / CentOS)
* Unix
* Windows XP (using Cygwin; minimal support)


## Structure

* `bin/` - executables available via $PATH
* `docs/` - help files, tutorials, cheatsheets, etc.
* `functions/` - autoloaded global functions
* `modules/` - autoloaded config files grouped by library/feature/package
* `init.sh` - main script that loads all functions and modules


## How it works

#### `*.symlink` magic

All files and directories ending with `.symlink` will get automatically
symlinked into the `$HOME` directory when you run the `dotfiles` installer.

The `dotfiles` installer is safe in that it will never destroy existing files,
it can run multiple times with the same outcome (i.e. idempotent), and you can
undo all changes with the uninstaller. You'll only need to run the dotfiles
installer once.

After running the `dotfiles` installer, your `$HOME` folder will look something
like:

    $ ls -l `find ~ -maxdepth 1 -type l -print`
    lrwxr-xr-x  1 myuser  staff  57 Aug 11 11:28 /Users/myuser/.bash_profile@ -> /Users/myuser/.dotfiles/modules/bash/bash_profile.symlink
    lrwxr-xr-x  1 myuser  staff  51 Aug 11 11:28 /Users/myuser/.bashrc@ -> /Users/myuser/.dotfiles/modules/bash/bashrc.symlink
    lrwxr-xr-x  1 myuser  staff  51 Aug 11 11:28 /Users/myuser/.bundle@ -> /Users/myuser/.dotfiles/modules/ruby/bundle.symlink
    lrwxr-xr-x  1 myuser  staff  50 Aug 11 11:28 /Users/myuser/.gemrc@ -> /Users/myuser/.dotfiles/modules/ruby/gemrc.symlink
    lrwxr-xr-x  1 myuser  staff  53 Aug 11 11:28 /Users/myuser/.gitignore@ -> /Users/myuser/.dotfiles/modules/git/gitignore.symlink
    lrwxr-xr-x  1 myuser  staff  52 Aug 11 11:28 /Users/myuser/.inputrc@ -> /Users/myuser/.dotfiles/modules/bash/inputrc.symlink
    ...

NOTE: The symlinked source files should never begin with a `.` dot. The symlink
installer will automatically add a preceeding dot to the symlink destination files.
For example, `~/.bashrc -> ~/.dotfiles/bash/bashrc.symlink`.

#### Load `init.sh`

The `init.sh` file is the one and only main bootstrapper script that loads
global shell variables, loads globally available functions, and autoloads
module scripts.

The `init.sh` script is sourced by very thin `.bashrc` and `.bash_profile` which
get symlinked into your $HOME directory via the `dotfiles` installer.  These
files can be found within the `modules/bash/` directory.

#### Load global functions

The `init.sh` loader will first `source` functions before any modules so all
global functions are available within each module.

Functions will load in alphabetic order of their filename. Ideally, each file
should contain a single function or a group of tightly knit functions.

#### Load `*.autoload.sh` module files

After loading functions, the `init.sh` bootstrapper will find all files appended
with `.autoload.sh` and load them using the built-in `source` command. The
bootstrap loader will take multiple passes to load bash files:

1. first loading files ending in `.autoload.first.sh`
2. then `.autoload.sh`
3. and finally `.autoload.last.sh`

During each pass, files will load in alphabetical order of directory name
followed by filename. Autoloaded files are typically found within the `modules/`
directory.

#### Copy `*.template` files

Files or directories ending with `.template` will get copied into the `$HOME`
directory when you run the dotfiles installer.

_NOTE: This functionality is not supported yet._

#### Bin commands

The bin commands will be made available by adding the `bin/` directory to
`$PATH` from within the `bash` module.

* `dotfiles` - install, uninstall, and more
* `reload` - reloads the shell without exiting



## Install

#### Clone dotfiles

    git clone https://github.com/benlinton/dotfiles.git ~/.dotfiles

#### Install symlinks

Finds dotfiles ending with `.symlink` and symlinks them in `$HOME`:

    ~/.dotfiles/bin/dotfiles --install

#### Install template files

Some files require templates (instead of symlinks) because they contain
sensitive data.

    ~/.dotfiles/modules/git/gitconfig-restore

_NOTE: Eventually we'll use the `dotfiles` command for these tasks._

#### Configure sensitive git settings

Update `~/.gitconfig` with your secret credentials:

    git config --global user.name "Firstname Lastname"
    git config --global user.email "your_email@example.com"
    git config --global github.user "your_github_username"
    git config --global github.token "1234567890abcdefghijklmnop"

#### Run optional installers

    ~/.dotfiles/modules/sublime/sublime-install
    ~/.dotfiles/modules/sublime/sublime-restore
    ~/.dotfiles/modules/iterm2/iterm2-restore
    ~/.dotfiles/modules/osx/defaults.sh


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
