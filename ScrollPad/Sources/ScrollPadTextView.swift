import AppKit

class ScrollPadTextView: NSTextView {
    
    weak var noteStorage: NoteStorage?
    
    // Reference to the window for ESC handling
    weak var windowController: MainWindowController?
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        allowsUndo = true
        menu = createContextMenu()
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        return createContextMenu()
    }
    
    // Handle ESC key to close window
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            window?.close()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        window?.close()
    }
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Send to Notes
        let sendToNotesItem = NSMenuItem(title: "Send to Notes", action: #selector(sendSelectionToNotes), keyEquivalent: "")
        sendToNotesItem.target = self
        menu.addItem(sendToNotesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Cut, Copy, Paste
        let cutItem = NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(cutItem)
        
        let copyItem = NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(copyItem)
        
        let pasteItem = NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(pasteItem)
        
        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(selectAllItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit ScrollPad", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func openSettings() {
        if let viewController = window?.contentViewController as? ScrollPadViewController {
            viewController.showSettings()
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Section Detection
    
    private func getCurrentSectionRange() -> NSRange? {
        guard let storage = noteStorage else { return nil }
        
        let cursorLocation = selectedRange().location
        if cursorLocation == NSNotFound || cursorLocation == 0 { return nil }
        
        let fullText = string
        let sections = storage.getSections()
        
        for section in sections {
            let sectionStart = section.range.location
            let sectionEnd = section.range.location + section.range.length
            
            if cursorLocation >= sectionStart && cursorLocation <= sectionEnd {
                return section.range
            }
        }
        
        return NSRange(location: 0, length: fullText.count)
    }
    
    private func getSectionTitle(for range: NSRange) -> String {
        let text = (string as NSString)
        
        var lineEnd = 0
        var contentsEnd = 0
        text.getLineStart(nil, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: range.location, length: 0))
        
        if lineEnd > range.location {
            let firstLine = text.substring(with: NSRange(location: range.location, length: min(lineEnd - range.location, range.length)))
            let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                return "Untitled"
            }
            return trimmed
        }
        
        return "Untitled"
    }
    
    private func getSectionBody(for range: NSRange) -> String {
        let text = (string as NSString)
        
        var lineEnd = 0
        var contentsEnd = 0
        text.getLineStart(nil, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: range.location, length: 0))
        
        if lineEnd >= range.location + range.length {
            return ""
        }
        
        let bodyStart = min(lineEnd, range.location + range.length - 1)
        let body = text.substring(with: NSRange(location: bodyStart, length: range.location + range.length - bodyStart))
        
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @objc private func sendSelectionToNotes() {
        var rangeToSend: NSRange
        
        if selectedRange().length > 0 {
            rangeToSend = selectedRange()
        } else {
            if let sectionRange = getCurrentSectionRange() {
                rangeToSend = sectionRange
            } else {
                rangeToSend = NSRange(location: 0, length: string.count)
            }
        }
        
        let title = getSectionTitle(for: rangeToSend)
        let body = getSectionBody(for: rangeToSend)
        
        sendToAppleNotes(title: title, body: body)
    }
    
    private func sendToAppleNotes(title: String, body: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
        
        let script = """
        tell application "Notes"
            tell account "iCloud"
                make new note at folder "Notes" with properties {name:"\(escapedTitle)", body:"\(escapedBody)"}
            end tell
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                let alert = NSAlert()
                alert.messageText = "Failed to Create Note"
                alert.informativeText = "Error: \(error)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    // MARK: - Section Command (/s)
    
    override func insertNewline(_ sender: Any?) {
        let currentLine = getCurrentLine()
        
        if currentLine == "/s" {
            let lineRange = getCurrentLineRange()
            if let textStorage = textStorage {
                textStorage.replaceCharacters(in: lineRange, with: "")
            }
            
            insertSectionMarker()
            return
        }
        
        super.insertNewline(sender)
    }
    
    private func getCurrentLine() -> String {
        let lineRange = getCurrentLineRange()
        return (string as NSString).substring(with: lineRange)
    }
    
    private func getCurrentLineRange() -> NSRange {
        let cursorPos = selectedRange().location
        if cursorPos == 0 { return NSRange(location: 0, length: 0) }
        
        let text = string as NSString
        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0
        
        text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: cursorPos - 1, length: 0))
        
        return NSRange(location: lineStart, length: lineEnd - lineStart)
    }
    
    private func insertSectionMarker() {
        guard let textStorage = textStorage else { return }
        
        let divider = "\n\n---\n\n"
        textStorage.replaceCharacters(in: selectedRange(), with: divider)
        
        noteStorage?.save()
    }
    
    // MARK: - Drawing Section Dividers
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawSectionDividers()
    }
    
    private func drawSectionDividers() {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else { return }
        
        let text = string as NSString
        
        var searchRange = NSRange(location: 0, length: text.length)
        var foundRange = NSRange()
        
        let dividerText = "---"
        
        while searchRange.location < text.length {
            foundRange = text.range(of: dividerText, options: [], range: searchRange)
            
            if foundRange.location != NSNotFound {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: foundRange, actualCharacterRange: nil)
                var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                
                let yPosition = lineRect.origin.y + textContainerInset.height - 8
                
                let path = NSBezierPath()
                path.move(to: NSPoint(x: textContainerInset.width + 20, y: yPosition))
                path.line(to: NSPoint(x: bounds.width - textContainerInset.width - 20, y: yPosition))

                // White divider
                NSColor.white.withAlphaComponent(0.3).setStroke()
                path.lineWidth = 1
                path.stroke()
                
                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = text.length - searchRange.location
            } else {
                break
            }
        }
    }
}
