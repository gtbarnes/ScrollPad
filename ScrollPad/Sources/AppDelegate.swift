import AppKit
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {

    private var mainWindowController: MainWindowController?
    private var statusItem: NSStatusItem?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    /// Set to true while SettingsView is recording a hotkey, to suppress the global hotkey
    static var suppressHotkey = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")

        // Check for accessibility permissions
        checkAccessibilityPermissions()

        setupStatusItem()
        setupGlobalHotkey()
        setupSettingsObservers()

        // Show window on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showMainWindow()
        }
    }

    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Accessibility access not granted - hotkeys may not work until enabled")

            // Show alert to user
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "ScrollPad needs Accessibility permissions to register global hotkeys. Please grant permission in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Later")

                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        removeHotkeyMonitors()
    }

    // MARK: - Status Item (Menu Bar)

    private func setupStatusItem() {
        print("Setting up status item")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "ScrollPad")
            print("Status item button created")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show ScrollPad", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
        print("Status item menu set")
    }

    @objc private func openSettings() {
        showMainWindow()
        if let viewController = mainWindowController?.window?.contentViewController as? ScrollPadViewController {
            viewController.showSettings()
        }
    }

    // MARK: - Global Hotkey (NSEvent monitors)

    private func setupGlobalHotkey() {
        removeHotkeyMonitors()

        let targetKeyCode = UInt16(Settings.shared.hotkeyKeyCode)
        let targetModifiers = carbonToCocoaModifiers(Settings.shared.hotkeyModifiers)

        print("Setting up hotkey monitors: keyCode=\(targetKeyCode), modifiers=\(Settings.shared.hotkeyModifiers)")

        // Global monitor: fires when another app is active
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.eventMatchesHotkey(event, keyCode: targetKeyCode, modifiers: targetModifiers) == true {
                print("Global hotkey fired")
                DispatchQueue.main.async {
                    self?.toggleMainWindow()
                }
            }
        }

        // Local monitor: fires when this app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.eventMatchesHotkey(event, keyCode: targetKeyCode, modifiers: targetModifiers) == true {
                print("Local hotkey fired")
                DispatchQueue.main.async {
                    self?.toggleMainWindow()
                }
                return nil // Consume the event
            }
            return event
        }

        print("Hotkey monitors installed")
    }

    private func eventMatchesHotkey(_ event: NSEvent, keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        guard !AppDelegate.suppressHotkey else { return false }
        guard event.keyCode == keyCode else { return false }
        // Compare only the modifier keys we care about (cmd, shift, option, control)
        let significantFlags: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        let eventMods = event.modifierFlags.intersection(significantFlags)
        let targetMods = modifiers.intersection(significantFlags)
        return eventMods == targetMods
    }

    private func carbonToCocoaModifiers(_ carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        return flags
    }

    private func removeHotkeyMonitors() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    // MARK: - Settings Observers

    private func setupSettingsObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeySettingsChanged),
            name: .hotkeySettingsChanged,
            object: nil
        )
    }

    @objc private func hotkeySettingsChanged() {
        setupGlobalHotkey()
    }

    // MARK: - Window Management

    @objc func showMainWindow() {
        print("Showing main window")

        if mainWindowController == nil {
            print("Creating new window controller")
            mainWindowController = MainWindowController()
        }

        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.center()
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        mainWindowController?.window?.orderFrontRegardless()

        NSApp.activate(ignoringOtherApps: true)
        print("Window should be visible now")
    }

    @objc func hideMainWindow() {
        mainWindowController?.close()
    }

    @objc func toggleMainWindow() {
        print("Toggling main window")

        if let window = mainWindowController?.window {
            if window.isVisible {
                print("Hiding window")
                window.orderOut(nil)
            } else {
                print("Showing window")
                showMainWindow()
            }
        } else {
            print("Creating and showing window")
            showMainWindow()
        }
    }
}
