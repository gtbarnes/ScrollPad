import AppKit

struct Section {
    var range: NSRange
    var title: String
    var body: String
}

class NoteStorage {
    
    private weak var textView: NSTextView?
    private var saveTimer: Timer?
    private let saveDelay: TimeInterval = 0.5
    
    // Use the file path from Settings
    private var storageURL: URL {
        let path = Settings.shared.storagePath
        return URL(fileURLWithPath: path)
    }
    
    init(textView: NSTextView) {
        self.textView = textView
        
        // Listen for storage path changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storagePathChanged),
            name: .storagePathChanged,
            object: nil
        )
    }
    
    @objc private func storagePathChanged() {
        // Reload from new path
        load()
    }
    
    // MARK: - Loading
    
    func load() {
        guard let textView = textView else { return }

        // Ensure folder exists
        ensureFolderExists()

        if FileManager.default.fileExists(atPath: storageURL.path) {
            do {
                let content = try String(contentsOf: storageURL, encoding: .utf8)
                let formattedContent = content.replacingOccurrences(of: "---SECTION---", with: "---\n")
                textView.string = formattedContent
            } catch {
                print("Failed to load notes: \(error)")
            }
        } else {
            textView.string = ""
        }

        // Restyle dividers after loading
        (textView as? ScrollPadTextView)?.refreshDividerStyling()
    }
    
    // MARK: - Saving
    
    func save() {
        saveTimer?.invalidate()
        
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveDelay, repeats: false) { [weak self] _ in
            self?.performSave()
        }
    }
    
    private func performSave() {
        guard let textView = textView else { return }
        
        let content = textView.string
        let storedContent = content.replacingOccurrences(of: "---", with: "---SECTION---")
        
        // Ensure folder exists
        ensureFolderExists()
        
        do {
            try storedContent.write(to: storageURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save notes: \(error)")
        }
    }
    
    private func ensureFolderExists() {
        let folderURL = storageURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Section Management
    
    func getSections() -> [Section] {
        guard let textView = textView else { return [] }
        
        let text = textView.string as NSString
        var sections: [Section] = []
        
        var searchRange = NSRange(location: 0, length: text.length)
        var dividerRanges: [NSRange] = []
        
        let dividerText = "---"
        
        while searchRange.location < text.length {
            let foundRange = text.range(of: dividerText, options: [], range: searchRange)
            
            if foundRange.location != NSNotFound {
                dividerRanges.append(foundRange)
                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = text.length - searchRange.location
            } else {
                break
            }
        }
        
        if dividerRanges.isEmpty {
            let title = extractTitle(from: NSRange(location: 0, length: text.length))
            return [Section(range: NSRange(location: 0, length: text.length), title: title, body: text as String)]
        }
        
        let firstDivider = dividerRanges[0]
        
        if firstDivider.location > 0 {
            let sectionRange = NSRange(location: 0, length: firstDivider.location)
            let title = extractTitle(from: sectionRange)
            let body = extractBody(from: sectionRange)
            sections.append(Section(range: sectionRange, title: title, body: body))
        }
        
        for i in 0..<dividerRanges.count - 1 {
            let start = dividerRanges[i].location + dividerRanges[i].length
            let end = dividerRanges[i + 1].location
            let sectionRange = NSRange(location: start, length: end - start)
            
            let title = extractTitle(from: sectionRange)
            let body = extractBody(from: sectionRange)
            sections.append(Section(range: sectionRange, title: title, body: body))
        }
        
        let lastDivider = dividerRanges[dividerRanges.count - 1]
        if lastDivider.location + lastDivider.length < text.length {
            let sectionRange = NSRange(location: lastDivider.location + lastDivider.length, length: text.length - (lastDivider.location + lastDivider.length))
            let title = extractTitle(from: sectionRange)
            let body = extractBody(from: sectionRange)
            sections.append(Section(range: sectionRange, title: title, body: body))
        }
        
        return sections
    }
    
    private func extractTitle(from range: NSRange) -> String {
        guard let textView = textView else { return "Untitled" }
        
        let text = textView.string as NSString
        if range.length == 0 { return "Untitled" }
        
        var lineEnd = 0
        var contentsEnd = 0
        text.getLineStart(nil, end: &lineEnd, contentsEnd: &contentsEnd, for: range)
        
        let firstLine: String
        if lineEnd > range.location {
            let lineLength = min(lineEnd - range.location, range.length)
            firstLine = text.substring(with: NSRange(location: range.location, length: lineLength))
        } else {
            firstLine = ""
        }
        
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }
    
    private func extractBody(from range: NSRange) -> String {
        guard let textView = textView else { return "" }
        
        let text = textView.string as NSString
        if range.length == 0 { return "" }
        
        var lineEnd = 0
        var contentsEnd = 0
        text.getLineStart(nil, end: &lineEnd, contentsEnd: &contentsEnd, for: range)
        
        if lineEnd >= range.location + range.length {
            return ""
        }
        
        let bodyStart = min(lineEnd, range.location + range.length - 1)
        let body = text.substring(with: NSRange(location: bodyStart, length: range.location + range.length - bodyStart))
        
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
