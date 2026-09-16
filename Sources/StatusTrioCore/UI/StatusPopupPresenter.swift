import AppKit

/// A transparent window lets glass sample the desktop instead of an opaque
/// NSPopover background. Older systems keep the native popover implementation.
@MainActor
final class StatusPopupPresenter: NSObject, NSPopoverDelegate, NSWindowDelegate {
    private let legacy = NSPopover()
    private var panel: GlassPanel?
    private var container: PopupContentController?
    private var anchorRect = NSRect.zero
    private var availableFrame = NSRect.zero
    private var edge: NSRectEdge = .minY
    var onClose: (() -> Void)?

    var contentViewController: NSViewController? {
        didSet {
            if Self.usesGlassPanel {
                container = contentViewController.map { PopupContentController(content: $0) }
                container?.sizeChanged = { [weak self] size in self?.resize(to: size) }
                panel?.contentViewController = container
            } else {
                legacy.contentViewController = contentViewController
            }
        }
    }

    static var usesGlassPanel: Bool {
#if compiler(>=6.2)
        if #available(macOS 26.0, *) { return true }
#endif
        return false
    }

    override init() {
        super.init()
        legacy.behavior = .transient
        legacy.delegate = self
    }

    var isShown: Bool { Self.usesGlassPanel ? panel?.isVisible == true : legacy.isShown }

    func show(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge) {
        guard Self.usesGlassPanel else {
            legacy.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
            return
        }
        guard let window = view.window, let container else { return }
        anchorRect = window.convertToScreen(view.convert(rect, to: nil))
        let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: anchorRect.midX, y: anchorRect.midY)) }
            ?? window.screen ?? NSScreen.main
        guard let screen else { return }
        availableFrame = screen.visibleFrame.insetBy(dx: 6, dy: 6)
        edge = preferredEdge

        if panel == nil {
            let newPanel = GlassPanel(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.appearance = NSAppearance(named: .darkAqua)
            newPanel.hasShadow = false // Each glass surface casts its own shadow.
            newPanel.isReleasedWhenClosed = false
            newPanel.isExcludedFromWindowsMenu = true
            newPanel.hidesOnDeactivate = false
            newPanel.level = .popUpMenu
            newPanel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient, .ignoresCycle]
            newPanel.delegate = self
            newPanel.onCancel = { [weak self] in self?.performClose(nil) }
            newPanel.title = "Status Trio"
            panel = newPanel
        }
        panel?.contentViewController = container
        container.view.layoutSubtreeIfNeeded()
        resize(to: container.contentSize)
        panel?.makeKeyAndOrderFront(nil)
    }

    func performClose(_ sender: Any?) {
        guard Self.usesGlassPanel else {
            legacy.performClose(sender)
            return
        }
        guard let panel, panel.isVisible else { return }
        panel.orderOut(sender)
        onClose?()
    }

    func popoverDidClose(_ notification: Notification) { onClose?() }

    func windowDidResignKey(_ notification: Notification) {
        // Password sheets must remain usable when they take keyboard focus.
        guard panel?.attachedSheet == nil else { return }
        performClose(nil)
    }

    private func resize(to size: NSSize) {
        guard let panel, size.width > 0, size.height > 0,
              size.width.isFinite, size.height.isFinite else { return }
        let frame = Self.frame(size: size, anchor: anchorRect, available: availableFrame, edge: edge)
        if panel.frame != frame { panel.setFrame(frame, display: panel.isVisible) }
    }

    static func frame(size: NSSize, anchor: NSRect, available: NSRect, edge: NSRectEdge) -> NSRect {
        let width = min(size.width, available.width)
        let height = min(size.height, available.height)
        var x = anchor.midX - width / 2
        var y = anchor.minY - height - 4
        switch edge {
        case .maxY: y = anchor.maxY + 4
        case .minX: x = anchor.minX - width - 4; y = anchor.midY - height / 2
        case .maxX: x = anchor.maxX + 4; y = anchor.midY - height / 2
        default: break
        }
        return NSRect(x: min(max(x, available.minX), available.maxX - width),
                      y: min(max(y, available.minY), available.maxY - height),
                      width: width, height: height)
    }
}

@MainActor
private final class GlassPanel: NSPanel {
    var onCancel: (() -> Void)?
    override var canBecomeKey: Bool { true }
    // This is the app's primary surface while open, so activation and
    // accessibility clients can focus it without resurrecting Settings.
    override var canBecomeMain: Bool { true }
    override func cancelOperation(_ sender: Any?) { onCancel?() }
}

@MainActor
private final class PopupContentController: NSViewController {
    let content: NSViewController
    var sizeChanged: ((NSSize) -> Void)?
    private var sizeObservation: NSKeyValueObservation?
    var contentSize: NSSize {
        let preferred = content.preferredContentSize
        return preferred.width > 0 && preferred.height > 0 ? preferred : content.view.fittingSize
    }

    init(content: NSViewController) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
        addChild(content)
        sizeObservation = content.observe(\.preferredContentSize, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.sizeChanged?(self.contentSize)
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        view = NSView()
        content.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content.view)
        NSLayoutConstraint.activate([
            content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.view.topAnchor.constraint(equalTo: view.topAnchor),
            content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func preferredContentSizeDidChange(for viewController: NSViewController) {
        super.preferredContentSizeDidChange(for: viewController)
        sizeChanged?(contentSize)
    }
}
