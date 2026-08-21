# Hands-Free Claude Code on macOS

Use **macOS Voice Control + Superwhisper + Kitty + Claude Code** to work primarily by voice.

## 1. Basic Setup

1. Enable **Voice Control** in macOS Accessibility settings.
2. Say **“Command Mode”** when working in Kitty so normal speech isn't typed into the terminal.
3. Create a custom Voice Control command:

   * **Phrase:** `Superwhisper`
   * **Action:** press `Option + Space`
4. Configure `Option + Space` in Superwhisper to toggle recording.

**Workflow:** `“Superwhisper” → dictate prompt → “Superwhisper” → “Press Return”`

## 2. Remove the Trailing “Superwhisper”

The stop command is captured by the microphone before recording ends. Add this to your **Superwhisper Custom Mode** instructions:

```text id="y6vlca"
I use "Superwhisper" as a Voice Control command to stop recording, so it may be captured at the end of the User Message even though it isn't intended as dictated content.

When "Superwhisper" appears at the end as this stop command, remove it and any punctuation or whitespace belonging to it. Preserve legitimate uses of "Superwhisper" in the dictated content.
```

Examples:

```text id="x9vdkm"
"Find the bug in the authentication code Superwhisper"
→ "Find the bug in the authentication code"

"Open the Superwhisper configuration."
→ "Open the Superwhisper configuration."
```

## 3. Useful Voice-Control Vocabulary

| Say                     | Action                                  |
| ----------------------- | --------------------------------------- |
| **Superwhisper**        | `Option + Space` — start/stop dictation |
| **Send it**             | Return                                  |
| **Cancel Claude**       | `Control + C`                           |
| **Escape Claude**       | Escape                                  |
| **Claude up / down**    | Up / Down Arrow                         |
| **Claude left / right** | Left / Right Arrow                      |
| **Claude yes**          | `y` + Return                            |
| **Claude no**           | `n` + Return                            |
| **Clear terminal**      | `Control + L`                           |
| **New terminal**        | Kitty new-tab shortcut                  |
| **Next / Previous tab** | Kitty tab shortcuts                     |

Use distinctive phrases such as **“Claude up”** rather than generic commands such as “up arrow” to reduce Voice Control collisions.

## 4. Make Kitty More Powerful

Kitty's **remote-control API** can create/focus tabs and windows, launch processes, send text/keys, and target specific terminals.

Enable it in `kitty.conf`:

```conf id="ir71n2"
allow_remote_control yes
```

> Consider Kitty's remote-control security restrictions before enabling unrestricted access.

Examples:

```bash id="mz9lhd"
# Start Claude in a new tab
kitten @ launch --type=tab --tab-title Claude claude

# Focus Claude
kitten @ focus-window --match 'title:Claude'

# Send text
kitten @ send-text --match 'title:Claude' 'hello'

# Send Ctrl+C
kitten @ send-key --match 'title:Claude' ctrl+c
```

### Future Voice Commands

Combine **Voice Control → macOS Shortcut/script → Kitty Remote Control** to create higher-level commands:

* **“Open Claude”** → open/focus Kitty, create a tab, enter a project, start Claude.
* **“Go to Claude”** → focus the Kitty tab running Claude.
* **“New Claude”** → launch another Claude session.
* **“Cancel Claude”** → send `Control+C` directly to Claude.

## Architecture

```text id="fnxg7d"
Voice Control
    ├── Superwhisper → dictated prompts
    ├── Key commands → Return / Escape / arrows
    └── Shortcuts/scripts → Kitty Remote Control
                              ├── focus tabs
                              ├── launch Claude
                              ├── switch projects
                              └── send text/keys
```

* **Superwhisper:** content
* **Voice Control:** commands
* **Kitty:** terminal automation
* **Claude Code:** development agent
