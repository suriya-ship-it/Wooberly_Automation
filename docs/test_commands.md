# Test Execution Commands

This document contains the exact CLI commands required to execute the automation testing workflows for the Wooberly platform.

---

## 1. Prerequisites
Ensure the Appium server is running and your Android test device is connected via ADB:
```bash
# Verify connected devices
adb devices

# Start Appium server (default port 4723)
appium --address 127.0.0.1 --port 4723
```

---

## 2. Test Execution Commands

### A. Play Store Dynamic App Installation Flow (New Milestone - Standalone)
Sequentially provisions and installs both Rider and Driver applications directly from the Google Play Store using URLs configured in `.env`:
1. Checks phone status, wakes up and unlocks device screen.
2. Reads `PLAYSTORE_RIDER_URL`, navigates to Play Store, and automates Rider app download & installation.
3. Returns to device Home screen.
4. Reads `PLAYSTORE_DRIVER_URL`, navigates to Play Store, and automates Driver app download & installation.
5. Returns to Home screen and confirms both apps via Android PackageManager.
```bash
npm run test:store-install
# or shortcut:
npm run test:playstore
```

---

### B. Unified Step #1 Orchestrator Flow (Existing Unchanged Flow)
Executes the full automated workflow in sequence:
1. **Stage 1 (`npm run test:driver-online`)**: Brings Driver online and leaves it running in the foreground.
2. **Stage 2 (`npm run test:login`)**: Authenticates Rider, books ride to "Mattuthavani madurai", selects category, confirms cash, and dispatches.
3. **Stage 3 (`npm run test:trip`)**: Relaunches Driver to foreground, accepts ride request, and completes the entire 13-step in-ride & post-trip lifecycle.
```bash
npm run "test:step #1"
# shortcuts:
npm run test:step1
npm run test:step-1
```

---

### C. Unified Step #2 Orchestrator Flow (Store Install + Step #1 E2E)
Executes the full automated workflow including fresh store provisioning and trip lifecycle:
1. **Stage 1 (`npm run test:store-install`)**: Wakes phone, dynamically navigates to Play Store for Rider and Driver apps, and automates downloads.
2. **Stage 2 (`npm run "test:step #1"`)**: Automatically starts the full Step #1 flow (Driver Online -> Rider Booking -> Driver Ride Acceptance & Trip Lifecycle).
```bash
npm run "test:step #2"
# shortcuts:
npm run test:step2
npm run test:step-2
```

---

### B. Driver Ride Acceptance & 13-Step Lifecycle Flow (Stage 3 Standalone)
Executes the driver ride acceptance and full 13-step lifecycle independently (accepts incoming ride, location reached, chat message, start ride with OTP, complete ride, toll fee, cash modal hold, rider confirm & review, driver cash yes & review):
```bash
npm run test:trip
# or directly via tsx:
npx tsx tests/e2e/wooberly_trip_flow.ts
```

---

### C. Full End-to-End "During Booking" & Trip Lifecycle Flow (Combined Single Session)
Executes the full synchronized dispatch and trip completion cycle:
1. **Stage 1 (Driver Online)**: Logs into Driver app (`+91 7639699826`), completes OS background location permissions ("Allow all the time"), and brings Driver Online.
2. **Stage 2 (Rider Booking)**: Switches to Rider app, enters destination ("Mattuthavani madurai"), selects vehicle category, handles Cash payment and Precaution modals, and dispatches ride request to "Connecting you to nearby drivers".
3. **Stage 3 (Driver Ride Acceptance)**: Switches back to Driver app, detects incoming ride request modal/card, and clicks the **"Accept"** button.
4. **Stage 4 (Trip Lifecycle, Chat, Toll, Cash Confirmation & Reviews)**:
   - **Step 1**: Swipes slider for **"Location reached"** (Driver reaches pickup location).
   - **Step 2**: Clicks **Up Arrow** at bottom section to expand sheet and clicks **Chat/Message** icon.
   - **Step 3**: Types random message in chat, closes keyboard, and clicks **Send** button.
   - **Step 4**: Clicks **Back** button from chat screen, returns to bottom sheet, and clicks **Down Arrow** to collapse sheet.
   - **Step 5**: Swipes slider for **"Start ride"** to begin trip.
   - **Step 6**: Swipes slider for **"Complete ride"** to end trip.
   - **Step 7**: Enters **$1** in the Toll Fee input field and clicks **"Done"**.
   - **Step 8**: Holds Driver app on the **Cash Payment Confirmation** modal ("Did you collect cash?").
   - **Step 9**: Switches to Rider app trip details page.
   - **Step 10**: Clicks **"Confirm"** button on Rider app to finalize fare payment.
   - **Step 11**: Selects a star rating on Rider review page and clicks **"Done"**.
   - **Step 12**: Switches to Driver app and clicks **"Yes"** on the cash confirmation modal.
   - **Step 13**: Selects a star rating on Driver review page and clicks **"Done"**.
```bash
npm run test:during-booking
# or directly via tsx:
npx tsx tests/e2e/wooberly_combined_driver_rider_flow.ts
```

---

### B. Driver Online Flow Only
Brings the driver online by logging in with phone `+91 7639699826`, OTP `1234`, granting location disclosure permissions ("While using the app", "Allow all the time" in OS settings), denying battery optimization, and toggling the status to "You're online":
```bash
npm run test:driver-online
# or directly via tsx:
npx tsx tests/e2e/wooberly_driver_online_flow.ts
```

---

### C. Rider Login & On-Demand Booking Flow Only
Logs into the rider app with `9876543210` and OTP `1234`, navigates to destination search, selects an available vehicle category, confirms cash payment, accepts precautions, and stays on the searching driver screen:
```bash
npm run test:login
# or directly via tsx:
npx tsx tests/e2e/wooberly_login_e2e_flow.ts
```

---

### D. Rider Signup Flow Only
Performs end-to-end registration of a new rider account:
```bash
npm run test:signup
# or directly via tsx:
npx tsx tests/e2e/wooberly_e2e_flow.ts
```

---

### E. Theme & Design Specs Synchronization
Synchronizes color codes and typography constants from `design_specs/theme.md` to `Wooberly_Rider_V3.5/lib/resources/values/app_colors.dart`:
```bash
npm run sync-theme
```

---

## 3. Automatic Video Reference Recording

All automated workflows automatically record high-definition video of the entire device screen execution:
- **Trigger**: Recording begins automatically immediately after the phone is awakened and unlocked.
- **Completion**: Recording finalizes automatically when the automation script completes (or exits gracefully on failure).
- **Storage Location**: Videos are stored in the project's dedicated directory: `Test reference/`
  - **Timestamped Recording**: `Test reference/<workflow_name>_<YYYY-MM-DD_HH-mm-ss>.mp4`
  - **Latest Copy**: `Test reference/<workflow_name>_latest.mp4` (and `latest_execution.mp4` for quick inspection)
- **Multi-segment Safety**: Long test executions that span multiple minutes are monitored via a background watchdog that seamlessly joins segments using stream-copy into one complete, continuous MP4 file without quality loss.

