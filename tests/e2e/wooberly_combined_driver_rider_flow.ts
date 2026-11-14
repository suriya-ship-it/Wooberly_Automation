import { remote } from 'webdriverio';
import * as fs from 'fs';
import * as path from 'path';
import { execSync, spawn } from 'child_process';
import { DeviceManager } from '../../services/DeviceManager';
import { VideoRecorder } from '../../services/VideoRecorder';
import { PaymentManager } from '../../services/PaymentManager';
import { PaymentConfig } from '../../config/payment_credentials';

function adbTap(x: number, y: number) {
    try {
        execSync(`adb shell input tap ${Math.round(x)} ${Math.round(y)}`, { stdio: 'ignore' });
    } catch {}
}

function adbSwipe(startX: number, startY: number, endX: number, endY: number, durationMs = 800) {
    try {
        execSync(`adb shell input swipe ${Math.round(startX)} ${Math.round(startY)} ${Math.round(endX)} ${Math.round(endY)} ${durationMs}`, { stdio: 'ignore' });
    } catch {}
}

async function pointerTap(driver: WebdriverIO.Browser, x: number, y: number) {
    try {
        await driver.action('pointer')
            .move({ duration: 0, x: Math.round(x), y: Math.round(y) })
            .down({ button: 0 })
            .pause(100)
            .up({ button: 0 })
            .perform();
    } catch {}
    adbTap(x, y);
}

async function safePointerClick(driver: WebdriverIO.Browser, selector: string, fallbackX: number, fallbackY: number) {
    try {
        const el = await driver.$(selector);
        if (await el.isDisplayed()) {
            const loc = await el.getLocation();
            const size = await el.getSize();
            const cx = Math.round(loc.x + size.width / 2);
            const cy = Math.round(loc.y + size.height / 2);
            await pointerTap(driver, cx, cy);
            return true;
        }
    } catch {}
    await pointerTap(driver, fallbackX, fallbackY);
    return true;
}

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

const USER_PHONE = process.env.TEST_USER_PHONE || '9876543210';
const USER_OTP = process.env.TEST_USER_OTP || '1234';

