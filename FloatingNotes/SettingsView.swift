//
//  SettingsView.swift
//  FloatingNotes
//
//  Created by Fletcher Alderton on 24/5/2025.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @State private var isCreateNewNoteEnabled: Bool = true
    @State private var isOpenRecentNoteEnabled: Bool = true
    @State private var currentNotesDirectory: String = ""
    @State private var showingDirectoryPicker = false
    @State private var showingMigrationAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedDirectory: URL?
    @State private var isPinned: Bool = true
    @ObservedObject private var notesManager = NotesManager.shared
    
    private let createNewNoteEnabledKey = "createNewNoteEnabled"
    private let openRecentNoteEnabledKey = "openRecentNoteEnabled"
    
    var body: some View {
        ZStack {
            // Background visual effect to match other views
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.bottom, 10)
                
                // Notes Storage Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Notes Storage")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Location:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(currentNotesDirectory)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 10) {
                            Button("Change Location...") {
                                showingDirectoryPicker = true
                            }
                            .buttonStyle(TransparentButtonStyle())
                            
                            Button("Reset to Default") {
                                resetToDefaultDirectory()
                            }
                            .buttonStyle(TransparentButtonStyle())
                            .disabled(isUsingDefaultDirectory())
                        }
                    }
                }
                .padding(.bottom, 20)

                // Custom divider with transparency
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)

                // Pin Notes Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Pin Notes")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Automatically Pin Notes to All Spaces")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Toggle("", isOn: $isPinned)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .onChange(of: isPinned) {
                                UserDefaults.standard.set(isPinned, forKey: "defaultIsPinned")
                            }
                    }
                }
                .padding(.bottom, 20)

                // Custom divider with transparency
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                
                // Keyboard Shortcuts Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Keyboard Shortcuts")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Create New Note")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Toggle("", isOn: $isCreateNewNoteEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    .onChange(of: isCreateNewNoteEnabled) {
                                        KeyboardShortcutManager.shared.toggleShortcut(.createNewNote, enabled: isCreateNewNoteEnabled)
                                        UserDefaults.standard.set(isCreateNewNoteEnabled, forKey: createNewNoteEnabledKey)
                                    }
                            }
                            KeyboardShortcuts.Recorder(for: .createNewNote)
                                .disabled(!isCreateNewNoteEnabled)
                                .opacity(isCreateNewNoteEnabled ? 1.0 : 0.5)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Open Recent Note")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Toggle("", isOn: $isOpenRecentNoteEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    .onChange(of: isOpenRecentNoteEnabled) {
                                        KeyboardShortcutManager.shared.toggleShortcut(.openRecentNote, enabled: isOpenRecentNoteEnabled)
                                        UserDefaults.standard.set(isOpenRecentNoteEnabled, forKey: openRecentNoteEnabledKey)
                                    }
                            }
                            KeyboardShortcuts.Recorder(for: .openRecentNote)
                                .disabled(!isOpenRecentNoteEnabled)
                                .opacity(isOpenRecentNoteEnabled ? 1.0 : 0.5)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
                
                Text("Note: Changes take effect immediately. Keyboard shortcuts work system-wide when the app is running.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
        }
        .frame(minWidth: 350, maxWidth: 350, minHeight: 550, maxHeight: .infinity)
        .onAppear {
            loadSettings()
            updateCurrentDirectoryDisplay()
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Ensure the URL has security scope access
                    if url.startAccessingSecurityScopedResource() {
                        selectedDirectory = url
                        showingMigrationAlert = true
                        // Note: We don't call stopAccessingSecurityScopedResource here
                        // because we need the access to persist for the migration/change operations
                    } else {
                        errorMessage = "Unable to access the selected directory. Please try again."
                        showingErrorAlert = true
                    }
                }
            case .failure(let error):
                errorMessage = "Failed to select directory: \(error.localizedDescription)"
                showingErrorAlert = true
            }
        }
        .alert("Migrate Notes?", isPresented: $showingMigrationAlert) {
            Button("Migrate") {
                if let newDirectory = selectedDirectory {
                    migrateToNewDirectory(newDirectory)
                }
            }
            Button("Change Without Migrating") {
                if let newDirectory = selectedDirectory {
                    changeDirectoryWithoutMigration(newDirectory)
                }
            }
            Button("Cancel", role: .cancel) {
                selectedDirectory?.stopAccessingSecurityScopedResource()
                selectedDirectory = nil
            }
        } message: {
            Text("Would you like to migrate your existing notes to the new location, or just change the location for new notes?")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateCurrentDirectoryDisplay() {
        currentNotesDirectory = notesManager.getCurrentNotesDirectory().path
    }
    
    private func isUsingDefaultDirectory() -> Bool {
        let defaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FloatingNotesApp").path
        return currentNotesDirectory == defaultPath
    }
    
    private func resetToDefaultDirectory() {
        notesManager.resetToDefaultDirectory()
        updateCurrentDirectoryDisplay()
    }
    
    private func migrateToNewDirectory(_ newDirectory: URL) {
        defer {
            // Release security scope access after operation
            newDirectory.stopAccessingSecurityScopedResource()
            selectedDirectory = nil
        }
        
        if notesManager.migrateNotesToNewDirectory(newDirectory) {
            updateCurrentDirectoryDisplay()
        } else {
            errorMessage = "Failed to migrate notes to the new directory."
            showingErrorAlert = true
        }
    }
    
    private func changeDirectoryWithoutMigration(_ newDirectory: URL) {
        defer {
            // Release security scope access after operation
            newDirectory.stopAccessingSecurityScopedResource()
            selectedDirectory = nil
        }
        
        if notesManager.setCustomNotesDirectory(newDirectory) {
            updateCurrentDirectoryDisplay()
        } else {
            errorMessage = "Failed to set the new directory. Please ensure it's writable."
            showingErrorAlert = true
        }
    }
    
    private func loadSettings() {
        isCreateNewNoteEnabled = UserDefaults.standard.object(forKey: createNewNoteEnabledKey) as? Bool ?? true
        isOpenRecentNoteEnabled = UserDefaults.standard.object(forKey: openRecentNoteEnabledKey) as? Bool ?? true
        isPinned = UserDefaults.standard.object(forKey: "defaultIsPinned") as? Bool ?? true

        // Apply the current state to the shortcuts using the KeyboardShortcutManager
        KeyboardShortcutManager.shared.toggleShortcut(.createNewNote, enabled: isCreateNewNoteEnabled)
        KeyboardShortcutManager.shared.toggleShortcut(.openRecentNote, enabled: isOpenRecentNoteEnabled)
    }
}

// Custom button style to match the transparent theme
struct TransparentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(configuration.isPressed ? 0.2 : 0.1))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    SettingsView()
} 
