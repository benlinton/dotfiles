# Toggling macOS Voice Control with a Hotkey

Once Voice Control is fully disabled, voice commands like `"Wake up"` won't
re-enable it — the microphone isn't listening. You need an OS-level trigger.
Below are three options to turn Voice Control back on without opening System
Settings.

## Option 1: Accessibility Shortcut (built-in)

A system-level gesture that toggles accessibility features. Works even when
Voice Control is completely off because the OS owns the hotkey.

**Setup:**
- Open **System Settings** → **Accessibility**
- Scroll to the bottom → click **Shortcut…**
- Check **Voice Control** and uncheck everything else
- Close the dialog

**Use:**
- Triple-press the **Touch ID button** (or ⌥⌘F5 on Macs without Touch ID)
- Triple-press again to turn it off

**Pros:**
- Zero setup beyond a checkbox
- No third-party software
- Survives OS reinstalls and migrations
- Always available, even on a fresh login

**Cons:**
- Hotkey is fixed (triple-press / ⌥⌘F5) — can't pick your own combo
- If multiple accessibility items are checked, you get a menu instead of a
  direct toggle
- Triple-press gesture is slower than a single keystroke

## Option 2: Shortcuts.app + custom hotkey

Use Apple's built-in Shortcuts app to create a toggle and bind it to a
keyboard shortcut of your choice.

**Setup:**
- Open **Shortcuts.app** (preinstalled on macOS Monterey and later)
- Click **+** to create a new shortcut
- Add the **Set Voice Control** action and set it to **Toggle** (or **Turn On**)
- Press ⌘I to open the shortcut details
- Click **Add Keyboard Shortcut** and press your desired key combo
- Name the shortcut something memorable (e.g. "Toggle Voice Control")

**Use:**
- Press your chosen key combo from anywhere

**Pros:**
- Pick any key combo you want
- Single keystroke, no menu
- No third-party software
- Same shortcut can be triggered from the menu bar or Spotlight

**Cons:**
- Requires macOS Monterey or later
- Hotkey occasionally fails to register until you open Shortcuts.app once
  per login session
- Slightly more setup than Option 1

## Option 3: Alfred 5 workflow

Use Alfred's hotkey trigger to invoke either a Shortcuts.app shortcut or a
direct shell command.

**Setup:**
- Open **Alfred Preferences** → **Workflows**
- Click **+** at the bottom → **Blank Workflow**
- Right-click the canvas → **Triggers** → **Hotkey** → set your key combo
- Right-click → **Actions** → **Run Script**
- Set language to `/bin/bash` and enter:
  ```sh
  shortcuts run "Toggle Voice Control"
  ```
- Connect the Hotkey trigger to the Run Script action by dragging
- (Requires the Shortcuts.app shortcut from Option 2 to exist)

**Use:**
- Press your chosen key combo from anywhere

**Pros:**
- Pick any key combo you want
- Integrates with the rest of your Alfred workflows
- Can chain additional actions (notifications, follow-up commands)

**Cons:**
- Requires Alfred 5 with the **Powerpack** license (~£34) for workflows
- Still depends on a Shortcuts.app shortcut existing under the hood
- Most complex of the three options

## Recommendation

Start with **Option 1**. It's a single checkbox, costs nothing, and works
forever. Move to Option 2 only if the triple-press gesture feels too slow or
awkward. Option 3 is worth it only if you already use Alfred workflows
heavily and want everything in one place.
