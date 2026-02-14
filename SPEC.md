# ScrollPad - Quick Note Taking App Specification

## 1. Project Overview

- **Project Name**: ScrollPad
- **Bundle Identifier**: com.scrollpad.app
- **Core Functionality**: A minimalist, frictionless quick note-taking app with an endless scroll of text, Tahoe Liquid Glass design, hotkey activation, and the ability to send sections to Apple Notes.
- **Target Users**: Anyone who needs to quickly capture ideas before forgetting them
- **macOS Version Support**: macOS 15.0+ (Tahoe/Liquid Glass)

## 2. UI/UX Specification

### Window Structure

- **Main Window**: Single borderless window with liquid glass appearance
- **Window Behavior**:
  - Appears centered on screen when activated via hotkey
  - No title bar - unified liquid glass background
  - Closes instantly on ESC key
  - Floats above other windows (floating level)
  - No window controls (close/minimize/zoom)
  - Transparent background with vibrancy

### Visual Design

#### Color Palette
- **Background**: System liquid glass material (`.hudWindow` with `.dark` blending)
- **Text Primary**: #FFFFFF (white) at 100% opacity
- **Text Secondary**: #FFFFFF at 70% opacity (for section headers)
- **Section Divider**: #FFFFFF at 30% opacity
- **Selection**: #0A84FF at 40% opacity (macOS blue)
- **Context Menu**: Standard macOS menu with liquid glass styling

#### Typography
- **Font Family**: SF Mono (Monospace) - system monospace font
- **Body Text**: 14pt, regular weight
- **Section Header**: 14pt, bold weight (auto-detected from first line after `/s`)

#### Spacing System (8pt grid)
- **Window Padding**: 24pt all sides
- **Line Spacing**: 8pt between lines
- **Section Divider**: 16pt vertical padding, 1pt height line
- **Cursor Position**: 8pt from left edge

### Views & Components

1. **Main Window (BorderlessWindow)**
   - NSPanel subclass with `.nonactivatingPanel` style
   - Liquid glass background via NSVisualEffectView
   - Centers on screen on hotkey activation

2. **Scrollable Text View (ScrollPadTextView)**
   - NSTextView subclass for endless scrolling
   - Custom drawing for section dividers
   - Monospace font throughout
   - Auto-save on every keystroke
   - Support for `/s` section command
   - Right-click context menu

3. **Section Divider**
   - Horizontal line with subtle gradient fade
   - Drawn between sections
   - Invisible but detectable for selection

## 3. Functionality Specification

### Core Features

1. **Hotkey Activation** (Priority: Critical)
   - Global hotkey: ⌘⇧Space (Command+Shift+Space)
   - Toggles window visibility
   - If hidden, shows centered on main screen
   - If visible, hides window

2. **Instant Close** (Priority: Critical)
   - Press ESC to instantly hide window
   - No confirmation dialogs
   - Saves all content before closing

3. **Auto-Save** (Priority: Critical)
   - Saves content to file on every keystroke (debounced 500ms)
   - Storage location: `~/Library/Application Support/ScrollPad/notes.txt`
   - Creates directory if needed

4. **Endless Scroll** (Priority: Critical)
   - Single continuous text view
   - No page breaks or sections by default
   - Smooth scrolling with no boundaries

5. **Section Command** (Priority: High)
   - Type `/s` at beginning of a new line to create section
   - Renders as: newline + divider line + newline
   - Section title inferred from first line after divider

6. **Section Divider Rendering** (Priority: High)
   - Horizontal line with 30% white opacity
   - Appears between sections
   - Stored as special marker in text (e.g., `---SECTION---`)

7. **Send to Apple Notes** (Priority: High)
   - Right-click on any section to show context menu
   - "Send to Notes" option
   - Creates new note in Apple Notes
   - Note title: First line of section (or "Untitled" if empty)
   - Note body: Rest of section content

### User Interactions

- **Typing**: Immediate text input with auto-save
- **Scrolling**: Native smooth scrolling
- **Right-click**: Context menu for section actions
- **Hotkey**: Toggle window visibility
- **ESC**: Hide window instantly

### Data Handling

- **Storage**: Plain text file at `~/Library/Application Support/ScrollPad/notes.txt`
- **Section Markers**: Stored as `---SECTION---` in file (not visible in UI)
- **Loading**: Load content on app launch
- **Saving**: Auto-save with 500ms debounce

### Architecture Pattern

- **MVC** with AppKit
- **AppDelegate**: Application lifecycle, hotkey registration
- **BorderlessWindow**: Custom NSPanel for liquid glass
- **ScrollPadViewController**: Main view controller
- **ScrollPadTextView**: Custom NSTextView
- **NoteStorage**: Auto-save manager

### Edge Cases

- Empty document: Show placeholder text "Start typing..."
- No sections: No dividers rendered
- Very long text: Efficient scrolling with lazy rendering
- Apple Notes unavailable: Show alert on failure
- File permission error: Silent retry, log error

## 4. Technical Specification

### Required Dependencies

- None (pure AppKit implementation)

### UI Framework

- **AppKit** (not SwiftUI for full liquid glass control)

### Third-Party Libraries

- None required

### Asset Requirements

- **App Icon**: Not required for MVP (use default)
- **Fonts**: System fonts only (SF Mono)

### Key Implementation Details

1. **Liquid Glass Effect**
   ```swift
   let visualEffect = NSVisualEffectView()
   visualEffect.material = .hudWindow
   visualEffect.blendingMode = .behindWindow
   visualEffect.state = .active
   ```

2. **Global Hotkey**
   - Use Carbon API or MASShortcut-style approach
   - Register ⌘⇧Space globally

3. **Borderless Window**
   - NSPanel with `.borderless` style mask
   - `.nonactivatingPanel` to not steal focus
   - `.hudWindow` for liquid glass

4. **Text Storage for Sections**
   - Custom NSTextStorage to handle section markers
   - Draw dividers in `draw(_:)` override

5. **Apple Notes Integration**
   - Use AppleScript via NSAppleScript
   - Create note with title and body
