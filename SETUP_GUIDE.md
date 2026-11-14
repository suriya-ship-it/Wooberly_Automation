# Wooberly Appium Automation — Complete Setup & Execution Guide

This document provides step-by-step instructions to set up and run the Wooberly Mobile Test Automation suite on a completely fresh, bare machine (no pre-installed tools or dependencies).

---

## 1. System Requirements & Tested Versions

| Tool / Dependency | Recommended Version | Purpose |
| :--- | :--- | :--- |
| **Operating System** | macOS Sequoia (15.x) or later (Apple Silicon / Intel) | Test runner host |
| **Node.js** | `v22.16.0` LTS (or `v20.x`+) | JavaScript/TypeScript execution runtime |
| **npm** | `10.9.2` (comes with Node) | Package manager |
| **Java (JDK)** | `OpenJDK 21.0.12.1` (or `OpenJDK 17`) | Required by Android SDK & Appium |
| **Android SDK** | `Android SDK Platform-Tools 37.0.0+` (`adb 1.0.41`) | Android device communication |
| **Appium Server** | `v3.8.0` (or `v2.x`+) | Mobile automation server |
| **UiAutomator2 Driver** | `v8.7.0` | Appium Android automation driver |
| **XCUITest Driver** | `v12.15.0` *(optional for iOS)* | Appium iOS automation driver |
| **Python** | `Python 3.13.x` (or `3.10+`) | Video processing & inspection helpers |
| **FFmpeg** | `v8.0.1` (or `v6.x+`) | Test screen video recording & compression |

---

## 2. Phase 1: Fresh Machine Environment Installation (macOS)

Open the **Terminal** on the new machine and run the following steps sequentially.

### Step 1: Install Homebrew (Package Manager)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
*Follow the on-screen instructions to add Homebrew to your PATH (e.g. `eval "$(/opt/homebrew/bin/brew shellenv)"`).*

---

### Step 2: Install Node.js (LTS), Java OpenJDK 21, Python & FFmpeg
```bash
brew install node@22 openjdk@21 python ffmpeg
```

---

### Step 3: Install Android Command Line Tools & Platform-Tools
You can either install Android Studio or install standalone command-line tools via Homebrew:
```bash
brew install --cask android-platform-tools
```
*If you have Android Studio installed, the SDK is located at `~/Library/Android/sdk`.*

---

### Step 4: Configure Environment Variables
Add the required paths to your `~/.zshrc` (or `~/.bash_profile` if using bash):

```bash
cat << 'EOF' >> ~/.zshrc

# Java Environment
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Android SDK Environment
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Node & Global NPM binaries
export PATH="/opt/homebrew/opt/node@22/bin:$HOME/.npm-global/bin:$PATH"

EOF
```

Apply the environment changes:
```bash
source ~/.zshrc
```

Verify installations:
```bash
node -v       # Expected: v22.x or v20.x
npm -v        # Expected: 10.x
java -version # Expected: openjdk version "21.x" (or 17.x)
adb --version # Expected: Android Debug Bridge version 1.0.41+
ffmpeg -version # Expected: ffmpeg version 7.x or 8.x
```

---

## 3. Phase 2: Appium Server & Driver Setup

### Step 1: Configure NPM Global Directory (Avoid sudo permissions)
```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
```

### Step 2: Install Appium Globally
```bash
npm install -g appium@3.8.0
```
*(Or `npm install -g appium` for the latest stable version).*

### Step 3: Install the Android UiAutomator2 Driver
```bash
appium driver install uiautomator2
```

*(Optional for iOS testing)*:
```bash
appium driver install xcuitest
```

### Step 4: Verify Installed Appium Drivers
```bash
appium driver list --installed
```
*Output should show `✔ uiautomator2` as installed.*

---

## 4. Phase 3: Project Setup & Dependency Installation

### Step 1: Unpack or Clone the Project
Navigate into the project root directory:
```bash
cd /path/to/appium-automation
```

### Step 2: Install Node Dependencies
```bash
npm install
```
This installs the required packages:
- `webdriverio`: `^9.32.0`
- `tsx`: `^4.23.15`
- `typescript`: `^7.0.2`
- `nodemailer`: `^10.1.7`

### Step 3: Configure `.env` Credentials
Check or edit the `.env` file in the project root:
```properties
# Rider Login Test User Credentials
TEST_USER_EMAIL=Suriya@radicalstart.com
TEST_USER_PHONE=7010308231
TEST_USER_OTP=1234

# Driver Login Test Credentials
DRIVER_DIAL_CODE=+91
DRIVER_PHONE=7639699826
DRIVER_OTP=1234

# Play Store Dynamic Installation URLs
PLAYSTORE_RIDER_URL=https://play.google.com/store/apps/details?id=com.radicalstart.wooberly
PLAYSTORE_DRIVER_URL=https://play.google.com/store/apps/details?id=com.radicalstart.wooberlydriver

STORE_CLEAN_INSTALL=false
STORE_INSTALL_TIMEOUT_SEC=180
AUTO_RETRY_ATTEMPTS=3
```

