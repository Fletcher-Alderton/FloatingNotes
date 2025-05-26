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

// AppDelegate to manage application lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize keyboard shortcut manager
        _ = KeyboardShortcutManager.shared
        
        // Open the last note when the app finishes launching, or create a new one if no notes exist
        WindowManager.shared.openLastNoteOrCreateNew()
        print("AppDelegate: applicationDidFinishLaunching - Opening last note or creating new one.")
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
}

@main
struct FloatingNotesApp: App {
    // Use NSApplicationDelegateAdaptor to connect AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The WindowGroup is removed. Windows are now managed by WindowManager.
        // SwiftUI still requires at least one Scene.
        // A Settings scene can be used as a placeholder if no main window is defined here.
        // Or, if you plan to have a main control window or settings accessible from menu,
        // you could define it here. For now, an empty scene group or Settings {} is fine.
        Settings {
            // Settings view for keyboard shortcuts configuration
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

// The ContentView helper struct and WindowAccessor are no longer needed here
// as WindowManager directly creates NSWindow and NoteView instances.
// They were previously used to get the NSWindow reference for the initial window.
