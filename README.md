# FloatingNotes

A macOS app for creating floating note windows.

## URL Schemes

FloatingNotes supports URL schemes that allow other apps to interact with it programmatically.

### URL Scheme Format

The URL scheme is `floatingnotes://`

### Supported Actions

#### Create a New Note

Create a new empty note:
```
floatingnotes://new
floatingnotes://create
floatingnotes:///new
floatingnotes:///create
```

Create a new note with initial content:
```
floatingnotes://new?text=Your%20note%20content%20here
floatingnotes://create?content=Your%20note%20content%20here
```

#### Open Most Recent Note

Open the most recently modified note:
```
floatingnotes://recent
floatingnotes://last
floatingnotes:///recent
floatingnotes:///last
```

### Examples

#### From Terminal/Scripts

```bash
# Create a new empty note
open "floatingnotes://new"

# Create a note with content
open "floatingnotes://new?text=Meeting%20notes%20for%20today"

# Open the most recent note
open "floatingnotes://recent"
```

#### From Other Apps

You can use these URLs in:
- Alfred workflows
- Raycast extensions
- AppleScript
- Shortcuts app
- Any app that can open URLs

#### AppleScript Example

```applescript
tell application "System Events"
    open location "floatingnotes://new?text=Quick%20note%20from%20AppleScript"
end tell
```

#### Shortcuts App

1. Add a "Open URLs" action
2. Set the URL to `floatingnotes://new?text=Your note text here`
3. Run the shortcut

### URL Encoding

Remember to URL-encode special characters in the text parameter:
- Spaces: `%20`
- Newlines: `%0A`
- Special characters should be properly encoded

### Features

- **Floating Windows**: Notes appear as floating windows that stay on top
- **Cross-Space**: Notes follow you across different desktop spaces
- **Auto-Save**: Notes are automatically saved as you type
- **Keyboard Shortcuts**: Global shortcuts for quick note creation
- **URL Integration**: Create and access notes from other applications

## Features

### Notes Storage
- **Customizable Storage Location**: Choose where your notes are stored on your system
- **Default Location**: `~/Documents/FloatingNotesApp/`
- **Migration Support**: Automatically migrate existing notes when changing storage location
- **Flexible Options**: Change location with or without migrating existing notes

### Keyboard Shortcuts
- **Create New Note**: Cmd+Shift+N (configurable)
- **Open Recent Note**: Cmd+Shift+O (configurable)
- **Show All Notes**: Cmd+Shift+L
- **Toggle Shortcuts**: Enable/disable individual shortcuts in Settings

### Note Management
- **Pin/Unpin Notes**: Keep important notes at the top of your list
- **Search**: Quickly find notes by title
- **Auto-save**: Notes are automatically saved as you type
- **Markdown Support**: Notes are saved as `.md` files

## Settings

Access settings through the app menu or by pressing Cmd+, (when implemented).

### Notes Storage Settings
1. **View Current Location**: See where your notes are currently stored
2. **Change Location**: Select a new folder for storing notes
3. **Migration Options**:
   - **Migrate**: Copy existing notes to the new location
   - **Change Without Migrating**: Start fresh in the new location
4. **Reset to Default**: Return to the default storage location

### Keyboard Shortcuts Settings
- Enable/disable individual shortcuts
- Customize key combinations
- System-wide shortcuts work when the app is running

## File Format

Notes are stored as Markdown files with the naming convention:
```
[Note Title]_[UUID].md
```

This ensures unique filenames while maintaining readable titles.

## Requirements

- macOS 15.4 or later
- Sandbox permissions for file access

## Privacy

The app only accesses:
- The selected notes storage directory
- User-selected folders (when changing storage location)
- No network access or data collection 