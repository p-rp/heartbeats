# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

An Apple Watch app that allows two people to feel each other's heartbeats in real-time through haptic feedback.

### Core Features
- **Heartbeat Request**: Receiver initiates a request to feel sender's heartbeat
- **Live Heart Rate Streaming**: Sender's watch streams live heart rate data for a set duration
- **Haptic Feedback**: Receiver feels each heartbeat through Watch vibrations
- **Zero Cost**: Uses free infrastructure only (no paid services)

## Architecture

### App Structure
- **iOS App**: Handles pairing, user identification, and network communication
- **watchOS App**: Records heart rate via HealthKit, streams data, and plays haptic feedback
- **Backend**: Free real-time communication layer (WebSocket or pub/sub via free tier service)

### Key Technologies
- **SwiftUI** for iOS/watchOS UI
- **HealthKit** for heart rate access from Apple Watch sensors
- **WatchConnectivity** for iPhone-Watch data transfer
- **Core Haptics** for heartbeat vibration patterns
- **MultipeerConnectivity** or free WebSocket service (e.g., PieSocket free tier, WebSocket.org) for real-time P2P communication

### Data Flow
1. Receiver sends heartbeat request via network
2. Sender's Watch receives request, starts HealthKit heart rate queries
3. Sender streams live BPM readings to receiver
4. Receiver's Watch uses haptics to vibrate in sync with received BPM

## Development Commands

```bash
# Open in Xcode
open Heartbeats.xcodeproj

# Build for iOS simulator
xcodebuild -project Heartbeats.xcodeproj -scheme Heartbeats -sdk iphonesimulator build

# Build for watchOS
xcodebuild -project Heartbeats.xcodeproj -scheme Heartbeats -sdk watchos build

# Run tests
xcodebuild test -project Heartbeats.xcodeproj -scheme Heartbeats -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Important Constraints

- **Free Backend Only**: Use free services only - consider PieSocket free tier (100 concurrent connections, 200k messages/day), or WebRTC via a free signaling server
- **HealthKit Authorization**: Must request `HKQuantityType(.heartRate)` permission
- **Background Execution**: Watch app needs proper background modes for heart rate streaming
- **Haptic Intensity**: Match haptic timing to received BPM (e.g., 60 BPM = 1 vibration per second)

## Pairing Strategy

For minimal cost, consider these free pairing approaches:
1. **QR Code**: One user shows QR code with connection ID, other scans
2. **iMessage/WhatsApp**: Share connection ID via messaging app
3. **Nearby Interaction**: Use NFC for local pairing, then connect over internet
