import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()

        if AccountsManager.shared.accounts.isEmpty {
            AccountsManager.shared.addAccount(Account(
                name: "Test Account",
                issuer: "Autificator",
                secret: "JAGLM27RZ5FQAROV2M3B5PBLVBSHFNKV"
            ))
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            // Use SF Symbol - crisp at any size
            if let image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: "Autificator") {
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageOnly
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}