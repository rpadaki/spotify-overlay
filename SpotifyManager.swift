import Foundation
import SwiftUI

struct SpotifyTrack: Equatable {
    let name: String
    let artist: String
    let album: String
    let artworkURL: String?
    let isPlaying: Bool
    let position: Double // Current position in seconds
    let duration: Double // Total duration in seconds
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(position / duration, 1.0)
    }
    
    static let empty = SpotifyTrack(
        name: "No track playing",
        artist: "",
        album: "",
        artworkURL: nil,
        isPlaying: false,
        position: 0,
        duration: 0
    )
}

class SpotifyManager: ObservableObject {
    @Published var currentTrack = SpotifyTrack.empty
    @Published var isSpotifyRunning = false
    
    private var timer: Timer?
    private var lastTrackUpdate = Date()
    private var basePosition: Double = 0
    private var baseUpdateTime = Date()
    
    func startTracking() {
        // Single timer for all updates - faster polling for better responsiveness
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            self.updateCurrentTrack()
        }
        updateCurrentTrack()
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }
    
    func forceUpdate() {
        updateCurrentTrack()
    }
    
    func togglePlayPause() {
        let script = """
        tell application "Spotify"
            playpause
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            // Immediately update after the action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateCurrentTrack()
            }
        }
    }
    
    func seekToPosition(_ position: Double) {
        let script = """
        tell application "Spotify"
            set player position to \(position)
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            // Update position immediately
            DispatchQueue.main.async {
                self.basePosition = position
                self.baseUpdateTime = Date()
            }
            
            // Force a full update after seeking
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.updateCurrentTrack()
            }
        }
    }
    
    private func updateCurrentTrack() {
        DispatchQueue.global(qos: .background).async {
            let track = self.getCurrentSpotifyTrack()
            DispatchQueue.main.async {
                let now = Date()
                
                // Only update if track actually changed or it's been more than 2 seconds
                let trackChanged = track.name != self.currentTrack.name || 
                                 track.artist != self.currentTrack.artist ||
                                 track.isPlaying != self.currentTrack.isPlaying
                
                if trackChanged || now.timeIntervalSince(self.lastTrackUpdate) > 2.0 {
                    self.lastTrackUpdate = now
                    self.basePosition = track.position
                    self.baseUpdateTime = now
                    
                    if trackChanged {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.currentTrack = track
                        }
                    } else {
                        // Just update position without animation
                        self.currentTrack = track
                    }
                } else if track.isPlaying {
                    // Interpolate position smoothly for playing tracks
                    let timeDelta = now.timeIntervalSince(self.baseUpdateTime)
                    let interpolatedPosition = min(self.basePosition + timeDelta, track.duration)
                    
                    self.currentTrack = SpotifyTrack(
                        name: self.currentTrack.name,
                        artist: self.currentTrack.artist,
                        album: self.currentTrack.album,
                        artworkURL: self.currentTrack.artworkURL,
                        isPlaying: self.currentTrack.isPlaying,
                        position: interpolatedPosition,
                        duration: self.currentTrack.duration
                    )
                }
            }
        }
    }
    
    private func getCurrentSpotifyTrack() -> SpotifyTrack {
        let script = """
        tell application "System Events"
            if (exists process "Spotify") then
                tell application "Spotify"
                    if player state is playing then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set artworkUrl to artwork url of current track
                        set trackPosition to (player position as string)
                        set trackDuration to (duration of current track / 1000 as string)
                        return trackName & "|" & artistName & "|" & albumName & "|" & artworkUrl & "|playing|" & trackPosition & "|" & trackDuration
                    else if player state is paused then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set artworkUrl to artwork url of current track
                        set trackPosition to (player position as string)
                        set trackDuration to (duration of current track / 1000 as string)
                        return trackName & "|" & artistName & "|" & albumName & "|" & artworkUrl & "|paused|" & trackPosition & "|" & trackDuration
                    else
                        return "||||||||stopped"
                    end if
                end tell
            else
                return "||||||||not_running"
            end if
        end tell
        """
        
        guard let appleScript = NSAppleScript(source: script) else {
            return SpotifyTrack.empty
        }
        
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        
        if let error = error {
            let errorCode = error["NSAppleScriptErrorNumber"] as? Int ?? 0
            if errorCode == -1751 {
                // Spotify is not running or object doesn't exist
                DispatchQueue.main.async {
                    self.isSpotifyRunning = false
                }
                return SpotifyTrack.empty
            } else {
                print("AppleScript error: \(error)")
                return SpotifyTrack.empty
            }
        }
        
        guard let resultString = result.stringValue else {
            return SpotifyTrack.empty
        }
        
        let components = resultString.components(separatedBy: "|")
        guard components.count >= 7 else {
            return SpotifyTrack.empty
        }
        
        let state = components[4]
        
        if state == "not_running" {
            DispatchQueue.main.async {
                self.isSpotifyRunning = false
            }
            return SpotifyTrack.empty
        }
        
        DispatchQueue.main.async {
            self.isSpotifyRunning = true
        }
        
        if state == "stopped" {
            return SpotifyTrack.empty
        }
        
        let position = Double(components[5]) ?? 0
        let duration = Double(components[6]) ?? 0
        
        return SpotifyTrack(
            name: components[0].isEmpty ? "Unknown Track" : components[0],
            artist: components[1].isEmpty ? "Unknown Artist" : components[1],
            album: components[2].isEmpty ? "Unknown Album" : components[2],
            artworkURL: components[3].isEmpty ? nil : components[3],
            isPlaying: state == "playing",
            position: position,
            duration: duration
        )
    }
}