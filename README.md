# Spotify Overlay

> **Disclaimer**: This whole thing was vibecoded but it does seem to work

A beautiful floating Spotify overlay for macOS that shows your currently playing track with a glass aesthetic.

## Features

- **Glass Design**: Translucent panel with grayscale album artwork
- **Color on Hover**: Album art becomes colorful and panel tints with dominant color when hovered
- **Drag & Snap**: Drag to reposition, automatically snaps to screen edges/corners
- **Interactive**: Click album art to play/pause, click progress bar to seek
- **Auto-fade**: Fades to 60% opacity after 2 seconds, full opacity on hover/interaction
- **Song Change Flash**: Brief color burst when new songs start
- **Double-click Dismiss**: Double-click anywhere to hide for 1 minute
- **Smart Positioning**: Defaults to bottom-right, stays within screen bounds

## Installation

### Option 1: Download Release (Recommended)
1. Download the latest `.dmg` from [Releases](../../releases)
2. Mount the DMG and drag `SpotifyOverlay.app` to Applications
3. Launch the app (it will request accessibility permissions)
4. Optional: Add to Login Items in System Preferences for auto-start

### Option 2: Build from Source
```bash
git clone https://github.com/yourusername/spotify-overlay.git
cd spotify-overlay
swift run
```

The app runs silently in the background and only appears when Spotify is running.

## Controls

- **Hover**: Full opacity + color mode
- **Click Album**: Play/pause toggle  
- **Click Progress Bar**: Seek to position
- **Drag Panel**: Move and auto-snap to edges
- **Double-click**: Dismiss for 1 minute

That's it! 🎵