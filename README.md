# FloatingNotes

A lightweight, elegant macOS app for quick note-taking with floating, transparent windows that integrate seamlessly with your desktop workflow.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.5+-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green)

## ✨ Features

### 🪟 Floating Transparent Windows
- **Beautiful blurry transparency** that blends with your desktop
- **Always-on-top floating windows** that stay visible across all apps
- **Multi-space support** - notes appear on all desktop spaces
- **Intelligent window placement** with smart positioning for multiple windows

### ⚡ Quick Access
- **Global keyboard shortcuts** for instant note creation
- **URL scheme support** for automation and integrations
- **Menu bar integration** with quick access menu
- **Dock or menu bar only** display options

### 📝 Smart Note Management
- **Auto-save functionality** - your notes are saved automatically
- **Markdown support** with live preview
- **Pin important notes** to keep them accessible
- **Notes list view** with search and organization
- **Custom storage locations** - choose where your notes are saved

### Intergrations
- **Use with racast to replace raycast notes** - [Guide here] (./FloatingNotes/Raycast.md)
- **Store notes in obsidain** - [Guide here] (./FloatingNotes/Obsidian.md)

## 🚀 Getting Started

### Installation

1. Download the latest release from the [Releases](../../releases) page
2. Drag FloatingNotes.app to your Applications folder
3. Launch the app and grant necessary permissions

### First Launch

On first launch, FloatingNotes will:
- Create a notes directory in `~/Documents/FloatingNotesApp/`
- Set up default keyboard shortcuts
- Display your first floating note window

## ⌨️ Keyboard Shortcuts

| Action | Default Shortcut | Customizable |
|--------|------------------|--------------|
| Create New Note | `⌘⇧N` | ✅ |
| Open Recent Note | `⌘⇧O` | ✅ |

*Shortcuts can be customized in Settings → Keyboard Shortcuts*

## 🔗 URL Scheme Integration

FloatingNotes supports URL schemes for automation and integration with other apps:

### Create New Note
```
floatingnotes://create
```

### Create Note with Content
```
floatingnotes://create?content=Your%20note%20content
```

### Open Recent Note
```
floatingnotes://last
```

## ⚙️ Settings & Customization

Access settings through the menu bar icon or the application menu:

### 📁 Storage Settings
- **Custom storage location** - choose where notes are saved
- **Note migration** - easily move existing notes to new locations
- **Directory management** with automatic folder creation

### 📌 Pin Notes
- **Pin important notes** to keep them easily accessible
- **Pinned notes management** in the notes list view

### 🖥️ App Display
- **Menu bar mode** - run quietly in the menu bar
- **Dock mode** - traditional dock icon behavior
- **Toggle between modes** without restarting

### ⌨️ Keyboard Shortcuts
- **Enable/disable shortcuts** individually
- **Custom key combinations** for all actions
- **Real-time shortcut testing**

## 🛠️ Development

### Requirements
- macOS 14.0+
- Xcode 13.0+
- Swift 5.5+

### Dependencies
- **KeyboardShortcuts** - Global keyboard shortcut management
- **SwiftDown** - Markdown parsing and rendering
- **SwiftUI** - Modern UI framework
- **AppKit** - Native macOS window management

### Project Structure
```
FloatingNotes/
├── FloatingNotesApp.swift          # Main app entry point
├── ContentView.swift               # Note window UI
├── WindowManager.swift             # Window lifecycle management
├── NotesManager.swift              # Note data management
├── SettingsView.swift              # Settings interface
├── NotesListView.swift             # Notes browser
├── MenuBarManager.swift            # Menu bar integration
└── Supporting/
    ├── KeyboardShortcutNames.swift
    ├── MenuCommands.swift
    └── AppDisplayManager.swift
```

### Building
1. Clone the repository
2. Open `FloatingNotes.xcodeproj` in Xcode
3. Build and run (⌘R)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bugs and feature requests.

### Areas for Contribution
- UI/UX improvements
- Additional keyboard shortcuts
- Export/import functionality
- Theme customization
- Plugin system

## 📄 License

This project is available under the MIT License. See LICENSE file for details.

## 🙏 Acknowledgments

- Built with ❤️ for the macOS community
- Inspired by the need for seamless, non-intrusive note-taking
- Special thanks to the SwiftUI and AppKit communities 

---

**FloatingNotes** - Where your thoughts float freely on your desktop ✨ 