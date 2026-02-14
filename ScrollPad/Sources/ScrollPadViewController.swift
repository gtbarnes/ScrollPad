import AppKit

class ScrollPadViewController: NSViewController, NSTextViewDelegate, SettingsViewDelegate {

    private var visualEffectView: NSVisualEffectView!
    private var scrollView: NSScrollView!
    private var textView: ScrollPadTextView!
    private var noteStorage: NoteStorage!
    private var windowControllerRef: MainWindowController?
    private var settingsView: SettingsView?
    private var isShowingSettings = false
    
    override func loadView() {
        // Create the main view
        let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        // Create terminal-styled visual effect view
        visualEffectView = NSVisualEffectView(frame: mainView.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.92).cgColor
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1.0
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        
        mainView.addSubview(visualEffectView)
        
        // Setup scroll view and text view
        setupTextView()
        
        self.view = mainView
    }
    
    private func setupTextView() {
        // Create scroll view
        scrollView = NSScrollView(frame: visualEffectView.bounds.insetBy(dx: 16, dy: 16))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        
        scrollView.contentView.postsBoundsChangedNotifications = true
        
        // Create text view
        let contentSize = scrollView.contentSize
        let textContainer = NSTextContainer(size: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        textView = ScrollPadTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        
        // Terminal-style monospace font
        if let sfMono = NSFont(name: "SF Mono", size: 14) {
            textView.font = sfMono
        } else if let menlo = NSFont(name: "Menlo", size: 14) {
            textView.font = menlo
        } else {
            textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        }

        // White text color
        textView.textColor = .white
        textView.insertionPointColor = .white
        
        // Set padding
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        // Setup storage manager
        noteStorage = NoteStorage(textView: textView)
        noteStorage.load()

        // Set delegates
        textView.noteStorage = noteStorage
        textView.delegate = self
        
        scrollView.documentView = textView
        visualEffectView.addSubview(scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(textView)
    }
    
    func setWindowController(_ controller: MainWindowController) {
        self.windowControllerRef = controller
        if let tv = textView {
            tv.windowController = controller
        }
    }

    // MARK: - NSTextViewDelegate

    func textDidChange(_ notification: Notification) {
        noteStorage?.save()
    }

    // MARK: - Settings Management

    func showSettings() {
        guard !isShowingSettings else { return }

        isShowingSettings = true
        scrollView.isHidden = true

        if settingsView == nil {
            settingsView = SettingsView()
            settingsView?.translatesAutoresizingMaskIntoConstraints = false
            settingsView?.delegate = self
        }

        if let settingsView = settingsView {
            visualEffectView.addSubview(settingsView)

            NSLayoutConstraint.activate([
                settingsView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 20),
                settingsView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 20),
                settingsView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -20),
                settingsView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -20)
            ])
        }
    }

    func hideSettings() {
        guard isShowingSettings else { return }

        isShowingSettings = false
        settingsView?.removeFromSuperview()
        scrollView.isHidden = false
        view.window?.makeFirstResponder(textView)
    }
}
