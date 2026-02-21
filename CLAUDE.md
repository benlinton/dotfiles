# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install symlinks into $HOME
~/.dotfiles/bin/dotfiles --install

# Uninstall symlinks from $HOME
dotfiles --uninstall

# Reload the shell without exiting
reload

# Run tests (requires bats: brew install bats)
bats $DOTFILES_HOME/bin/tests
```

## Architecture

This is a modular dotfiles management system for bash, git, and other tools.

### Bootstrap Flow

Shell startup sources `modules/bash/bashrc.symlink` or `bash_profile.symlink`, which sources `init.sh`. `init.sh` loads everything in this order:

1. All files in `functions/` (global shell functions, available to all modules)
2. All `*.autoload.first.sh` files (PATH, MANPATH — order-sensitive setup)
3. All `*.autoload.sh` files (general configuration)
4. All `*.autoload.last.sh` files (hooks like direnv that must run last)

Within each phase, files load alphabetically by directory then filename.

### File Naming Conventions

| Pattern | Behavior |
|---|---|
| `*.symlink` | Symlinked into `$HOME` as a dotfile (e.g., `bashrc.symlink` → `~/.bashrc`). Files must NOT start with a dot. |
| `*.autoload.first.sh` | Sourced in phase 1 (path setup) |
| `*.autoload.sh` | Sourced in phase 2 (general config) |
| `*.autoload.last.sh` | Sourced in phase 3 (late hooks) |
| `*.template` | Intended to be copied to `$HOME` (not yet implemented by installer) |

### Module Structure

Each directory under `modules/` groups configuration for a single tool or feature. A module can contain any mix of the above file types. The `$DOTFILES_HOME` environment variable points to the repo root and is set by `bashrc.symlink`.

### Adding a New Module

1. Create `modules/<name>/` directory
2. Add `*.autoload.sh` files for shell configuration
3. Add `*.symlink` files for dotfiles that need to live in `$HOME`
4. No registration needed — `init.sh` discovers files automatically

### Installer Behavior

`bin/dotfiles-install` finds all `*.symlink` files recursively and creates `~/.<name>` symlinks. It is idempotent and non-destructive (skips files that already exist). `bin/dotfiles-uninstall` reverses this.
