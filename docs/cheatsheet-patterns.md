# Cheatsheet Patterns

Style guide for files in `docs/cheatsheets/`.

## File format

- **Extension:** `.sh` — gives shell syntax highlighting on GitHub while keeping files readable via `cat` in the terminal. Not `.md` because every `#` comment renders as a markdown heading.
- **Title:** `# TOOL CHEATSHEET` on line 1 (single `#`)
- **Section headers:** `## SECTION NAME` (double `##` for visual weight in terminal output)
- **Commands:** `command arg` followed by `# description`, right-aligned with spaces
- **Inline comments:** use `#` for descriptions on the same line as a command
- **Explanatory notes:** use `#` on their own line within a section

## Example

```
# TOOL CHEATSHEET

## SECTION
command arg                        # what it does
command --flag <param>             # what it does

## ANOTHER SECTION
# Explanation of something non-obvious.
command arg                        # what it does
```

## Known tradeoffs

- Unmatched quotes in commands (e.g., `git commit -m "msg"`) can break `.sh` syntax highlighting on GitHub. This is acceptable — the alternative extensions are worse overall.
- `##` is not standard shell comment syntax, but it works as a valid comment and stands out as a section divider in terminal output.
