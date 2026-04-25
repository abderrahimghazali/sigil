import AppKit
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 440)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: ContentView())

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let trayImage = trayIcon()
            button.image = trayImage
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func trayIcon() -> NSImage {
        if let custom = NSImage(named: "TrayIcon") {
            custom.size = NSSize(width: 18, height: 18)
            custom.isTemplate = true
            return custom
        }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let symbol = NSImage(systemSymbolName: "seal.fill", accessibilityDescription: "Sigil")?
            .withSymbolConfiguration(config) ?? NSImage()
        symbol.isTemplate = true
        return symbol
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Show", action: #selector(openFromMenu), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openFromMenu() {
        openPopover()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Launch at login toggle failed: \(error)")
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    func closePopover() {
        popover.performClose(nil)
        popover.contentViewController?.view.window?.orderOut(nil)
    }

    func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}
