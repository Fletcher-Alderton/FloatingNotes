//
//  FloatingNotesApp.swift
//  FloatingNotes
//
//  Created by Fletcher Alderton on 24/5/2025.
//

import SwiftUI
import AppKit // Ensure AppKit is imported for NSApplicationDelegate

// AppDelegate to manage application lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Open the last note when the app finishes launching, or create a new one if no notes exist
        WindowManager.shared.openLastNoteOrCreateNew()
        print("AppDelegate: applicationDidFinishLaunching - Opening last note or creating new one.")
    }

    // Optional: Decide if the app should terminate when the last window is closed.
    // Default is true. Return false to keep the app running (e.g., for a menu bar app).
    /*
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true // or false, depending on desired behavior
    }
    */

    // Optional: Handle app reactivation (e.g., clicking the dock icon)
    // if no windows are open and the app shouldn't terminate.
    /*
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            WindowManager.shared.addNewNoteWindow()
        }
        return true
    }
    */
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
            // Empty settings view for now, or add actual settings later.
            // This satisfies the Scene requirement without creating a default window.
            EmptyView()
        }
    }
}

// The ContentView helper struct and WindowAccessor are no longer needed here
// as WindowManager directly creates NSWindow and NoteView instances.
// They were previously used to get the NSWindow reference for the initial window.