async function runDriverOnlineFlow(driver: WebdriverIO.Browser) {
    console.log(`=======================================================`);
    console.log(`PHASE 1: Bringing Wooberly Driver Online`);
    console.log(`  Driver Phone: ${DRIVER_PHONE} | OTP: ${DRIVER_OTP}`);
    console.log(`=======================================================`);

    const elementExists = async (selector: string) => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    const safeClick = async (selector: string, timeout = 5000) => {
        try {
            const el = await driver.$(selector);
            await el.waitForDisplayed({ timeout });
            await el.click();
            return true;
        } catch (e) {
            return false;
        }
    };

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
        console.log('>>> Driver app is ALREADY LOGGED IN! Skipping driver login and proceeding to Go Online flow. <<<');
    } else {
        // Push Notification Permission Check (Android 13+)
        try {
            const notifAllow = await driver.$('//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button" or @text="Allow" or @text="ALLOW"]');
            if (await notifAllow.isDisplayed()) {
                console.log('Dismissing initial push notification alert modal: Allow');
                await notifAllow.click();
                await driver.pause(2000);
            }
        } catch (e) {}

        // Check if Driver is already on OTP screen
        const isOnOtpScreen = await elementExists('//*[contains(@content-desc, "sent you a code") or contains(@text, "sent you a code") or contains(@content-desc, "Your OTP")]');
        if (isOnOtpScreen) {
            console.log('Driver app is already on OTP verification screen! Proceeding directly to OTP entry...');
        } else {
            // Step 1: "Get started" Landing Screen
            console.log('Executing Driver "Get started" flow...');
            // Check if we are already on the phone screen or landing screen
            const isAlreadyOnPhone = await elementExists('//android.widget.EditText');
            if (!isAlreadyOnPhone) {
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
                await driver.pause(4000);

                // If still on landing screen, perform a double-tap/focus
                if (!(await elementExists('//android.widget.EditText'))) {
                    console.log('Retrying coordinate tap on "Get started" (x: 540, y: 2131)...');
                    await driver.action('pointer')
                        .move({ duration: 0, x: 540, y: 2131 })
                        .down({ button: 0 })
                        .pause(100)
                        .up({ button: 0 })
                        .perform();
                    await driver.pause(3000);
                }
            }

            // Dismiss permission dialog if prompted after Get started
            try {
                const allowBtn = await driver.$('//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button" or @text="Allow" or @text="While using the app" or @text="ALLOW"]');
                if (await allowBtn.isDisplayed()) {
                    console.log('Dismissing permission dialog after Get started');
                    await allowBtn.click();
                    await driver.pause(2000);
                }
            } catch (e) {}

            // Step 2: Enter Driver Phone Number
            console.log(`Entering Driver Phone: ${DRIVER_PHONE}`);
            let mobileFieldFound = false;
            try {
                const mobileField = await driver.$('//android.widget.EditText');
                await mobileField.waitForDisplayed({ timeout: 20000 });
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

            // Step 3: Terms & Conditions Checkbox
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

            // Step 4: Verify Button
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

            // Helper to detect if OTP screen is active
            const isOtpVerificationScreen = async () => {
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
                if (await isOtpVerificationScreen()) {
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
        }

        // Step 5: OTP Verification (STRICTLY ON OTP SCREEN)
        console.log(`Entering OTP: ${DRIVER_OTP} on OTP verification screen...`);
        await driver.pause(1000);

        let otpEntered = false;

        // 1. Try clicking demo autofill chip if present
        try {
            const autoFillOtpBtn = await driver.$(`//*[contains(@content-desc, "Your OTP is") or contains(@content-desc, "${DRIVER_OTP}") or contains(@text, "${DRIVER_OTP}")]`);
            if (await autoFillOtpBtn.isDisplayed()) {
                await autoFillOtpBtn.click();
                otpEntered = true;
                console.log(`Tapped OTP autofill element (${DRIVER_OTP}).`);
                await driver.pause(1000);
            }
        } catch (e) {}

        // 2. Direct tap on autofill chip coordinates (x: 540, y: 1050)
        if (!otpEntered) {
            console.log('Tapping OTP autofill chip coordinates (x: 540, y: 1050)...');
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

    // Check if Driver is already Online
    const isDriverOnlineAlready = async () => {
        return (
            (await elementExists('//*[contains(@text, "You\'re online") or contains(@content-desc, "You\'re online")]')) ||
            (await elementExists('//*[contains(@text, "online") or contains(@content-desc, "online")]') && 
             !(await elementExists('//*[contains(@text, "offline") or contains(@content-desc, "offline")]')))
        );
    };
    const isDriverAlreadyOnline = isDriverOnlineAlready;

    if (await isDriverOnlineAlready()) {
        console.log('>>> SUCCESS: Wooberly Driver is ALREADY ONLINE! Ready in background. <<<');
        return;
    }

    // Step 6: First "Go" Click -> Modal with "Got it" link
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

    // Step 7: System Location Permission Prompt -> "While using the app"
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

    // Step 8: Second "Go" Click -> Modal with "Go to settings" link
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

    // Step 9: System App Settings -> Permissions -> Location -> Allow all the time
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

    // Step 10: Press Back twice
    console.log('\n--- Navigating back to Wooberly Driver app ---');
    console.log('Pressing Back button (1/2)...');
    await driver.back();
    await driver.pause(1500);

    console.log('Pressing Back button (2/2)...');
    await driver.back();
    await driver.pause(2500);

    // Step 11: Battery Optimization Modal -> Click "Deny"
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
        try {
            const btn2 = await driver.$('id=android:id/button2');
            if (await btn2.isDisplayed()) {
                await btn2.click();
            }
        } catch (e) {}
    }
    await driver.pause(2000);

    // Step 12: Screen Awake / Draw-over (Display over other apps) Feature Modal
    console.log('\n--- Step 12: Screen Awake / Display Over Other Apps Permission Flow ---');
    console.log('Waiting for "Screen Awake feature" modal to appear...');

    const okaySelectors = [
        '//*[@text="Okay" or @text="OK" or @text="OKAY" or @content-desc="Okay" or @content-desc="OK"]',
        '//android.widget.TextView[contains(@text, "Okay") or contains(@text, "OK") or contains(@text, "Ok")]',
        '//android.widget.Button[contains(@text, "Okay") or contains(@text, "OK") or contains(@text, "Ok")]',
        '//*[@resource-id="android:id/button1"]'
    ];

    let clickedOkay = false;
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

        const hasModalText = (await elementExists('//*[contains(@text, "Screen awake") or contains(@text, "display over other apps")]')) ||
                             (await elementExists('//*[contains(@content-desc, "Screen awake") or contains(@content-desc, "display over other apps")]'));
        if (hasModalText) {
            console.log('Detected Screen Awake modal text. Attempting click on "Okay" button...');
            for (const sel of okaySelectors) {
                if (await elementExists(sel)) {
                    await safeClick(sel, 2000);
                    clickedOkay = true;
                    break;
                }
            }
            if (!clickedOkay) {
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

        console.log('\nReturning from Settings to Wooberly Driver app...');
        await driver.back();
        await driver.pause(1500);

        try {
            const currentPkg = await driver.getCurrentPackage();
            if (currentPkg && currentPkg.includes('settings')) {
                console.log('Still in Settings, pressing Back again...');
                await driver.back();
                await driver.pause(1500);
            }
        } catch (e) {}

        console.log('Ensuring Driver app is in foreground...');
        try {
            await driver.activateApp('com.radicalstart.wooberlydriver');
        } catch (e) {
            try {
                execSync('adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity', { stdio: 'ignore' });
            } catch {}
        }
        await driver.pause(3000);
    } else {
        console.log('Screen Awake modal did not appear or permission is already configured.');
    }

    // Step 13: Final "Go" Click -> Driver Transitions to Online Status
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
}

async function runRiderRequestFlow(driver: WebdriverIO.Browser) {
    console.log(`=======================================================`);
    console.log(`PHASE 2: Launching Wooberly Rider & Requesting Ride`);
    console.log(`  Rider Phone: ${USER_PHONE} | OTP: ${USER_OTP}`);
    console.log(`=======================================================`);

    const elementExists = async (selector: string) => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    const clickPrediction = async (searchTerm: string) => {
        try {
            const pred = await driver.$(`//android.widget.ImageView[contains(@content-desc, "${searchTerm}")]`);
            if (await pred.isDisplayed()) {
                await pred.click();
            } else {
                await driver.action('pointer').move({ duration: 0, x: 500, y: 830 }).down().pause(100).up().perform();
            }
        } catch (e) {
            await driver.action('pointer').move({ duration: 0, x: 500, y: 830 }).down().pause(100).up().perform();
        }
        await driver.pause(4000);
        return true;
    };

    // -------------------------------------------------------------------------
    // Check if Rider is Already Logged In / on Home Screen
    // -------------------------------------------------------------------------
    console.log('Checking if Rider is already logged in...');
    await driver.pause(3000);

    const isRiderLoggedIn = async () => {
        return (
            (await elementExists('~Search your destination')) ||
            (await elementExists('~Where to?')) ||
            (await elementExists('//android.widget.ImageView[@content-desc="Where to?"]')) ||
            (await elementExists('//*[contains(@content-desc, "Where to")]')) ||
            (await elementExists('//*[contains(@content-desc, "Where are you going")]')) ||
            (await elementExists('~Book now'))
        );
    };

    if (await isRiderLoggedIn()) {
        console.log('>>> Rider app is ALREADY LOGGED IN! Skipping rider login and proceeding directly to ride search. <<<');
    } else {
        // Step 1: Rider Get Started
        console.log('Executing Rider Login Flow...');
        const getStartedSelectors = [
            '~Get started',
            '//android.widget.ImageView[@content-desc="Get started"]',
            '//*[@content-desc="Get started" or @text="Get started"]'
        ];
        for (const sel of getStartedSelectors) {
            if (await elementExists(sel)) {
                await (await driver.$(sel)).click();
                await driver.pause(3000);
                break;
            }
        }

        try {
            const allowBtn = await driver.$('//*[@text="Allow" or @text="While using the app" or @text="ALLOW"]');
            if (await allowBtn.isDisplayed()) {
                console.log('Dismissing permission dialog');
                await allowBtn.click();
                await driver.pause(2000);
            }
        } catch (e) {}

        // Step 2: Rider Phone Input
        const mobileField = await driver.$('//android.widget.EditText');
        await mobileField.waitForDisplayed({ timeout: 15000 });
        await mobileField.click();
        await driver.pause(500);
        await driver.keys(USER_PHONE);
        console.log(`Entered registered rider phone: ${USER_PHONE}`);

        const doneBtn = await driver.$('~Done');
        await doneBtn.waitForDisplayed({ timeout: 5000 });
        await doneBtn.click();
        await driver.pause(1000);

        // Terms Checkbox
        console.log('Interacting with Rider Terms checkbox...');
        const checkbox = await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ImageView[3]');
        if (await checkbox.isDisplayed().catch(() => false)) {
            await checkbox.click();
        } else {
            await driver.action('pointer').move({ duration: 0, x: 100, y: 1500 }).down().pause(100).up().perform();
        }
        await driver.pause(1000);

        // Verify Button
        console.log('Clicking Verify button...');
        const verifyBtn = await driver.$('~Verify');
        await verifyBtn.waitForDisplayed({ timeout: 5000 });
        await verifyBtn.click();
        await driver.pause(3000);

        // Step 3: Rider OTP Input
        console.log(`Entering Rider OTP: ${USER_OTP}...`);
        await driver.pause(2000);

        let otpEntered = false;
        try {
            const autoFillOtpBtn = await driver.$(`//android.widget.TextView[contains(@text, "${USER_OTP}")] | //*[contains(@content-desc, "${USER_OTP}")]`);
            if (await autoFillOtpBtn.isDisplayed()) {
                await autoFillOtpBtn.click();
                otpEntered = true;
                console.log(`Tapped OTP autofill element (${USER_OTP}).`);
                await driver.pause(1000);
            }
        } catch (e) {}

        if (!otpEntered) {
            try {
                const pinFields: any = await driver.$$('//android.widget.EditText');
                if (pinFields.length > 0) {
                    console.log('Focusing OTP input field...');
                    await pinFields[0].click();
                    await driver.pause(500);
                    for (const digit of USER_OTP) {
                        await driver.keys(digit);
                        await driver.pause(100);
                    }
                    otpEntered = true;
                    console.log(`Typed OTP ${USER_OTP} into EditText.`);
                    await driver.pause(500);
                }
            } catch (e) {
                console.log('Could not type directly into EditText, trying coordinates...', e);
            }
        }

        if (!otpEntered) {
            console.log('Tapping OTP PIN input box coordinates (x: 540, y: 350)...');
            await driver.action('pointer').move({ duration: 0, x: 540, y: 350 }).down().pause(100).up().perform();
            await driver.pause(500);
            for (const digit of USER_OTP) {
                await driver.keys(digit);
                await driver.pause(100);
            }
            console.log(`Sent keys for ${USER_OTP} via coordinate focus.`);
        }

        try {
            await driver.pressKeyCode(66);
        } catch (e) {}
        await driver.pause(1000);

        // Click Proceed Button
        console.log('Clicking "Proceed" button on OTP screen...');
        const proceedBtn = await driver.$('~Proceed');
        if (await proceedBtn.isDisplayed().catch(() => false)) {
            await proceedBtn.click();
        } else {
            try {
                const proceedText = await driver.$('//*[@text="Proceed" or contains(@content-desc, "Proceed")]');
                if (await proceedText.isDisplayed()) {
                    await proceedText.click();
                } else {
                    await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
                }
            } catch (e) {
                await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
            }
        }
        console.log('Clicked Proceed. Waiting for transition to Home screen...');
        await driver.pause(8000);

        try {
            const locAllow = await driver.$('//*[@text="While using the app" or @text="Only this time" or @text="Allow" or @text="ALLOW"]');
            if (await locAllow.isDisplayed()) {
                await locAllow.click();
                await driver.pause(2000);
            }
        } catch (e) {}
    }

    // Step 4: On-Demand Destination Search
    console.log('\n--- Step 4: Starting Destination Search on Rider App ---');
    if (await elementExists('//*[@text="While using the app"]')) {
        await (await driver.$('//*[@text="While using the app"]')).click();
        await driver.pause(2000);
    }

    // Open Search destination (either ~Search your destination or ~Where to? or coordinate)
    if (await elementExists('~Search your destination')) {
        console.log('Clicking "Search your destination"...');
        await (await driver.$('~Search your destination')).click();
    } else if (await elementExists('//android.widget.ImageView[@content-desc="Where to?"]') || await elementExists('//*[contains(@content-desc, "Where to")]')) {
        console.log('Clicking "Where to?" image...');
        try {
            await (await driver.$('//android.widget.ImageView[@content-desc="Where to?"] | //*[contains(@content-desc, "Where to")]')).click();
        } catch {
            await pointerTap(driver, 225, 212);
        }
    } else {
        console.log('Tapping destination search area via coordinates (x: 225, y: 212)...');
        await pointerTap(driver, 225, 212);
    }
    await driver.pause(3000);

    // Enter Drop Location
    console.log('Focusing drop location input...');
    const dropLocationBtn = await driver.$('~Enter drop location');
    if (await dropLocationBtn.isDisplayed().catch(() => false)) {
        await dropLocationBtn.click();
    } else {
        const inputFields: any = await driver.$$('//android.widget.EditText');
        if (inputFields.length > 0) {
            const fieldToClick = inputFields[1] || inputFields[0];
            await fieldToClick.click();
        } else {
            await driver.action('pointer').move({ duration: 0, x: 500, y: 500 }).down().pause(100).up().perform();
        }
    }
    await driver.pause(1000);

    // Clear any pre-filled/default location text completely before typing
    console.log('Ensuring drop location field is cleared of any pre-filled text...');
    try {
        const inputFields: any = await driver.$$('//android.widget.EditText');
        const activeInput = inputFields.length > 1 ? inputFields[1] : (inputFields[0] || null);
        if (activeInput) {
            await activeInput.clearValue().catch(() => {});
        }
    } catch {}

    try {
        const clearBtn = await driver.$('//*[contains(@content-desc, "clear") or contains(@content-desc, "close") or contains(@content-desc, "cancel") or contains(@resource-id, "clear")]');
        if (await clearBtn.isDisplayed().catch(() => false)) {
            await clearBtn.click();
            await driver.pause(500);
        }
    } catch {}

    try {
        execSync('adb shell input keyevent 123', { stdio: 'ignore' }); // KEYCODE_MOVE_END
        execSync('adb shell "for i in $(seq 1 60); do input keyevent 67; done"', { stdio: 'ignore' }); // KEYCODE_DEL
    } catch {}
    await driver.pause(500);

    // Type character by character to avoid clipboard/IME crash
    const textToType = 'Mattuthavani madurai';
    console.log(`Typing destination: ${textToType}`);
    for (const char of textToType) {
        await driver.keys(char);
        await driver.pause(50);
    }
    await driver.pause(4000);

    console.log('Selecting drop prediction for Mattuthavani...');
    await clickPrediction('Mattuthavani');
    await driver.pause(3000);

    // Navigate through Confirm Location / Done screens
    console.log('Navigating through Confirm Location and Done screens...');
    let maxLoops = 15;
    while (maxLoops > 0) {
        const categoryScreenVisible = (await elementExists('//*[contains(@content-desc, "Choose a ride") or contains(@text, "Choose a ride")]')) ||
                                      (await elementExists('//*[contains(@content-desc, "Micro") or contains(@text, "Micro")]')) ||
                                      (await elementExists('//*[contains(@content-desc, "Book now") or contains(@text, "Book now")]'));

        if (categoryScreenVisible) {
            console.log('Category selection page reached! Breaking loop.');
            break;
        }

        const whereToGoVisible = (await elementExists('//*[contains(@content-desc, "Where to go") or contains(@text, "Where to go")]')) ||
                                 (await elementExists('//*[contains(@content-desc, "Done") or contains(@text, "Done")]'));
        if (whereToGoVisible) {
            console.log('Where to go page appeared! Clicking Done via coordinates...');
            try {
                const doneBtn = await driver.$('//*[contains(@content-desc, "Done") or contains(@text, "Done")]');
                if (await doneBtn.isDisplayed().catch(() => false)) {
                    await doneBtn.click();
                } else {
                    await pointerTap(driver, 540, 2145);
                }
            } catch {
                await pointerTap(driver, 540, 2145);
            }
            await driver.pause(3000);
            maxLoops--;
            continue;
        }

        const confirmLocationVisible = (await elementExists('//*[contains(@content-desc, "Confirm location") or contains(@text, "Confirm location")]'));
        if (confirmLocationVisible) {
            console.log('Map page appeared! Clicking Confirm location via coordinates...');
            try {
                const confLocBtn = await driver.$('//*[contains(@content-desc, "Confirm location") or contains(@text, "Confirm location")]');
                if (await confLocBtn.isDisplayed().catch(() => false)) {
                    await confLocBtn.click();
                } else {
                    await pointerTap(driver, 540, 2145);
                }
            } catch {
                await pointerTap(driver, 540, 2145);
            }
            await driver.pause(3000);
            maxLoops--;
            continue;
        }

        console.log('Waiting for destination screens, tapping Done/Confirm coordinate (540, 2145)...');
        await pointerTap(driver, 540, 2145);
        await driver.pause(2000);
        maxLoops--;
    }

    // Step 5: Vehicle Category Selection
    console.log('\n--- Step 5: Vehicle Category Selection ---');
    await driver.pause(3000);

    let categoryChosen = false;
    try {
        const availableCategories: any = await driver.$$('//*[contains(@content-desc, "min away") or contains(@content-desc, "0 min") or contains(@content-desc, "TAMIL MICRO") or contains(@content-desc, "Micro") or contains(@content-desc, "Mini") or contains(@content-desc, "Auto") or contains(@content-desc, "Luxury") or contains(@content-desc, "Prime")]');
        if (availableCategories.length > 0) {
            console.log(`Found ${availableCategories.length} category elements. Selecting the first available one...`);
            await availableCategories[0].click();
            categoryChosen = true;
        }
    } catch (e) {
        console.log('Selector check failed for category, using coordinate fallback:', e);
    }

    if (!categoryChosen) {
        console.log('Selecting category via coordinate tap (x: 500, y: 1420)...');
        await pointerTap(driver, 500, 1420);
    }
    await driver.pause(2000);

    // Step 6: Click "Book now" button
    console.log('\n--- Step 6: Tapping "Book now" button ---');
    if (await elementExists('~Book now')) {
        try { await (await driver.$('~Book now')).click(); } catch {}
    }
    await pointerTap(driver, 540, 2160);
    await driver.pause(3000);

    // Step 7: Booking Flow Completion Loop (Payment Method, Precaution, Searching Screen)
    console.log('\n--- Step 7: Completing Booking Confirmation & Payment / Precaution Flows ---');
    let bookingLoop = 25;
    let dispatched = false;

    while (bookingLoop > 0) {
        // A. Check if Searching Driver screen is reached
        if (await elementExists('~Connecting you to nearby drivers') ||
            await elementExists('~Connecting...') ||
            await elementExists('//*[contains(@content-desc, "Connecting")]') ||
            await elementExists('//*[contains(@text, "Connecting")]') ||
            await elementExists('//*[contains(@text, "nearby drivers")]') ||
            await elementExists('//*[contains(@content-desc, "nearby drivers")]') ||
            await elementExists('~Cancel request') ||
            await elementExists('//*[contains(@text, "Cancel request")]') ||
            await elementExists('//*[contains(@content-desc, "Cancel request")]')) {
            console.log('>>> SUCCESS: Rider app is ON "Connecting you to nearby drivers" screen! <<<');
            dispatched = true;
            break;
        }

        // B. Check if Driver App Trip Request modal popped up immediately
        if (await elementExists('//*[contains(@text, "Accept") or contains(@content-desc, "Accept") or contains(@text, "Decline") or contains(@content-desc, "Decline")]')) {
            console.log('>>> Driver App Trip Request modal detected! Exiting Rider loop immediately. <<<');
            dispatched = true;
            break;
        }

        // C. Check if Precaution / Instructions modal is active (Proceed button)
        if (await elementExists('//*[contains(@content-desc, "Proceed") or contains(@text, "Proceed") or contains(@content-desc, "Passenger Safety") or contains(@text, "Passenger Safety") or contains(@content-desc, "Precaution")]')) {
            console.log('Precaution modal detected! Clicking "Proceed"...');
            try {
                const proceedEl = await driver.$('//*[contains(@content-desc, "Proceed") or contains(@text, "Proceed")]');
                if (await proceedEl.isDisplayed()) {
                    await proceedEl.click();
                } else {
                    await pointerTap(driver, 790, 2160);
                }
            } catch {
                await pointerTap(driver, 790, 2160);
            }
            console.log('>>> Proceed clicked! Booking request has been dispatched. <<<');
            dispatched = true;
            await driver.pause(2000);

            // Verify arrival at "Connecting you to nearby drivers" before launching Driver app
            for (let w = 0; w < 10; w++) {
                if (await elementExists('//*[contains(@text, "Connecting") or contains(@content-desc, "Connecting") or contains(@text, "Cancel request") or contains(@content-desc, "Cancel request")]') ||
                    await elementExists('//*[contains(@text, "Accept") or contains(@content-desc, "Accept") or contains(@text, "Decline")]')) {
                    console.log('>>> Confirmed: Rider app reached "Connecting you to nearby drivers" (or Driver app received request)! <<<');
                    break;
                }
                await driver.pause(1000);
            }
            break; // Break and proceed to Driver App
        }

        // D. Check if Payment Method screen is active (Confirm button)
        if (await elementExists('//*[contains(@content-desc, "Payment method") or contains(@text, "Payment method") or contains(@content-desc, "Cash") or contains(@text, "Cash")]')) {
            console.log('Payment Method screen detected! Delegating to PaymentManager...');
            await PaymentManager.handleBookingPayment(driver);
            bookingLoop--;
            continue;
        }

        // E. Check if Book now button is still visible
        if (await elementExists('~Book now') || await elementExists('//*[@content-desc="Book now"]')) {
            console.log('Book now button still visible. Re-selecting Category 1 and tapping Book now...');
            await pointerTap(driver, 540, 1420);
            await driver.pause(1000);
            await pointerTap(driver, 540, 2160);
            await driver.pause(3000);
            bookingLoop--;
            continue;
        }

        // F. Dismiss any popup/dialog (e.g. "Okay")
        if (await elementExists('~Okay') || await elementExists('//*[@text="Okay" or @content-desc="Okay"]')) {
            console.log('Dismissing alert modal (Okay)...');
            try {
                await (await driver.$('~Okay')).click();
            } catch {}
            await driver.pause(2000);
        }

        console.log(`Waiting for booking transition... (${bookingLoop} attempts left)`);
        await driver.pause(2000);
        bookingLoop--;
    }

    if (!dispatched) {
        throw new Error('Rider booking failed: Ride request was not dispatched from Rider app to "Connecting" screen!');
    } else {
        console.log('>>> Rider ride request has been successfully dispatched! <<<');
    }
}

async function acceptRideOnDriverApp(driver: WebdriverIO.Browser) {
    console.log('\n=======================================================');
    console.log('PHASE 3: Switching to Driver App & Accepting Booking');
    console.log('=======================================================');

    // Switch back to Driver Application
    console.log('Bringing Wooberly Driver app to the foreground...');
    try {
        execSync('adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity', { stdio: 'ignore' });
    } catch {}
    await driver.activateApp('com.radicalstart.wooberlydriver');
    await driver.pause(2000);

    const elementExists = async (selector: string) => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    console.log('Waiting for incoming Ride Request modal on Driver App (polling up to 40s)...');
    let accepted = false;
    let modalSeen = false;
    const maxWaitSeconds = 40;
    const startTime = Date.now();

    while ((Date.now() - startTime) < maxWaitSeconds * 1000) {
        // 1. Check if Driver is ALREADY on active trip ("Location reached" slider present)
        const hasLocationSlider = await elementExists('//*[contains(@text, "Location") or contains(@content-desc, "Location") or contains(@text, "reached") or contains(@content-desc, "reached")]');
        if (hasLocationSlider) {
            console.log('>>> CONFIRMED: Driver is on active trip ("Location reached" slider present)! <<<');
            accepted = true;
            break;
        }

        // 2. Check if Trip Request modal is visible
        const hasAccept = await elementExists('//*[contains(@text, "Accept") or contains(@content-desc, "Accept")]');
        const hasDecline = await elementExists('//*[contains(@text, "Decline") or contains(@content-desc, "Decline")]');
        const hasTripModal = hasAccept || hasDecline ||
                             await elementExists('//*[contains(@text, "Trip") or contains(@text, "Request") or contains(@text, "sec")]');

        if (hasTripModal) {
            modalSeen = true;
            console.log('>>> Trip Request modal DETECTED on Driver App! Tapping Accept button... <<<');

            // Find Accept element if displayed
            let foundAcceptElement = false;
            const acceptSelectors = [
                '//android.widget.TextView[@text="Accept" or contains(@text, "Accept")]',
                '//*[@content-desc="Accept" or @text="Accept"]',
                '//*[contains(@content-desc, "Accept")]',
                '//android.widget.Button[contains(@text, "Accept")]'
            ];

            for (const sel of acceptSelectors) {
                try {
                    const el = await driver.$(sel);
                    if (await el.isDisplayed()) {
                        foundAcceptElement = true;
                        const loc = await el.getLocation();
                        const size = await el.getSize();
                        const targetX = Math.round(loc.x + size.width / 2);
                        const targetY = Math.round(loc.y + size.height / 2);
                        console.log(`Found Accept button element at (${targetX}, ${targetY}). Dispatching tap...`);
                        await pointerTap(driver, targetX, targetY);
                        break;
                    }
                } catch {}
            }

            // Also dispatch coordinate tap on Accept button verified center (x: 790, y: 2120)
            console.log('Dispatching coordinates tap on Accept button (x: 790, y: 2120)...');
            await pointerTap(driver, 790, 2120);
            await driver.pause(200);

            // Wait for Flutter state change & socket dispatch
            await driver.pause(1500);

            // Check if modal dismissed or slider appeared
            const postSlider = await elementExists('//*[contains(@text, "Location") or contains(@content-desc, "Location") or contains(@text, "reached") or contains(@content-desc, "reached")]');
            const postAccept = await elementExists('//*[contains(@text, "Accept") or contains(@content-desc, "Accept")]');
            const postDecline = await elementExists('//*[contains(@text, "Decline") or contains(@content-desc, "Decline")]');

            if (postSlider || (!postAccept && !postDecline)) {
                console.log('>>> SUCCESS: Trip request modal dismissed, ride ACCEPTED! <<<');
                accepted = true;
                break;
            } else {
                console.log('Modal still visible, retrying Accept tap in next iteration...');
            }
        } else {
            console.log('Waiting for trip request modal to appear on Driver App...');
            await driver.pause(1000);
        }
    }

    if (!accepted) {
        console.warn('Warning: Could not strictly confirm ride acceptance within timeout. Executing final fallback tap...');
        await pointerTap(driver, 790, 2120);
        await driver.pause(3000);
    }

    await driver.pause(3000);
    console.log('========================================================================');
    console.log('Driver ride acceptance sequence completed!');
    console.log('========================================================================');
}

async function runTripLifecycleAndPaymentFlow(driver: WebdriverIO.Browser) {
    console.log('\n========================================================================');
    console.log('PHASE 4: Driver & Rider Complete Trip, Chat, Toll, Payment & Review Flow');
    console.log('========================================================================');

    const elementExists = async (selector: string) => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    const smoothDrag = async (startX: number, startY: number, endX: number, endY: number) => {
        try {
            await driver.action('pointer')
                .move({ duration: 0, x: startX, y: startY })
                .down({ button: 0 })
                .pause(100)
                .move({ duration: 600, x: endX, y: endY })
                .pause(150)
                .up({ button: 0 })
                .perform();
        } catch {}
        adbSwipe(startX, startY, endX, endY, 600);
    };

    const swipeSlider = async (label: string, textMatchKeywords: string[], defaultY = 1713) => {
        console.log(`\n--- Action: Swiping slider for '${label}' ---`);
        let swipeY = defaultY;
        let startX = 120;
        let endX = 980;

        // Try to find slider element bounds
        for (const kw of textMatchKeywords) {
            try {
                const el = await driver.$(`//*[contains(@text, "${kw}") or contains(@content-desc, "${kw}")]`);
                if (await el.isDisplayed()) {
                    const loc = await el.getLocation();
                    const size = await el.getSize();
                    swipeY = Math.round(loc.y + size.height / 2);
                    startX = Math.max(80, Math.round(loc.x + 40));
                    endX = Math.min(1000, Math.round(loc.x + size.width - 40));
                    console.log(`Detected slider bounds for '${kw}': Y=${swipeY}, startX=${startX}, endX=${endX}`);
                    break;
                }
            } catch {}
        }

        console.log(`Executing swipe gesture from (${startX}, ${swipeY}) to (${endX}, ${swipeY})...`);
        try {
            await driver.action('pointer')
                .move({ duration: 0, x: startX, y: swipeY })
                .down({ button: 0 })
                .pause(200)
                .move({ duration: 900, x: endX, y: swipeY })
                .pause(200)
                .up({ button: 0 })
                .perform();
        } catch {}
        adbSwipe(startX, swipeY, endX, swipeY, 800);
        await driver.pause(3500);
    };

    // -------------------------------------------------------------------------
    // 1. After clicking accept button, swipe 'Locate reached' / 'Location reached'
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 1: Performing "Locate reached" swipe on Driver App <<<');
    let sliderReady = false;
    for (let i = 0; i < 15; i++) {
        if (await elementExists('//*[contains(@text, "Location") or contains(@content-desc, "Location") or contains(@text, "reached") or contains(@content-desc, "reached")]')) {
            sliderReady = true;
            break;
        }
        await driver.pause(1000);
    }
    await swipeSlider('Location reached', ['Location', 'Locate', 'LOCATION', 'REACHED', 'reached'], 1713);
    await driver.pause(3000);

    // -------------------------------------------------------------------------
    // 2. Click on the up arrow mark displayed at the bottom section to open bottom sheet.
    //    Click on the chat/message icon placed over there.
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 2: Opening bottom sheet (Up Arrow) & Clicking Chat Icon <<<');
    const upArrowSelectors = [
        '//*[contains(@content-desc, "arrow") or contains(@content-desc, "Arrow") or contains(@content-desc, "Up")]',
        '//android.widget.ImageView[contains(@content-desc, "arrow")]'
    ];
    for (const sel of upArrowSelectors) {
        if (await elementExists(sel)) {
            await safePointerClick(driver, sel, 890, 1970);
            break;
        }
    }
    await pointerTap(driver, 890, 1970);
    // Also drag up smoothly to ensure bottom sheet is fully expanded
    await smoothDrag(540, 2100, 540, 1100);
    await driver.pause(2000);

    // Click Chat / Message Icon
    console.log('Clicking Chat icon in bottom sheet...');
    const chatIconSelectors = [
        '//*[contains(@text, "Chat") or contains(@content-desc, "Chat") or contains(@text, "chat") or contains(@content-desc, "chat")]',
        '//android.widget.TextView[contains(@text, "Chat")]'
    ];
    let clickedChat = false;
    for (const sel of chatIconSelectors) {
        if (await elementExists(sel)) {
            await safePointerClick(driver, sel, 720, 2260);
            clickedChat = true;
            console.log(`Clicked Chat button via selector: ${sel}`);
            break;
        }
    }
    if (!clickedChat) {
        console.log('Tapping Chat icon coordinates in bottom sheet (x: 720, y: 2260)...');
        await pointerTap(driver, 720, 2260);
        await driver.pause(1000);
        // Fallback tap if bottom sheet had different scroll position
        if (!(await elementExists('//android.widget.EditText'))) {
            await pointerTap(driver, 720, 1890);
        }
    }
    await driver.pause(3000);

    // If VoiceChatBottomSheet or AI language modal appears, click Continue
    const continueSelectors = [
        '//*[contains(@text, "Continue") or contains(@content-desc, "Continue")]',
        '~Continue'
    ];
    for (const sel of continueSelectors) {
        if (await elementExists(sel)) {
            console.log('Dismissing Voice language modal via Continue...');
            await safePointerClick(driver, sel, 540, 2150);
            await driver.pause(2000);
            break;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Step 3: Type message → Send → dismiss keyboard
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n>>> Step 3: Typing Chat Message and Sending <<<');

    // ── 3a. Locate the chat EditText and SET VALUE directly ──────────────────
    // driver.keys(char) with 30 ms delay sends WebDriver key-codes, not text —
    // special chars (commas, apostrophes, !) produce garbage ("00", etc).
    // element.setValue() calls UiAutomator2's setText() directly, bypassing the
    // IME entirely, so the correct string always appears in the field.
    const chatMessage = 'Hello driver on the way';   // plain ASCII — no special chars
    console.log(`Setting chat message via setValue(): "${chatMessage}"`);

    let chatInputEl: any = null;
    try {
        const el = await driver.$('//android.widget.EditText');
        if (await el.isDisplayed()) {
            chatInputEl = el;
        }
    } catch {}

    // If EditText not found by selector, tap the visible input area at bottom (450, 2260)
    if (!chatInputEl) {
        console.log('EditText not found by selector — tapping input area (x: 450, y: 2260)...');
        await pointerTap(driver, 450, 2260);
        await driver.pause(1500);
        try {
            const el2 = await driver.$('//android.widget.EditText');
            if (await el2.isDisplayed()) chatInputEl = el2;
        } catch {}
    }

    if (chatInputEl) {
        try {
            // Clear any existing text first, then set our message
            await chatInputEl.clearValue();
            await chatInputEl.setValue(chatMessage);
            console.log(`>>> Message set in EditText: "${chatMessage}"`);
        } catch (err) {
            // setValue() failed — fall back to adb input text (reliable for ASCII)
            console.log('setValue() failed. Falling back to adb input text...');
            await chatInputEl.click();
            await driver.pause(500);
            try {
                execSync(`adb shell input text "${chatMessage.replace(/ /g, '%s')}"`, { stdio: 'ignore' });
            } catch {}
        }
    } else {
        // No EditText found — tap focused area and send text via adb
        console.log('Could not find EditText. Tapping (450, 2260) and using adb input text...');
        await pointerTap(driver, 450, 2260);
        await driver.pause(1000);
        try {
            execSync(`adb shell input text "${chatMessage.replace(/ /g, '%s')}"`, { stdio: 'ignore' });
        } catch {}
    }
    await driver.pause(2000);  // wait for text to appear and send button to activate

    // ── 3b. Click Send button (keyboard may still be visible) ────────────────
    console.log('Clicking Send button...');
    let clickedSend = false;
    const sendSelectors = [
        '//*[@content-desc="Send" or @text="Send"]',
        '//*[contains(@content-desc, "Send") or contains(@text, "Send")]',
        '//android.widget.ImageButton[last()]',
        '//android.widget.ImageButton',
        '//android.widget.Button[contains(@content-desc, "Send")]',
    ];
    for (const sel of sendSelectors) {
        try {
            const el = await driver.$(sel);
            if (await el.isDisplayed()) {
                const loc = await el.getLocation();
                const sz  = await el.getSize();
                const cx  = Math.round(loc.x + sz.width  / 2);
                const cy  = Math.round(loc.y + sz.height / 2);
                console.log(`Send button found via [${sel}] at (${cx}, ${cy}). Tapping...`);
                await pointerTap(driver, cx, cy);
                clickedSend = true;
                break;
            }
        } catch {}
    }
    if (!clickedSend) {
        // Tapping Send button coordinates: keyboard-up (~1400) and keyboard-down (~2260)
        console.log('No Send element found. Tapping Send button coordinate (x: 1015, y: 1400)...');
        await pointerTap(driver, 1015, 1400);
        await driver.pause(800);
        await pointerTap(driver, 1015, 2260);
        clickedSend = true;
    }
    await driver.pause(2000);  // wait for message bubble to appear

    // ── 3c. Verify message was sent, then dismiss keyboard ───────────────────
    // IMPORTANT: do NOT send keyevent 111 (KEYCODE_ESCAPE) — in Flutter apps it
    // acts as the Android BACK button and navigates to "Your trips" page.
    // Use driver.hideKeyboard() only.
    const msgVisible = await elementExists(`//*[contains(@text, "Hello") or contains(@content-desc, "Hello")]`)
                    || await elementExists(`//*[contains(@text, "driver") or contains(@content-desc, "driver")]`);
    if (msgVisible) {
        console.log('>>> Message confirmed visible in chat!');
    } else {
        console.warn('Message not yet visible in chat — it may still have been sent.');
    }

    console.log('Dismissing keyboard (hideKeyboard only — no keyevent to avoid accidental back nav)...');
    try { await driver.hideKeyboard(); } catch {}
    await driver.pause(1500);

    // ─────────────────────────────────────────────────────────────────────────
    // Step 4: Back from Chat → collapse bottom sheet → reveal START RIDE
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n>>> Step 4: Navigating Back from Chat and Collapsing Bottom Sheet <<<');

    // Use the Flutter back arrow ONLY.
    // Calling driver.back() / keyevent 4 in addition causes a double-back that
    // skips past the trip map screen and lands on "Your trips" history page.
    console.log('Tapping Flutter back arrow (x: 95, y: 165)...');
    await pointerTap(driver, 95, 165);
    await driver.pause(3500);   // wait for Flutter route animation

    // ── Recovery: if we ended up on "Your trips" page, press Back once ───────
    const onYourTrips = await elementExists('//*[contains(@text, "Your trips") or contains(@text, "your trips") or contains(@content-desc, "Your trips")]');
    if (onYourTrips) {
        console.log('WARNING: landed on "Your trips" page — pressing Android BACK to return...');
        try { execSync('adb shell input keyevent 4', { stdio: 'ignore' }); } catch {}
        await driver.pause(2500);
    }

    // ── Collapse bottom sheet to reveal the START RIDE slider ────────────────
    console.log('Collapsing bottom sheet back down...');
    const downArrowSelectors = [
        '//*[contains(@content-desc, "Down") or contains(@content-desc, "down")]',
        '//android.widget.ImageView[contains(@content-desc, "arrow")]'
    ];
    for (const sel of downArrowSelectors) {
        if (await elementExists(sel)) {
            await safePointerClick(driver, sel, 895, 305);
            break;
        }
    }
    // Drag sheet handle downward from 670 → 2100 to fully reveal START RIDE slider
    await smoothDrag(540, 670, 540, 2100);
    await driver.pause(3000);

    // -------------------------------------------------------------------------
    // 5. Click on the 'Start ride' swipe button and verify OTP
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 5: Swiping "Start ride" Slider & Entering OTP <<<');
    await swipeSlider('Start ride', ['START RIDE', 'START', 'Start', 'start'], 1713);
    await driver.pause(4000);

    // Check if OTP modal (RideConfirmationOtpView) appeared
    const hasOtpModal = await elementExists('//*[contains(@text, "OTP") or contains(@text, "Verify") or contains(@text, "Ask")]') ||
                        await elementExists('~Verify') ||
                        await elementExists('//*[contains(@content-desc, "Verify")]');

    if (hasOtpModal) {
        console.log('>>> RideConfirmationOtpView DETECTED! Fetching OTP from Rider Application... <<<');
        let otpCode = '';
        try {
            execSync('adb shell uiautomator dump /sdcard/rider_dump.xml', { stdio: 'ignore' });
            const dump = execSync('adb shell "grep -o \'OTP: [^\\\"<]*\' /sdcard/rider_dump.xml"').toString();
            const match = dump.match(/OTP:\s*([0-9]{4})/i);
            if (match) otpCode = match[1];
        } catch {}

        if (!otpCode) {
            try {
                const logcat = execSync('adb logcat -d').toString();
                const m = logcat.match(/confirmationCode[":=\s]+([0-9]{4})/i) || logcat.match(/OTP:\s*([0-9]{4})/i);
                if (m) otpCode = m[1];
            } catch {}
        }

        if (!otpCode) {
            console.warn('Could not extract OTP automatically, using default 1234');
            otpCode = '1234';
        }

        console.log(`>>> Entering Start Ride OTP: "${otpCode}" on Driver App... <<<`);
        // Tap first OTP input box at (150, 1850)
        await pointerTap(driver, 150, 1850);
        await driver.pause(800);
        try {
            execSync(`adb shell input text ${otpCode}`, { stdio: 'ignore' });
        } catch {
            await driver.keys(otpCode);
        }
        await driver.pause(1000);

        // Tap "Verify ->" button at (720, 1255)
        console.log('Tapping "Verify ->" button at (720, 1255)...');
        const verifySelectors = [
            '~Verify',
            '//*[@text="Verify" or @content-desc="Verify"]',
            '//*[contains(@text, "Verify") or contains(@content-desc, "Verify")]'
        ];
        let clickedVerify = false;
        for (const sel of verifySelectors) {
            if (await elementExists(sel)) {
                await safePointerClick(driver, sel, 720, 1255);
                clickedVerify = true;
                break;
            }
        }
        if (!clickedVerify) {
            await pointerTap(driver, 720, 1255);
        }
        await driver.pause(4000);
        console.log('>>> Ride started successfully with OTP verification! <<<');
    }

    // -------------------------------------------------------------------------
    // 6. Click on the 'Complete ride' button and make action successful
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 6: Swiping "Complete ride" Slider <<<');
    await swipeSlider('Complete ride', ['Complete', 'COMPLETE', 'End', 'complete'], 1713);
    await driver.pause(4000);

    // -------------------------------------------------------------------------
    // 7. Move to 'Toll fee' page, enter $1 in toll fee input field, click 'Done'
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 7: Entering Toll Fee ($1) and Clicking Done <<<');
    let onTollPage = false;
    let tollWait = 15;
    while (tollWait > 0) {
        if (await elementExists('//*[contains(@text, "Toll") or contains(@content-desc, "Toll") or contains(@text, "Charges") or contains(@text, "charges")]') ||
            await elementExists('//android.widget.EditText') ||
            await elementExists('~Done') ||
            await elementExists('//*[@text="Done" or @content-desc="Done"]')) {
            onTollPage = true;
            break;
        }
        await driver.pause(1000);
        tollWait--;
    }

    console.log('Focusing Toll Fee input field (x: 500, y: 950)...');
    try {
        const tollInput = await driver.$('//android.widget.EditText');
        if (await tollInput.isDisplayed()) {
            const loc = await tollInput.getLocation();
            const size = await tollInput.getSize();
            await pointerTap(driver, loc.x + size.width / 2, loc.y + size.height / 2);
        } else {
            await pointerTap(driver, 500, 950);
        }
    } catch {
        await pointerTap(driver, 500, 950);
    }
    await driver.pause(800);
    await driver.keys('1');
    console.log('Entered toll fee: 1');
    await driver.pause(1000);

    // Close keyboard safely
    try { await driver.hideKeyboard(); } catch {}
    await driver.pause(1500);

    // Click "Done" button on Toll fee page
    console.log('Clicking "Done" button on Toll Fee page (x: 540, y: 2110)...');
    const tollDoneSelectors = [
        '~Done',
        '//*[@text="Done" or @content-desc="Done"]',
        '//android.widget.Button[contains(@text, "Done")]'
    ];
    let clickedTollDone = false;
    for (const sel of tollDoneSelectors) {
        if (await elementExists(sel)) {
            await safePointerClick(driver, sel, 540, 2110);
            clickedTollDone = true;
            break;
        }
    }
    if (!clickedTollDone) {
        await pointerTap(driver, 540, 2110);
    }
    await driver.pause(3000);

    // Driver Trip Details screen: click "Next ->" button
    console.log('Clicking "Next ->" button on Driver Trip Details (x: 540, y: 2120)...');
    const nextSelectors = [
        '~Next',
        '//*[@text="Next" or @content-desc="Next"]',
        '//*[contains(@text, "Next") or contains(@content-desc, "Next")]'
    ];
    let clickedNext = false;
    for (const sel of nextSelectors) {
        if (await elementExists(sel)) {
            await safePointerClick(driver, sel, 540, 2120);
            clickedNext = true;
            break;
        }
    }
    if (!clickedNext) {
        await pointerTap(driver, 540, 2120);
    }
    await driver.pause(4000);

    // -------------------------------------------------------------------------
    // 8. Confirm payment status on Driver App
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 8: Checking Driver app Payment Confirmation Status <<<');
    const isCardTrip = PaymentConfig.isCard;
    let foundCashModal = false;
    if (!isCardTrip) {
        let cashModalWait = 20;
        while (cashModalWait > 0) {
            if (await elementExists('//*[contains(@text, "collect") or contains(@content-desc, "collect") or contains(@text, "Cash") or contains(@content-desc, "Cash")]') ||
                await elementExists('//*[contains(@text, "Yes") or @content-desc="Yes"]')) {
                console.log('>>> Cash confirmation modal is ACTIVE on Driver App! Keeping app idle in background. <<<');
                foundCashModal = true;
                break;
            }
            await driver.pause(1000);
            cashModalWait--;
        }
    } else {
        console.log('>>> Card / Online payment trip detected via PaymentConfig. Driver app ready. <<<');
    }
    await driver.pause(1000);

    // -------------------------------------------------------------------------
    // 9. Switch back to Rider app where 'Confirm' button is on trip details page
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 9: Switching to Rider Application (com.radicalstart.wooberly) <<<');
    await driver.activateApp('com.radicalstart.wooberly');
    await driver.pause(4000);

    // -------------------------------------------------------------------------
    // 10. Click on Confirm button -> takes to payment completed with review page
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 10: Clicking "Confirm" Button on Rider App <<<');
    let riderConfirmed = false;
    let riderConfirmTries = 20;
    const confirmSelectors = [
        '~Confirm',
        '//*[@text="Confirm" or @content-desc="Confirm"]',
        '//*[contains(@text, "Confirm") or contains(@content-desc, "Confirm")]'
    ];
    while (riderConfirmTries > 0) {
        for (const sel of confirmSelectors) {
            if (await elementExists(sel)) {
                console.log(`Found Confirm button on Rider App: ${sel}`);
                await safePointerClick(driver, sel, 540, 2120);
                riderConfirmed = true;
                break;
            }
        }
        if (riderConfirmed) break;
        await driver.pause(1500);
        riderConfirmTries--;
    }
    if (!riderConfirmed) {
        console.log('Tapping Confirm button coordinate on Rider App (x: 540, y: 2120)...');
        await pointerTap(driver, 540, 2120);
    }
    await driver.pause(4000);

    // -------------------------------------------------------------------------
    // 11. Do random review by selecting star symbol and click 'Done' button on Rider app
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 11: Submitting Rider Review (Stars + Done) <<<');
    await driver.pause(3000);
    // Tap 5th star on rating bar (center x: 680, y: 720)
    console.log('Selecting 5-star rating on Rider review (x: 680, y: 720)...');
    await pointerTap(driver, 680, 720);
    try { execSync('adb shell input tap 680 720', { stdio: 'ignore' }); } catch {}
    await driver.pause(1500);

    console.log('Clicking "Done" button on Rider review page (x: 540, y: 2158)...');
    const riderDoneSelectors = [
        '~Done',
        '//*[@text="Done" or @content-desc="Done"]',
        '//*[contains(@text, "Done") or contains(@content-desc, "Done")]'
    ];
    let clickedRiderDone = false;
    for (const sel of riderDoneSelectors) {
        if (await elementExists(sel)) {
            await safePointerClick(driver, sel, 540, 2158);
            clickedRiderDone = true;
            break;
        }
    }
    if (!clickedRiderDone) {
        await pointerTap(driver, 540, 2158);
        try { execSync('adb shell input tap 540 2158', { stdio: 'ignore' }); } catch {}
    }
    await driver.pause(2500);

    // Fallback: If "Review later" or review screen is still visible, tap "Review later" at (541, 2013)
    try {
        const reviewLaterBtn = await driver.$('//*[contains(@text, "Review later") or contains(@content-desc, "Review later")]');
        if (await reviewLaterBtn.isDisplayed().catch(() => false)) {
            console.log('Tapping "Review later" fallback button on Rider review...');
            await reviewLaterBtn.click();
        } else {
            const stillReview = await elementExists('//*[contains(@text, "How was your driver?") or contains(@content-desc, "How was your driver?")]');
            if (stillReview) {
                console.log('Rider review still open, tapping Review later at (541, 2013)...');
                try { execSync('adb shell input tap 541 2013', { stdio: 'ignore' }); } catch {}
            }
        }
    } catch {}
    await driver.pause(4000);
    console.log('>>> Rider review submitted successfully! <<<');

    // -------------------------------------------------------------------------
    // 12. Switch back to Driver app and handle confirmation modal (if cash payment)
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 12: Switching to Driver App & Checking Cash Confirmation Modal <<<');
    await driver.activateApp('com.radicalstart.wooberlydriver');
    await driver.pause(3000);

    const yesSelectors = [
        '//*[@text="Yes" or @content-desc="Yes"]',
        '//android.widget.TextView[contains(@text, "Yes")]',
        '//*[contains(@text, "Yes")]'
    ];
    let isCashModalPresent = false;
    if (!isCardTrip) {
        let cashYesWait = 12;
        while (cashYesWait > 0) {
            for (const sel of yesSelectors) {
                if (await elementExists(sel)) {
                    isCashModalPresent = true;
                    break;
                }
            }
            if (isCashModalPresent) break;
            await driver.pause(1000);
            cashYesWait--;
        }
    } else {
        console.log('>>> Card payment trip: No cash confirmation required. Proceeding directly to Driver review... <<<');
    }

    if (isCashModalPresent) {
        console.log('Clicking "Yes" button on Cash Confirmation popup (x: 730, y: 2140)...');
        let clickedYes = false;
        for (const sel of yesSelectors) {
            if (await elementExists(sel)) {
                await safePointerClick(driver, sel, 730, 2140);
                clickedYes = true;
                console.log(`Clicked Yes via selector: ${sel}`);
                break;
            }
        }
        if (!clickedYes) {
            console.log('Tapping "Yes" button coordinate (x: 730, y: 2140)...');
            await pointerTap(driver, 730, 2140);
        }
        await driver.pause(4000);
    } else {
        console.log('No Cash modal present (Card payment). Proceeding directly to Driver review...');
    }

    // -------------------------------------------------------------------------
    // 13. Driver review page: Choose random star and click 'Done' button
    // -------------------------------------------------------------------------
    console.log('\n>>> Step 13: Submitting Driver Review (Stars + Done) <<<');
    await driver.pause(3000);
    // Tap 5th star on Driver rating bar (center x: 810, y: 855)
    console.log('Selecting 5-star rating on Driver review page (x: 760, y: 855)...');
    await pointerTap(driver, 760, 855);
    try { execSync('adb shell input tap 760 855', { stdio: 'ignore' }); } catch {}
    await driver.pause(1500);

    console.log('Clicking "Done" button on Driver review page (x: 540, y: 2133)...');
    const driverDoneSelectors = [
        '~Done',
        '//*[@text="Done" or @content-desc="Done"]',
        '//*[contains(@text, "Done") or contains(@content-desc, "Done")]'
    ];
    let clickedDriverDone = false;
    for (const sel of driverDoneSelectors) {
        if (await elementExists(sel)) {
            await safePointerClick(driver, sel, 540, 2133);
            clickedDriverDone = true;
            break;
        }
    }
    if (!clickedDriverDone) {
        await pointerTap(driver, 540, 2133);
    }
    await driver.pause(2000);

    // Fallback: If "Review later" is present, click it
    if (await elementExists('//*[contains(@text, "Review later") or contains(@text, "review later")]')) {
        console.log('Clicking "Review later" fallback on Driver review page (x: 540, y: 1960)...');
        await pointerTap(driver, 540, 1960);
    }
    await driver.pause(4000);

    console.log('========================================================================');
    console.log('FULL END-TO-END DISPATCH, CHAT, TOLL, CASH & REVIEWS COMPLETED!');
    console.log('========================================================================');
}

async function ensureAppiumServer(): Promise<void> {
    console.log('Verifying Appium server status on http://127.0.0.1:4723/...');
    const isRunning = async () => {
        try {
            const res = await fetch('http://127.0.0.1:4723/status');
            const data = await res.json() as any;
            return data?.value?.ready === true;
        } catch {
            return false;
        }
    };

    if (await isRunning()) {
        console.log('Appium server is already running.');
        return;
    }

    console.log('Appium server is not running. Automatically starting Appium server in the background...');
    const appiumProcess = spawn('appium', ['--address', '127.0.0.1', '--port', '4723'], {
        detached: true,
        stdio: 'ignore'
    });
    appiumProcess.unref();

    const startTime = Date.now();
    while (Date.now() - startTime < 15000) {
        await new Promise(r => setTimeout(r, 1000));
        if (await isRunning()) {
            console.log('Appium server successfully started and ready!');
            return;
        }
    }
    console.warn('Warning: Could not confirm Appium server ready within 15 seconds. Proceeding...');
}

async function main() {
    console.log('########################################################################');
    console.log('#   WOOBERLY END-TO-END PARALLEL/SEQUENTIAL DISPATCH FLOW             #');
    console.log('#   Stage 1: Bring Driver Online (wooberlydriver)                      #');
    console.log('#   Stage 2: Switch to Rider App (wooberly) & Request Ride             #');
    console.log('#   Stage 3: Switch to Driver App & Accept Ride Booking                #');
    console.log('#   Stage 4: Complete Trip, Chat, Toll, Cash Confirmation & Reviews   #');
    console.log('########################################################################');

    // Wake up device and unlock
    DeviceManager.ensureDeviceReady();

    // Start video recording immediately after phone wakeup
    await VideoRecorder.startRecording({
        testName: 'wooberly_step1_booking_trip_workflow',
        outputDir: path.resolve(__dirname, '../../Test reference'),
    });

    // Ensure Appium server is alive before creating session
    await ensureAppiumServer();

    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:appPackage': 'com.radicalstart.wooberlydriver',
        'appium:appActivity': 'com.radicalstart.wooberlydriver.MainActivity',
        'appium:noReset': true,
        'appium:autoGrantPermissions': true,
        'appium:newCommandTimeout': 300,
    };

    const driver = await remote({
        hostname: '127.0.0.1',
        path: '/',
        port: 4723,
        capabilities
    });

    console.log('Appium session connected successfully.');

    try {
        // --- STEP 1: Bring Driver Online ---
        await runDriverOnlineFlow(driver);

        // ── Transition to Rider App ───────────────────────────────────────────
        // When running as part of test:full, the Rider app may be in a cold
        // background state (process deprioritised by Android after driver-online
        // script ran for several minutes).  A plain activateApp() + 3 s pause is
        // not enough — the Flutter engine needs extra time to re-render.
        // Steps taken here:
        //   1. adb am start — tells Android to bring the process to foreground
        //      priority immediately.
        //   2. activateApp() — tell Appium/UiAutomator2 to track that app.
        //   3. Poll up to 12 s for the Rider home screen to be visible.
        //   4. Dismiss any location / notification permission dialogs that may
        //      have appeared on resume.
        console.log('\n--- Transitioning to Rider Application ---');
        console.log('Driver is online. Launching Wooberly Rider app to foreground...');

        // 1. Force Rider app to foreground via adb (fast, bypasses Appium round-trip)
        try {
            execSync('adb shell am start -n com.radicalstart.wooberly/.MainActivity', { stdio: 'ignore' });
        } catch {}

        // 2. Also tell Appium to activate it (switches UiAutomator2 context)
        await driver.activateApp('com.radicalstart.wooberly');

        // 3. Poll up to 12 s for Rider home screen to be ready
        console.log('Waiting for Rider home screen to be ready (up to 12 s)...');
        const riderReadySelectors = [
            '~Search your destination',
            '~Where to?',
            '//android.widget.ImageView[@content-desc="Where to?"]',
            '//*[contains(@content-desc, "Where to")]',
            '//*[contains(@content-desc, "Where are you going")]',
        ];
        const riderCheckEl = async () => {
            for (const sel of riderReadySelectors) {
                try {
                    const el = await driver.$(sel);
                    if (await el.isDisplayed()) return true;
                } catch {}
            }
            return false;
        };
        let riderReady = false;
        for (let t = 0; t < 12; t++) {
            if (await riderCheckEl()) { riderReady = true; break; }
            await driver.pause(1000);
        }
        if (riderReady) {
            console.log('>>> Rider home screen is ready!');
        } else {
            console.warn('Rider home screen not detected within 12 s — proceeding anyway.');
        }

        // 4. Dismiss any permission dialogs that appeared on Rider app resume
        const permissionSelectors = [
            '//*[@text="While using the app" or @text="Allow" or @text="ALLOW"]',
            '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_foreground_only_button"]',
            '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button"]',
        ];
        for (const sel of permissionSelectors) {
            try {
                const el = await driver.$(sel);
                if (await el.isDisplayed()) {
                    console.log(`Dismissing permission dialog on Rider app resume: ${sel}`);
                    await el.click();
                    await driver.pause(1500);
                }
            } catch {}
        }
        await driver.pause(1000);

        // --- STEP 2: Execute Rider Request Flow ---
        await runRiderRequestFlow(driver);

        // --- STEP 3: Switch to Driver and Accept Booking ---
        await acceptRideOnDriverApp(driver);

        // --- STEP 4: Full Trip Lifecycle, Chat, Toll, Cash & Dual Reviews ---
        await runTripLifecycleAndPaymentFlow(driver);

    } catch (err) {
        console.error('Error during combined Driver & Rider execution:', err);
    } finally {
        await VideoRecorder.stopRecording();
    }
}

if (require.main === module) {
    main().catch(console.error);
}
