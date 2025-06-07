//
//  FloatingNotesApp.swift
//  FloatingNotes
//
//  Created by Fletcher Alderton on 24/5/2025.
//

import SwiftUI
import AppKit // Ensure AppKit is imported for NSApplicationDelegate
import KeyboardShortcuts

// Keyboard Shortcut Manager to handle enable/disable functionality
class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()
    
    private var isCreateNewNoteRegistered = false
    private var isOpenRecentNoteRegistered = false
    
    private init() {
        // Register shortcuts initially
        registerShortcuts()
        
        // Listen for UserDefaults changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func registerShortcuts() {
        // Only register if not already registered
        if !isCreateNewNoteRegistered {
            KeyboardShortcuts.onKeyUp(for: .createNewNote) {
                print("Hotkey triggered: Create new note")
                WindowManager.shared.addNewNoteWindow()
            }
            isCreateNewNoteRegistered = true
        }
        
        if !isOpenRecentNoteRegistered {
            KeyboardShortcuts.onKeyUp(for: .openRecentNote) {
                print("Hotkey triggered: Open recent note")
                WindowManager.shared.openLastNoteOrCreateNew()
            }
            isOpenRecentNoteRegistered = true
        }
        
        // Apply current enabled/disabled state
        updateShortcutStates()
    }
    
    @objc private func userDefaultsDidChange() {
        updateShortcutStates()
    }
    
    private func updateShortcutStates() {
        let createNewNoteEnabled = UserDefaults.standard.object(forKey: "createNewNoteEnabled") as? Bool ?? true
        let openRecentNoteEnabled = UserDefaults.standard.object(forKey: "openRecentNoteEnabled") as? Bool ?? true
        
        if createNewNoteEnabled {
            KeyboardShortcuts.enable(.createNewNote)
        } else {
            KeyboardShortcuts.disable(.createNewNote)
        }
        
        if openRecentNoteEnabled {
            KeyboardShortcuts.enable(.openRecentNote)
        } else {
            KeyboardShortcuts.disable(.openRecentNote)
        }
        
        print("Keyboard shortcuts updated - Create: \(createNewNoteEnabled), Open: \(openRecentNoteEnabled)")
    }
    
    func toggleShortcut(_ name: KeyboardShortcuts.Name, enabled: Bool) {
        if enabled {
            KeyboardShortcuts.enable(name)
        } else {
            KeyboardShortcuts.disable(name)
        }
        print("Toggled shortcut \(name) to \(enabled ? "enabled" : "disabled")")
    }
}

// URL Handler class to manage URL scheme actions
class URLHandler: ObservableObject {
    static let shared = URLHandler()
    
    private init() {}
    
    func handleURL(_ url: URL) {
        print("URLHandler: Received URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              scheme == "floatingnotes" else {
            print("URLHandler: Invalid URL scheme")
            return
        }
        
        let host = components.host
        let path = components.path
        
        switch host {
        case "new", "create":
            handleCreateNewNote(queryItems: components.queryItems)
        case "recent", "last":
            handleOpenRecentNote()
        default:
            if path == "/new" || path == "/create" {
                handleCreateNewNote(queryItems: components.queryItems)
            } else if path == "/recent" || path == "/last" {
                handleOpenRecentNote()
            } else {
                print("URLHandler: Unknown URL action")
            }
        }
    }
    
    private func handleCreateNewNote(queryItems: [URLQueryItem]?) {
        print("URLHandler: Creating new note")
        
        // Check if there's initial text provided
        var initialText = ""
        if let queryItems = queryItems {
            for item in queryItems {
                if item.name == "text" || item.name == "content" {
                    initialText = item.value?.removingPercentEncoding ?? ""
                    break
                }
            }
        }
        
        // Create new note window with initial text if provided
        DispatchQueue.main.async {
            if !initialText.isEmpty {
                WindowManager.shared.addNewNoteWindow(withInitialText: initialText)
            } else {
                WindowManager.shared.addNewNoteWindow()
            }
        }
    }
    
    private func handleOpenRecentNote() {
        print("URLHandler: Opening most recent note")
        DispatchQueue.main.async {
            WindowManager.shared.openLastNoteOrCreateNew()
        }
    }
}

// AppDelegate to manage application lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hasProcessedURLOnLaunch = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize keyboard shortcut manager
        _ = KeyboardShortcutManager.shared
        
        // Initialize app display manager (dock vs menu bar)
        AppDisplayManager.shared.initialize()
        
        // Delay opening the last note to allow URL handling to occur first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Only open the last note if no URL was processed during launch
            if !self.hasProcessedURLOnLaunch {
                WindowManager.shared.openLastNoteOrCreateNew()
                print("AppDelegate: applicationDidFinishLaunching - Opening last note or creating new one.")
            } else {
                print("AppDelegate: applicationDidFinishLaunching - Skipped opening last note because URL was processed.")
            }
        }
    }

    // Optional: Handle app reactivation (e.g., clicking the dock icon)
    // if no windows are open and the app shouldn't terminate.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // If no windows are visible, open the last note or create a new one
            WindowManager.shared.openLastNoteOrCreateNew()
            print("AppDelegate: applicationShouldHandleReopen - No visible windows, opening last note or creating new one.")
        }
        // If there are visible windows, standard behavior is to bring them to front, so just return true.
        return true
    }
    
    // Handle URL schemes
    func application(_ application: NSApplication, open urls: [URL]) {
        hasProcessedURLOnLaunch = true
        for url in urls {
            URLHandler.shared.handleURL(url)
        }
    }
}

@main
struct FloatingNotesApp: App {
    // Use NSApplicationDelegateAdaptor to connect AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // URL handler instance
    @StateObject private var urlHandler = URLHandler.shared

    var body: some Scene {
        // Settings scene for keyboard shortcuts configuration
        Settings {
            SettingsView()
                .onAppear {
                    // .onAppear actions are performed on the main thread.
                    // Attempt to find and style the settings window.
                    for window in NSApplication.shared.windows {
                        // Heuristic to identify the settings window:
                        // Check if its content view hosts SettingsView or if its title is "Floating Notes Settings".
                        if let contentView = window.contentView,
                           contentView.subviews.contains(where: { ($0 as? NSHostingView<SettingsView>) != nil }) || window.title == "Floating Notes Settings" {
                            window.titlebarAppearsTransparent = true
                            window.styleMask.insert(.fullSizeContentView)
                            window.isOpaque = false
                            window.backgroundColor = .clear
                            window.level = .floating // Match the floating behavior of note windows
                            window.collectionBehavior = .canJoinAllSpaces // Show on all spaces
                            print("Applied transparent title bar, full size content view, floating level, and canJoinAllSpaces to Settings window.")
                            break // Stop after finding and modifying the settings window
                        }
                    }
                }
        }
        .commands {
            MenuCommands()
        }
    }
}