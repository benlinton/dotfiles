# Managed dotfiles policy

This repo is the **source of truth** for files that chezmoi deploys into `$HOME`.
The copies under `$HOME` (e.g. `~/.zshrc`, `~/.claude/settings.json`) are generated
output — editing them directly causes drift between the live file and the chezmoi
source, and a later `chezmoi apply` can silently revert or clobber those edits.

This policy exists to prevent that. It has two halves: a **workflow** for editing
managed files, and a **disclaimer comment** that marks them.

## When to read and apply this policy

Read and follow this policy whenever you:

- create or edit any file under `$HOME` that could be chezmoi-managed, **or**
- encounter the managed-file disclaimer (below) at the top of a file, **or**
- find a live `$HOME` file that has drifted from its chezmoi source.

## Workflow: edit the source, never the live copy

1. **Detect.** Before editing a file under `$HOME`, check whether it is managed:

   ```bash
   chezmoi source-path ~/.zshrc      # prints the source file, or errors if unmanaged
   chezmoi managed | grep -F .zshrc  # list everything chezmoi manages
   ```

2. **Edit the source, not the live file.** If managed, edit the source under
   `~/.local/share/chezmoi/` (or `chezmoi edit ~/.zshrc`), then deploy with
   `chezmoi apply`. Do not edit the `$HOME` copy directly.

3. **Preview before applying.** Use `chezmoi diff` to confirm the change does what
   you expect and isn't about to revert unrelated live drift.

4. **Reconcile drift with `re-add`, not `--force`.** If a live file has already
   drifted ahead of the source (it has wanted changes the source lacks), pull the
   live state back into the source with `chezmoi re-add <path>` — then commit it.
   Do **not** run `chezmoi apply --force` over a drifted file: that discards the
   live changes silently. (`--force` is only appropriate once you've deliberately
   decided the source should win.)

5. **Notify the user.** If you do edit a live `$HOME` copy directly — or you
   discover one has drifted — tell the user and reconcile it back into the source
   before moving on. Don't leave the source and live copy out of sync.

## Disclaimer comment

Every managed file **whose format supports comments** carries this disclaimer near
the top, using the file's native comment syntax. Keep the wording consistent so the
marker is easy to recognize:

```
IMPORTANT: Managed by chezmoi - do not edit this copy directly.
Source: ~/.local/share/chezmoi - edit there, then run `chezmoi apply`.
If you edit this file directly, notify the user and reconcile with the chezmoi source.
```

### Placement

- The disclaimer goes on the **first lines that are free to be comments**, i.e.
  *after* any line a format requires to come first: a `#!` shebang, a chezmoi
  template header (e.g. the `# bootstrap hash:` line in `run_onchange_*.tmpl`), or
  an editor modeline. Otherwise, top of file.
- Use the file's comment leader: `#` (shell, yaml, toml, gitignore, inputrc),
  `"` (vim), `;` (ini), `//` (jsonc), etc.

### Files that cannot take comments

Some formats have no comment syntax (strict JSON like `dot_claude/settings.json`,
binaries, etc.). **Do not** force a disclaimer into them — it will break the parser.
For these, rely on the detection step (`chezmoi managed` / `chezmoi source-path`)
instead. Treat any file that step reports as managed as covered by this policy,
disclaimer or not.

### Exceptions

The disclaimer is for files deployed **as-is** as persistent config. It is not
required for:

- `run_once_*` / `run_onchange_*` provisioning scripts (operational, not config the
  user keeps and edits), though a short managed note is fine.
- Files excluded via `.chezmoiignore` (`docs/`, `CLAUDE.md`, `README.md`, etc.) —
  these are never deployed to `$HOME`.
