# heartbeats Development Plan

## Project Overview
Apple Watch app for sharing heartbeats via haptic feedback using Firebase (free tier).
- **Platforms**: iOS (iPhone) + watchOS (Apple Watch)
- **Style**: Dark mode, colorful, playful UI
- **Partners**: One permanent partner (architecture ready for multiple)
- **Testing**: One Apple Watch + Simulator
- **Backend**: Firebase Realtime Database (free tier)

---

## Phase 1: Foundation & Setup
**Goal:** Get Firebase connected and basic app structure running

- [x] **Step 1.1: Firebase Setup**
  - [x] Create Firebase project at console.firebase.google.com
  - [x] Add WatchKit Extension app to Firebase
  - [x] Download `GoogleService-Info.plist`
  - [x] Install Firebase SDK via Swift Package Manager
  - [x] Configure Firebase in `heartbeatsApp.swift`
  - **Test:** App launches without crashes, Firebase initialized ✅

- [x] **Step 1.2: Basic Navigation Structure**
  - [x] Create dark mode color scheme
  - [x] Add "Setup" screen (shown if not paired)
  - [x] Add "Main" screen (shown if paired)
  - [x] Create playful UI components
  - **Test:** Can toggle between screens with mock data ✅

---

## Phase 2: Permanent Pairing System
**Goal:** Two devices can pair once and remember each other forever

- [x] **Step 2.1: Anonymous Auth**
  - [x] Implement Firebase Anonymous Authentication
  - [x] Store auth ID locally in UserDefaults
  - **Test:** App gets stable user ID, survives app restart ✅

- [x] **Step 2.2: Generate Pairing Code**
  - [x] Create 6-digit unique code generator (e.g., "BEAT-1234")
  - [x] Show code on Setup screen with colorful UI
  - [x] Save to Realtime DB `/users/{userId}/pairCode`
  - **Test:** Code displays, saved to Firebase, unique each time ✅

- [x] **Step 2.3: Enter Pairing Code**
  - [x] Add text field to enter code with playful styling
  - [x] Look up code in Realtime DB
  - **Test:** Can search for codes, handles "not found" gracefully ✅

- [x] **Step 2.4: Complete Pairing**
  - [x] Save partner ID to both users' documents in Realtime DB
  - [x] Store locally in UserDefaults
  - [x] Show "Paired!" confirmation with animation
  - **Test:** Two simulators can pair, IDs saved on both sides ✅

- [x] **Step 2.5: Persistent State**
  - [x] On launch, check if paired in UserDefaults
  - [x] Skip setup if already paired
  - [x] Show partner name/status with colorful indicator
  - **Test:** Kill app, reopen - still paired ✅

---

## Phase 3: Real-time Session (Mock Data)
**Goal:** Simulate heartbeat sending before HealthKit integration

- [x] **Step 3.1: Session Request**
  - [x] "Feel Heartbeat" button on Main screen (playful design)
  - [x] Write session to Realtime DB `/sessions/{id}`
  - [x] Status: "requested"
  - **Test:** Button creates DB entry, visible in Firebase console ✅

- [x] **Step 3.2: Session Listener**
  - [x] Watch app listens for incoming requests
  - [ ] Show colorful notification/alert when request arrives
  - **Test:** Two devices, one requests, other receives notification ⚠️

- [ ] **Step 3.3: Accept Session**
  - [ ] Sender can accept/decline with nice UI
  - [ ] Update session status to "active"
  - **Test:** Both sides see status change ❌

- [x] **Step 3.4: Mock Heartbeat Streaming**
  - [x] Sender sends fake BPM (60-120) every 500ms to DB
  - [x] Receiver reads values in real-time
  - [x] Display BPM number with pulsing animation
  - **Test:** Numbers update live on receiver screen ✅

- [ ] **Step 3.5: Session Lifecycle**
  - [ ] Auto-end after 10 seconds
  - [ ] Update status to "completed"
  - [ ] Clean up DB entry
  - **Test:** Session ends automatically, data removed ❌

---

## Phase 4: HealthKit Integration
**Goal:** Read real heart rate from Apple Watch

- [ ] **Step 4.1: Permission Request**
  - [ ] Request HealthKit authorization for heart rate
  - [ ] Handle granted/denied cases with nice UI
  - **Test:** Permission dialog shows, settings accessible ❌

- [ ] **Step 4.2: Read Heart Rate**
  - [ ] Query HKHealthStore for heart rate
  - [ ] Get latest BPM value
  - **Test:** Shows actual heart rate from watch ❌

