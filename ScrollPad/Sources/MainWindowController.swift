import AppKit

class MainWindowController: NSWindowController {
    
    convenience init() {
        let window = BorderlessPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear.withAlphaComponent(0.01) // Nearly transparent to be clickable
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        
        // Allow resizing
        window.minSize = NSSize(width: 300, height: 200)
        window.maxSize = NSSize(width: 2000, height: 2000)
        
        // Don't become key automatically
        window.becomesKeyOnlyIfNeeded = false
        
        self.init(window: window)
        
        let viewController = ScrollPadViewController()
        viewController.setWindowController(self)
        window.contentViewController = viewController
    }
    
    override func showWindow(_ sender: Any?) {
        // Position window at center of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = window?.frame.size ?? NSSize(width: 600, height: 500)
            let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
            let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        super.showWindow(sender)
        
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure the window is key
        window?.makeFirstResponder(window?.contentViewController)
    }
}

// Custom borderless panel with liquid glass
class BorderlessPanel: NSPanel {
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            orderOut(nil)
        } else {
            super.keyDown(with: event)
        }
    }
    
    // Accept ESC to close
    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}
