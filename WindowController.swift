import SwiftUI
import AppKit

class WindowController: ObservableObject {
    @Published var isVisible = true
    @Published var opacity: Double = 1.0
    @Published var isDismissed = false
    
    private var hideTimer: Timer?
    private var dismissTimer: Timer?
    private var lastInteractionTime = Date()
    
    func resetHideTimer() {
        lastInteractionTime = Date()
        hideTimer?.invalidate()
        
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.opacity = 0.4
                }
            }
        }
    }
    
    func showWindow() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 1.0
            isVisible = true
        }
        resetHideTimer()
    }
    
    func hideWindow() {
        withAnimation(.easeInOut(duration: 0.5)) {
            opacity = 0.0
        }
    }
    
    func dismissForOneMinute() {
        hideTimer?.invalidate()
        dismissTimer?.invalidate()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isDismissed = true
        }
        
        // Re-enable after 1 minute
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isDismissed = false
                }
                self.showWindow()
            }
        }
    }
}