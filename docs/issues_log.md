# Wooberly Rider App - Issue Log

This document tracks all issues (UI, functionality, performance, security, crashes) encountered during the automation and testing of the Wooberly Rider application.

| ID | Issue Description | Category | Severity | Status | Steps to Reproduce |
|---|---|---|---|---|---|
| 001 | Last Name Validation accepts 3 chars but generic error message | Functionality | Low | Open | Enter a 2-character last name during registration. The UI blocks it but the tooltip could be clearer. |
| 002 | Password fields obscured by "Finish" button | UI / UX | Medium | Open | On smaller screens, the "Finish" floating button covers the password fields, requiring manual scroll to interact with them. |


### Issue 3: Multi-Stop `+` Button Missing Accessibility Label
- **Severity**: Low (Automation/Accessibility)
- **Description**: In the location search screen, the `+` button used to add a multi-stop does not have a `content-desc` attached to its `ImageView` in the Flutter accessibility tree. This makes it difficult for automation scripts and screen readers to identify the button without relying on hardcoded screen coordinates.
- **Steps to Reproduce**: 
  1. Go to Home -> Search your destination.
  2. Inspect the screen hierarchy.
  3. The `+` button directly right of the "Enter drop location" field lacks a label.

### Issue 4: Flutter `EditText` Fails to Receive Appium `setValue`
- **Severity**: Medium (Automation)
- **Description**: Calling standard WebDriver `setValue` or `sendKeys` on a Flutter `EditText` element updates the accessibility node text visually but does not trigger the internal Flutter `TextEditingController`.
- **Workaround**: Tests must explicitly issue a native `.click()` to focus the field, invoke `driver.keys()`, and hit the Enter/Back button to dismiss the keyboard.

### Issue 5: Navigation Stack Persists on App Restart
- **Severity**: Low
- **Description**: Terminating and re-activating the app does not return the user to the Home screen if they were previously in a sub-flow (like Confirm Location on the map). The Android Activity stack is preserved.
- **Workaround**: The user or script must explicitly tap the back button multiple times to reach the Home Screen.

### Issue 6: Map Confirmation Loop after Location Selection
- **Severity**: Medium (UX / Automation)
- **Description**: After selecting a drop location from the Google Auto-populate list and tapping `Done`, the app forces the user into a Map view to confirm the pin. Tapping `Confirm location` returns the user back to the `Where to go` screen, forcing them to tap `Done` a second time to proceed to Category Selection. This double-confirmation loop is unintuitive and confusing for automation.
- **Workaround**: The script is programmed to check if the map view appears after the first `Done` tap, click `Confirm location`, wait for the `Where to go` screen to reload, and tap `Done` again.

## [v1.3] Location Selection and Map Loop
**Severity:** High
**Issue:** The script would get stuck on the "Where to go" page or accidentally open the "Add work" map, leading the user to believe the script was failing or the app was behaving incorrectly.
**Root Cause:** In the Flutter accessibility tree, the `~Done` button on the "Where to go" page has a bounding box that covers almost the entire screen `[0,277][1080,2273]`. By default, Appium clicks the exact center of this box `(540, 1275)`. This coordinate happens to land perfectly on the `Add work` / `Set location on map` list items. This caused the app to navigate to a map screen for setting the Work address, confusing the E2E flow.
**Resolution:** Replaced the generic `.click()` method with explicit pointer actions targeting the exact visual coordinates of the bottom buttons `(x: 500, y: 2100)`. Additionally, the loop was made more robust to handle the loading spinners that appear during map rendering.

