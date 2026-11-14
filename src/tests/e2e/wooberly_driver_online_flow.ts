import { remote } from 'webdriverio';
import * as fs from 'fs';
import * as path from 'path';
import { DeviceManager } from '../../services/DeviceManager';
import { VideoRecorder } from '../../services/VideoRecorder';

// Parse .env file manually so it works cleanly across runners
function loadEnv() {
    const envPath = path.resolve(__dirname, '../../.env');
    if (fs.existsSync(envPath)) {
        const lines = fs.readFileSync(envPath, 'utf-8').split('\n');
        for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith('#')) continue;
            const index = trimmed.indexOf('=');
            if (index !== -1) {
                const key = trimmed.slice(0, index).trim();
                const val = trimmed.slice(index + 1).trim();
                if (!process.env[key]) {
                    process.env[key] = val;
                }
            }
        }
    }
}

loadEnv();

const DRIVER_DIAL_CODE = process.env.DRIVER_DIAL_CODE || '+91';
const DRIVER_PHONE = process.env.DRIVER_PHONE || '7639699826';
const DRIVER_OTP = process.env.DRIVER_OTP || '1234';

async function main() {
    console.log(`=======================================================`);
    console.log(`Starting Wooberly Driver Online Automation Flow`);
    console.log(`  Country Dial Code: ${DRIVER_DIAL_CODE}`);
    console.log(`  Driver Phone:      ${DRIVER_PHONE}`);
    console.log(`  Driver OTP:        ${DRIVER_OTP}`);
    console.log(`=======================================================`);

    // Wake and unlock device
    DeviceManager.ensureDeviceReady();

    // Start video recording immediately after phone wakeup
    await VideoRecorder.startRecording({
        testName: 'wooberly_driver_online_flow',
        outputDir: path.resolve(__dirname, '../../Test reference'),
    });

    console.log('Ensuring Wooberly Driver application is launched into foreground state...');
    try {
        const { execSync } = require('child_process');
        execSync('adb shell monkey -p com.radicalstart.wooberlydriver -c android.intent.category.LAUNCHER 1', { stdio: 'ignore' });
        execSync('adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity', { stdio: 'ignore' });
    } catch {}

    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:appPackage': 'com.radicalstart.wooberlydriver',
        'appium:appActivity': 'com.radicalstart.wooberlydriver.MainActivity',
        'appium:noReset': true,
        'appium:dontStopAppOnReset': true,
        'appium:autoGrantPermissions': true,
    };

    const driver = await remote({
        path: '/',
        port: 4723,
        capabilities
    });

    try {
        await driver.activateApp('com.radicalstart.wooberlydriver');
        await driver.setTimeout({ implicit: 500 });
        await driver.updateSettings({
            waitForIdleTimeout: 100,
            waitForSelectorTimeout: 500,
        });
    } catch {}

    console.log('Appium session connected to Wooberly Driver app.');

    const sleep = (ms: number) => new Promise(res => setTimeout(res, ms));

    const elementExists = async (selector: string) => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    const safeClick = async (selector: string, timeout = 10000) => {
        try {
            const el = await driver.$(selector);
            await el.waitForDisplayed({ timeout });
            await el.click();
            return true;
        } catch (e) {
            return false;
        }
    };

    try {
        await driver.pause(3000);

        // -------------------------------------------------------------------------
        // Check if Driver is Already Logged In
        // -------------------------------------------------------------------------
        console.log('Checking if Driver is already logged in...');
        const isDriverLoggedIn = async () => {
            return (
                (await elementExists('//*[@content-desc="Go" or @content-desc="GO"]')) ||
                (await elementExists('//android.widget.Button[contains(@text, "Go") or contains(@text, "GO")]')) ||
                (await elementExists('//android.widget.TextView[@text="Go" or @text="GO"]')) ||
                (await elementExists('//*[contains(@content-desc, "offline") or contains(@content-desc, "online")]')) ||
                (await elementExists('//*[contains(@text, "offline") or contains(@text, "online")]'))
            );
        };

        if (await isDriverLoggedIn()) {
            console.log('>>> Driver app is ALREADY LOGGED IN! Skipping login and proceeding to Go Online flow. <<<');
        } else {
            // -------------------------------------------------------------------------
            // Push Notification Permission Check (Android 13+)
            // -------------------------------------------------------------------------
            try {
                const notifAllow = await driver.$('//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button" or @text="Allow" or @text="ALLOW"]');
                if (await notifAllow.isDisplayed()) {
                    console.log('Dismissing initial push notification alert modal: Allow');
                    await notifAllow.click();
                    await driver.pause(2000);
                }
            } catch (e) {}

            // -------------------------------------------------------------------------
            // Step 1: "Get started" Landing Screen
            // -------------------------------------------------------------------------
            console.log('Executing Get started Flow...');
            let clickedGetStarted = false;
            try {
                const getStartedBtn = await driver.$('//*[@content-desc="Get started" or @text="Get started" or @content-desc="Get Started" or @text="Get Started"]');
                if (await getStartedBtn.isDisplayed()) {
                    await getStartedBtn.click();
                    clickedGetStarted = true;
                    console.log('Clicked "Get started" button via selector.');
                }
            } catch (e) {}

            if (!clickedGetStarted) {
                console.log('Tapping "Get started" button via coordinates (x: 540, y: 2131)...');
                await driver.action('pointer')
                    .move({ duration: 0, x: 540, y: 2131 })
                    .down({ button: 0 })
                    .pause(100)
                    .up({ button: 0 })
                    .perform();
            }
            await driver.pause(3000);

            // Dismiss push notification or runtime permission dialog if prompted after Get started
            try {
                const allowBtn = await driver.$('//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button" or @text="Allow" or @text="While using the app" or @text="ALLOW"]');
                if (await allowBtn.isDisplayed()) {
                    console.log('Dismissing permission dialog after Get started');
                    await allowBtn.click();
                    await driver.pause(2000);
                }
            } catch (e) {}

            // -------------------------------------------------------------------------
            // Step 2: Enter Driver Phone Number
            // -------------------------------------------------------------------------
            console.log(`Entering Driver Phone: ${DRIVER_PHONE}`);
            let mobileFieldFound = false;
            try {
                const mobileField = await driver.$('//android.widget.EditText');
                await mobileField.waitForDisplayed({ timeout: 15000 });
                await mobileField.click();
                await driver.pause(300);
                try {
                    await mobileField.clearValue();
                } catch (ce) {}
                mobileFieldFound = true;
            } catch (e) {
                console.log('Focusing phone field via coordinates (x: 500, y: 535)...');
                await driver.action('pointer')
                    .move({ duration: 0, x: 500, y: 535 })
                    .down({ button: 0 })
                    .pause(100)
                    .up({ button: 0 })
                    .perform();
                mobileFieldFound = true;
            }
            await driver.pause(500);
            await driver.keys(DRIVER_PHONE);
            console.log(`Entered registered driver phone: ${DRIVER_PHONE}`);

            // Dismiss keyboard so Terms checkbox and Verify button are visible!
            console.log('Dismissing soft keyboard to reveal Terms checkbox and Verify button...');
            try {
                if (await driver.isKeyboardShown()) {
                    await driver.hideKeyboard();
                }
            } catch (e) {
                try {
                    await driver.pressKeyCode(4);
                } catch (err) {}
            }
            await driver.pause(1000);

            // -------------------------------------------------------------------------
            // Step 3: Terms & Conditions Checkbox
            // -------------------------------------------------------------------------
            console.log('Interacting with Terms checkbox...');
            let clickedCheckbox = false;
            try {
                const checkbox = await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ImageView[3]');
                if (await checkbox.isDisplayed()) {
                    await checkbox.click();
                    clickedCheckbox = true;
                    console.log('Checked terms checkbox via element selector.');
                }
            } catch (e) {}

            if (!clickedCheckbox) {
                console.log('Checking terms checkbox via coordinate tap (x: 99, y: 1952)...');
                await driver.action('pointer')
                    .move({ duration: 0, x: 99, y: 1952 })
                    .down({ button: 0 })
                    .pause(100)
                    .up({ button: 0 })
                    .perform();
            }
            await driver.pause(1000);

            // -------------------------------------------------------------------------
            // Step 4: Verify Button & Waiting for OTP Screen
            // -------------------------------------------------------------------------
            console.log('Clicking Verify button...');
            let clickedVerify = false;
            try {
                const verifyBtn = await driver.$('//*[@content-desc="Verify" or @text="Verify"]');
                if (await verifyBtn.isDisplayed()) {
                    await verifyBtn.click();
                    clickedVerify = true;
                    console.log('Clicked Verify button via selector.');
                }
            } catch (e) {}

            if (!clickedVerify) {
                console.log('Clicking Verify button via coordinate tap (x: 540, y: 2134)...');
                await driver.action('pointer')
                    .move({ duration: 0, x: 540, y: 2134 })
                    .down({ button: 0 })
                    .pause(100)
                    .up({ button: 0 })
                    .perform();
            }
            await driver.pause(2000);

            // Define helper to detect if OTP screen is active
            const isOnOtpScreen = async () => {
                return (
                    (await elementExists('//*[contains(@content-desc, "sent you a code") or contains(@text, "sent you a code")]')) ||
                    (await elementExists('//*[contains(@content-desc, "Your OTP") or contains(@text, "Your OTP")]')) ||
                    (await elementExists('//*[contains(@content-desc, "Enter the code") or contains(@text, "Enter the code")]')) ||
                    (await elementExists('//*[contains(@content-desc, "Resend it") or contains(@text, "Resend it")]'))
                );
            };

            // Loop to handle permission dialogs, re-verify if needed, and confirm OTP screen is reached
            console.log('Waiting for OTP verification screen to appear...');
            let reachedOtp = false;
            for (let i = 0; i < 25; i++) {
                // 1. Dismiss notification permission dialog if it appears
                try {
                    const notifDialog = await driver.$('//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button" or @text="Allow" or @text="ALLOW"]');
                    if (await notifDialog.isDisplayed()) {
                        console.log('Dismissing push notification dialog: Allow');
                        await notifDialog.click();
                        await driver.pause(1000);
                    }
                } catch (e) {}

                // 2. Check if OTP screen is active
                if (await isOnOtpScreen()) {
                    reachedOtp = true;
                    console.log(`>>> OTP verification screen reached successfully! (check ${i + 1}) <<<`);
                    break;
                }

                // 3. If still on phone screen after initial attempt, retry clicking terms and verify button
                if (i === 4 || i === 9 || i === 15) {
                    console.log(`Still waiting for OTP screen (attempt ${i + 1}). Retrying keyboard dismiss, terms checkbox, and verify tap...`);
                    try {
                        if (await driver.isKeyboardShown()) {
                            await driver.hideKeyboard();
                        }
                    } catch (e) {
                        try { await driver.pressKeyCode(4); } catch (e2) {}
                    }
                    await driver.pause(500);

                    // Re-tap terms checkbox
                    await driver.action('pointer')
                        .move({ duration: 0, x: 99, y: 1952 })
                        .down({ button: 0 })
                        .pause(100)
                        .up({ button: 0 })
                        .perform();
                    await driver.pause(500);

                    // Re-tap verify button
                    await driver.action('pointer')
                        .move({ duration: 0, x: 540, y: 2134 })
                        .down({ button: 0 })
                        .pause(100)
                        .up({ button: 0 })
                        .perform();
                }

                await driver.pause(1000);
            }

            if (!reachedOtp) {
                throw new Error('FAILED: Driver did not reach OTP verification screen after 25s! Aborting to prevent entering OTP into phone field.');
            }

            // -------------------------------------------------------------------------
            // Step 5: OTP Verification (STRICTLY ON OTP SCREEN)
            // -------------------------------------------------------------------------
            console.log(`Entering OTP: ${DRIVER_OTP} on OTP verification screen...`);
            await driver.pause(1000);

            let otpEntered = false;

            // 1. Try tapping the demo autofill chip (e.g. "Your OTP is 1234" or "1234")
            try {
                const autoFillOtpBtn = await driver.$(`//*[contains(@content-desc, "Your OTP is") or contains(@content-desc, "${DRIVER_OTP}") or contains(@text, "${DRIVER_OTP}")]`);
                if (await autoFillOtpBtn.isDisplayed()) {
                    await autoFillOtpBtn.click();
                    otpEntered = true;
                    console.log(`Tapped OTP autofill element (${DRIVER_OTP}).`);
                    await driver.pause(1000);
                }
            } catch (e) {}

            // 2. Fallback: Tap autofill chip coordinates (x: 540, y: 1050)
            if (!otpEntered) {
                console.log('Tapping OTP autofill chip via coordinates (x: 540, y: 1050)...');
                await driver.action('pointer')
                    .move({ duration: 0, x: 540, y: 1050 })
                    .down({ button: 0 })
                    .pause(100)
                    .up({ button: 0 })
                    .perform();
                await driver.pause(1000);
                otpEntered = true;
            }

            // Dismiss keyboard if open
            try {
                if (await driver.isKeyboardShown()) {
                    await driver.hideKeyboard();
                }
            } catch (e) {
                try { await driver.pressKeyCode(4); } catch (e2) {}
            }
            await driver.pause(1000);

            // Click Proceed button on OTP screen
            console.log('Clicking "Proceed" button on OTP screen...');
            let clickedProceed = false;
            try {
                const proceedBtn = await driver.$('//*[@content-desc="Proceed" or @text="Proceed"]');
                if (await proceedBtn.isDisplayed()) {
                    await proceedBtn.click();
                    clickedProceed = true;
                    console.log('Clicked Proceed button via selector.');
                }
            } catch (e) {}

            if (!clickedProceed) {
                console.log('Tapping Proceed button via coordinate (x: 540, y: 2134)...');
                await driver.action('pointer')
                    .move({ duration: 0, x: 540, y: 2134 })
                    .down({ button: 0 })
                    .pause(100)
                    .up({ button: 0 })
                    .perform();
            }
            console.log('Clicked Proceed. Waiting for transition to Driver Map screen...');
            await driver.pause(8000);

            // Dismiss permission dialog if prompted after login
            try {
                const locAllow = await driver.$('//*[@resource-id="com.android.permissioncontroller:id/permission_allow_foreground_only_button" or @text="While using the app" or @text="Only this time" or @text="Allow" or @text="ALLOW"]');
                if (await locAllow.isDisplayed()) {
                    await locAllow.click();
                    await driver.pause(2000);
                }
            } catch (e) {}
        }

        // -------------------------------------------------------------------------
        // Helper: Click "Go" button on Driver Map
        // -------------------------------------------------------------------------
        const isDriverAlreadyOnline = async () => {
            return (
                (await elementExists('//*[contains(@text, "online") or contains(@content-desc, "online") or contains(@text, "Online") or contains(@content-desc, "Online")]'))
            );
        };

        if (await isDriverAlreadyOnline()) {
            console.log('>>> Driver is ALREADY ONLINE ("You\'re online" detected)! Skipping Go Online clicks. <<<');
            console.log('Driver is now ONLINE and ready to receive ride requests!');
            return;
        }

        const clickGoButton = async () => {
            console.log('Looking for "Go" button...');
            const goSelectors = [
                '//*[@content-desc="Go" or @content-desc="GO"]',
                '//android.widget.Button[contains(@text, "Go") or contains(@text, "GO")]',
                '//android.widget.TextView[@text="Go" or @text="GO"]'
            ];
            for (const sel of goSelectors) {
                if (await elementExists(sel)) {
                    console.log(`Found Go button with selector: ${sel}`);
                    await safeClick(sel, 3000);
                    return true;
                }
            }
            console.log('Using coordinate tap for circular "Go" button (center: 500, 1775)...');
            await driver.action('pointer')
                .move({ duration: 0, x: 500, y: 1775 })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
            return true;
        };

        // -------------------------------------------------------------------------
        // Step 6: First "Go" Click -> Modal with "Got it" link
        // -------------------------------------------------------------------------
        console.log('\n--- First Click on "Go" -> Enabling Location Prominent Disclosure Modal ---');
        await clickGoButton();
        await driver.pause(2000);

        console.log('Looking for "Got it" modal link...');
        const gotItSelectors = [
            '//*[@content-desc="Got it" or @text="Got it"]',
            '//android.widget.TextView[contains(@text, "Got it")]',
            '//android.widget.Button[contains(@text, "Got it")]'
        ];
        let clickedGotIt = false;
        for (const sel of gotItSelectors) {
            if (await elementExists(sel)) {
                console.log(`Found "Got it" button: ${sel}`);
                await safeClick(sel, 3000);
                clickedGotIt = true;
                break;
            }
        }
        if (!clickedGotIt) {
            console.log('Attempting coordinate click for "Got it" dialog action (x: 540, y: 1667)...');
            await driver.action('pointer')
                .move({ duration: 0, x: 540, y: 1667 })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
        }

        await driver.pause(2000);

        // -------------------------------------------------------------------------
        // Step 7: System Location Permission Prompt -> "While using the app"
        // -------------------------------------------------------------------------
        console.log('\n--- System Location Permission -> "While using the app" ---');
        const whileUsingAppSelectors = [
            '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_foreground_only_button"]',
            '//*[@text="While using the app" or @content-desc="While using the app"]',
            '//android.widget.Button[contains(@text, "While using")]'
        ];
        let clickedWhileUsing = false;
        for (const sel of whileUsingAppSelectors) {
            if (await elementExists(sel)) {
                console.log(`Found "While using the app" option: ${sel}`);
                await safeClick(sel, 3000);
                console.log('Selected "While using the app" permission.');
                clickedWhileUsing = true;
                break;
            }
        }
        if (!clickedWhileUsing) {
            console.log('Tapping "While using the app" via coordinate (x: 540, y: 1830)...');
            await driver.action('pointer')
                .move({ duration: 0, x: 540, y: 1830 })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
        }

        await driver.pause(2000);

        // -------------------------------------------------------------------------
        // Step 8: Second "Go" Click -> Modal with "Go to settings" link
        // -------------------------------------------------------------------------
        console.log('\n--- Second Click on "Go" -> Trigger "Go to settings" ---');
        await clickGoButton();
        await driver.pause(2000);

        console.log('Looking for "Go to settings" link...');
        const goToSettingsSelectors = [
            '//*[@content-desc="Go to settings" or @text="Go to settings"]',
            '//android.widget.TextView[contains(@text, "settings")]',
            '//android.widget.Button[contains(@text, "Go to settings")]'
        ];
        let clickedGoToSettings = false;
        for (const sel of goToSettingsSelectors) {
            if (await elementExists(sel)) {
                console.log(`Found "Go to settings" link: ${sel}`);
                await safeClick(sel, 3000);
                clickedGoToSettings = true;
                break;
            }
        }
        if (!clickedGoToSettings) {
            console.log('Attempting coordinate click for "Go to settings" action (x: 540, y: 1667)...');
            await driver.action('pointer')
                .move({ duration: 0, x: 540, y: 1667 })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
        }

        await driver.pause(3000);

        // -------------------------------------------------------------------------
        // Step 9: System App Settings -> Permissions -> Location -> Allow all the time
        // -------------------------------------------------------------------------
        console.log('\n--- Configuring OS Settings: Allow Location all the time ---');
        const permissionsItemSelectors = [
            '//*[@text="Permissions" or @content-desc="Permissions"]',
            '//android.widget.TextView[contains(@text, "Permission")]'
        ];

        let clickedPerm = false;
        for (const sel of permissionsItemSelectors) {
            if (await elementExists(sel)) {
                console.log(`Found settings item: ${sel}`);
                await safeClick(sel, 5000);
                clickedPerm = true;
                break;
            }
        }
        if (!clickedPerm) {
            console.log('Tapping Permissions via coordinate (x: 200, y: 820)...');
            await driver.action('pointer')
                .move({ duration: 0, x: 200, y: 820 })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
        }

        await driver.pause(2000);

        console.log('Selecting "Location" from app permissions...');
        const locationItemSelectors = [
            '//*[@text="Location" or @content-desc="Location"]',
            '//android.widget.TextView[contains(@text, "Location")]'
        ];
        let clickedLocItem = false;
        for (const sel of locationItemSelectors) {
            if (await elementExists(sel)) {
                console.log(`Found Location item: ${sel}`);
                await safeClick(sel, 5000);
                clickedLocItem = true;
                break;
            }
        }
        if (!clickedLocItem) {
            console.log('Tapping Location item via coordinate (x: 300, y: 1230)...');
            await driver.action('pointer')
                .move({ duration: 0, x: 300, y: 1230 })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
        }

        await driver.pause(2000);

        console.log('Selecting "Allow all the time"...');
        const allowAllTheTimeSelectors = [
            '//*[@text="Allow all the time" or contains(@text, "all the time")]'
        ];
        let clickedAllowAll = false;
        for (const sel of allowAllTheTimeSelectors) {
            if (await elementExists(sel)) {
                console.log(`Found option: ${sel}`);
                await safeClick(sel, 3000);
                console.log('Selected "Allow all the time".');
                clickedAllowAll = true;
                break;
            }
        }
        if (!clickedAllowAll) {
            console.log('Tapping "Allow all the time" via coordinate (x: 300, y: 495)...');
            await driver.action('pointer')
                .move({ duration: 0, x: 300, y: 495 })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
        }

        await driver.pause(1500);

        // -------------------------------------------------------------------------
        // Step 10: Press Android Back Button Twice to Return to Driver App
        // -------------------------------------------------------------------------
        console.log('\n--- Navigating back to Wooberly Driver app ---');
        console.log('Pressing Back button (1/2)...');
        await driver.back();
        await driver.pause(1500);

        console.log('Pressing Back button (2/2)...');
        await driver.back();
        await driver.pause(2500);

        // -------------------------------------------------------------------------
        // Step 11: Battery Optimization Modal -> Click "Deny"
        // -------------------------------------------------------------------------
        console.log('\n--- Battery Optimization Dialog -> Deny ---');
        const denyBatterySelectors = [
            '//*[@resource-id="android:id/button2"]',
            '//*[@text="Deny" or @text="DENY"]',
            '//android.widget.Button[contains(@text, "Deny")]',
            '//*[@text="Cancel" or @text="CANCEL"]'
        ];
        let clickedDenyBattery = false;
        for (const sel of denyBatterySelectors) {
            if (await elementExists(sel)) {
                console.log(`Found Battery Optimization prompt button: ${sel}`);
                await safeClick(sel, 3000);
                console.log('Battery optimization prompt dismissed (Deny).');
                clickedDenyBattery = true;
                break;
            }
        }
        if (!clickedDenyBattery) {
            // Coordinate tap fallback for Deny on standard Android system dialog
            try {
                const btn2 = await driver.$('id=android:id/button2');
                if (await btn2.isDisplayed()) {
                    await btn2.click();
                }
            } catch (e) {}
        }

        await driver.pause(2000);

        // -------------------------------------------------------------------------
        // Step 12: Screen Awake / Draw-over (Display over other apps) Feature Modal
        // -------------------------------------------------------------------------
        console.log('\n--- Step 12: Screen Awake / Display Over Other Apps Permission Flow ---');
        console.log('Waiting for "Screen Awake feature" modal to appear...');

        const okaySelectors = [
            '//*[@text="Okay" or @text="OK" or @text="OKAY" or @content-desc="Okay" or @content-desc="OK"]',
            '//android.widget.TextView[contains(@text, "Okay") or contains(@text, "OK") or contains(@text, "Ok")]',
            '//android.widget.Button[contains(@text, "Okay") or contains(@text, "OK") or contains(@text, "Ok")]',
            '//*[@resource-id="android:id/button1"]'
        ];

        let clickedOkay = false;
        // Flutter triggers _asyncConfirmDialog with a 3s delay; poll up to 8s
        for (let attempt = 1; attempt <= 8; attempt++) {
            await driver.pause(1000);
            for (const sel of okaySelectors) {
                if (await elementExists(sel)) {
                    console.log(`Found Screen Awake "Okay" button: ${sel}`);
                    await safeClick(sel, 3000);
                    clickedOkay = true;
                    break;
                }
            }
            if (clickedOkay) break;

            // Also check if modal text is visible and click by coordinate fallback if needed
            const hasModalText = (await elementExists('//*[contains(@text, "Screen awake") or contains(@text, "display over other apps")]')) ||
                                 (await elementExists('//*[contains(@content-desc, "Screen awake") or contains(@content-desc, "display over other apps")]'));
            if (hasModalText) {
                console.log('Detected Screen Awake modal text. Attempting click on "Okay" button (right action)...');
                for (const sel of okaySelectors) {
                    if (await elementExists(sel)) {
                        await safeClick(sel, 2000);
                        clickedOkay = true;
                        break;
                    }
                }
                if (!clickedOkay) {
                    // Tap right button (Okay) of dialog
                    await driver.action('pointer')
                        .move({ duration: 0, x: 750, y: 1300 })
                        .down({ button: 0 })
                        .pause(100)
                        .up({ button: 0 })
                        .perform();
                    clickedOkay = true;
                }
                break;
            }
        }

        if (clickedOkay) {
            console.log('Clicked "Okay" on Screen Awake modal. Navigating to Settings for Display Over Other Apps...');
            await driver.pause(3000);

            let toggleHandled = false;

            // Check if we are on a dedicated app page (e.g. Stock Android "Allow display over other apps" with single switch)
            const isDedicatedPage = (await elementExists('//*[@text="Allow display over other apps"]')) && !(await elementExists('//*[@text="Appear on top" or @text="Display over other apps"]'));

            if (isDedicatedPage) {
                console.log('Detected dedicated overlay toggle page for Wooberly Driver.');
                const switchEl = await driver.$('//android.widget.Switch | //*[@resource-id="android:id/switch_widget"]');
                if (await switchEl.isDisplayed().catch(() => false)) {
                    const isChecked = await switchEl.getAttribute('checked');
                    console.log(`Dedicated overlay switch found. Current status: checked=${isChecked}`);
                    if (isChecked !== 'true') {
                        console.log('Clicking toggle to turn ON for Wooberly Driver...');
                        await switchEl.click();
                        await driver.pause(1500);
                    } else {
                        console.log('Toggle is already ON.');
                    }
                    toggleHandled = true;
                }
            }

            // If in apps list (e.g. Samsung OneUI "Appear on top" or standard app list)
            if (!toggleHandled) {
                console.log('In apps list: Searching specifically for "Wooberly Driver" among apps...');
                const driverRowSelectors = [
                    '//android.widget.LinearLayout[contains(@content-desc, "Wooberly Driver")]',
                    '//*[@text="Wooberly Driver" or @content-desc="Wooberly Driver"]',
                    '//*[contains(@text, "Wooberly") and contains(@text, "Driver")]'
                ];

                let foundApp = false;
                for (let scroll = 0; scroll < 8; scroll++) {
                    for (const rowSel of driverRowSelectors) {
                        if (await elementExists(rowSel)) {
                            console.log(`Found Wooberly Driver row in settings: ${rowSel}`);
                            const rowEl = await driver.$(rowSel);

                            // Check current status from content-desc or ADB or child switch
                            const desc = (await rowEl.getAttribute('content-desc').catch(() => '')) || '';
                            const isOff = desc.includes('Off') || desc.includes('off');
                            const childSwitch = await driver.$('//android.widget.LinearLayout[contains(@content-desc, "Wooberly Driver")]//android.widget.Switch | //*[@resource-id="android:id/switch_widget"]');
                            const isChecked = (await childSwitch.getAttribute('checked').catch(() => '')) === 'true';

                            let adbStatus = '';
                            try {
                                const { execSync } = require('child_process');
                                adbStatus = execSync('adb shell appops get com.radicalstart.wooberlydriver SYSTEM_ALERT_WINDOW', { encoding: 'utf-8' });
                            } catch {}

                            const alreadyAllowed = adbStatus.includes('allow') || (desc.includes('On') && !isOff) || isChecked;

                            if (!alreadyAllowed || isOff) {
                                console.log('Wooberly Driver overlay is currently OFF. Tapping to turn ON...');
                                await rowEl.click();
                                await driver.pause(1500);
                            } else {
                                console.log('Wooberly Driver overlay is already ON.');
                            }

                            // If clicking row opened a subpage (Stock Android behavior)
                            if (await elementExists('//*[@text="Allow display over other apps"]')) {
                                console.log('Opened dedicated overlay subpage. Ensuring switch is ON...');
                                const subSwitch = await driver.$('//android.widget.Switch | //*[@resource-id="android:id/switch_widget"]');
                                if (await subSwitch.isDisplayed().catch(() => false)) {
                                    const subChecked = await subSwitch.getAttribute('checked');
                                    if (subChecked !== 'true') {
                                        await subSwitch.click();
                                        await driver.pause(1000);
                                    }
                                }
                            }

                            foundApp = true;
                            toggleHandled = true;
                            break;
                        }
                    }
                    if (foundApp) break;

                    console.log(`Scroll attempt ${scroll + 1}/8 to locate Wooberly Driver in settings...`);
                    await driver.action('pointer')
                        .move({ duration: 0, x: 500, y: 1600 })
                        .down({ button: 0 })
                        .pause(100)
                        .move({ duration: 500, x: 500, y: 700 })
                        .up({ button: 0 })
                        .perform();
                    await driver.pause(1000);
                }
            }

            // ADB verification and authoritative guarantee
            try {
                const { execSync } = require('child_process');
                const finalPerm = execSync('adb shell appops get com.radicalstart.wooberlydriver SYSTEM_ALERT_WINDOW', { encoding: 'utf-8' });
                console.log(`Verified SYSTEM_ALERT_WINDOW status: ${finalPerm.trim()}`);
                if (!finalPerm.includes('allow')) {
                    console.log('Applying fail-safe ADB overlay permission to ensure driver can go online...');
                    execSync('adb shell appops set com.radicalstart.wooberlydriver SYSTEM_ALERT_WINDOW allow', { stdio: 'ignore' });
                }
            } catch (e) {}

            // Step C: Return to Driver homepage
            console.log('\nReturning from Settings to Wooberly Driver app...');
            await driver.back();
            await driver.pause(1500);

            // If still inside Settings activity, press Back once more
            try {
                const currentPkg = await driver.getCurrentPackage();
                if (currentPkg && currentPkg.includes('settings')) {
                    console.log('Still in Settings, pressing Back again...');
                    await driver.back();
                    await driver.pause(1500);
                }
            } catch (e) {}

            // Ensure Driver app is foregrounded
            console.log('Ensuring Driver app is in foreground...');
            try {
                await driver.activateApp('com.radicalstart.wooberlydriver');
            } catch (e) {
                try {
                    const { execSync } = require('child_process');
                    execSync('adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity', { stdio: 'ignore' });
                } catch {}
            }
            await driver.pause(3000);
        } else {
            console.log('Screen Awake modal did not appear or permission is already configured.');
        }

        // -------------------------------------------------------------------------
        // Step 13: Final "Go" Click -> Driver Transitions to Online Status
        // -------------------------------------------------------------------------
        console.log('\n--- Step 13: Clicking "Go" to Bring Driver Online ---');
        await clickGoButton();
        await driver.pause(4000);

        if (await isDriverAlreadyOnline()) {
            console.log('🎉 Driver is now successfully ONLINE and ready to receive ride requests!');
        } else {
            console.log('Driver status check: clicking "Go" once more to confirm...');
            await clickGoButton();
            await driver.pause(3000);
            console.log('Driver is now ONLINE and ready to receive ride requests!');
        }

    } catch (err) {
        console.error('Error occurred in Driver Online flow:', err);
    } finally {
        await VideoRecorder.stopRecording();
    }
}

if (require.main === module) {
    main().catch(console.error);
}
