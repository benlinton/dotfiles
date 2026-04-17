# ZOXIDE CHEATSHEET

## NAVIGATION
z foo                          # cd to highest-ranked match for "foo"
z foo bar                      # cd to highest-ranked match for "foo" then "bar"
z ~                            # cd to home
z -                            # cd to previous directory
zi foo                         # interactive selection (requires fzf)

## DATABASE MANAGEMENT
zoxide add /path               # manually add a directory
zoxide remove /path            # remove a directory from the database
zoxide edit                    # interactively edit the database

## QUERYING
zoxide query foo               # print best match (don't cd)
zoxide query -l                # list all entries ranked by score
zoxide query -l foo            # list entries matching "foo"

## SCORING
# Directories rank higher the more frequently and recently you visit them.
# Entries decay over time and are pruned when the db exceeds 10,000 entries.
