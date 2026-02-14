import AppKit
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {

    private var mainWindowController: MainWindowController?
    private var statusItem: NSStatusItem?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Set to true while SettingsView is recording a hotkey, to suppress the global hotkey
    static var suppressHotkey = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")

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
        removeEventTap()
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

    // MARK: - Global Hotkey (CGEvent tap)

    private func setupGlobalHotkey() {
        removeEventTap()

        let targetKeyCode = Settings.shared.hotkeyKeyCode
        let targetCarbonModifiers = Settings.shared.hotkeyModifiers

        print("Setting up CGEvent tap: keyCode=\(targetKeyCode), modifiers=\(targetCarbonModifiers)")

        // Store hotkey config in a context struct so the C callback can access it
        let context = HotkeyContext(keyCode: targetKeyCode, modifiers: targetCarbonModifiers)
        let contextPtr = UnsafeMutablePointer<HotkeyContext>.allocate(capacity: 1)
        contextPtr.initialize(to: context)

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // If the tap is disabled by the system, re-enable it
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let refcon = refcon {
                        let ctx = refcon.assumingMemoryBound(to: HotkeyContext.self).pointee
                        // Post notification to re-enable on main thread
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .reEnableEventTap, object: nil)
                        }
                    }
                    return Unmanaged.passRetained(event)
                }

                guard type == .keyDown else {
                    return Unmanaged.passRetained(event)
                }

                guard !AppDelegate.suppressHotkey else {
                    return Unmanaged.passRetained(event)
                }

                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }

                let ctx = refcon.assumingMemoryBound(to: HotkeyContext.self).pointee
                let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))
                let flags = event.flags

                guard keyCode == ctx.keyCode else {
                    return Unmanaged.passRetained(event)
                }

                // Check modifiers match
                var targetFlags = CGEventFlags()
                if ctx.modifiers & UInt32(cmdKey) != 0 { targetFlags.insert(.maskCommand) }
                if ctx.modifiers & UInt32(shiftKey) != 0 { targetFlags.insert(.maskShift) }
                if ctx.modifiers & UInt32(optionKey) != 0 { targetFlags.insert(.maskAlternate) }
                if ctx.modifiers & UInt32(controlKey) != 0 { targetFlags.insert(.maskControl) }

                let significantMask: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
                let eventMods = flags.intersection(significantMask)

                if eventMods == targetFlags {
                    DispatchQueue.main.async {
                        (NSApp.delegate as? AppDelegate)?.toggleMainWindow()
                    }
                    // Return nil to consume the event (prevent the beep)
                    return nil
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: contextPtr
        ) else {
            print("Failed to create CGEvent tap - accessibility permission may be needed")
            contextPtr.deallocate()
            return
        }

        eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Listen for re-enable requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reEnableEventTap),
            name: .reEnableEventTap,
            object: nil
        )

        print("CGEvent tap installed and enabled")
    }

    @objc private func reEnableEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
            print("Re-enabled event tap")
        }
    }

    private func removeEventTap() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        NotificationCenter.default.removeObserver(self, name: .reEnableEventTap, object: nil)
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

// MARK: - Supporting types

private struct HotkeyContext {
    let keyCode: UInt32
    let modifiers: UInt32
}

extension Notification.Name {
    static let reEnableEventTap = Notification.Name("reEnableEventTap")
}
