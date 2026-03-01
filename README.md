# Heartbeats

An Apple Watch app that allows two people to feel each other's heartbeats in real-time through haptic feedback.

## Features

- **Heartbeat Sharing**: Stream your live heart rate to a partner
- **Haptic Feedback**: Feel your partner's heartbeat through Watch vibrations
- **Simple Pairing**: Connect via a 6-character connection code
- **Zero Cost**: Uses free Firebase Realtime Database (Spark plan)

## Architecture

```
┌─────────────────┐     WatchConnectivity     ┌─────────────────┐
│   iPhone App    │◄──────────────────────────►│  watchOS App    │
│  - Pairing UI   │                           │  - HealthKit    │
│  - Manage pairs │                           │  - Haptics      │
└────────┬────────┘                           └────────┬────────┘
         │                                             │
         │   Firebase Realtime Database (Free Tier)    │
         └─────────────────────────────────────────────┘
```

## Setup Instructions

### 1. Firebase Setup (Required)

The app uses Firebase Realtime Database for real-time communication. You need to set up your own free Firebase project:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and select the Spark plan (free)
3. Give your project a name (e.g., "heartbeats-app")
4. Once created, go to **Realtime Database** from the left menu
5. Click "Create Database" and select any location
6. Choose **Start in test mode** for now
7. Set the following database rules:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

8. Copy your **Database URL** from the Realtime Database section
   - Format: `https://your-project-id.firebaseio.com`

### 2. Configure the App

1. Open the app on your iPhone
2. Go to **Settings** tab
3. Enter your Firebase Database URL
4. (Optional) Enter a database secret for authentication
5. Tap "Save Configuration"

### 3. Get Your Connection Code

1. Go to **Pair** tab
2. Tap "Generate Code" to get your unique 6-character code
3. Share this code with your partner (iMessage, WhatsApp, etc.)

### 4. Pair with Your Partner

1. Your partner enters your code in the "Enter Partner's Code" field
2. They enter your name
3. Tap "Connect"
4. Both devices are now paired!

## How to Use

### Sharing Your Heartbeat

1. Open the app on your Apple Watch
2. Tap "Share My Heartbeat"
3. Your heart rate will start streaming to your paired partner
4. They will feel each beat as a haptic vibration

### Feeling Someone's Heartbeat

1. Open the app on your Apple Watch
2. Tap "Feel Heartbeat"
3. When your partner shares their heartbeat, you'll feel it!

## Database Structure

```
/users/{userId}
  /connectionCode: string
  /currentBPM: number
  /status: "idle" | "streaming" | "receiving"
  /name: string (optional)

/pairs/{pairId}
  /user1Id: string
  /user2Id: string
  /createdAt: timestamp

/sessions/{sessionId}
  /senderId: string
  /receiverId: string
  /startTime: timestamp
  /duration: number
  /isActive: boolean
```

## Development

### Building the Project

```bash
# Open in Xcode
open Heartbeats.xcodeproj

# Build for iOS
xcodebuild -project Heartbeats.xcodeproj -scheme Heartbeats -sdk iphonesimulator build

# Build for watchOS
xcodebuild -project Heartbeats.xcodeproj -scheme "Heartbeats Watch App" -sdk watchos build
```

### Project Structure

```
Heartbeats/
├── Heartbeats/                    # iOS App
│   ├── App/
│   │   └── HeartbeatsApp.swift
│   ├── Views/                     # SwiftUI views
│   ├── Models/                    # Data models
│   ├── Services/                  # Firebase & WatchConnectivity
│   └── Resources/                 # Assets & Info.plist
├── Heartbeats Watch App/          # watchOS App
│   ├── Views/
│   ├── ViewModels/
│   └── Managers/                  # HeartRate & Haptics
└── Shared/                        # Shared code
```

## Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 15.0+
- Apple Watch Series 4 or later (for haptic feedback)
- HealthKit authorization

## Privacy

- Heart rate data is transmitted securely via Firebase
- No data is stored permanently on Firebase servers
- Paired users are stored locally on your device only
- Connection codes are regenerated each session

## Troubleshooting

**Q: Pairing fails with "Could not find user" error**

A: Make sure your partner has generated a connection code in the app. Both devices need internet connectivity.

**Q: I'm not feeling the haptic feedback**

A: Check that your Apple Watch supports haptic feedback (Series 4+). Also verify that haptic alerts are enabled in Watch settings.

**Q: Heart rate shows 0**

A: Make sure you've granted HealthKit permission. For testing, the app can use simulated heart rate if real data isn't available.

## License

This project is for personal use. Feel free to modify and extend for your own needs.

## Credits

Created with ❤️ for long-distance relationships.
