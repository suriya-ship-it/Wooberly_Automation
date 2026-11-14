# Wooberly Automation Platform - Technology Stack & Architecture Guide

This document provides a comprehensive, easy-to-understand breakdown of the programming languages, frameworks, drivers, tools, and libraries used to build and execute the Wooberly Mobile Automation testing ecosystem.

---

## 1. Quick Summary Table

| Category | Technology / Tool | Version | Purpose / Role in Project |
| :--- | :--- | :--- | :--- |
| **Primary Language** | [TypeScript](https://www.typescriptlang.org/) | `^7.0.2` | Strongly-typed language used to write all automation test suites, locator definitions, and custom workflows. |
| **Runtime Environment** | [Node.js](https://nodejs.org/) | `v22.16.0` | JavaScript/TypeScript asynchronous engine running the test scripts and tooling on macOS. |
| **Package Manager** | [npm](https://www.npmjs.com/) | `10.9.2` | Dependency management and script runner (`npm run test:...`, `npm run sync-theme`). |
| **TypeScript Execution Engine** | [tsx](https://github.com/privatenumber/tsx) | `^4.23.15` | Fast TypeScript execute-in-place loader (powered by esbuild) allowing direct execution of `.ts` files without a manual compilation step. |
| **Test Automation Client** | [WebdriverIO](https://webdriver.io/) | `^9.32.0` | Next-generation WebDriver / Appium client library providing the high-level API (`$`, `$$`, `action()`, `pause()`, etc.) to control mobile apps. |
| **Mobile Automation Server** | [Appium Server](https://appium.io/) | `3.8.0` | Open-source mobile test automation server bridging client WebDriver HTTP commands to native device drivers. |
| **Android Automation Driver** | [UiAutomator2](https://github.com/appium/appium-uiautomator2-driver) | `8.7.0` | Appium driver communicating directly with Google's Android UiAutomator server on the physical test device. |
| **iOS Automation Driver** | [XCUITest](https://github.com/appium/appium-xcuitest-driver) | `12.15.0` | Appium driver installed and prepared for Apple iOS / Simulator test execution. |
| **Device Bridge & Control** | [Android Debug Bridge (ADB)](https://developer.android.com/tools/adb) | `1.0.41 (v37)` | Interacts with physical Android devices: app installations, permission grants, activity stack inspection, screen capture, and pointer input. |
| **Mobile Application Framework** | [Flutter (Dart)](https://flutter.dev/) | `3.x / Dart 3` | Framework used by the target mobile apps (`Wooberly_Rider_V3.5` and `Wooberly_Driver_V3.5`). |

---

## 2. Detailed Component Breakdown

### 2.1 Programming & Scripting Languages

#### A. TypeScript (`.ts`)
- **What it is:** A superset of JavaScript that adds strict static typing, interfaces, and modern ECMAScript features.
- **Where it is used:** All test flows under [`tests/e2e/`](file:///Users/radicalstart/Documents/appium-automation/tests/e2e/):
  - `wooberly_combined_driver_rider_flow.ts` (Dual-app orchestration)
  - `wooberly_driver_online_flow.ts` (Driver online and permission management)
  - `wooberly_login_e2e_flow.ts` (Rider authentication and booking flow)
  - `wooberly_e2e_flow.ts` (Full registration and multi-stop booking)
- **Why we chose it:** Prevents runtime typos, provides rich autocomplete for Appium/WebdriverIO commands, and ensures predictable, robust test code.

#### B. JavaScript / Node.js (`.js`)
- **Where it is used:**
  - Build helper scripts such as [`scripts/sync_theme.js`](file:///Users/radicalstart/Documents/appium-automation/scripts/sync_theme.js) (synchronizing design tokens from `design_specs/` markdown into Flutter Dart code).
  - Quick runtime verification and configuration inspection.

#### C. Bash / Zsh Shell Scripting
- **Where it is used:** Terminal automation commands, ADB pipeline commands (`adb shell dumpsys`, `adb shell uiautomator dump`), and process checks.

---

### 2.2 Frameworks & Core Automation Libraries

#### A. WebdriverIO (`webdriverio` v9.32.0)
- **Role:** The core client automation library.
- **Capabilities used:**
  - **Session Management:** Connecting to Appium via W3C WebDriver capabilities protocol.
  - **Element Finding:** Querying elements via Accessibility ID (`~`), XPath (`//android.widget...`), and Android resource ID (`id=...`).
  - **W3C Pointer Gestures:** Native touch actions (`driver.action('pointer')`) for precise coordinates, swipes, and screen scrolling.
  - **App Lifecycle Control:** Foreground switching via `driver.activateApp(appId)`.

#### B. Appium 3.x & UiAutomator2 Driver
- **Role:** The central test server and native Android automation engine.
- **UiAutomator2:** Interacts directly with Android OS components, system dialogs ("Allow all the time", battery optimization dialogs), and Flutter Accessibility nodes.

#### C. `tsx` (TypeScript Execute)
- **Role:** Zero-configuration TypeScript execution engine.
- **Why we chose it:** Eliminates tedious `tsc` build steps; allows developers and CI/CD pipelines to run tests directly:
  ```bash
  npx tsx tests/e2e/wooberly_combined_driver_rider_flow.ts
  ```

---

### 2.3 Mobile Applications Under Test (AUT)

The automation suite interacts directly with two Flutter applications built with the **Dart** programming language:

1. **Wooberly Rider (`com.radicalstart.wooberly`)**:
   - Location prediction via Google Places API.
   - Dynamic map pin dragging and drop-off selection.
   - Vehicle category selection (Mini, Sedan, SUV, etc.).
   - Payment method selection (Cash, Card, Wallet) and dispatch.
2. **Wooberly Driver (`com.radicalstart.wooberlydriver`)**:
   - Packaged as [`apps/wooberly_driver.apk`](file:///Users/radicalstart/Documents/appium-automation/apps/wooberly_driver.apk).
   - Driver phone authentication with OTP verification.
   - Android system settings redirection for Background Location (`ACCESS_BACKGROUND_LOCATION` - "Allow all the time").
   - Battery optimization management.
   - Real-time ride request listener and **"Accept"** button action.

---

## 3. Architecture & Data Flow Diagram

```
+-------------------------------------------------------------------------------+
|                             TEST RUNNER ENVIRONMENT                           |
|                                                                               |
|   +-----------------------+              +--------------------------------+   |
|   |  npm / npx CLI        |              |  TypeScript Test Scripts       |   |
|   |  (npm run test:...)   |  --------->  |  (tests/e2e/*.ts)              |   |
|   +-----------------------+              +---------------+----------------+   |
|                                                          |                    |
|                                          +---------------v----------------+   |
|                                          |  WebdriverIO Client v9         |   |
|                                          +---------------+----------------+   |
+----------------------------------------------------------|--------------------+
                                                           | W3C WebDriver Protocol
                                                           | (HTTP / JSON over port 4723)
+----------------------------------------------------------v--------------------+
|                             APPIUM SERVER (v3.8.0)                            |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |  Appium UiAutomator2 Driver (v8.7.0)                                  |   |
|   +-----------------------------------+-----------------------------------+   |
+---------------------------------------|---------------------------------------+
                                        | ADB / Socket Connection
                                        |
+---------------------------------------v---------------------------------------+
|                       PHYSICAL TEST DEVICE (Samsung / Android 13+)            |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |  UiAutomator2 Server Daemon                                           |   |
|   +-------------------+-----------------------------------+---------------+   |
|                       |                                   |                   |
|                       v                                   v                   |
|       +-------------------------------+   +-------------------------------+   |
|       |  Wooberly Driver App          |   |  Wooberly Rider App           |   |
|       |  (com.radicalstart.wooberly-  |   |  (com.radicalstart.wooberly)  |   |
|       |   driver)                     |   |                               |   |
|       |  Status: ONLINE               |   |  Status: BOOKING DISPATCHED   |   |
|       +-------------------------------+   +-------------------------------+   |
+-------------------------------------------------------------------------------+
```

---

## 4. Key Design Patterns & Engineering Highlights

1. **Dual-App Orchestration**:
   - Single test session coordinates both Driver and Rider apps sequentially without restarting the device or killing background location services.
2. **"Already Logged In" State Bypass**:
   - Proactive UI detection checks if an active session already exists, bypassing redundant OTP / registration screens and saving up to 45 seconds per run.
3. **Flutter Character-by-Character IME Typing**:
   - Sequential character typing prevents Flutter engine crashes and ensures Google Places autocomplete triggers reliably.
4. **Resilient Dual-Strategy Element Targeting**:
   - Accessibility ID / XPath element lookup with automatic fallback to high-precision W3C pointer coordinates.
5. **Spec-Driven Theme Synchronization**:
   - Node.js script synchronizes design tokens from Markdown specifications (`design_specs/`) directly to Flutter theme Dart files.
