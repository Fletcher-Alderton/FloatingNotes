import Foundation

class NoteItem: Identifiable, Hashable, ObservableObject {
    let id: UUID
    var title: String
    let url: URL
    @Published var isPinned: Bool = false
    var lastModified: Date? // Optional: for sorting or display

    init(id: UUID, title: String, url: URL, isPinned: Bool = false, lastModified: Date? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.isPinned = isPinned
        self.lastModified = lastModified
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