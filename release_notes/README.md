# Wooberly Appium Automation - Release Notes

This document provides a consolidated history of all versions, releases, and changelogs for the Wooberly Rider mobile automation project.

Each release is also documented in its own dedicated document within this directory.

---

## Release Summary

| Version | Release Date | Summary | Detailed Doc |
| :---: | :---: | :--- | :---: |
| **v1.6** | 2026-10-14 | Unified Multi-Stage E2E Orchestrator (`npm run "test:step #1"`). Coordinates Stage 1 (Driver Online), Stage 2 (Rider Booking & Dispatch), and Stage 3 (Driver Acceptance & 13-Step Lifecycle). Solved selector timeout latency, foregrounding intents, Toll modal dismissals, and OTP field separation. Milestone Finalized and Signed Off as Completed. | [`v1.6.md`](file:///Users/radicalstart/Documents/appium-automation/release_notes/v1.6.md) |
| **v1.5** | 2026-10-13 | Complete 13-step post-dispatch lifecycle: Location Reached swipe, in-ride chat & sheet toggle, Start Ride with dynamic OTP verification, Complete Ride swipe, Toll Fee & driver trip details, Driver Cash Confirmation popup hold, Rider fare payment confirmation, Rider 5-star review, Driver Cash confirmation "Yes", and Driver 5-star review. Fixed `ECONNREFUSED` with IPv4 `127.0.0.1` binding and added self-healing Appium launcher. | [`v1.5.md`](file:///Users/radicalstart/Documents/appium-automation/release_notes/v1.5.md) |
| **v1.4** | 2026-10-12 | Dual-App Orchestration ("During booking" Driver & Rider integration), Driver Online permissions flow, "Already Logged In" bypass state detection, and Test commands documentation ([`docs/test_commands.md`](file:///Users/radicalstart/Documents/appium-automation/docs/test_commands.md)). | [`v1.4.md`](file:///Users/radicalstart/Documents/appium-automation/release_notes/v1.4.md) |

---

## Version Highlights

### [Version 1.6 (2026-10-14)](file:///Users/radicalstart/Documents/appium-automation/release_notes/v1.6.md)
- **Unified Multi-Stage E2E Orchestration**: Created `npm run "test:step #1"` (`tests/e2e/wooberly_step1_flow.ts`), orchestrating Stage 1 (`test:driver-online`), Stage 2 (`test:login`), and Stage 3 (`test:trip`) in sequence with zero manual intervention.
- **Standalone Stage 3 Module**: Implemented `tests/e2e/wooberly_trip_flow.ts` to execute Driver app acceptance and the 13-step lifecycle with robust selector timeouts (`waitForSelectorTimeout: 500`) and dual ADB/WebdriverIO foregrounding.
- **Toll Charges & Dynamic OTP Hardening**: Stabilized toll charges input without dismissing the dialog and extracted the Rider OTP dynamically from logcat for automated verification.
- **Milestone Completed**: Signed off and verified end-to-end with Exit Code 0 and all 24 page visual transitions captured.

### [Version 1.5 (2026-10-13)](file:///Users/radicalstart/Documents/appium-automation/release_notes/v1.5.md)
- **Complete Post-Dispatch Trip Lifecycle**: Fully implemented and tested all 13 steps of the trip lifecycle in [`tests/e2e/wooberly_combined_driver_rider_flow.ts`](file:///Users/radicalstart/Documents/appium-automation/tests/e2e/wooberly_combined_driver_rider_flow.ts) (`npm run test:during-booking`):
  1. Driver swipes **"Location reached"** at `Y = 1713`.
  2. Driver expands bottom sheet via Up Arrow and taps **Chat** icon at `(500, 1890)`.
  3. Driver types message `"Hello, driver has arrived at the pickup point!"`, hides keyboard, and taps **Send** at `(985, 2280)`.
  4. Driver taps Flutter back `<` at `(95, 165)` and drags sheet handle `(540, 670) -> (540, 2100)` to collapse.
  5. Driver swipes **"Start ride"** at `Y = 1713`, detects `RideConfirmationOtpView`, dynamically retrieves the 4-digit OTP from Rider app UI/logcat, enters it at `(150, 1850)`, and taps **"Verify ->"** at `(720, 1255)`.
  6. Driver swipes **"Complete ride"** at `Y = 1713`.
  7. Driver enters `$1` in Toll Fee input at `(500, 950)`, taps **"Done ->"** at `(540, 2110)`, and taps **"Next ->"** on Trip Details at `(540, 2120)`.
  8. Driver displays **Cash Confirmation** modal ("Did you collect cash?") and remains idle in background without closing.
  9. Script switches to Rider app.
  10. Rider taps **"Confirm ->"** on Trip Summary at `(540, 2120)`.
  11. Rider selects 5-star rating at `(760, 1430)` and taps **"Done ->"** at `(540, 2120)`.
  12. Script switches back to Driver app and taps **"Yes ->"** at `(730, 2140)`.
  13. Driver selects 5-star rating at `(810, 855)` and taps **"Done ->"** at `(540, 2133)` (with "Review later" fallback at `(540, 1960)`). Both apps return to clean home screens!
- **Connection Error Fix (`ECONNREFUSED`)**: Configured WebdriverIO to bind explicitly to IPv4 `127.0.0.1:4723`, resolving `localhost` IPv6 loopback failures.
- **Self-Healing Appium Server**: Added `ensureAppiumServer()` to automatically start Appium if not running.

### [Version 1.1 (2026-10-06)](file:///Users/radicalstart/Documents/appium-automation/release_notes/v1.1.md)
- **Resolved Flutter Text Input**: Tapped fields prior to keystroke dispatch to establish an active IME connection, resolving the issue where `element.setValue()` silently failed to update Flutter's `TextEditingController`.
- **Google Places Autocomplete**: Clicked the location container to launch `CitySearch` (`google_place_search.dart`), queried `"Madurai, India"`, and selected `"Madurai, Tamil Nadu, India"` from the live prediction list.
- **Validation Rule Discovery**: Identified that `validateLastName()` enforces `globals.nameLength[0]` (minimum 3 characters), rejecting `"kb"` with a SnackBar warning. Updated input to `"kbb"` to pass validation.
- **Scroll Gestures**: Implemented W3C pointer actions to scroll down past the fixed "Finish" button and reveal "Password" and "Confirm password".
- **Successful Registration**: Clicked Finish, executed `callSignUpAPI()` and `getProfileInfo()`, and successfully navigated to the **Explore / Home Map page ("Hi, Suriya - Where are you going?")**.

### [Version 1.0 (2026-10-05)](file:///Users/radicalstart/Documents/appium-automation/release_notes/v1.0.md)
- **Appium 2.x & UiAutomator2 Setup**: Established session connectivity for Android device (`RZ8T7113KRM`).
- **Welcome & Auth Flow**: Automated clicking `"Get started"`, entering phone number (`9876543210`), and accepting terms.
- **OTP Auto-Fill**: Targeted the accessibility element `"Your OTP is 1234"` to automatically populate the verification code.
- **Permissions & Keyboards**: Bypassed runtime system permissions and handled keyboard dismissals using keycode events.

---

## Running the Automation
To execute the latest end-to-end test suite against a connected physical device or emulator:

```bash
npx tsx tests/wooberly_login.ts
```

# Release Notes v1.2 - Booking Flow Implementation

## Overview
This phase successfully implemented the core On-Demand and Scheduled booking flows, as well as validating the user authentication bypass functionality.

## Features Implemented
1. **Login Profile Bypass (Requirement #1)**
   - Verified that entering a previously registered mobile number (e.g., 9876543210) bypasses the Profile Details registration screen and logs the user straight into the Home Map Screen.

2. **On-Demand Booking with Multi-Stop (Requirement #2)**
   - Automated the navigation from the Home Screen to the Location Search screen.
   - Handled destination entry via the Google Places autocomplete predictions.
   - Successfully added a multi-stop location by tapping the `+` icon and entering a secondary destination (e.g., "Madurai Railway Station").
   - Executed the "Done" action to finalize the route.

3. **Category Selection & Driver Allocation (Requirement #3)**
   - Automated the selection of vehicle categories (Mini/Sedan/SUV) from the modal view.
   - Automated the `Book now`/`Confirm` step.
   - Handled the timeout when no drivers are found.

4. **Scheduled Booking Flow (Requirement #4)**
   - Navigates back to the Home Screen to locate the "Schedule a ride" option.
   - Populates the destination (e.g., "Madurai Airport").
   - Progresses through the default Date and Time confirmation.
   - Finalizes the scheduled booking via the category selection modal.

## Technical Details
- The test script utilizes a full app data reset (`noReset: false`) to guarantee the login bypass is verified from a pristine state.
- Dynamic `content-desc` searching is used to handle location predictions accurately.
- `BypassSandbox=true` was utilized for robust local Appium proxying during test execution.

## [v1.3] - 2026-10-06
### Added
- **Unified E2E Script**: Added `wooberly_e2e_flow.ts` to seamlessly run Profile Signup -> On-Demand Booking -> Scheduled Booking sequentially.
- **Map Loop Handling**: Script now properly navigates the map confirmation loop after entering a drop location.

### Fixed
- **Clipboard Crash Bypass**: Fixed fatal Flutter crash caused by `driver.keys` by typing the location strings character-by-character.
