# ScrollPad Development Log

## Date: February 14, 2026

## Project Overview
ScrollPad is a macOS menu bar note-taking application with a terminal-themed UI, global hotkey support, and automatic file saving.

---

## Issues Fixed

### 1. Hotkey Capture Not Working
**Problem:** The settings window couldn't capture keyboard shortcuts for the global hotkey.

**Solution:**
- Fixed the hotkey capture mechanism in `SettingsWindowController.swift`
- Changed window's first responder handling to properly capture keyboard events
- Added visual feedback (background color changes) during recording
- Properly converted NSEvent modifiers to Carbon framework format for hotkey registration
- **Note:** Arrow keys (↑ ↓ ← →) and special keys now supported with or without modifiers

**Files Modified:**
- `ScrollPad/Sources/SettingsWindowController.swift`
- `ScrollPad/Sources/SettingsView.swift`

### 2. Text File Auto-Saving Not Working
**Problem:** Text changes weren't being saved to disk automatically.

**Solution:**
- Made `ScrollPadViewController` conform to `NSTextViewDelegate`
- Set the text view's delegate properly in `setupTextView()`
- Implemented `textDidChange(_:)` to trigger save on every text change
- The `NoteStorage` class now properly saves with a 0.5 second debounce timer

**Files Modified:**
- `ScrollPad/Sources/ScrollPadViewController.swift`

### 3. Settings Window Redesign
**Problem:** Settings opened in a separate window; user wanted in-window settings.

**Solution:**
- Created new `SettingsView.swift` - a custom NSView that appears as an overlay
- Settings now show/hide within the main window
- Text view is hidden when settings are shown
- Press ESC or click Cancel to return to text view
- Updated all menu items and shortcuts to use inline settings

**Files Created:**
- `ScrollPad/Sources/SettingsView.swift`

**Files Modified:**
- `ScrollPad/Sources/ScrollPadViewController.swift`
- `ScrollPad/Sources/ScrollPadTextView.swift`
- `ScrollPad/Sources/AppDelegate.swift`

### 4. UI Theme Changes
**Problem:** User wanted clean terminal theme with white text only (no green).

**Solution Applied:**
- **Window:** Black background (92% opacity), white border (20% opacity), 12px rounded corners
- **Text:** White text with white cursor
- **Section Dividers:** White lines (30% opacity)
- **Settings Panel:** Black background, white text, monospaced fonts
- **Terminal Styling:** Unix-style prompts (`>`, `$`, `#`) in settings UI

**Files Modified:**
- `ScrollPad/Sources/ScrollPadViewController.swift`
- `ScrollPad/Sources/ScrollPadTextView.swift`
- `ScrollPad/Sources/SettingsView.swift`

### 5. Custom App Icon
**Problem:** No app icon.

**Solution:**
- Created terminal-themed icon with Python/PIL
- Black rounded rectangle background
- Terminal green `>_` prompt symbol
- Generated at all required sizes (16px to 1024px)
- Compiled into `AppIcon.icns` using iconutil
- Added to Xcode project and Info.plist

**Files Created:**
- `ScrollPad/Resources/AppIcon.icns`

**Files Modified:**
- `ScrollPad/Resources/Info.plist`
- `ScrollPad.xcodeproj/project.pbxproj`

### 6. Accessibility Permissions
**Problem:** Global hotkeys require macOS Accessibility permissions but app didn't request them.

**Solution:**
- Added accessibility permission check on app launch
- Shows alert dialog if permissions not granted
- Offers to open System Settings directly to Accessibility panel
- User must grant permission for global hotkey registration to work

**Files Modified:**
- `ScrollPad/Sources/AppDelegate.swift`

---

## Current File Structure

```
ScrollPad/
├── ScrollPad/
│   ├── Sources/
│   │   ├── main.swift
│   │   ├── AppDelegate.swift
│   │   ├── Settings.swift
│   │   ├── NoteStorage.swift
│   │   ├── MainWindowController.swift
│   │   ├── ScrollPadViewController.swift
│   │   ├── ScrollPadTextView.swift
│   │   ├── SettingsView.swift (NEW)
│   │   └── SettingsWindowController.swift (kept for compatibility)
│   └── Resources/
│       ├── Info.plist
│       ├── ScrollPad.entitlements
│       └── AppIcon.icns (NEW)
├── ScrollPad.xcodeproj/
├── ScrollPad.app (built release version)
└── DEVELOPMENT_LOG.md (this file)
```

---

## Key Features

### Text Management
- Auto-save with 0.5 second debounce
- Section markers with `---` or `/s` command
- Visual section dividers
- Monospaced font (SF Mono or Menlo)
- Saves to `scrollpad.txt` in configurable folder

### Window Behavior
- Borderless floating window
- ESC key to hide
- Global hotkey to toggle (default: Cmd+Shift+Space)
- Menu bar icon with status menu
- Terminal-styled dark theme

