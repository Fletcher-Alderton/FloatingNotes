//
//  MenuCommands.swift
//  FloatingNotes
//
//  Created by Fletcher Alderton on 24/5/2025.
//

import SwiftUI
import KeyboardShortcuts

struct MenuCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Create Note Window") {
                WindowManager.shared.addNewNoteWindow()
            }
            
            Button("Open Last Note") {
                WindowManager.shared.openLastNoteOrCreateNew()
            }
            
            Divider()
            
            Button("Show All Notes") {
                WindowManager.shared.showNotesListWindow()
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
        }
    }
} 