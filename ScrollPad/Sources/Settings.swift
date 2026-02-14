import Foundation
import Carbon.HIToolbox

class Settings {
    
    static let shared = Settings()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let storageFolder = "storageFolder"
    }
    
    // Default values
    private let defaultHotkeyModifiers: UInt32 = UInt32(cmdKey | shiftKey) // Cmd+Shift
    private let defaultHotkeyKeyCode: UInt32 = UInt32(kVK_Space) // Space
    
    var hotkeyModifiers: UInt32 {
        get {
            if defaults.object(forKey: Keys.hotkeyModifiers) != nil {
                return UInt32(defaults.integer(forKey: Keys.hotkeyModifiers))
            }
            return defaultHotkeyModifiers
        }
        set {
            defaults.set(Int(newValue), forKey: Keys.hotkeyModifiers)
        }
    }

    var hotkeyKeyCode: UInt32 {
        get {
            if defaults.object(forKey: Keys.hotkeyKeyCode) != nil {
                return UInt32(defaults.integer(forKey: Keys.hotkeyKeyCode))
            }
            return defaultHotkeyKeyCode
        }
        set {
            defaults.set(Int(newValue), forKey: Keys.hotkeyKeyCode)
        }
    }
    
    /// The folder where scrollpad.txt will be stored
    var storageFolder: String {
        get {
            if let path = defaults.string(forKey: Keys.storageFolder), !path.isEmpty {
                return path
            }
            // Default folder
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return appSupport.appendingPathComponent("ScrollPad").path
        }
        set {
            defaults.set(newValue, forKey: Keys.storageFolder)
            NotificationCenter.default.post(name: .storagePathChanged, object: nil)
        }
    }
    
    /// The full path to the notes file (storageFolder + "scrollpad.txt")
    var storagePath: String {
        let folder = storageFolder
        if folder.isEmpty {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return appSupport.appendingPathComponent("ScrollPad/scrollpad.txt").path
        }
        return (folder as NSString).appendingPathComponent("scrollpad.txt")
    }
    
    func resetToDefaults() {
        defaults.set(Int(defaultHotkeyModifiers), forKey: Keys.hotkeyModifiers)
        defaults.set(Int(defaultHotkeyKeyCode), forKey: Keys.hotkeyKeyCode)
        NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        storageFolder = appSupport.appendingPathComponent("ScrollPad").path
    }
    
    private init() {}
}

// Notification names
extension Notification.Name {
    static let hotkeySettingsChanged = Notification.Name("hotkeySettingsChanged")
    static let storagePathChanged = Notification.Name("storagePathChanged")
}
