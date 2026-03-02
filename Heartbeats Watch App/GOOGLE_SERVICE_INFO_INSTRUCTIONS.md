# GoogleService-Info.plist Setup

The GoogleService-Info.plist file is NOT in git (see .gitignore). You need to add it manually.

## Steps to get GoogleService-Info.plist:

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: heartbeats-8345f
3. Click on gear icon ⚙️ → Project Settings
4. Scroll down to "Your apps" section
5. Click on your iOS app (the watch app)
6. Click "Download GoogleService-Info.plist"
7. Save it to this exact location:
   
   Heartbeats Watch App Watch App/GoogleService-Info.plist

## After adding the file:

Build the app to verify everything works:

xcodebuild -project heartbeats.xcodeproj -scheme "Heartbeats Watch App Watch App" build
