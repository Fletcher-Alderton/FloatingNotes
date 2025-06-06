//
//  SettingsView.swift
//  FloatingNotes
//
//  Created by Fletcher Alderton on 24/5/2025.
//

import SwiftUI
import KeyboardShortcuts

enum SettingsSection: String, CaseIterable, Identifiable {
    case storage = "Storage"
    case pinning = "Pin Notes"
    case display = "App Display"
    case shortcuts = "Keyboard Shortcuts"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .storage: return "folder"
        case .pinning: return "pin"
        case .display: return "app.badge"
        case .shortcuts: return "keyboard"
        }
    }
}

struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .storage
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
    @ObservedObject private var appDisplayManager = AppDisplayManager.shared
    
    private let createNewNoteEnabledKey = "createNewNoteEnabled"
    private let openRecentNoteEnabledKey = "openRecentNoteEnabled"
    
    var body: some View {
        ZStack {
            // Background visual effect to match other views
            VisualEffectView()
                .ignoresSafeArea()
            
            HSplitView {
                // Sidebar
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }
                    
                    // Sidebar list
                    List(SettingsSection.allCases, selection: $selectedSection) { section in
                        HStack(spacing: 10) {
                            Image(systemName: section.iconName)
                                .foregroundColor(.primary)
                                .frame(width: 16, height: 16)
                            Text(section.rawValue)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .tag(section)
                    }
                    .listStyle(SidebarListStyle())
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
                .frame(minWidth: 180, maxWidth: 180)
                .background(Color.white.opacity(0.05))
                
                // Detail view
                VStack(alignment: .leading, spacing: 0) {
                    // Section header
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: selectedSection.iconName)
                                .foregroundColor(.primary)
                                .font(.title2)
                            Text(selectedSection.rawValue)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                    }
                    
                    // Content area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            switch selectedSection {
                            case .storage:
                                StorageSettingsView(
                                    currentNotesDirectory: $currentNotesDirectory,
                                    showingDirectoryPicker: $showingDirectoryPicker
                                )
                            case .pinning:
                                PinSettingsView(isPinned: $isPinned)
                            case .display:
                                DisplaySettingsView()
                            case .shortcuts:
                                ShortcutsSettingsView(
                                    isCreateNewNoteEnabled: $isCreateNewNoteEnabled,
                                    isOpenRecentNoteEnabled: $isOpenRecentNoteEnabled,
                                    createNewNoteEnabledKey: createNewNoteEnabledKey,
                                    openRecentNoteEnabledKey: openRecentNoteEnabledKey
                                )
                            }
                        }
                        .padding(20)
                    }
                }
                .frame(minWidth: 400)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
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

// MARK: - Individual Settings Views

struct StorageSettingsView: View {
    @Binding var currentNotesDirectory: String
    @Binding var showingDirectoryPicker: Bool
    @ObservedObject private var notesManager = NotesManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Choose where your notes are stored on your Mac.")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Current Location")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(currentNotesDirectory)
                    .font(.system(.body, design: .monospaced))
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
            }
            
            HStack(spacing: 10) {
                Button("Change Location...") {
                    showingDirectoryPicker = true
                }
                .buttonStyle(MacOSButtonStyle())
                
                Button("Reset to Default") {
                    resetToDefaultDirectory()
                }
                .buttonStyle(MacOSButtonStyle(isSecondary: true))
                .disabled(isUsingDefaultDirectory())
            }
        }
    }
    
    private func isUsingDefaultDirectory() -> Bool {
        let defaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FloatingNotesApp").path
        return currentNotesDirectory == defaultPath
    }
    
    private func resetToDefaultDirectory() {
        notesManager.resetToDefaultDirectory()
        currentNotesDirectory = notesManager.getCurrentNotesDirectory().path
    }
}

struct PinSettingsView: View {
    @Binding var isPinned: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Control whether new notes are automatically pinned to all desktop spaces.")
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Automatically Pin New Notes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("New notes will appear on all desktop spaces")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isPinned)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: isPinned) {
                        UserDefaults.standard.set(isPinned, forKey: "defaultIsPinned")
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct DisplaySettingsView: View {
    @ObservedObject private var appDisplayManager = AppDisplayManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Choose how the app appears in your system.")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Show App In")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("", selection: $appDisplayManager.currentMode) {
                    ForEach(AppDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("Dock: Shows the app icon in the Dock and allows switching with Cmd+Tab")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Menu Bar Only: Hides from Dock, accessible only via menu bar icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct ShortcutsSettingsView: View {
    @Binding var isCreateNewNoteEnabled: Bool
    @Binding var isOpenRecentNoteEnabled: Bool
    let createNewNoteEnabledKey: String
    let openRecentNoteEnabledKey: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Set up global keyboard shortcuts that work system-wide when the app is running.")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15) {
                // Create New Note Shortcut
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create New Note")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Opens a new floating note")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                // Open Recent Note Shortcut
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Recent Note")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Opens the most recently modified note")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            Text("Changes take effect immediately. Keyboard shortcuts work system-wide when the app is running.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
    }
}

// MARK: - Custom Button Styles

struct MacOSButtonStyle: ButtonStyle {
    let isSecondary: Bool
    
    init(isSecondary: Bool = false) {
        self.isSecondary = isSecondary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSecondary {
                        Color.white.opacity(configuration.isPressed ? 0.15 : 0.05)
                    } else {
                        Color.blue.opacity(configuration.isPressed ? 0.8 : 0.6)
                    }
                }
            )
            .foregroundColor(isSecondary ? .primary : .white)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(isSecondary ? 0.2 : 0), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Legacy button style for compatibility
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
