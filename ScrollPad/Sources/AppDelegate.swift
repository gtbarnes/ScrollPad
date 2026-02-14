import AppKit
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var mainWindowController: MainWindowController?
    private var statusItem: NSStatusItem?
    private var eventHotKey: EventHotKeyRef?
    
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
        unregisterHotkey()
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
    
    // MARK: - Global Hotkey
    
    private func setupGlobalHotkey() {
        unregisterHotkey()
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5343524C) // "SCRL"
        hotKeyID.id = 1
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                
                if hotKeyID.id == 1 {
                    DispatchQueue.main.async {
                        print("Hotkey pressed")
                        (NSApp.delegate as? AppDelegate)?.toggleMainWindow()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        
        if status == noErr {
            let modifiers = Settings.shared.hotkeyModifiers
            let keyCode = Settings.shared.hotkeyKeyCode
            
            let registerStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &eventHotKey)
            if registerStatus != noErr {
                print("Failed to register hotkey: \(registerStatus)")
            } else {
                print("Hotkey registered successfully")
            }
        }
    }
    
    private func unregisterHotkey() {
        if let hotKey = eventHotKey {
            UnregisterEventHotKey(hotKey)
            eventHotKey = nil
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
