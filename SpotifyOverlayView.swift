import SwiftUI

struct SpotifyOverlayView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @StateObject private var windowController = WindowController()
    @State private var isVisible = true
    @State private var artworkImage: NSImage?
    @State private var isHovered = false
    @State private var isArtworkHovered = false
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var dominantColor: Color = .clear
    @State private var initialWindowFrame: CGRect = .zero
    @State private var isColorFlashing = false
    
    private func extractDominantColor(from image: NSImage) -> Color {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .clear
        }
        
        let width = 50
        let height = 50
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return .clear
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var red: UInt64 = 0
        var green: UInt64 = 0
        var blue: UInt64 = 0
        var pixelCount: UInt64 = 0
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            red += UInt64(pixelData[i])
            green += UInt64(pixelData[i + 1])
            blue += UInt64(pixelData[i + 2])
            pixelCount += 1
        }
        
        let avgRed = Double(red) / Double(pixelCount) / 255.0
        let avgGreen = Double(green) / Double(pixelCount) / 255.0
        let avgBlue = Double(blue) / Double(pixelCount) / 255.0
        
        return Color(red: avgRed, green: avgGreen, blue: avgBlue)
    }
    
    private func snapToEdgeOrCorner(window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        let windowSize = windowFrame.size
        let padding: CGFloat = 20
        let snapThreshold: CGFloat = 80
        
        var newX = windowFrame.origin.x
        var newY = windowFrame.origin.y
        
        // Snap to left or right edge
        if windowFrame.origin.x < screenFrame.origin.x + snapThreshold {
            newX = screenFrame.origin.x + padding
        } else if windowFrame.origin.x + windowSize.width > screenFrame.maxX - snapThreshold {
            newX = screenFrame.maxX - windowSize.width - padding
        }
        
        // Snap to top or bottom edge
        if windowFrame.origin.y < screenFrame.origin.y + snapThreshold {
            newY = screenFrame.origin.y + padding
        } else if windowFrame.origin.y + windowSize.height > screenFrame.maxY - snapThreshold {
            newY = screenFrame.maxY - windowSize.height - padding
        }
        
        let newOrigin = CGPoint(x: newX, y: newY)
        window.setFrameOrigin(newOrigin)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HStack(spacing: 12) {
                // Album artwork with click to play/pause
                Button(action: {
                    windowController.showWindow()
                    spotifyManager.togglePlayPause()
                }) {
                    ZStack {
                        AlbumArtworkView(
                            artworkURL: spotifyManager.currentTrack.artworkURL,
                            image: $artworkImage,
                            isHovered: isHovered || isColorFlashing
                        )
                        
                        // Play/pause overlay on hover
                        if isArtworkHovered {
                            Image(systemName: spotifyManager.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isArtworkHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isArtworkHovered)
                .onHover { hovering in
                    isArtworkHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                
                // Track information
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spotifyManager.currentTrack.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text(spotifyManager.currentTrack.artist)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .onTapGesture(count: 2) {
                            windowController.dismissForOneMinute()
                        }
                        
                        Spacer()
                        
                        // Music visualizer or flat bars when paused
                        if spotifyManager.currentTrack.isPlaying {
                            MusicVisualizerView()
                        } else {
                            MusicVisualizerView(isPlaying: false) // Show flat bars when paused
                        }
                    }
                    
                    // Progress bar (clickable for seeking)
                    ProgressBarView(
                        progress: spotifyManager.currentTrack.progress,
                        position: spotifyManager.currentTrack.position,
                        duration: spotifyManager.currentTrack.duration,
                        onSeek: { position in
                            windowController.showWindow()
                            spotifyManager.seekToPosition(position)
                            // Force immediate update after seeking
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                spotifyManager.forceUpdate()
                            }
                        }
                    )
                }
                
                Spacer(minLength: 8)
            }
        }
        .padding(16)
        .frame(maxWidth: 380, minHeight: 100)
        .background(
            GlassBackgroundView(
                dominantColor: (isHovered || isColorFlashing) ? dominantColor : .clear
            )
            .onTapGesture(count: 2) {
                windowController.dismissForOneMinute()
            }
        )
        .opacity(windowController.isDismissed ? 0.0 : (isVisible ? (isHovered ? 1.0 : max(0.6, windowController.opacity)) : 0.0))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
        .animation(.easeInOut(duration: 0.3), value: isHovered)
        .animation(.easeInOut(duration: 0.4), value: isColorFlashing)
        .highPriorityGesture(
            TapGesture(count: 2)
                .onEnded {
                    windowController.dismissForOneMinute()
                }
        )
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                windowController.showWindow()
            } else {
                windowController.resetHideTimer()
            }
        }
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        windowController.showWindow()
                        
                        // Store initial window frame when drag starts
                        if let window = NSApplication.shared.windows.first(where: { $0.contentView is NSHostingView<SpotifyOverlayView> }) {
                            initialWindowFrame = window.frame
                        }
                    }
                    
                    // Move window smoothly based on initial position
                    if let window = NSApplication.shared.windows.first(where: { $0.contentView is NSHostingView<SpotifyOverlayView> }) {
                        let newOrigin = CGPoint(
                            x: initialWindowFrame.origin.x + value.translation.width,
                            y: initialWindowFrame.origin.y - value.translation.height
                        )
                        
                        // Ensure window stays within screen bounds
                        if let screen = NSScreen.main {
                            let screenFrame = screen.visibleFrame
                            let clampedX = max(screenFrame.minX, min(screenFrame.maxX - window.frame.width, newOrigin.x))
                            let clampedY = max(screenFrame.minY, min(screenFrame.maxY - window.frame.height, newOrigin.y))
                            
                            window.setFrameOrigin(CGPoint(x: clampedX, y: clampedY))
                        }
                    }
                }
                .onEnded { value in
                    isDragging = false
                    
                    // Snap to edge/corner after drag ends
                    if let window = NSApplication.shared.windows.first(where: { $0.contentView is NSHostingView<SpotifyOverlayView> }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                self.snapToEdgeOrCorner(window: window)
                            }
                        }
                    }
                }
        )
        .onChange(of: spotifyManager.currentTrack.name) { _ in
            // Only animate when track name changes (new song)
            windowController.showWindow()
            
            // Trigger color flash
            isColorFlashing = true
            
            withAnimation(.easeInOut(duration: 0.15)) {
                isVisible = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
            
            // End color flash after brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isColorFlashing = false
                }
            }
        }
        .onChange(of: artworkImage) { image in
            if let image = image {
                dominantColor = extractDominantColor(from: image)
            } else {
                dominantColor = .clear
            }
        }
        .onChange(of: spotifyManager.currentTrack.isPlaying) { isPlaying in
            if isPlaying {
                // Briefly activate panel when play starts
                windowController.showWindow()
            }
        }
    }
}

