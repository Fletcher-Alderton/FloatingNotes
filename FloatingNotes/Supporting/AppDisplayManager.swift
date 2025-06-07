import SwiftUI
import AppKit

enum AppDisplayMode: String, CaseIterable {
    case dock = "dock"
    case menuBar = "menuBar"
    
    var displayName: String {
        switch self {
        case .dock:
            return "Dock"
        case .menuBar:
            return "Menu Bar"
        }
    }
}

class AppDisplayManager: ObservableObject {
    static let shared = AppDisplayManager()
    private let userDefaultsKey = "appDisplayMode"
    
    @Published var currentMode: AppDisplayMode {
        didSet {
            applyDisplayMode(currentMode)
            UserDefaults.standard.set(currentMode.rawValue, forKey: userDefaultsKey)
        }
    }
    
    private init() {
        // Load saved preference or default to dock
        let savedMode = UserDefaults.standard.string(forKey: userDefaultsKey) ?? AppDisplayMode.dock.rawValue
        self.currentMode = AppDisplayMode(rawValue: savedMode) ?? .dock
    }
    
    func initialize() {
        // Apply the current mode on app startup
        applyDisplayMode(currentMode)
    }
    
    private func applyDisplayMode(_ mode: AppDisplayMode) {
        DispatchQueue.main.async {
            switch mode {
            case .dock:
                self.setupDockMode()
            case .menuBar:
                self.setupMenuBarMode()
            }
        }
    }
    
    private func setupDockMode() {
        // Set activation policy to regular (show in dock)
        NSApp.setActivationPolicy(.regular)
        
        // Remove menu bar item
        MenuBarManager.shared.removeMenuBar()
        
        print("AppDisplayManager: Switched to Dock mode")
    }
    
    private func setupMenuBarMode() {
        // Set activation policy to accessory (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar item
        MenuBarManager.shared.setupMenuBar()
        
        print("AppDisplayManager: Switched to Menu Bar mode")
    }
    
    func toggleMode() {
        switch currentMode {
        case .dock:
            currentMode = .menuBar
        case .menuBar:
            currentMode = .dock
        }
    }
} 