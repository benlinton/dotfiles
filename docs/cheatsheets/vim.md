# VIM CHEATSHEET

# MODES
i           # Insert mode (before cursor)
a           # Insert mode (after cursor)
I           # Insert at beginning of line
A           # Insert at end of line
o           # Open new line below
O           # Open new line above
v           # Visual mode (character)
V           # Visual mode (line)
Ctrl-v      # Visual mode (block)
Esc         # Return to normal mode

# MOVEMENT
h j k l     # Left, down, up, right
w / b       # Next / previous word
e           # End of word
0 / ^       # Start of line / first non-blank
$           # End of line
gg / G      # Top / bottom of file
<n>G        # Go to line n
%           # Jump to matching bracket
Ctrl-d/u    # Scroll half page down / up
Ctrl-f/b    # Scroll full page down / up
{ / }       # Previous / next blank line (paragraph)

# EDITING
x           # Delete character under cursor
dd          # Delete line
dw          # Delete word
d$          # Delete to end of line
cc          # Change line (delete + insert)
cw          # Change word
r<c>        # Replace character with c
u           # Undo
Ctrl-r      # Redo
.           # Repeat last change
p / P       # Paste after / before cursor
yy          # Yank (copy) line
yw          # Yank word
y$          # Yank to end of line

# TEXT OBJECTS (combine with d, c, y, v)
iw / aw     # Inner / around word
is / as     # Inner / around sentence
ip / ap     # Inner / around paragraph
i" / a"     # Inner / around double quotes
i( / a(     # Inner / around parentheses
i{ / a{     # Inner / around braces
i[ / a[     # Inner / around brackets
it / at     # Inner / around HTML/XML tag

# SEARCH & REPLACE
/pattern    # Search forward
?pattern    # Search backward
n / N       # Next / previous match
* / #       # Search word under cursor forward / backward
:%s/old/new/g       # Replace all in file
:%s/old/new/gc      # Replace all with confirmation
:s/old/new/g        # Replace all on current line

# FILES & BUFFERS
:e <file>   # Open file
:w          # Save
:w <file>   # Save as
:q          # Quit
:wq / ZZ    # Save and quit
:q!         # Quit without saving
:bn / :bp   # Next / previous buffer
:ls         # List open buffers
:bd         # Close buffer

# WINDOWS & TABS
:sp <file>  # Horizontal split
:vsp <file> # Vertical split
Ctrl-w h/j/k/l      # Move between windows
Ctrl-w =    # Equal window sizes
Ctrl-w _    # Maximize height
Ctrl-w |    # Maximize width
:tabnew     # New tab
gt / gT     # Next / previous tab

# MARKS & JUMPS
m<a>        # Set mark a (lowercase = file-local, uppercase = global)
`<a>        # Jump to mark a
''          # Jump to last position
Ctrl-o/i    # Jump back / forward in jump list

# MACROS
q<a>        # Start recording macro into register a
q           # Stop recording
@<a>        # Play macro a
@@          # Repeat last macro
<n>@<a>     # Play macro n times

# MISC
:!<cmd>     # Run shell command
:r !<cmd>   # Insert output of shell command
gg=G        # Re-indent entire file
=           # Auto-indent selection (visual mode)
~           # Toggle case of character
gU          # Uppercase selection (visual mode)
gu          # Lowercase selection (visual mode)
Ctrl-a/x    # Increment / decrement number under cursor
