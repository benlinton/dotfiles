# Claude Code permission rules

Read this whenever you're asked to allow, ask, deny, or "stop prompting for" a
Bash command.

## Where the machinery lives now

The permission gate — the PreToolUse hook, the per-project policy, the
`luma-foreman policy` command, and the tests — **moved out of this repository**
into [luma-foreman](https://github.com/LumaStack/luma-foreman). It is versioned,
tested and installable there rather than being a loose script in someone's
dotfiles.

- **Change what a project allows:** `luma-foreman policy allow curl`. Effective
  on the next tool call. Nothing in this repository is involved.
- **The gate, its policy, and its docs:** the foreman checkout, and
  `docs/claude-permission-policy.md` inside it.
- **Reinstall after upgrading foreman:** `luma-foreman policy install`.

## What this repository still owns

Exactly one thing: `dot_claude/settings.json`. Two parts of it matter.

**The hook wiring**, which points Claude Code at the installed gate:

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash|Read|Write|Edit|MultiEdit|NotebookEdit",
      "hooks": [{ "type": "command", "command": "$HOME/.local/share/luma/luma-foreman/permission-gate.sh" }]
    }
  ]
}
```

**The native rules** under `permissions.deny` / `.ask` / `.allow`. These are
global — one answer for every repository — and they are the layer the hook
cannot override. Two of them are load-bearing for the gate:

- `Edit(~/.config/luma/**)` and `Edit(~/.local/share/luma/**)` in `deny` — the
  first stops a session editing the policy, the second stops it editing the gate
  script that enforces the policy. Foreman splits these across two roots
  (`~/.config/luma` for state, `~/.local/share/luma` for code), so denying only
  one leaves the other writable. **Both, and not optional.**
- `Bash(rm -r*)` and the force-push entries in `ask` — backups that keep working
  if the hook script ever goes missing. A missing hook fails *open*.

`luma-foreman policy install` checks both and tells you what is missing.

## Rules of thumb for a new rule

| You want… | Put it in |
|---|---|
| Hard block everywhere | native `permissions.deny`, here |
| Always prompt, every repository, simple leading pattern | native `permissions.ask`, here |
| A different answer per repository | `luma-foreman policy`, not here |
| Prompt in normal modes but not bypass | `luma-foreman policy set <key> ask` |
| Prompt in every mode including bypass | `luma-foreman policy set <key> always` |

Native patterns are anchored to the **start** of the command, so `Bash(git push *)`
does not match `foo && git push`. Catching a command inside a compound is the
hook's job, which is another reason it exists.

## Two ways a native rule silently does nothing

Both were live in this repo. Neither is visible from the config — the rules look
right and match nothing.

**A single leading `/` is not the filesystem root.** It resolves relative to the
settings file's own root, so in `~/.claude/settings.json`, `Read(/tmp/**)` means
`~/.claude/tmp/**`. The four forms: `//path` = filesystem root, `/path` =
relative to the settings source, `~/path` = home, `path` = relative to cwd.
**There is no warning for getting this wrong.** That is why the temp rules here
are `Read(//tmp/**)` and `Edit(//tmp/**)` with two slashes.

**Only some tool names are consulted for file rules.** `Write(...)`,
`NotebookEdit(...)` and `MultiEdit(...)` are inert — write `Edit(...)`, which
covers every file-editing tool. `Glob(...)` is inert too; use `Read(...)`. This
one *does* warn at startup, so launch Claude Code once after adding a file rule
and read the first screen.

The general lesson: a permission rule can only be verified against the running
product, never by inspecting the config. `chezmoi apply`, start a session, and
confirm the prompt behaviour actually changed.

## chezmoi

`settings.json` is chezmoi-managed, so edit the source, not the live copy — see
[`managed-dotfiles-policy.md`](managed-dotfiles-policy.md). It is strict JSON and
cannot carry the managed-file disclaimer, so confirm with `chezmoi source-path`
instead.

```bash
chezmoi source-path ~/.claude/settings.json   # -> dot_claude/settings.json
jq . ~/.claude/settings.json >/dev/null && echo OK
```

The gate itself is **not** chezmoi-managed any more. `luma-foreman policy install`
puts it in place; do not add it back here.
