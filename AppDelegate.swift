import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    private var spotifyManager = SpotifyManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupOverlayWindow()
        startSpotifyTracking()
    }
    
    private func setupOverlayWindow() {
        // Create the overlay window
        overlayWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 380, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties for notification-like behavior
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = NSColor.clear
        overlayWindow.hasShadow = false
        overlayWindow.level = .statusBar
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.sharingType = .none
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.acceptsMouseMovedEvents = true
        overlayWindow.isMovableByWindowBackground = true
        
        // Set content view
        let contentView = SpotifyOverlayView()
            .environmentObject(spotifyManager)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        overlayWindow.contentView = hostingView
        
        // Position window like a macOS notification (top-right corner)
        positionAsNotification()
        
        overlayWindow.makeKeyAndOrderFront(nil)
        overlayWindow.orderFrontRegardless()
        
        // Monitor for notification center changes
        setupNotificationMonitoring()
    }
    
    private func positionAsNotification() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = CGSize(width: 380, height: 100)
        
        // Position in bottom right with proper spacing
        let padding: CGFloat = 20
        let x = screenFrame.maxX - windowSize.width - padding
        let y = screenFrame.minY + padding
        
        overlayWindow.setFrame(
            NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height),
            display: true
        )
    }
    
    private func setupNotificationMonitoring() {
        // Monitor for screen changes but don't automatically reposition
        // Let user control positioning after initial setup
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Only reposition if window is off-screen
            guard let self = self, let window = self.overlayWindow else { return }
            
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                
                // Only reposition if completely off-screen
                if !screenFrame.intersects(windowFrame) {
                    self.positionAsNotification()
                }
            }
        }
    }
    
    private func startSpotifyTracking() {
        spotifyManager.startTracking()
    }
}