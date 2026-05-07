import AppKit
import SwiftUI

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = item.button {
            let iconImage: NSImage? = {
                if let url = Bundle.module.url(forResource: "menu-icon", withExtension: "svg") {
                    let img = NSImage(contentsOf: url)
                    img?.isTemplate = true
                    return img
                }
                return nil
            }()
            button.image = iconImage ?? NSImage(
                systemSymbolName: "eyedropper",
                accessibilityDescription: "取色器"
            )?.withSymbolConfiguration(
                NSImage.SymbolConfiguration(paletteColors: [NSColor.white])
            )
            button.action = #selector(togglePopover)
            button.target = self
        }

        statusItem = item

        let p = NSPopover()
        p.contentSize = NSSize(width: 300, height: 580)
        p.behavior = .transient
        p.contentViewController = NSHostingController(rootView: ColorPanelView())
        popover = p
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func showPopover() {
        guard let button = statusItem?.button, let popover, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func closePopover() {
        popover?.performClose(nil)
    }
}
