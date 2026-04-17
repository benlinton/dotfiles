# GIT CHEATSHEET

## BASICS
git init                        # Initialize repo in current directory
git clone <url>                 # Clone remote repo
git status                      # Show working tree status
git add <file>                  # Stage file
git add -p                      # Interactively stage hunks
git commit -m "msg"             # Commit staged changes
git commit --amend              # Amend last commit (message or content)

## BRANCHING
git branch                      # List local branches
git branch <name>               # Create branch
git branch -d <name>            # Delete branch (safe)
git branch -D <name>            # Delete branch (force)
git switch <name>               # Switch to branch
git switch -c <name>            # Create and switch to branch
git merge <branch>              # Merge branch into current
git rebase <branch>             # Rebase current onto branch

## REMOTE
git remote -v                   # List remotes
git remote add origin <url>     # Add remote
git fetch                       # Fetch all remotes
git pull                        # Fetch and merge
git pull --rebase               # Fetch and rebase
git push                        # Push current branch
git push -u origin <branch>     # Push and set upstream
git push --force-with-lease     # Safe force push

## INSPECTION
git log --oneline               # Compact commit history
git log --oneline --graph       # Commit graph
git diff                        # Unstaged changes
git diff --staged               # Staged changes
git show <commit>               # Show commit details
git blame <file>                # Show who changed each line

## UNDOING
git restore <file>              # Discard unstaged changes
git restore --staged <file>     # Unstage file (keep changes)
git revert <commit>             # New commit that undoes a commit
git reset --soft HEAD~1         # Undo last commit, keep staged
git reset --mixed HEAD~1        # Undo last commit, keep unstaged
git reset --hard HEAD~1         # Undo last commit, discard changes

## STASH
git stash                       # Stash current changes
git stash pop                   # Apply and drop most recent stash
git stash list                  # List stashes
git stash drop                  # Drop most recent stash

## TAGS
git tag                         # List tags
git tag <name>                  # Create lightweight tag
git tag -a <name> -m "msg"      # Create annotated tag
git push origin <tag>           # Push tag to remote
git push origin --tags          # Push all tags

## COMMON WORKFLOWS

# Interactive rebase (squash, reorder, edit commits)
git rebase -i HEAD~3

# Cherry-pick a commit from another branch
git cherry-pick <commit>

# Find commit that introduced a bug
git bisect start
git bisect bad                  # current commit is bad
git bisect good <commit>        # known good commit
git bisect reset                # done

# Clean untracked files (dry run first)
git clean -n
git clean -fd
