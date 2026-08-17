# Claude Code permission-rule change workflow

How to add or change a permission rule for Claude Code **without leaving the two
enforcement layers out of sync**. Read this whenever you're asked to allow, ask,
deny, or "stop prompting for" a Bash command.

This doc describes the *workflow*, not the current rule set — read the live files
for that:

- `~/.claude/settings.json` → source `dot_claude/settings.json` (**chezmoi-managed**)
- `~/.claude/permission-gate.sh` → source `dot_claude/executable_permission-gate.sh`
- `~/.config/luma/policy.toml` and `~/.config/luma/projects/<slug>.toml` — the
  per-project policy the hook reads. **Not chezmoi-managed and never committed:**
  it is machine- and project-local by design. Read it with `luma-policy`.

Most day-to-day changes are now a `luma-policy set` away and touch none of the
files above. Reach for the sections below when you need to change what the
*machinery* does, not what this project's answer is.

## The two enforcement layers ("both places")

1. **Native declarative rules** in `settings.json` under
   `permissions.deny` / `.ask` / `.allow`. Patterns look like `Bash(git push *)`,
   are gitignore-style, and are **anchored to the start of the command** — so they
   do *not* match a command buried in a compound like `foo && git push`. These are
   global: there is no per-project dimension.

2. **The PreToolUse hook** `permission-gate.sh` (matcher `Bash`). It reads the command,
   `permission_mode` and `cwd` from stdin and can emit `permissionDecision: "ask"`
   or `"deny"`. It matches **anywhere in the command string**, so it *is* what
   catches compound commands and odd flag forms the native rules miss — and it is
   the only layer that can answer differently per project.

Any change that adds/removes gating usually touches **one of these on purpose** —
but check the other so they don't contradict. (E.g. removing a native `ask` rule
does nothing if the hook still gates the same command.)

## Precedence — what actually wins

Effective order, most-restrictive-wins: **deny → hook decision → ask → allow**.

Mode behavior — this is the crux:

| Layer | Fires in normal modes? | Fires in `bypassPermissions`? | Fires under `trust = "full"`? |
|---|---|---|---|
| native `deny` | yes | yes | yes |
| native `ask` | yes | **yes** | **yes** |
| hook `always` / `deny` (above the short-circuit) | yes | **yes** | **yes** |
| hook `ask` / `trusted` / `safe` (below it) | yes | **no** | **no** |
| native `allow` prompt | n/a (allows) | skipped | skipped |

`bypassPermissions` only skips the *allow*-stage prompting and the hook's lower
block. It does **not** skip native `deny`, native `ask`, or the hook's `always`
tier. That asymmetry is the whole design: `always` = "prompt even in bypass",
`ask` = "prompt except in bypass".

**The native layer is global, so it wins the argument.** A native `ask` rule
still prompts in a project whose policy says `allow` — the hook can only tighten
what settings.json already permits, never loosen it. If a project-level `allow`
appears to do nothing, look for a native rule covering the same command first.

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

- **hook `always` — "always confirm, and don't let anything slip past."**
  Same intent as native `ask` (prompt in every mode, bypass included — the `always`
  pass runs *before* the bypass short-circuit), but enforced in the hook because you
  need matching the native list can't do: substrings/compounds (`cd x && rm -rf y`),
  flag variants (`-r`, `-R`, `-rf`, `-fr`, `--recursive`), or absolute paths
  (`/bin/rm`). Pair it with a native `ask` backup so the guard survives the hook
  script going missing. Reach here only when the danger is severe enough to justify
  bypass-proof, compound-proof matching — otherwise native `ask` is simpler.

- **hook `ask` — "confirm normally, but trust me in bypass."**
  This is the bucket the whole setup was built for. These commands are risky enough
  to want a check during ordinary work (`ssh`, `curl`, `wget`, `sudo`, non-force
  `git push`) but *not* so dangerous that you'd want them to interrupt an explicit
  bypass session, where you've deliberately opted into "don't ask me about routine
  things." It sits *below* the bypass short-circuit, so bypass silences it. If a
  command is reversible and its risk is context-dependent, it belongs here.

- **hook `deny` — "not in this project."**
  A project-scoped hard block. Distinct from native `deny` only in that it can be
  set for one repository without affecting the others, which is the entire reason it
  exists. Note it still cannot loosen anything: a native `allow` plus a hook `deny`
  blocks the command.