---

## 5. Phase 4: Android Device Connection Setup

### Option A: USB Connection
1. On the Android phone, enable **Developer Options**:
   - Go to **Settings > About Phone > Software Information**.
   - Tap **Build Number** 7 times until developer mode is unlocked.
2. Under **Settings > Developer Options**:
   - Enable **USB Debugging**.
   - Enable **Install via USB** and **USB Debugging (Security settings)** if prompted.
3. Connect the phone via USB cable and allow USB Debugging prompt on the screen.
4. Verify:
   ```bash
   adb devices
   ```

### Option B: Wireless Connection (Wi-Fi)
1. Ensure the phone and computer are on the same Wi-Fi network.
2. Find the phone's IP address (e.g. `192.168.5.39`) from **Settings > About Phone > Status information > IP address**.
3. Enable Wireless Debugging in Developer Options (or run `adb tcpip 5555` while connected via USB once).
4. Connect wirelessly:
   ```bash
   adb connect 192.168.5.39:5555
   adb devices
   ```

### Pre-grant App Permissions (Recommended)
To prevent unexpected Android OS runtime permission dialogs, run:
```bash
adb shell pm grant com.radicalstart.wooberly android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb shell pm grant com.radicalstart.wooberly android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
adb shell pm grant com.radicalstart.wooberly android.permission.POST_NOTIFICATIONS 2>/dev/null || true

adb shell pm grant com.radicalstart.wooberlydriver android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb shell pm grant com.radicalstart.wooberlydriver android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
adb shell pm grant com.radicalstart.wooberlydriver android.permission.ACCESS_BACKGROUND_LOCATION 2>/dev/null || true
adb shell pm grant com.radicalstart.wooberlydriver android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb shell appops set com.radicalstart.wooberlydriver SYSTEM_ALERT_WINDOW allow 2>/dev/null || true
```

---

## 6. Phase 5: Terminal Execution Commands

### Step 1: Start Appium Server (Terminal Tab #1)
Open a dedicated terminal tab and launch the Appium server:
```bash
appium --relaxed-security --port 4723
```
*Leave this running in the background. It will listen on `http://127.0.0.1:4723`.*

---

### Step 2: Execute Automation Flows (Terminal Tab #2)

Navigate to the project directory:
```bash
cd /path/to/appium-automation
```

#### 🚀 Full Step #2 End-to-End Orchestration (Recommended)
Installs both Rider & Driver apps from Google Play Store, brings Driver online, books ride via Rider app with Cash, and completes the full 13-step driver trip lifecycle:
```bash
npm run "test:step #2"
```

---

#### 📱 Step #1 Flow (Driver Online -> Rider Booking -> Complete Trip)
If both apps are already installed and you want to run the full booking and trip lifecycle without reinstalling from Play Store:
```bash
npm run "test:step #1"
```

---

#### 🛒 Stage-by-Stage Individual Commands

1. **Install Apps from Play Store:**
   ```bash
   npm run test:store-install
   ```

2. **Bring Driver Online Only:**
   ```bash
   npm run test:driver-online
   ```

3. **Run Rider Login & Booking Flow:**
   ```bash
   npm run test:login
   ```

4. **Run Driver Trip Acceptance & 13-Step Lifecycle:**
   ```bash
   npm run test:trip
   ```

5. **Single Combined End-to-End Test:**
   ```bash
   npm run test
   ```

---

## 7. Independent Revert Commands

If you ever need to revert specific fixes independently:

| Revert Action | Command | Script | Description |
| :--- | :--- | :--- | :--- |
| **Revert Issue #1 Only** | `npm run revert:rider-dest` | `scripts/revert_rider_destination.js` | Restores original destination input logic without affecting Issue #2 |
| **Revert Issue #2 Only** | `npm run revert:driver-start-ride` | `scripts/revert_driver_start_ride.js` | Restores original Start Ride swipe delay without affecting Issue #1 |
| **Revert Retry/Email** | `npm run revert:retry-email` | `scripts/revert_retry_and_email.js` | Restores pre-email/retry configuration |

---

## 8. Where Test Artifacts & Videos Are Saved

- **Step Screenshots:** `debug_screenshots/*.png`
- **Execution Videos (MP4):** `Test reference/*.mp4` (latest execution: `Test reference/wooberly_step2_full_workflow_latest.mp4`)
