import AppKit
import Carbon.HIToolbox

protocol SettingsViewDelegate: AnyObject {
    func hideSettings()
}

class SettingsView: NSView {

    weak var delegate: SettingsViewDelegate?

    private var hotkeyField: NSTextField!
    private var storagePathLabel: NSTextField!
    private var isRecordingHotkey = false
    private var currentModifiers: UInt32 = 0
    private var currentKeyCode: UInt32 = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadSettings()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadSettings()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        layer?.cornerRadius = 12

        // Title with terminal styling
        let titleLabel = NSTextField(labelWithString: "> ScrollPad Settings")
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Hotkey Section
        let hotkeyTitleLabel = NSTextField(labelWithString: "$ Toggle Hotkey:")
        hotkeyTitleLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        hotkeyTitleLabel.textColor = .white
        hotkeyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hotkeyTitleLabel)

        hotkeyField = NSTextField()
        hotkeyField.placeholderString = "Click to record hotkey"
        hotkeyField.isEditable = false
        hotkeyField.isSelectable = false
        hotkeyField.isBordered = true
        hotkeyField.bezelStyle = .roundedBezel
        hotkeyField.alignment = .center
        hotkeyField.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        hotkeyField.textColor = .white
        hotkeyField.backgroundColor = NSColor(white: 0.15, alpha: 1.0)
        hotkeyField.translatesAutoresizingMaskIntoConstraints = false

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(hotkeyFieldClicked))
        hotkeyField.addGestureRecognizer(clickGesture)
        addSubview(hotkeyField)

        let hotkeyHint = NSTextField(labelWithString: "# Click field, then press your desired key combination")
        hotkeyHint.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        hotkeyHint.textColor = NSColor(white: 0.6, alpha: 1.0)
        hotkeyHint.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hotkeyHint)

        // Storage Path Section
        let storageTitleLabel = NSTextField(labelWithString: "$ Notes Folder:")
        storageTitleLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        storageTitleLabel.textColor = .white
        storageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(storageTitleLabel)

        storagePathLabel = NSTextField(labelWithString: "")
        storagePathLabel.isEditable = false
        storagePathLabel.isSelectable = true
        storagePathLabel.isBordered = true
        storagePathLabel.bezelStyle = .roundedBezel
        storagePathLabel.lineBreakMode = .byTruncatingMiddle
        storagePathLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        storagePathLabel.textColor = .white
        storagePathLabel.backgroundColor = NSColor(white: 0.15, alpha: 1.0)
        storagePathLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(storagePathLabel)

        let browseButton = createTerminalButton(title: "[Choose...]", action: #selector(browseClicked))
        addSubview(browseButton)

        let storageHint = NSTextField(labelWithString: "# The app will create scrollpad.txt in this folder")
        storageHint.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        storageHint.textColor = NSColor(white: 0.6, alpha: 1.0)
        storageHint.translatesAutoresizingMaskIntoConstraints = false
        addSubview(storageHint)

        // Buttons
        let resetButton = createTerminalButton(title: "[Reset to Defaults]", action: #selector(resetClicked))
        addSubview(resetButton)

        let saveButton = createTerminalButton(title: "[Save & Close]", action: #selector(saveClicked))
        addSubview(saveButton)

        let cancelButton = createTerminalButton(title: "[Cancel]", action: #selector(cancelClicked))
        addSubview(cancelButton)

        // Layout
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            hotkeyTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            hotkeyTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            hotkeyField.topAnchor.constraint(equalTo: hotkeyTitleLabel.bottomAnchor, constant: 8),
            hotkeyField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            hotkeyField.widthAnchor.constraint(equalToConstant: 250),
            hotkeyField.heightAnchor.constraint(equalToConstant: 32),

            hotkeyHint.topAnchor.constraint(equalTo: hotkeyField.bottomAnchor, constant: 6),
            hotkeyHint.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            storageTitleLabel.topAnchor.constraint(equalTo: hotkeyHint.bottomAnchor, constant: 24),
            storageTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            storagePathLabel.topAnchor.constraint(equalTo: storageTitleLabel.bottomAnchor, constant: 8),
            storagePathLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            storagePathLabel.trailingAnchor.constraint(equalTo: browseButton.leadingAnchor, constant: -12),
            storagePathLabel.heightAnchor.constraint(equalToConstant: 28),

            browseButton.centerYAnchor.constraint(equalTo: storagePathLabel.centerYAnchor),
            browseButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            storageHint.topAnchor.constraint(equalTo: storagePathLabel.bottomAnchor, constant: 6),
            storageHint.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            resetButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            resetButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            cancelButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -12),

            saveButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
    }

    private func createTerminalButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func loadSettings() {
        currentModifiers = Settings.shared.hotkeyModifiers
        currentKeyCode = Settings.shared.hotkeyKeyCode
        updateHotkeyField()

        storagePathLabel.stringValue = Settings.shared.storageFolder
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
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_PageUp: return "Page Up"
        case kVK_PageDown: return "Page Down"
        case kVK_Home: return "Home"
        case kVK_End: return "End"
        case kVK_ForwardDelete: return "Fwd Delete"
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

    private var localEventMonitor: Any?

    @objc private func hotkeyFieldClicked() {
        isRecordingHotkey = true
        hotkeyField.stringValue = "Waiting for input..."
        hotkeyField.backgroundColor = NSColor(white: 0.3, alpha: 1.0)

        // Install a local event monitor to intercept key events before the responder chain.
        // This is necessary because Cmd+Arrow and other system key combos get consumed
        // by AppKit before reaching keyDown().
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isRecordingHotkey else { return event }
            self.handleRecordedKeyEvent(event)
            return nil // Consume the event
        }
    }

    private func stopRecording() {
        isRecordingHotkey = false
        hotkeyField.backgroundColor = NSColor(white: 0.15, alpha: 1.0)
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    private func handleRecordedKeyEvent(_ event: NSEvent) {
        // ESC cancels recording
        if event.keyCode == 53 {
            stopRecording()
            updateHotkeyField()
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let carbonModifiers = convertModifiersToCarbon(modifiers)
        let keyCode = UInt32(event.keyCode)

        // Allow arrow keys and special keys without modifier requirement
        let isArrowKey = [kVK_UpArrow, kVK_DownArrow, kVK_LeftArrow, kVK_RightArrow].contains(Int(keyCode))
        let isSpecialKey = [kVK_PageUp, kVK_PageDown, kVK_Home, kVK_End].contains(Int(keyCode))

        if carbonModifiers == 0 && !isArrowKey && !isSpecialKey {
            hotkeyField.stringValue = "Need modifier (⌘⇧⌥⌃)"
            hotkeyField.backgroundColor = NSColor(white: 0.4, alpha: 1.0)
            return
        }

        currentModifiers = carbonModifiers
        currentKeyCode = keyCode
        stopRecording()
        updateHotkeyField()
    }

    @objc private func browseClicked() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        let currentFolder = Settings.shared.storageFolder
        if !currentFolder.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: currentFolder)
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
        stopRecording()
        Settings.shared.hotkeyModifiers = currentModifiers
        Settings.shared.hotkeyKeyCode = currentKeyCode
        NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)

        Settings.shared.storageFolder = storagePathLabel.stringValue

        delegate?.hideSettings()
    }

    @objc private func cancelClicked() {
        stopRecording()
        loadSettings()
        delegate?.hideSettings()
    }

    override func removeFromSuperview() {
        stopRecording()
        super.removeFromSuperview()
    }

    override func keyDown(with event: NSEvent) {
        // When recording, the local event monitor handles all key events.
        // This is only reached for non-recording state.
        if event.keyCode == 53 { // ESC key
            cancelClicked()
        } else {
            super.keyDown(with: event)
        }
    }

    private func convertModifiersToCarbon(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbonModifiers: UInt32 = 0

        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }

        return carbonModifiers
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}