- **native `allow` — "routine, never worth a prompt."**
  Read-only or trivially-safe commands (`ls`, `cat`, `git status`). The reasoning is
  the inverse of `ask`: prompting on these is pure friction with no upside. Note the
  hook can still override an `allow` (precedence puts the hook ahead of `allow`),
  which is how a broad `allow` entry plus a tier gate coexist without contradiction.

The dividing lines, stated as three questions:
1. **Reversible?** If no → native `ask` / hook `always` (confirm every mode). If
   yes → hook `ask` or `allow`.
2. **Should bypass skip the prompt?** If no → native `ask` or hook `always`. If
   yes → hook `ask` (gated normally, silent in bypass) or `allow` (never gated).
3. **Is the answer the same in every repository?** If yes → native rule. If no →
   hook, and set it with `luma-policy` rather than editing the script.

## Decide where a new rule goes

| You want… | Put it in |
|---|---|
| Hard block everywhere, command never runs | native `permissions.deny` |
| Always prompt, every mode, simple leading pattern | native `permissions.ask` |
| Always prompt every mode **and** catch compound / odd flags / be bypass-proof | policy value `always` — optionally a native `ask` as a backup if the hook script goes missing |
| Prompt in normal modes, **silent under bypass** | policy value `ask` |
| Always run silently | native `permissions.allow`, or policy value `allow` for one project |
| A different answer in this repo than everywhere else | `luma-policy set <key> <value>` |
| A brand-new *class* of command gated at all | a new key in the hook (see below) |

## Per-project policy

The hook resolves a policy on every Bash call, per key, most specific wins:

```
~/.config/luma/projects/<slug>.toml   the project the session is in
~/.config/luma/policy.toml            global fallback
the def_* values in the hook          built-in
```

`<slug>` is the project's absolute path with `/` and `.` both replaced by `-`,
matching how Claude Code names directories under `~/.claude/projects`. The path is
the **repository root** — the nearest ancestor holding a `.git` — so every session
in a repo shares one policy no matter which subdirectory it started in. Outside a
repo it is the session cwd. Worktrees have their own `.git` and so their own
policy, which is deliberate.

Nothing is stored inside the project, so none of this can be committed by
accident. That is why the config lives under `~/.config/luma` rather than the
`.hq/` directory it was first sketched as.

```bash
luma-policy                          # effective policy here, and where each value came from
luma-policy keys                     # every key, what it gates, what it accepts
luma-policy keys curl                # the long version for one key, incl. its limits

luma-policy allow curl               # shorthand for the three common values
luma-policy ask curl
luma-policy deny curl
luma-policy set curl safe            # general form — reaches safe, trusted, always
luma-policy set -g sudo ask          # global fallback
luma-policy reset curl               # drop one override
luma-policy reset                    # drop every override in this scope

luma-policy projects                 # every project that has a config
```

Changes take effect on the **next tool call**. No restart — the hook re-reads
these files each time it runs. This is the reason policy lives in a file the hook
reads rather than in `settings.json`: Claude Code snapshots hook *configuration*
at session start, so a settings-based design would need a restart per change.

### Why the commands are named that way

Modelled on prior art rather than invented, so the muscle memory transfers:

| | precedent |
|---|---|
| bare invocation / `list` = effective config | `claude auto-mode config`, `git config list`, `npm config list`, `gh config list`, `kubectl config view` |
| `reset [<key>]` = back to defaults | `claude auto-mode reset` ("reset to the shipped defaults"). `unset` still works — it is what `git config` and `kubectl config` call it — but it reads as "turn off", which is the wrong meaning |
| `allow` / `ask` / `deny` verbs | `ufw allow`/`deny`, and Claude Code's own `permissions.allow`/`.ask`/`.deny`. **Not** `disallow` — nothing in this space uses that word |
| `projects` = list the instances | `defaults domains`, `docker context ls`, `git worktree list` — a plural noun naming the thing being enumerated |
| `keys` = list the schema | the weakest precedent; most tools push this to a man page. `kubectl explain` is the nearest |

The shorthands only apply to keys with a closed value set. `ssh_hosts` takes a
value, so `luma-policy allow ssh_hosts` is refused rather than writing the string
`"allow"` into the hostname list.