### Issue 8: OTP Input Field Freezing on Login ("Please enter OTP")
- **Severity**: High (Automation / UI)
- **Description**: On the OTP verification screen, the app displays a custom `PinInputTextField` consisting of a hidden `TextField` with custom painting. Looking strictly for accessibility ID `~Your OTP is 1234` can fail if `globals.phoneNumberStatus` is disabled by the backend, causing the automation script to skip input and click `Proceed` with an empty pin. This triggers the validation banner "Please enter OTP" and stalls the test flow.
- **Resolution**: Enhanced the OTP entry routine in `tests/e2e/wooberly_login_e2e_flow.ts` to use a 3-layer resilient approach:
  1. Detect demo autofill button if rendered.
  2. Fall back to directly finding and focusing the underlying `EditText`, typing the OTP character-by-character (`driver.keys()`).
  3. Coordinate tap on the pin entry box followed by keypad dispatch and `Proceed` tap.
  Removed unnecessary email and profile prompts from the login flow so it authenticates with only Phone number + OTP.

### Issue 9: Driver Online Multi-Stage System Permission & Background Dialog Orchestration
- **Severity**: Medium (Automation / OS Interoperability)
- **Description**: Toggling the driver online requires a multi-stage permission journey conforming to Google Play prominent disclosure guidelines. The sequence requires:
  1. Initial "Go" tap triggering prominent location disclosure modal with "Got it".
  2. OS foreground location prompt ("While using the app").
  3. Second "Go" tap triggering "Go to settings" modal.
  4. System Settings navigation: `Permissions` -> `Location` -> `Allow all the time`.
  5. Double back-navigation to return to the application.
  6. Explicit dismissal ("Deny") of battery optimization and app-invoke / overlay dialogues.
  7. Final "Go" tap to transition the driver online.
- **Resolution**: Implemented dedicated robust step handling in `tests/e2e/wooberly_driver_online_flow.ts` utilizing resilient XPath/accessibility selectors, automated system back keys, and coordinate fallbacks.

