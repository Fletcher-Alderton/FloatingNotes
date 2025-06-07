# How to use Floating Notes with Raycast

Replace Raycast's built-in notes with FloatingNotes for a superior floating note-taking experience that integrates seamlessly with your Raycast workflow.

## 🎯 Overview

By setting up Raycast quicklinks with FloatingNotes' URL schemes, you can:

- **Replace Raycast Notes** with beautiful floating transparent windows
- **Create notes instantly** from Raycast with a simple command
- **Open recent notes** quickly without leaving your current workflow
- **Maintain Raycast's speed** while gaining FloatingNotes' superior UI
- **Create notes with content** by passing text directly from Raycast

## 🚀 Step 1: Open Raycast Settings

1. **Open Raycast** (⌘ + Space by default)
2. **Type "Settings"** and press Enter
3. **Or use the keyboard shortcut**: `Command + ,`

![Raycast Settings](https://via.placeholder.com/400x200/FF6B35/FFFFFF?text=Raycast+%3E+Settings)

## 🔧 Step 2: Navigate to Extensions

1. **Click the "Extensions" tab** in the Raycast settings sidebar
2. **Look for the "+" button** (Add Extension/Quicklink)
3. **Click the "+" button** to create a new quicklink

![Extensions Tab](https://via.placeholder.com/400x200/FF6B35/FFFFFF?text=Extensions+Tab+%3E+Plus+Button)

## ➕ Step 3: Create New Note Quicklink

1. **Click "Create Quicklink"**
2. **Fill in the details**:
   - **Name**: `New Floating Note`
   - **Link**: `floatingnotes://create`
   - **Open With**: `Select Floating Notes in your Application folder`
   - **Description**: `Create a new floating note window`

3. **Save the quicklink**

![New Note Quicklink](https://via.placeholder.com/400x200/FF6B35/FFFFFF?text=New+Note+Quicklink+Setup)

## 📋 Step 4: Create Recent Note Quicklink

1. **Click "+" again** to add another quicklink
2. **Fill in the details**:
   - **Name**: `Recent Note`
   - **Link**: `floatingnotes://last`
   - **Open With**: `Select Floating Notes in your Application folder`
   - **Description**: `Open the most recent floating note`

3. **Save the quicklink**

## 📝 Step 5: Advanced - Create Note with Content

For power users who want to create notes with predefined content:

1. **Create another quicklink**:
   - **Name**: `Quick Meeting Note`
   - **Link**: `floatingnotes://create?content=Meeting%20Notes%20-%20{date}`
   - **Open With**: `Select Floating Notes in your Application folder`
   - **Description**: `Create a meeting note with today's date`

*Note: You can customize the content parameter with any text you want*

## 🎮 How to Use

Once set up, you can:

### Create New Note
1. **Open Raycast** (`⌘ + Space`)
2. **Type**: `New Floating Note`
3. **Press Enter** - a new floating note window appears instantly!

### Open Recent Note  
1. **Open Raycast** (`⌘ + Space`)
2. **Type**: `Recent Note`
3. **Press Enter** - your last note opens immediately

### Quick Access Tips
- **Pin frequently used quicklinks** for even faster access
- **Use aliases** like "note" or "fn" for shorter commands
- **Organize in folders** if you create multiple note-related quicklinks

## 🔗 Available URL Schemes

FloatingNotes supports these URL schemes for Raycast integration:

| URL Scheme | Purpose | Example |
|------------|---------|---------|
| `floatingnotes://create` | Create new empty note | Basic new note |
| `floatingnotes://create?content=TEXT` | Create note with content | Pre-filled notes |
| `floatingnotes://last` | Open most recent note | Quick note access |

## 🚀 Pro Tips & Advanced Usage

### Custom Content Templates
Create multiple quicklinks with different templates:

```
# Daily Standup Notes
floatingnotes://create?content=Daily%20Standup%20-%20{date}%0A%0A**Yesterday:**%0A%0A**Today:**%0A%0A**Blockers:**

# Quick Todo
floatingnotes://create?content=Todo%20-%20{date}%0A%0A-%20[ ]%20

# Meeting Notes Template
floatingnotes://create?content=Meeting:%20%0A%0ADate:%20{date}%0AAttendees:%20%0A%0A**Notes:**%0A%0A**Action%20Items:**
```

### Raycast Scripts Integration
Create Raycast scripts that use FloatingNotes URL schemes:

```bash
#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Quick Note with Clipboard
# @raycast.mode compact

clipboard_content=$(pbpaste)
encoded_content=$(echo "$clipboard_content" | sed 's/ /%20/g')
open "floatingnotes://create?content=$encoded_content"
```

### Workflow Ideas
1. **Replace Raycast Notes**: Disable Raycast's built-in notes and use FloatingNotes instead
2. **Meeting Workflow**: Create pre-formatted meeting notes from Raycast
3. **Quick Capture**: Instantly capture thoughts without breaking focus
4. **Todo Management**: Create quick todo lists that float above your work

## 🔄 Migration from Raycast Notes

If you're currently using Raycast's built-in notes:

1. **Export existing Raycast notes** (if you have important content)
2. **Disable Raycast Notes extension** in Extensions settings
3. **Set up FloatingNotes quicklinks** as described above
4. **Import content** to FloatingNotes manually or via copy-paste

## 🔧 Troubleshooting

### Quicklinks Not Working
- **Check URL scheme**: Ensure `floatingnotes://` is spelled correctly
- **Test in browser**: Try pasting the URL in Safari to test
- **Restart Raycast**: Sometimes a restart helps refresh extensions

### FloatingNotes Not Opening
- **Verify app is installed**: Make sure FloatingNotes is in Applications folder
- **Check permissions**: macOS might require permission for URL scheme handling
- **Test manually**: Try the URL scheme in Terminal: `open "floatingnotes://create"`

### URL Encoding Issues
- **Spaces**: Use `%20` for spaces in content
- **Line breaks**: Use `%0A` for new lines
- **Special characters**: URL encode special characters

## 🎉 You're All Set!

Your Raycast now integrates perfectly with FloatingNotes! You can:

✅ Create floating notes instantly from Raycast  
✅ Open recent notes with a quick command  
✅ Use custom templates for different note types  
✅ Maintain your fast Raycast workflow with superior floating notes  

**Enjoy your supercharged note-taking workflow!** ⚡📝

---

*Pro tip: Consider setting up keyboard shortcuts in FloatingNotes settings for even faster access outside of Raycast!*