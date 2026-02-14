import AppKit
import Carbon.HIToolbox

class SettingsWindowController: NSWindowController, NSTextFieldDelegate {
    
    static let shared = SettingsWindowController()
    
    private var hotkeyField: NSTextField!
    private var storagePathLabel: NSTextField!
    private var browseButton: NSButton!
    
    private var currentModifiers: UInt32 = 0
    private var currentKeyCode: UInt32 = 0
    private var isRecordingHotkey = false
    
    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "ScrollPad Settings"
        window.center()
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
        
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        contentView.wantsLayer = true
        
        // Title label
        let titleLabel = NSTextField(labelWithString: "Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Hotkey Section
        let hotkeyTitleLabel = NSTextField(labelWithString: "Toggle Hotkey:")
        hotkeyTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        hotkeyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hotkeyTitleLabel)
        
        hotkeyField = NSTextField()
        hotkeyField.placeholderString = "Click to record hotkey"
        hotkeyField.isEditable = false
        hotkeyField.isSelectable = false
        hotkeyField.isBordered = true
        hotkeyField.bezelStyle = .roundedBezel
        hotkeyField.alignment = .center
        hotkeyField.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        hotkeyField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add click gesture to record hotkey
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(hotkeyFieldClicked))
        hotkeyField.addGestureRecognizer(clickGesture)
        
        contentView.addSubview(hotkeyField)
        
        let hotkeyHint = NSTextField(labelWithString: "Click field, then press your desired key combination")
        hotkeyHint.font = NSFont.systemFont(ofSize: 11)
        hotkeyHint.textColor = .secondaryLabelColor
        hotkeyHint.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hotkeyHint)
        
        // Storage Path Section
        let storageTitleLabel = NSTextField(labelWithString: "Notes Folder:")
        storageTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        storageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(storageTitleLabel)
        
        storagePathLabel = NSTextField(labelWithString: "")
        storagePathLabel.isEditable = false
        storagePathLabel.isSelectable = true
        storagePathLabel.isBordered = true
        storagePathLabel.bezelStyle = .roundedBezel
        storagePathLabel.lineBreakMode = .byTruncatingMiddle
        storagePathLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        storagePathLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(storagePathLabel)
        
        browseButton = NSButton(title: "Choose...", target: self, action: #selector(browseClicked))
        browseButton.bezelStyle = .rounded
        browseButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(browseButton)
        
        let storageHint = NSTextField(labelWithString: "The app will create scrollpad.txt in this folder")
        storageHint.font = NSFont.systemFont(ofSize: 11)
        storageHint.textColor = .secondaryLabelColor
        storageHint.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(storageHint)
        
        // Buttons
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetClicked))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resetButton)
        
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        // Layout
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            hotkeyTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            hotkeyTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            hotkeyField.topAnchor.constraint(equalTo: hotkeyTitleLabel.bottomAnchor, constant: 8),
            hotkeyField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            hotkeyField.widthAnchor.constraint(equalToConstant: 200),
            hotkeyField.heightAnchor.constraint(equalToConstant: 28),
            
            hotkeyHint.topAnchor.constraint(equalTo: hotkeyField.bottomAnchor, constant: 4),
            hotkeyHint.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            storageTitleLabel.topAnchor.constraint(equalTo: hotkeyHint.bottomAnchor, constant: 20),
            storageTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            storagePathLabel.topAnchor.constraint(equalTo: storageTitleLabel.bottomAnchor, constant: 8),
            storagePathLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            storagePathLabel.trailingAnchor.constraint(equalTo: browseButton.leadingAnchor, constant: -8),
            storagePathLabel.heightAnchor.constraint(equalToConstant: 24),
            
            browseButton.centerYAnchor.constraint(equalTo: storagePathLabel.centerYAnchor),
            browseButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            browseButton.widthAnchor.constraint(equalToConstant: 80),
            
            storageHint.topAnchor.constraint(equalTo: storagePathLabel.bottomAnchor, constant: 4),
            storageHint.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            resetButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            resetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
        ])
    }
    
    private func loadSettings() {
        currentModifiers = Settings.shared.hotkeyModifiers
        currentKeyCode = Settings.shared.hotkeyKeyCode
        updateHotkeyField()
        
        let folderPath = Settings.shared.storageFolder
        storagePathLabel.stringValue = folderPath
    }
    
    private func updateHotkeyField() {
        let modifierString = modifierFlagsToString(currentModifiers)
        let keyString = keyCodeToString(currentKeyCode)
        
        if modifierString.isEmpty {
            hotkeyField.stringValue = keyString
        } else {
            hotkeyField.stringValue = "\(modifierString)+\(keyString)"
        }
    }
    
    private func modifierFlagsToString(_ flags: UInt32) -> String {
        var parts: [String] = []
        
        if flags & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if flags & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if flags & UInt32(optionKey) != 0 { parts.append("⌥") }
        if flags & UInt32(controlKey) != 0 { parts.append("⌃") }
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Esc"
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return "?"
        }
    }
    
    @objc private func hotkeyFieldClicked() {
        isRecordingHotkey = true
        hotkeyField.stringValue = "Press hotkey..."
        hotkeyField.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.2)

        // Make window first responder to capture key events
        window?.makeFirstResponder(window)
    }
    
    @objc private func browseClicked() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        // Start at current folder
        let currentFolder = Settings.shared.storageFolder
        if !currentFolder.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: currentFolder)
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            panel.directoryURL = appSupport.appendingPathComponent("ScrollPad")
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            storagePathLabel.stringValue = url.path
        }
    }
    
    @objc private func resetClicked() {
        Settings.shared.resetToDefaults()
        loadSettings()
    }
    
    @objc private func saveClicked() {
        Settings.shared.hotkeyModifiers = currentModifiers
        Settings.shared.hotkeyKeyCode = currentKeyCode
        Settings.shared.storageFolder = storagePathLabel.stringValue
        
        window?.close()
    }
    
    
    // Prevent text field from becoming first responder
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        return true // Prevent any text input
    }
}