### Issue 10: Driver App Landing Screen "Get started" Button Interception
- **Severity**: Medium (Automation / Flow Blocking)
- **Description**: Upon a fresh launch of [`apps/wooberly_driver.apk`](file:///Users/radicalstart/Documents/appium-automation/apps/wooberly_driver.apk), the driver app displays an onboarding landing screen containing intro artwork and the primary "Get started" button before navigating to the mobile number input screen. Without automating the "Get started" tap, the script stalls looking for phone input fields.
- **Resolution**: Added Step 2 in `tests/e2e/wooberly_driver_online_flow.ts` to detect and tap the "Get started" button (via accessibility ID `~Get started`, XPath button/ImageView, or coordinate fallback `(540, 2100)`) and auto-dismiss any landing runtime permission prompts before entering the phone number.

### Issue 11: Driver Phone Authentication Keyboard Dismissal and Terms Checkbox Selection
- **Severity**: Medium (Automation / Flow Synchronization)
- **Description**: On the Driver phone number entry page, entering the phone number leaves the software keyboard and focus active, preventing interaction with the terms checkbox and `Verify` button. Additionally, the terms checkbox rendered in Flutter requires both specific XPath matching (`ImageView[3]`) and coordinate fallback to guarantee it is toggled prior to tapping `Verify`.
- **Resolution**: Updated `tests/e2e/wooberly_driver_online_flow.ts` to mirror the Rider application's exact flow:
  1. Input driver phone number.
  2. Tap `~Done` / hide keyboard.
  3. Toggle terms checkbox via exact XPath (`android.widget.ImageView[3]`) with coordinate fallback `(x: 100, y: 1500)`.
  4. Tap `~Verify` to proceed to the OTP verification screen.

### Issue 12: Driver OTP Entry Screen Freezing Without Entering Digits
- **Severity**: High (Automation / Flow Blocking)
- **Description**: After navigating from phone verification to the OTP verification screen, the script previously did not wait for the page transition to settle and relied on narrow accessibility label selectors for the demo OTP button. If `phoneNumberStatus` was not active on the backend or the Flutter CustomPaint PinInputTextField hadn't initialized, the script froze without entering the default `1234` digits and failed to proceed.
- **Resolution**: Rewrote the Driver login flow in `tests/e2e/wooberly_driver_online_flow.ts` to mirror `tests/e2e/wooberly_login_e2e_flow.ts` 1:1:
  1. Handled push notification permission alert modal.
  2. Executed `Get started` flow.
  3. Entered driver phone, tapped `~Done`, toggled terms checkbox via exact XPath (`android.widget.ImageView[3]`) and tapped `~Verify`.
  4. Executed rider-identical OTP block: detection of demo autofill `1234` text/desc, direct typing into `EditText` via `driver.keys(DRIVER_OTP)`, coordinate fallback `(540, 350)` + enter keycode `66`, and resilient `~Proceed` tap.
  5. Handled post-login location alert dismissal before proceeding to the "Go" online permission sequence.

### Issue 13: Invalid Compound XPath Selector Freezing "Get started"
- **Severity**: High (Automation / WebdriverIO)
- **Description**: Combining accessibility identifiers (`~`) and XPath (`//`) inside a single compound selector string with pipe operators (`|`) violates WebDriver selector syntax (`'//android.widget.ImageView[@content-desc="Get started"] | ~Get started'`). This threw an internal parse error or failed silently, halting execution on the "Get started" screen.
- **Resolution**: Refactored the selector to use standard XPath union (`//*[@content-desc="Get started" or @text="Get started"]`) accompanied by a verified coordinate fallback `(x: 540, y: 2131)`.

### Issue 14: Soft Keyboard Obscuring Driver Terms Checkbox and Verify Button
- **Severity**: High (UI / Automation)
- **Description**: When typing the driver phone number into `//android.widget.EditText`, the Samsung numeric soft keyboard remained opened across the lower half of the screen (`y: 1300` to `y: 2200`). This completely covered the Terms & Conditions checkbox (`y: 1952`) and the "Verify" button (`y: 2134`), causing tap interactions to be swallowed by the keyboard or missing the targets.
- **Resolution**: Explicitly dismissed the keyboard immediately following phone input using `~Done` / `driver.back()`. Applied multi-tiered locators and verified physical device touch coordinates for the Terms checkbox `(x: 90, y: 1952)` and Verify button `(x: 540, y: 2134)`. Handled Android 13+ Notification permission dialog between Verify and OTP screen.

### Issue 15: Dual-Application Orchestration for "During Booking" Flow
- **Severity**: Medium (Automation / Interoperability)
- **Description**: Verifying real on-demand ride dispatch requires the Driver application (`com.radicalstart.wooberlydriver`) to be in an active "You're online" state and running as a background service before the Rider application (`com.radicalstart.wooberly`) requests an available ride category. Running them as isolated tests required manual intervention to bridge the two states.
- **Resolution**: Created `tests/e2e/wooberly_combined_driver_rider_flow.ts` and registered `npm run test:during-booking`. It connects to Appium, executes the complete Driver online flow, leaves the Driver running online in the background via `driver.activateApp('com.radicalstart.wooberly')`, and executes the Rider login, destination search, category selection, cash payment confirmation, precaution consent, and moves to the Searching Driver screen while keeping the device foregrounded.

### Issue 16: WebDriver Connection Refused (`ECONNREFUSED`) on `http://localhost:4723/`
- **Severity**: High (Automation Infrastructure)
- **Description**: Running `npm run test:during-booking` resulted in `WebDriverError: Request failed with error code ECONNREFUSED when running "http://localhost:4723/session"`. On macOS, `localhost` resolves to IPv6 `::1`, whereas the local Appium server binds to IPv4 `127.0.0.1`.
- **Resolution**:
  1. Explicitly configured `hostname: '127.0.0.1'` in WebdriverIO client settings in `tests/e2e/wooberly_combined_driver_rider_flow.ts`.
  2. Integrated `ensureAppiumServer()` pre-flight check that polls `http://127.0.0.1:4723/status` and automatically launches Appium as a detached background process if it is not currently running.

### Issue 17: Post-Dispatch Trip Lifecycle, Dynamic OTP & Rating Bar Hitbox Calibration
- **Severity**: High (Automation / E2E Synchronization)
- **Description**: Several stages of the post-dispatch trip lifecycle required fine calibration:
  1. Slider hitboxes: On the `1080 x 2408` test device, the ConfirmationSliders ("Location reached", "Start ride", "Complete ride") are rendered at `Y = 1713` (bounds `120 -> 980`), rather than default screen bottom `Y = 2100`.
  2. Flutter Chat pop: Calling standard Android `driver.back()` dismissed the software keyboard but did not pop the Flutter route. The circle back button at `(95, 165)` is required to return to the active trip screen.
  3. Sheet collapse: Dragging sheet handle from `(540, 670)` to `(540, 2100)` smoothly collapses the sheet to expose the "Start ride" slider.
  4. Start Ride OTP: `RideConfirmationOtpView` blocks ride start until the 4-digit code is provided. Dynamically extracted the OTP from the Rider app UI (`OTP: <code\>`) / logcat, entered at `(150, 1850)`, and verified at `(720, 1255)`.
  5. Driver Rating Bar Hitbox: Driver `RiderReviewTransitionView` utilizes `_NoRatingWidget` with unrated SVG stars located vertically at `Y = 855` (between `Y = 790` and `920`), with the 5th star centered at `(810, 855)`. Tapping outside this range leaves rating at `0.0`, causing the "Done ->" button (`540, 2133`) to be ignored per `rxStarRatingController.value != 0.0`.
- **Resolution**: Fully calibrated all 13 steps with verified live device coordinates, automated dynamic OTP extraction, and resilient fallback handling.

### Issue 18: UiAutomator2 Polling Latency Leading to Missed Driver Acceptance Modal
- **Severity**: High (Automation / Timing)
- **Description**: The Driver app displays an incoming trip request modal that auto-cancels after 30 seconds. By default, WebdriverIO / UiAutomator2 polling times out after 10–20 seconds per failed lookup. When polling multiple elements (e.g. checking if sliders exist before checking `Accept`), the modal frequently expired before the accept button could be evaluated and clicked.
- **Resolution**: Reconfigured Appium settings dynamically:
  `await driver.updateSettings({ waitForIdleTimeout: 100, waitForSelectorTimeout: 500 })`.
  Prioritized the `Accept` selector check at the very top of the polling loop, and coupled it with immediate coordinate tap `(800, 2150)`.

### Issue 19: Foregrounding Latency When Switching Back to Driver App
- **Severity**: Medium (Automation / OS Interoperability)
- **Description**: After Rider booking completion in Stage 2, invoking `driver.activateApp('com.radicalstart.wooberlydriver')` occasionally left the app in the background activity stack without raising the visual window in time to catch the incoming ride request.
- **Resolution**: Implemented dual-layer explicit ADB intents prior to WebdriverIO app activation:
  `adb shell monkey -p com.radicalstart.wooberlydriver -c android.intent.category.LAUNCHER 1` and
  `adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity`.

### Issue 20: Blind Back Key Dismissing Toll Fee Dialog Instead of Soft Keyboard
- **Severity**: High (Automation / Flow Interruption)
- **Description**: After entering `$1` into the Toll Fee field, issuing a blind Android back key (`input keyevent 4`) dismissed the entire Toll modal dialog instead of just closing the keyboard, causing the app to return to an invalid state.
- **Resolution**: Replaced blind back keys with `driver.hideKeyboard()` followed by a safe background tap at `(540, 350)` and explicit click on `description("Done")` at `(540, 1238)` / `(540, 2111)`.

### Issue 21: Driver Login OTP Field Misdirection
- **Severity**: Medium (Automation)
- **Description**: On the Driver login flow, entering the OTP immediately after phone submission could send keystrokes to the phone input field if the page transition had not yet fully rendered the OTP screen.
- **Resolution**: Added explicit wait for the OTP verification screen to settle (`Please enter OTP` or `Verify OTP` indicator) before dispatching OTP input.









