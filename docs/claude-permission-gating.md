# Claude Code permission-rule change workflow

How to add or change a permission rule for Claude Code **without leaving the two
enforcement layers out of sync**. Read this whenever you're asked to allow, ask,
deny, or "stop prompting for" a Bash command.

This doc describes the *workflow*, not the current rule set — read the live files
for that:

- `~/.claude/settings.json` → source `dot_claude/settings.json` (**chezmoi-managed**)
- `~/.claude/permission-gate.sh`

## The two enforcement layers ("both places")

1. **Native declarative rules** in `settings.json` under
   `permissions.deny` / `.ask` / `.allow`. Patterns look like `Bash(git push *)`,
   are gitignore-style, and are **anchored to the start of the command** — so they
   do *not* match a command buried in a compound like `foo && git push`.

2. **The PreToolUse hook** `permission-gate.sh` (matcher `Bash`). It reads the command
   and `permission_mode` from stdin and can emit `permissionDecision: "ask"` to
   force a prompt. It matches **anywhere in the command string**, so it *is* what
   catches compound commands and odd flag forms the native rules miss.

Any change that adds/removes gating usually touches **one of these on purpose** —
but check the other so they don't contradict. (E.g. removing a native `ask` rule
does nothing if the hook still gates the same command.)

## Precedence — what actually wins

Effective order, most-restrictive-wins: **deny → hook decision → ask → allow**.

Mode behavior — this is the crux:

| Layer | Fires in normal modes? | Fires in `bypassPermissions`? |
|---|---|---|
| native `deny` | yes | yes |
| native `ask` | yes | **yes** |
| hook **tier 1** (above the bypass short-circuit) | yes | **yes** |
| hook **tier 2** (the `case` below the short-circuit) | yes | **no** |
| native `allow` prompt | n/a (allows) | skipped |

`bypassPermissions` only skips the *allow*-stage prompting and the hook's tier-2
block. It does **not** skip native `deny`, native `ask`, or hook tier-1. That
asymmetry is the whole design: tier-1 = "prompt even in bypass", tier-2 = "prompt
except in bypass".

## The buckets — what each is for, and why

There are five buckets a command can land in. They exist because two independent
questions have to be answered separately: **"how hard do we stop this?"**
(deny/ask/allow) and **"does bypass mode get to skip the stop?"** (native vs. hook,
tier-1 vs. tier-2). No single list can express both, which is why the hook exists
alongside the native rules.

- **native `deny` — "never, under any circumstance."**
  Use when running the command is itself the harm and there's no legitimate case for
  a prompt (e.g. reading secret files). Deny is absolute and mode-independent; if
  you find yourself wanting "deny, but sometimes allow," it isn't a deny — it's an
  `ask`.

- **native `ask` — "always make me confirm, in every mode."**
  The reasoning is *irreversibility over convenience*: for actions you can't take
  back (`git push --force`, recursive `rm`), the cost of one confirmation keystroke
  is trivial next to the cost of the mistake, so you pay it even in bypass. Native
  `ask` is the right home when a simple leading pattern describes the command and you
  don't need to catch it inside a compound. Its limitation is the reason tier-1
  exists: it only matches the *start* of the command.

- **hook tier-1 — "always confirm, and don't let anything slip past."**
  Same intent as native `ask` (prompt in every mode, bypass included — tier-1 runs
  *before* the bypass short-circuit), but enforced in the hook because you need
  matching the native list can't do: substrings/compounds (`cd x && rm -rf y`), flag
  variants (`-r`, `-R`, `-rf`, `-fr`, `--recursive`), or absolute paths (`/bin/rm`).
  Pair it with a native `ask` backup so the guard survives the hook script going
  missing. Reach here only when the danger is severe enough to justify bypass-proof,
  compound-proof matching — otherwise native `ask` is simpler.

- **hook tier-2 — "confirm normally, but trust me in bypass."**
  This is the bucket the whole setup was built for. These commands are risky enough
  to want a check during ordinary work (`ssh`, `curl`, `wget`, `sudo`, non-force
  `git push`) but *not* so dangerous that you'd want them to interrupt an explicit
  bypass session, where you've deliberately opted into "don't ask me about routine
  things." Tier-2 sits *below* the bypass short-circuit, so bypass silences it. If a
  command is reversible and its risk is context-dependent, it belongs here.

- **native `allow` — "routine, never worth a prompt."**
  Read-only or trivially-safe commands (`ls`, `cat`, `git status`). The reasoning is
  the inverse of `ask`: prompting on these is pure friction with no upside. Note the
  hook can still override an `allow` (precedence puts the hook ahead of `allow`),
  which is how a broad `allow` entry plus a tier gate coexist without contradiction.

The dividing lines, stated as the two questions:
1. **Reversible?** If no → `ask`/tier-1 (confirm every mode). If yes → tier-2 or
   `allow`.
