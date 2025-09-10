# Spotify Overlay

A beautiful, glass-styled overlay that displays information about your currently playing Spotify track. Positioned like a macOS notification, it floats elegantly on top of all applications and shows:

- **Grayscale album artwork** (click to play/pause)
- **Track name and artist**
- **Real-time progress bar** with time indicators
- **Animated music visualizer** when playing
- **Playback controls** integrated into the design

## Features

- **🎨 Glass Design**: Beautiful translucent glass effect with subtle borders
- **🖱️ Fully Interactive**: Click artwork to play/pause, drag anywhere to reposition
- **📊 Music Visualizer**: Animated bars that dance to indicate music is playing
- **⏱️ Progress Tracking**: Real-time progress bar with current/total time display
- **🔄 Smart Updates**: Optimized AppleScript polling for responsive updates
- **🖥️ Notification Style**: Positioned like native macOS notifications
- **🌐 Always on top**: Stays visible above all other windows
- **🏠 All virtual desktops**: Visible across all macOS Spaces
- **🎥 Screen sharing friendly**: Hidden from screen sharing apps like Zoom and Teams
- **✨ Smooth animations**: Elegant transitions and hover effects

## Requirements

- macOS 13.0 or later
- Spotify desktop app
- Swift 5.9 or later

## Setup

1. Clone or download this project
2. Open Terminal and navigate to the project directory
3. Run: `swift run`

## Permissions

The first time you run the app, macOS may ask for:
- **Accessibility permissions**: Required to read Spotify's current track information
- **Screen recording permissions**: May be requested but not actually used

Grant these permissions in System Preferences > Security & Privacy > Privacy.

## Usage

Once running, the overlay will automatically:
- **Appear** in the top-right corner like a macOS notification
- **Update in real-time** as you play, pause, or change tracks in Spotify  
- **Show progress** with a smooth progress bar that updates every 100ms
- **Display music visualizer** with animated bars when music is playing
- **Respond to clicks** - click the album artwork to toggle play/pause
- **Allow dragging** - drag anywhere on the overlay to reposition it
- **Stay out of the way** - positioned like system notifications

## Interactive Controls

- **Click album artwork**: Play/pause current track
- **Drag anywhere**: Move the overlay to your preferred position  
- **Automatic updates**: Real-time track info, progress, and playback state
- **Visual feedback**: Hover effects and smooth animations

## Real-time Performance

The app uses optimized AppleScript polling:
- **Track info updates**: Every 1 second for responsiveness
- **Progress bar updates**: Every 100ms for smooth animation
- **Position interpolation**: Calculates progress between polls for fluid motion
- **Smart caching**: Reduces unnecessary updates when track info hasn't changed

## Customization

Modify the appearance by editing:
- **`SpotifyOverlayView.swift`**: UI colors, fonts, sizing, animations
- **`AppDelegate.swift`**: Window positioning and behavior
- **`SpotifyManager.swift`**: Polling frequency and AppleScript queries

## How it works

- **AppleScript Integration**: Communicates directly with Spotify for track info
- **Glass UI**: Uses SwiftUI's `.ultraThinMaterial` for native glass effects
- **Notification Positioning**: Mimics macOS notification center placement  
- **Drag & Drop**: Custom gesture handling with window repositioning
- **Real-time Updates**: Efficient polling with position interpolation