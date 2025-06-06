import SwiftUI
import AppKit

class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    
    private override init() {
        super.init()
    }
    
    func setupMenuBar() {
        // Create status item if it doesn't exist
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            
            if let button = statusItem?.button {
                // Set the menu bar icon
                button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Floating Notes")
                button.imagePosition = .imageOnly
                button.toolTip = "Floating Notes"
                
                // Set action for button click to show SwiftUI menu
                button.action = #selector(showSwiftUIMenu)
                button.target = self
            }
        }
    }
    
    @objc private func showSwiftUIMenu() {
        // Create a SwiftUI menu using MenuBarMenu
        let menuView = MenuBarMenu()
        let hostingView = NSHostingView(rootView: menuView)
        
        // Create a popover to show the SwiftUI menu
        let popover = NSPopover()
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostingView
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 200, height: 250)
        
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func removeMenuBar() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    @objc private func createNewNote() {
        WindowManager.shared.addNewNoteWindow()
    }
    
    @objc private func openRecentNote() {
        WindowManager.shared.openLastNoteOrCreateNew()
    }
    
    @objc private func showAllNotes() {
        WindowManager.shared.showNotesListWindow()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// SwiftUI Menu for the Menu Bar
struct MenuBarMenu: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // New Note
            Button(action: {
                WindowManager.shared.addNewNoteWindow()
                hideMenu()
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("New Note")
                    Spacer()
                    Text("⌘N")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(MenuButtonStyle())
            
            // Open Recent Note
            Button(action: {
                WindowManager.shared.openLastNoteOrCreateNew()
                hideMenu()
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text("Open Recent Note")
                    Spacer()
                    Text("⌘R")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(MenuButtonStyle())
            
            // Show All Notes
            Button(action: {
                WindowManager.shared.showNotesListWindow()
                hideMenu()
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Show All Notes")
                    Spacer()
                    Text("⌘⇧L")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(MenuButtonStyle())
            
            Divider()
                .background(Color.secondary.opacity(0.3))
            
            // Settings using SettingsLink with default system label
            SettingsLink()
                .buttonStyle(MenuButtonStyle())
            
            // Alternative: Settings using SettingsLink with custom label
            // SettingsLink {
            //     HStack {
            //         Image(systemName: "gear")
            //         Text("Settings...")
            //         Spacer()
            //         Text("⌘,")
            //             .foregroundColor(.secondary)
            //             .font(.caption)
            //     }
            // }
            // .buttonStyle(MenuButtonStyle())
            
            Divider()
                .background(Color.secondary.opacity(0.3))
            
            // Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Floating Notes")
                    Spacer()
                    Text("⌘Q")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(MenuButtonStyle())
        }
        .padding(.vertical, 8)
        .frame(width: 200)
        .background(
            VisualEffectView()
        )
    }
    
    private func hideMenu() {
        // Close any open popovers
        NSApplication.shared.windows.forEach { window in
            if let popover = window.contentViewController?.presentedViewControllers?.first as? NSViewController,
               popover.view is NSHostingView<MenuBarMenu> {
                window.close()
            }
        }
    }
}

// Custom button style for menu items
struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                configuration.isPressed ? 
                Color.accentColor.opacity(0.2) : 
                Color.clear
            )
            .foregroundColor(.primary)
            .font(.system(size: 13))
    }
}