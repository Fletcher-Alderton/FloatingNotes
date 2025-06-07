import Foundation

class NoteItem: Identifiable, Hashable, ObservableObject {
    let id: UUID
    var title: String
    var url: URL // Changed from let to var to allow URL updates when files are renamed
    @Published var isPinned: Bool = false
    var lastModified: Date? // Optional: for sorting or display
    var wordCount: Int // Total word count of the note's content

    init(id: UUID, title: String, url: URL, isPinned: Bool = false, lastModified: Date? = nil, wordCount: Int = 0) {
        self.id = id
        self.title = title
        self.url = url
        self.isPinned = isPinned
        self.lastModified = lastModified
        self.wordCount = wordCount
    }

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Implement Equatable for Hashable
    static func == (lhs: NoteItem, rhs: NoteItem) -> Bool {
        lhs.id == rhs.id
    }
} 