### Two values that are not just tiers

- **`ssh = "trusted"`** allows a host listed in `ssh_hosts` and prompts for
  anything else. Anything it cannot parse confidently — no host, two `ssh`
  invocations in one compound — prompts.
- **`curl`/`wget = "safe"`** allows a plain fetch and prompts when the command
  writes to disk (`-o`, `-O`), uploads a body (`-T`, `-d`, `-F`), or pipes into an
  interpreter. **It cannot tell you what a URL returns** — the hook sees only the
  command string. `safe` is a claim about the *shape* of the command, never about
  the bytes that come back. Treat it as ergonomics, not containment.

### What this layer is not

The hook matches text. `$(echo curl)`, a renamed binary, or a Python script using
`urllib` all walk straight past it, and `downloads` can only list the common
package-manager front doors. It is a guard against your own slips and the agent's
carelessness, not against an adversary. For an actual boundary use Claude Code's
[sandboxing](https://code.claude.com/docs/en/sandboxing) — OS-level filesystem and
network limits on Bash and its children — with this layer on top for ergonomics.

### Keeping the agent out of its own rulebook

Two things stop a session editing the policy that governs it:

- `Edit(~/.config/luma/**)` in `permissions.deny` — absolute, covers the file tools.
- The `policy_write` key, `always` by default — catches Bash writes to those paths
  and `luma-policy set|unset|edit`, in every mode including bypass.

Both are load-bearing. Reads stay ungated: `luma-policy show` and `cat`ting the
files are fine, and being able to *see* the policy is what makes a refusal legible.

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

- **Change an existing gate for one project:** `luma-policy set <key> <value>`.
  Nothing to edit, nothing to apply, no restart. This covers most requests.
- **Change the default for every project:** `luma-policy set -g <key> <value>` if
  the machine should differ, or the `def_*` block in the hook source if the
  *shipped* default is wrong.
- **Native rule:** edit the relevant array in the **source** (`dot_claude/settings.json`).
  Use `Bash(<pattern> *)`. Remember it only matches the start of the command, and
  that it applies to every project.
- **Gate a command class that isn't gated at all yet:** three edits to the hook
  source, all in one place each — add `def_<key>` with the shipped default, add the
  key to `KEYS`, and add its arm to `matches()`. The two decision passes are
  data-driven and need no change. Add the key to `KEYS` and the help text in
  `dot_local/bin/executable_luma-policy` too, or the CLI will reject it as unknown.
  Then add cases to `tests/permission-gate-test.sh`.

Every `matches()` arm should start with a cheap shell `case` pre-filter before its
`grep`, e.g. `case $cmd in *docker*) ;; *) return 1 ;; esac`. The hook runs on
every Bash call and the pre-filter is what keeps the common path from forking a
`grep` per key.

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
# 1. The test suite. It is hermetic — it points LUMA_POLICY_HOME at a temp dir,
#    so it never reads or writes your real ~/.config/luma.
sh tests/permission-gate-test.sh

# 2. settings.json is still valid JSON
jq . ~/.claude/settings.json >/dev/null && echo OK

# 3. Exercise the hook directly. `cwd` now matters — it selects the project —
#    and gated commands must be tested in BOTH modes.
echo '{"tool_name":"Bash","cwd":"'"$PWD"'","tool_input":{"command":"sudo reboot"},"permission_mode":"default"}' | ~/.claude/permission-gate.sh
echo '{"tool_name":"Bash","cwd":"'"$PWD"'","tool_input":{"command":"sudo reboot"},"permission_mode":"bypassPermissions"}' | ~/.claude/permission-gate.sh

# 4. What the hook thinks the policy is, from the same directory
luma-policy
```

Expect JSON containing `"permissionDecision":"ask"` when it should prompt, and empty
output when it should stay silent. Back up first: `cp ~/.claude/settings.json{,.bak}`.

A gate that stops firing after a policy edit is almost always one of: the value is
`allow` when you meant `ask`, `trust = "full"` is set on the project, or you are
looking at a different project than the hook is — check `luma-policy` first, it
prints the resolved project path and the source of every value.

Note: the hook matches textually, so it can over-prompt on string literals like
`echo "rm -rf /"`. That's intentional — it fails safe toward prompting.
