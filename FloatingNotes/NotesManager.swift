import Foundation
import Combine

class NotesManager: ObservableObject {
    static let shared = NotesManager()
    
    @Published var notes: [NoteItem] = []
    private let pinnedNotesKey = "pinnedNoteIDs" // UserDefaults key
    private let customNotesDirectoryKey = "customNotesDirectory" // UserDefaults key for custom directory
    private let directoryBookmarkKey = "directoryBookmark" // UserDefaults key for security-scoped bookmark
    private var currentSecurityScopedURL: URL? // Track currently accessed security-scoped URL

    private init() {
        loadNotes()
    }
    
    deinit {
        // Clean up security-scoped resource access
        currentSecurityScopedURL?.stopAccessingSecurityScopedResource()
    }

    func getAppNotesDirectory() -> URL {
        // Clean up any previously accessed security-scoped resource
        if let previousURL = currentSecurityScopedURL {
            previousURL.stopAccessingSecurityScopedResource()
            currentSecurityScopedURL = nil
        }
        
        // Check if user has set a custom directory with security-scoped bookmark
        if let bookmarkData = UserDefaults.standard.data(forKey: directoryBookmarkKey) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale)
                
                if isStale {
                    print("Bookmark is stale, will need to re-select directory")
                    // Remove the stale bookmark
                    UserDefaults.standard.removeObject(forKey: directoryBookmarkKey)
                    UserDefaults.standard.removeObject(forKey: customNotesDirectoryKey)
                    UserDefaults.standard.synchronize()
                } else {
                    // Start accessing the security-scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        // Verify the directory still exists and is accessible
                        if FileManager.default.fileExists(atPath: url.path) {
                            currentSecurityScopedURL = url
                            return url
                        } else {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                }
            } catch {
                print("Error resolving bookmark: \(error)")
                // Remove invalid bookmark
                UserDefaults.standard.removeObject(forKey: directoryBookmarkKey)
                UserDefaults.standard.removeObject(forKey: customNotesDirectoryKey)
                UserDefaults.standard.synchronize()
            }
        }
        
        // Fallback: Check legacy custom path (for backwards compatibility)
        if let customPath = UserDefaults.standard.string(forKey: customNotesDirectoryKey),
           !customPath.isEmpty {
            let customURL = URL(fileURLWithPath: customPath)
            // Verify the directory exists and is accessible
            if FileManager.default.fileExists(atPath: customURL.path) {
                return customURL
            } else {
                // If custom directory doesn't exist, try to create it
                do {
                    try FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true, attributes: nil)
                    return customURL
                } catch {
                    print("Error creating custom notes directory: \(error). Falling back to default.")
                    // Fall back to default if custom directory can't be created
                }
            }
        }
        
        // Default behavior - use Documents/FloatingNotesApp
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let appDirectory = paths[0].appendingPathComponent("FloatingNotesApp")
        
        // Ensure the default directory exists
        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                print("Created default FloatingNotesApp directory at: \(appDirectory.path)")
            } catch {
                print("Error creating default FloatingNotesApp directory: \(error)")
            }
        }
        return appDirectory
    }
    
    func setCustomNotesDirectory(_ url: URL) -> Bool {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security-scoped resource")
            return false
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Verify the directory exists and is writable
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Selected directory does not exist: \(url.path)")
            return false
        }
        
        // Test if we can write to the directory
        let testFile = url.appendingPathComponent(".floating_notes_test")
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
        } catch {
            print("Cannot write to selected directory: \(error)")
            return false
        }
        
        // Create and store security-scoped bookmark
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                  includingResourceValuesForKeys: nil,
                                                  relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: directoryBookmarkKey)
            UserDefaults.standard.set(url.path, forKey: customNotesDirectoryKey)
            UserDefaults.standard.synchronize()
            
            print("Successfully set custom directory with bookmark: \(url.path)")
        } catch {
            print("Failed to create bookmark for directory: \(error)")
            return false
        }
        
        // Reload notes from the new directory
        DispatchQueue.main.async {
            self.loadNotes()
        }
        
        return true
    }
    
    func getCurrentNotesDirectory() -> URL {
        return getAppNotesDirectory()
    }
    
    func resetToDefaultDirectory() {
        UserDefaults.standard.removeObject(forKey: customNotesDirectoryKey)
        UserDefaults.standard.removeObject(forKey: directoryBookmarkKey)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.loadNotes()
        }
    }
    
    func migrateNotesToNewDirectory(_ newDirectory: URL) -> Bool {
        let currentDirectory = getAppNotesDirectory()
        
        // Don't migrate if it's the same directory
        guard currentDirectory != newDirectory else { return true }
        
        // Start accessing the security-scoped resource for the new directory
        guard newDirectory.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security-scoped resource for new directory")
            return false
        }
        
        defer {
            newDirectory.stopAccessingSecurityScopedResource()
        }
        
        do {
            // Ensure the new directory exists
            if !FileManager.default.fileExists(atPath: newDirectory.path) {
                try FileManager.default.createDirectory(at: newDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: currentDirectory,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)
            
            var migratedCount = 0
            for fileURL in fileURLs {
                if fileURL.pathExtension == "md" {
                    let destinationURL = newDirectory.appendingPathComponent(fileURL.lastPathComponent)
                    
                    // Check if file already exists at destination
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        // Create a unique name by appending a number
                        let baseName = fileURL.deletingPathExtension().lastPathComponent
                        let ext = fileURL.pathExtension
                        var counter = 1
                        var uniqueDestination = destinationURL
                        
                        while FileManager.default.fileExists(atPath: uniqueDestination.path) {
                            let uniqueName = "\(baseName)_\(counter).\(ext)"
                            uniqueDestination = newDirectory.appendingPathComponent(uniqueName)
                            counter += 1
                        }
                        
                        try FileManager.default.copyItem(at: fileURL, to: uniqueDestination)
                    } else {
                        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                    }
                    migratedCount += 1
                }
            }
            
            print("Migrated \(migratedCount) notes to new directory")
            
            // Create and store security-scoped bookmark for the new directory
            do {
                let bookmarkData = try newDirectory.bookmarkData(options: .withSecurityScope,
                                                              includingResourceValuesForKeys: nil,
                                                              relativeTo: nil)
                UserDefaults.standard.set(bookmarkData, forKey: directoryBookmarkKey)
                UserDefaults.standard.set(newDirectory.path, forKey: customNotesDirectoryKey)
                UserDefaults.standard.synchronize()
                
                print("Successfully created bookmark for migrated directory: \(newDirectory.path)")
            } catch {
                print("Failed to create bookmark for migrated directory: \(error)")
                // Still return true since migration succeeded, but bookmark creation failed
            }
            
            // Reload notes from new directory
            DispatchQueue.main.async {
                self.loadNotes()
            }
            
            return true
        } catch {
            print("Error migrating notes: \(error)")
            return false
        }
    }

    func loadNotes() {
        let notesDirectory = getAppNotesDirectory()
        var loadedNotes: [NoteItem] = []
        let pinnedIDs = UserDefaults.standard.array(forKey: pinnedNotesKey) as? [String] ?? []

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: notesDirectory,
                                                                   includingPropertiesForKeys: [.contentModificationDateKey, .nameKey],
                                                                   options: .skipsHiddenFiles)
            for url in fileURLs {
                if url.pathExtension == "md" {
                    let filename = url.lastPathComponent
                    // Handle potential underscores in the title correctly
                    let baseFilename = filename.replacingOccurrences(of: ".md", with: "")
                    let components = baseFilename.split(separator: "_")
                    
                    // Ensure there's at least one component for the ID
                    guard components.count > 0 else {
                        print("Could not parse filename into components: \(filename)")
                        continue // Skip this file if filename is empty or just ".md"
                    }

                    let idString = String(components.last!) // Get the last component as the potential UUID
                    let titleComponents = components.dropLast()
                    let title = titleComponents.isEmpty ? "Untitled Note" : titleComponents.joined(separator: "_")


                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let modificationDate = attributes[.modificationDate] as? Date

                    if let uuid = UUID(uuidString: idString) {
                         // Check if the file name actually ends with the UUID string, ensuring correct parsing
                        if baseFilename.hasSuffix("_\(idString)") {
                             let isPinned = pinnedIDs.contains(uuid.uuidString)
                            loadedNotes.append(NoteItem(id: uuid, title: title, url: url, isPinned: isPinned, lastModified: modificationDate))
                        } else {
                             // Fallback for files that don't end with a valid UUID format but might contain underscores
                            print("Filename \(filename) does not end with a valid UUID format after underscore. Using full filename as title and new UUID.")
                            let fallbackTitle = baseFilename // Use the whole filename as title if UUID is not at the end
                             // Generate a new UUID for the NoteItem instance, but it won't match the filename for persistence
                            loadedNotes.append(NoteItem(id: UUID(), title: fallbackTitle, url: url, isPinned: false, lastModified: modificationDate))
                        }

                    } else {
                        // Handle cases where the last component is not a valid UUID
                        print("Last component '\(idString)' in filename '\(filename)' is not a valid UUID. Using full filename as title and new UUID.")
                        let fallbackTitle = baseFilename // Use the whole filename as title
                        // Generate a new UUID for the NoteItem instance
                        loadedNotes.append(NoteItem(id: UUID(), title: fallbackTitle, url: url, isPinned: false, lastModified: modificationDate))
                    }
                }
            }
        } catch {
            print("Error loading notes: \(error)")
        }
        // The @Published property 'notes' will automatically notify observers when assigned
        self.notes = loadedNotes
    }

    func togglePin(note: NoteItem) {
        // Find the note by ID in the published notes array
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            // Because NoteItem is a class and ObservableObject,
            // modifying its @Published properties will automatically
            // notify any views observing this specific NoteItem instance.
            // However, to trigger a list re-evaluation for sorting/sectioning,
            // we need to signal a change in the array itself.
            // The simplest way is to trigger a manual objectWillChange.send()
            // or perform a minor array modification that doesn't change content,
            // or rely on the @Published on the array itself if we were directly modifying the array.
            // Since we're modifying an item *within* the array,
            // and want the list structure to update (pinned/unpinned sections),
            // toggling the @Published property on NoteItem *should* be enough for the cell to update,
            // but the list structure requires a change to the array or its @Published status.
            // Let's rely on the @Published on the array itself for now by reassigning the array.

             // Manually send a notification before the change for list structure updates
            objectWillChange.send()


            // Toggle the state on the existing object in the array
            notes[index].isPinned.toggle()


            // Update UserDefaults
            var pinnedIDs = UserDefaults.standard.array(forKey: pinnedNotesKey) as? [String] ?? []
            let noteIDString = notes[index].id.uuidString

            if notes[index].isPinned {
                if !pinnedIDs.contains(noteIDString) {
                    pinnedIDs.append(noteIDString)
                }
            } else {
                pinnedIDs.removeAll { $0 == noteIDString }
            }

            UserDefaults.standard.set(pinnedIDs, forKey: pinnedNotesKey)
            UserDefaults.standard.synchronize() // Ensure changes are written immediately
        }
    }

    func deleteNote(note: NoteItem) {
        do {
            try FileManager.default.removeItem(at: note.url)
            // Removing from the @Published notes array will automatically
            // notify observers and update the UI.
            notes.removeAll { $0.id == note.id }

            // Also remove from pinned list if it was pinned
            var pinnedIDs = UserDefaults.standard.array(forKey: pinnedNotesKey) as? [String] ?? []
            if let index = pinnedIDs.firstIndex(of: note.id.uuidString) {
                pinnedIDs.remove(at: index)
                UserDefaults.standard.set(pinnedIDs, forKey: pinnedNotesKey)
                UserDefaults.standard.synchronize()
            }

            print("Deleted note: \(note.title) from \(note.url.path)")
        } catch {
            print("Error deleting note \(note.title): \(error)")
            // Optionally, show an alert to the user
        }
    }
} 