2. **Should bypass skip the prompt?** If no → native `ask` or tier-1. If yes →
   tier-2 (gated normally, silent in bypass) or `allow` (never gated).

## Decide where a new rule goes

| You want… | Put it in |
|---|---|
| Hard block, command never runs | native `permissions.deny` |
| Always prompt, every mode, simple leading pattern | native `permissions.ask` |
| Always prompt every mode **and** catch compound / odd flags / be bypass-proof | hook **tier 1** (before the bypass short-circuit) — optionally a native `ask` as a backup if the hook script goes missing |
| Prompt in normal modes, **silent under bypass** | hook **tier 2** (the `case "$cmd"` block) |
| Always run silently | native `permissions.allow` |

## Two ways a rule silently does nothing

Both of these were live in this repo. Neither is visible from the config itself —
the rules look right, and everything stays internally consistent while matching
nothing. Check for both before concluding a rule works.

**A single leading `/` is not the filesystem root.** It resolves *relative to the
settings file's own root*, which for `~/.claude/settings.json` means `~/.claude`.
So `Read(/tmp/**)` matches `~/.claude/tmp/**`, not `/tmp`. Confirmed in the
2.1.220 binary:

```js
if (e.startsWith("//")) return e.slice(1);                            // absolute
if (e.startsWith("/") && !e.startsWith("//")) return resolve(t, e.slice(1));  // relative to root
```

The four forms: `//path` = filesystem root, `/path` = relative to the settings
source, `~/path` = home, `path` = relative to cwd. **There is no warning for
getting this wrong.** That is why the temp rules here are `Read(//tmp/**)` and
`Edit(//tmp/**)` with two slashes.

**Only some tool names are consulted for file rules.** `Write(...)`,
`NotebookEdit(...)` and `MultiEdit(...)` are all inert — write `Edit(...)`, which
covers every file-editing tool. `Glob(...)` is inert too; use `Read(...)`. This
one *does* warn at startup, so launch Claude Code once after adding a file rule
and read the first screen.

The general lesson: a permission rule can only be verified against the running
product, never by inspecting the config. `chezmoi apply`, start a session, and
confirm the prompt behavior actually changed.

## Make the change

- **Native rule:** edit the relevant array in the **source** (`dot_claude/settings.json`).
  Use `Bash(<pattern> *)`. Remember it only matches the start of the command.
- **Hook tier 2** (normal-ask / bypass-silent): add a glob to the `case "$cmd"`
  block, e.g. `*'docker '*)`.
- **Hook tier 1** (every-mode, bypass-proof): add a `grep`/`case` test **above** the
  `[ "$mode" = "bypassPermissions" ] && exit 0` line so it runs before bypass can
  short-circuit.

### The bypass trap (read before "let X run in bypass")

To truly let a currently-gated command run silently in bypass you must relax **both**
layers: move/remove it from the hook **and** delete any native `ask` rule for it —
because native `ask` still fires in bypass. Touching only one leaves it prompting.

## chezmoi: both files are managed — edit the source, not the live copy

Both `settings.json` and `permission-gate.sh` are deployed by chezmoi, so **edit the
source, not the live copy** (see `managed-dotfiles-policy.md`):

- `~/.claude/settings.json` → `dot_claude/settings.json`
- `~/.claude/permission-gate.sh` → `dot_claude/executable_permission-gate.sh`
  (the `executable_` prefix preserves the `+x` bit; the script carries the standard
  managed-file disclaimer after its shebang. `settings.json` is strict JSON so it
  can't — confirm it's managed with `chezmoi source-path` instead.)

```bash
chezmoi source-path ~/.claude/settings.json   # -> dot_claude/settings.json (managed)
chezmoi diff ~/.claude/permission-gate.sh     # preview source-vs-live before apply
```

Two valid ways to edit either file:

- Edit the source in the repo, then `chezmoi apply`, **or**
- Edit the live `~/.claude/…` copy, then pull it back with
  `chezmoi re-add ~/.claude/<file>`.

Never `chezmoi apply --force` over a drifted live file — it discards live changes.

## Verify after any change

```bash
# 1. settings.json is still valid JSON
jq . ~/.claude/settings.json >/dev/null && echo OK

# 2. Exercise the hook directly (test BOTH modes for gated commands)
echo '{"tool_input":{"command":"sudo reboot"},"permission_mode":"default"}' | ~/.claude/permission-gate.sh
echo '{"tool_input":{"command":"sudo reboot"},"permission_mode":"bypassPermissions"}' | ~/.claude/permission-gate.sh
```

Expect JSON containing `"permissionDecision":"ask"` when it should prompt, and empty
output when it should stay silent. Back up first: `cp ~/.claude/settings.json{,.bak}`.

Note: the hook matches textually, so it can over-prompt on string literals like
`echo "rm -rf /"`. That's intentional — it fails safe toward prompting.
