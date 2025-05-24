import Foundation
import Combine

class NotesManager: ObservableObject {
    @Published var notes: [NoteItem] = []
    private let pinnedNotesKey = "pinnedNoteIDs" // UserDefaults key

    init() {
        loadNotes()
    }

    func getAppNotesDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("FloatingNotesApp")
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