# `hands-free` — voice-driven Mac sessions

`hands-free` puts this Mac into the setup described in
[`macos-hands-free-claude-code.md`](macos-hands-free-claude-code.md): **Superwhisper
for content**, **macOS Voice Control for commands**.

```sh
hands-free init      # once per machine — installs the two Voice Control shortcuts
hands-free enable    # Superwhisper up + in "Hands Free" mode, Voice Control on
hands-free disable   # Voice Control off; Superwhisper left alone
hands-free status    # what is on right now
hands-free help
```

Source: `dot_local/bin/executable_hands-free` → `~/.local/bin/hands-free`.
Shortcut sources: `dot_local/share/hands-free/*.shortcut.plist` → `~/.local/share/hands-free/`.

Every command is idempotent, and every command is a warning-and-exit-0 no-op off
macOS so it cannot break a Linux provisioning run.

## Why `init` exists, and why it needs one click

There is **no unentitled way to turn Voice Control on**. The switch lives behind
the private Mach service `com.apple.speech.CommandAndControl.utility`, and the
only code allowed to call it holds entitlements Apple does not issue:

```console
$ codesign -d --entitlements - \
    /System/Library/PrivateFrameworks/UniversalAccess.framework/PlugIns/UASettingsShortcuts.appex/...
com.apple.private.security.storage.universalaccess
com.apple.private.tcc.allow
com.apple.security.temporary-exception.mach-lookup.global-name
```

`defaults write com.apple.Accessibility CommandAndControlEnabled` does nothing —
that key is *reported* state, not a control. Shortcuts.app is the workaround: it
runs Apple's own entitled extension on our behalf, and `shortcuts run` works
headlessly once a shortcut exists.

Shortcuts cannot be installed headlessly, though. `open foo.shortcut` raises an
**Add Shortcut** confirmation sheet and `shortcuts list` stays empty until a
human clicks it. Writing straight into `~/Library/Shortcuts/Shortcuts.sqlite` is
readable but is a CloudKit-synced Core Data store behind a live daemon — not
safe to poke.

So `init` does everything except the click: it signs the committed shortcut
sources with `shortcuts sign`, opens each one, and blocks until it sees the
shortcut appear. This is deliberately **not** an Ansible task — provisioning
stays non-interactive, and `init` is run by hand once per machine.

## The shortcut serialization is load-bearing — do not "fix" it

Both shortcuts drive one action,
`com.apple.UniversalAccess.UASettingsShortcuts.UAToggleVoiceControlIntent`
("Set Voice Control"). Its parameters look wrong and are correct:

| Shortcut | `WFWorkflowActionParameters` |
| --- | --- |
| Voice Control On | *empty* — no `state`, no `operation` |
| Voice Control Off | `state: 0` |

The intent's own definition numbers its enums `operation: turn=1, toggle=2` and
`state: on=1, off=2`. **Using those values makes the action fail at run time**
with a bare "An unknown error occurred" — confirmed by trying it. The table
above is what the Shortcuts editor actually emits, and it works. Keep it.

Because the on-case carries no parameters, it is not certain whether it means
"turn on" or "toggle". `hands-free` never depends on the answer: it reads the
current state first and only runs a shortcut when a change is actually needed.

Two more gotchas baked into the script:

- `shortcuts sign` **rejects any input file not named `*.shortcut`**, regardless
  of content — hence the staging copy in `cmd_init`. The output filename becomes
  the installed shortcut's name.
- `shortcuts run` and `shortcuts sign` are both intermittently flaky —
  `run` hangs indefinitely maybe one time in three, and `sign` occasionally
  returns "Failed to modify some records". `run_shortcut` bounds the run with a
  watchdog and then judges success by the accessibility preference rather than
  the exit code; signing is retried three times.

## What `hands-free` cannot do: Command Mode

`enable` cannot put Voice Control into **Command Mode**, and `disable` cannot use
"stop listening" instead of turning Voice Control off. `startCommandMode` and
`setPersistentSleepState:` sit behind the same entitled service, and the
accessibility Shortcuts extension publishes exactly one Voice Control action —
on/off. There is no Command Mode action, and no sleep/wake action:

```console
$ sqlite3 ~/Library/Shortcuts/ToolKit/Tools-prod.*.sqlite \
    "select id from Tools where id like '%oiceControl%';"
com.apple.UniversalAccess.UASettingsShortcuts.UAToggleVoiceControlIntent
```

So `enable` finishes by telling you to say **"Command mode"**. Until you do,
Voice Control types what you say into the focused window.

## Superwhisper mode switching

`hands-free` selects a mode by its **display name** ("Hands Free"), not its key.
The two are unrelated strings — "Hands Free" is stored under the key
`voice to text` — so the script resolves the name against
`~/Documents/superwhisper/modes/*.json` (read with `plutil`, which parses JSON
too) rather than hardcoding a key.

Switching prefers the URL scheme, `superwhisper://mode?key=<key>`, but that
**silently ignores keys containing spaces** — superwhisper does not decode the
query value, so `%20`, `+`, and a literal space all fail. When the key has a
space the script falls back to quitting the app, writing `activeModeKey`, and
relaunching; a running superwhisper rewrites its own defaults on quit, so that
order is required.

## Environment overrides

| Variable | Default |
| --- | --- |
| `HANDS_FREE_MODE` | `Hands Free` |
| `HANDS_FREE_SHORTCUT_ON` / `_OFF` | `Voice Control On` / `Voice Control Off` |
| `HANDS_FREE_TIMEOUT` | `15` (seconds to wait for a state change) |
| `HANDS_FREE_DATA_DIR` | `~/.local/share/hands-free` |