### Settings
- In-window overlay settings panel
- Hotkey capture with visual feedback
- Storage folder selection
- Support for arrow keys and special keys in hotkeys
- Reset to defaults option

### Apple Notes Integration
- Right-click menu: "Send to Notes"
- Sends current section or selection to Apple Notes app
- Uses AppleScript for integration

---

## Build Configuration

### Release Build
- Configuration: Release
- Optimized for distribution
- Located at: `/Users/gary/Programming/ScrollPad/ScrollPad.app`

### Build Warnings (non-critical)
- `NoteStorage.swift:122` - Unused variable `currentLocation`
- `ScrollPadTextView.swift:267` - Variable `lineRect` should be `let` constant
- AppIntents metadata processor warning (safe to ignore)

---

## Settings Storage

Uses `UserDefaults` for persistence:
- `hotkeyModifiers`: Carbon modifier flags (UInt32)
- `hotkeyKeyCode`: Carbon key code (UInt32)
- `storageFolder`: Path to folder containing `scrollpad.txt`

Default values:
- Hotkey: Cmd+Shift+Space
- Storage: `~/Library/Application Support/ScrollPad/`

---

## Accessibility Requirements

**IMPORTANT:** ScrollPad requires Accessibility permissions to function properly.

On first launch:
1. App will show permission dialog
2. Click "Open System Settings"
3. Grant permission in: System Settings > Privacy & Security > Accessibility
4. Restart app if needed
5. Hotkey should now work

Without accessibility permission, global hotkey registration will fail silently.

---

## Hotkey System

### Implementation
- Uses Carbon Event Manager API
- Registers global hotkey via `RegisterEventHotKey`
- Event handler toggles main window visibility
- Hotkey settings stored in UserDefaults

### Supported Keys
- Letters A-Z
- Numbers 0-9
- Function keys F1-F12
- Arrow keys (↑ ↓ ← →)
- Special keys: Space, Return, Tab, Delete, Esc
- Page Up/Down, Home, End, Forward Delete

### Modifiers Required
- Regular keys require at least one modifier (⌘⇧⌥⌃)
- Arrow keys and special keys can be used alone or with modifiers

---

## Known Issues / Future Improvements

### Current Limitations
1. Accessibility permission must be granted manually
2. No sandboxing (required for global hotkey access)
3. No code signing in current build
4. SettingsWindowController.swift kept but unused (can be removed)

### Potential Enhancements
1. iCloud sync support
2. Multiple note files/tabs
3. Markdown preview mode
4. Syntax highlighting
5. Search functionality
6. Export options (PDF, HTML, etc.)
7. Custom themes/color schemes
8. Window position persistence

---

## Testing Checklist

- [x] App launches successfully
- [x] Icon appears in menu bar
- [x] Window shows on launch
- [x] Text editing works
- [x] Auto-save functions (check scrollpad.txt)
- [x] ESC key hides window
- [x] Global hotkey toggles window (requires accessibility permission)
- [x] Settings panel opens and closes
- [x] Hotkey capture works with arrow keys
- [x] Storage folder can be changed
- [x] Section markers work (/s command)
- [x] Section dividers render
- [x] Send to Notes works
- [x] Accessibility permission prompt shows on first launch

---

## Color Scheme (Final)

- **Background:** Black (#000000 @ 92% opacity)
- **Border:** White (#FFFFFF @ 20% opacity)
- **Text:** White (#FFFFFF)
- **Cursor:** White (#FFFFFF)
- **Section Dividers:** White (#FFFFFF @ 30% opacity)
- **Settings Hints:** Gray (#999999)

---

## Dependencies

- macOS 15.0+ (deployment target)
- Swift 5
- AppKit framework
- Carbon framework (for global hotkeys)
- Accessibility framework (for permissions)

---

## Build Instructions

```bash
# Clean build
xcodebuild -project ScrollPad.xcodeproj -scheme ScrollPad -configuration Release clean build

# Built app location
/Users/gary/Library/Developer/Xcode/DerivedData/ScrollPad-*/Build/Products/Release/ScrollPad.app

# Copy to project directory
cp -R [DerivedData path] /Users/gary/Programming/ScrollPad/ScrollPad.app
```

---

## Code Quality Notes

### Good Practices
- Debounced auto-save prevents excessive disk writes
- Proper delegate patterns used throughout
- Settings singleton with notification system
- Clear separation of concerns (MVC pattern)

### Areas for Improvement
- Remove unused SettingsWindowController
- Fix compiler warnings (unused variables)
- Add error handling for file operations
- Add unit tests for NoteStorage
- Consider SwiftUI migration for settings

---

## Contact & Support

This app was developed with assistance from Claude (Anthropic).
For issues or questions, refer to the source code or contact the developer.

---

**End of Development Log**
