//
//  KeyboardShortcutNames.swift
//  FloatingNotes
//
//  Created by Fletcher Alderton on 24/5/2025.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let createNewNote = Self("createNewNote", default: .init(.n, modifiers: [.command, .shift]))
    static let openRecentNote = Self("openRecentNote", default: .init(.o, modifiers: [.command, .shift]))
} 