- [ ] **Step 4.3: Real-time Monitoring**
  - [ ] Set up HKAnchoredObjectQuery for live updates
  - [ ] Stream real BPM to Firebase
  - **Test:** As heart rate changes, DB updates ❌

- [ ] **Step 4.4: Fallback Handling**
  - [ ] If no heart rate available, show friendly error
  - [ ] Option to use mock data for testing
  - **Test:** Graceful handling when no data ❌

---

## Phase 5: Haptic Feedback
**Goal:** Receiver feels the heartbeat through haptics

- [ ] **Step 5.1: Basic Haptic**
  - [ ] Play `WKHapticType.heartbeat` on watch
  - **Test:** Can feel haptic on wrist ❌

- [ ] **Step 5.2: Timing Control**
  - [ ] Convert BPM to milliseconds: `60000 / BPM`
  - [ ] Trigger haptics at calculated intervals
  - **Test:** 60 BPM = 1 beat/second, 120 BPM = 2/second ❌

- [ ] **Step 5.3: Sync with Incoming Data**
  - [ ] Listen to Firebase BPM changes
  - [ ] Adjust haptic timing dynamically
  - **Test:** Haptics speed up/slow down as BPM changes ❌

- [ ] **Step 5.4: Session Management**
  - [ ] Start haptics when session starts
  - [ ] Stop when session ends
  - [ ] Handle interruptions gracefully
  - **Test:** Clean start/stop, no lingering haptics ❌

---

## Phase 6: UI/UX Polish
**Goal:** Beautiful, intuitive dark mode interface

- [ ] **Step 6.1: Heartbeat Animation**
  - [ ] Pulsing heart animation with vibrant colors
  - [ ] Speed matches BPM
  - [ ] Smooth transitions between rates
  - **Test:** Visual matches haptic timing ❌

- [ ] **Step 6.2: Connection Status**
  - [ ] Colorful indicator if partner is online/offline
  - [ ] Last seen timestamp with friendly formatting
  - [ ] Connection strength visual
  - **Test:** Accurate status display ❌

- [ ] **Step 6.3: Session UI**
  - [ ] "Requesting..." state with animated loader
  - [ ] "Receiving..." with large BPM display
  - [ ] Countdown timer (10 seconds)
  - [ ] Completion celebration animation
  - **Test:** Clear visual feedback throughout ❌

- [ ] **Step 6.4: Error Handling**
  - [ ] Network error messages with retry options
  - [ ] Partner offline handling with nice UI
  - [ ] Permission denied flows
  - **Test:** All error states handled gracefully ❌

---

## Phase 7: Testing & Refinement
**Goal:** Production-ready app

- [ ] **Step 7.1: Edge Cases**
  - [ ] App killed mid-session
  - [ ] Network drops and reconnects
  - [ ] Background/foreground transitions
  - **Test:** Handles all gracefully ❌

- [ ] **Step 7.2: Performance**
  - [ ] Optimize Firebase listeners
  - [ ] Reduce battery usage
  - [ ] Check for memory leaks
  - **Test:** Smooth performance, no crashes ❌

- [ ] **Step 7.3: Real Device Testing**
  - [ ] Test on your Apple Watch
  - [ ] Verify haptic feedback feels right
  - [ ] Test with partner on simulator
  - **Test:** Works on real device ❌

---

## Current Status
**Phase:** 3 (Partial)  
**Status:** 🟡 Core pairing complete - Session flow needs work

### Completed
- ✅ Firebase setup (SPM, Auth, Realtime DB)
- ✅ Dark mode UI with playful styling
- ✅ Pairing system (generate/enter codes)
- ✅ Persistent state (survives app restart)
- ✅ Mock heartbeat streaming
- ✅ iOS companion app (not in original plan)

### Remaining (Priority Order)
1. **HealthKit Integration** (Phase 4) - Core feature
2. **Haptic Feedback** (Phase 5) - Core feature  
3. **Session accept/decline UI** (Phase 3.3)
4. **Session lifecycle** (Phase 3.5)
5. **UI/UX polish** (Phase 6)
6. **Testing** (Phase 7)

### Notes
- Original plan was "Watch-only" but **iOS app was also built**
- **WatchConnectivity** bridges iPhone-Watch communication
- Architecture supports multiple partners later (DB schema ready)
- Using Firebase Spark plan (free tier)
- Dark mode + colorful UI throughout