struct GlassBackgroundView: View {
    let dominantColor: Color
    
    init(dominantColor: Color = .clear) {
        self.dominantColor = dominantColor
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .fill(dominantColor.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                dominantColor == .clear ? Color.white.opacity(0.4) : dominantColor.opacity(0.6),
                                dominantColor == .clear ? Color.white.opacity(0.1) : dominantColor.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct AlbumArtworkView: View {
    let artworkURL: String?
    @Binding var image: NSImage?
    let isHovered: Bool
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipped()
                    .grayscale(isHovered ? 0.0 : 1.0) // Color on hover, grayscale otherwise
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .onChange(of: artworkURL) { newURL in
            loadArtwork(from: newURL)
        }
        .onAppear {
            loadArtwork(from: artworkURL)
        }
    }
    
    private func loadArtwork(from urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              !isLoading else {
            image = nil
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                defer { isLoading = false }
                
                guard let data = data,
                      let nsImage = NSImage(data: data) else {
                    image = nil
                    return
                }
                
                image = nsImage
            }
        }.resume()
    }
}

struct ProgressBarView: View {
    let progress: Double
    let position: Double
    let duration: Double
    let onSeek: ((Double) -> Void)?
    
    @State private var isHovered = false
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Progress bar with large hit area
            GeometryReader { geometry in
                ZStack {
                    // Actual progress bar - always same size, centered vertically
                    VStack {
                        Spacer()
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(Color.primary)
                                .frame(width: geometry.size.width * progress, height: 6)
                                .animation(.linear(duration: 0.2), value: progress)
                        }
                        .allowsHitTesting(false) // Let clicks pass through to hit area below
                        Spacer()
                    }
                    
                    // Large invisible hit area for easier clicking - on top
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isHovered = hovering
                            if hovering {
                                NSCursor.pointingHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                        .onTapGesture { location in
                            let seekProgress = location.x / geometry.size.width
                            let seekPosition = seekProgress * duration
                            onSeek?(seekPosition)
                        }
                }
            }
            .frame(height: 20) // Large hit area for easy clicking
            
            // Time labels
            HStack {
                Text(formatTime(position))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MusicVisualizerView: View {
    let isPlaying: Bool
    @State private var animationValues: [CGFloat] = Array(repeating: 0.3, count: 5)
    @State private var timer: Timer?
    
    init(isPlaying: Bool = true) {
        self.isPlaying = isPlaying
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.primary.opacity(0.8),
                                Color.primary.opacity(0.4)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: isPlaying ? 4 + animationValues[index] * 12 : 4)
                    .animation(
                        isPlaying ? 
                        .easeInOut(duration: Double.random(in: 0.3...0.7)).repeatForever(autoreverses: true) :
                        .none,
                        value: animationValues[index]
                    )
            }
        }
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startAnimation()
            } else {
                timer?.invalidate()
                // Reset to flat bars
                animationValues = Array(repeating: 0.0, count: 5)
            }
        }
    }
    
    private func startAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in animationValues.indices {
                animationValues[i] = CGFloat.random(in: 0.2...1.0)
            }
        }
    }
}

struct PlaybackIndicator: View {
    let isPlaying: Bool
    
    var body: some View {
        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
    }
}