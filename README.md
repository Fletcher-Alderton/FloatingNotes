# FloatingNotes

A macOS app for creating and managing floating notes with customizable storage locations.

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