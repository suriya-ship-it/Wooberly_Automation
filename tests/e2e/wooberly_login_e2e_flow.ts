import { remote } from 'webdriverio';
import * as fs from 'fs';
import * as path from 'path';
import { DeviceManager } from '../../services/DeviceManager';
import { PaymentManager } from '../../services/PaymentManager';

// Parse .env file manually so it works with any execution runner without third-party dependencies
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

const USER_PHONE = process.env.TEST_USER_PHONE || '9876543210';
const USER_OTP = process.env.TEST_USER_OTP || '1234';

async function main() {
    console.log(`Starting Login-based E2E flow with:`);
    console.log(`  Phone: ${USER_PHONE}`);
    console.log(`  OTP:   ${USER_OTP}`);

    // Ensure device is awake and unlocked
    DeviceManager.ensureDeviceReady();

    // Verify package is present before launching Appium session
    const RIDER_PKG = 'com.radicalstart.wooberly';
    if (!DeviceManager.isPackageInstalled(RIDER_PKG)) {
        console.warn(`[Login Flow] ⚠️ Package "${RIDER_PKG}" not immediately found. Waiting up to 15s for OS to register...`);
        const startWait = Date.now();
        let found = false;
        while (Date.now() - startWait < 15000) {
            if (DeviceManager.isPackageInstalled(RIDER_PKG)) {
                found = true;
                break;
            }
            await new Promise(r => setTimeout(r, 1000));
        }
        if (!found) {
            console.warn(`[Login Flow] Package "${RIDER_PKG}" still not found. Initiating Play Store install...`);
            // Launch Play Store to the app page for manual install.
            DeviceManager.openPlayStoreUrl(RIDER_PKG);
            // Wait for installation to complete (max 2 minutes).
            const installStart = Date.now();
            while (Date.now() - installStart < 120000) {
                if (DeviceManager.isPackageInstalled(RIDER_PKG)) {
                    console.log('[Login Flow] Package installed after Play Store launch.');
                    break;
                }
                await new Promise(r => setTimeout(r, 3000));
            }
            if (!DeviceManager.isPackageInstalled(RIDER_PKG)) {
                throw new Error(`Cannot run login flow: Package "${RIDER_PKG}" is not installed on the Android device.`);
            }
        }
    }

    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:appPackage': 'com.radicalstart.wooberly',
        'appium:appActivity': 'com.radicalstart.wooberly.MainActivity',
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
        DeviceManager.runAdb('shell am start -n com.radicalstart.wooberly/com.radicalstart.wooberly.MainActivity');
        await driver.activateApp('com.radicalstart.wooberly');
    } catch {}

    console.log('Appium session connected to Wooberly Rider app.');
    try {
        await driver.setTimeout({ implicit: 500 });
        await driver.updateSettings({
            waitForIdleTimeout: 100,
            waitForSelectorTimeout: 500,
        });
    } catch {}

    const captureScreen = async (name: string) => {
        try {
            const debugDir = path.resolve(__dirname, '../../debug_screenshots');
            if (!fs.existsSync(debugDir)) fs.mkdirSync(debugDir, { recursive: true });
            const p = path.join(debugDir, `${name}.png`);
            DeviceManager.runAdb(`exec-out screencap -p > "${p}"`);
            console.log(`[Screenshot Captured] ${name}.png -> ${p}`);
        } catch (e) {
            console.warn(`[Screenshot] Could not capture ${name}:`, e);
        }
    };

    const pointerTap = async (x: number, y: number) => {
        try {
            await driver.action('pointer')
                .move({ duration: 0, x: Math.round(x), y: Math.round(y) })
                .down({ button: 0 })
                .pause(100)
                .up({ button: 0 })
                .perform();
        } catch {}
        try {
            DeviceManager.runAdb(`shell input tap ${Math.round(x)} ${Math.round(y)}`);
        } catch {}
    };

    const elementExists = async (selector: string) => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    const clickPrediction = async (searchTerm: string) => {
        console.log(`Selecting prediction for "${searchTerm}"...`);
        // 1. Explicitly match prediction item, strictly EXCLUDING EditText inputs
        try {
            const pred = await driver.$(`//*[not(self::android.widget.EditText) and (contains(@content-desc, "${searchTerm}") or contains(@text, "${searchTerm}"))]`);
            if (await pred.isDisplayed()) {
                console.log('Found prediction element (non-EditText), clicking...');
                await pred.click();
                await driver.pause(3000);
                return true;
            }
        } catch {}
        try {
            const predImg = await driver.$(`//android.widget.ImageView[contains(@content-desc, "${searchTerm}")] | //android.view.View[contains(@content-desc, "${searchTerm}")]`);
            if (await predImg.isDisplayed()) {
                console.log('Found prediction ImageView/View, clicking...');
                await predImg.click();
                await driver.pause(3000);
                return true;
            }
        } catch {}
        console.log('Tapping prediction item directly at (450, 840)...');
        await pointerTap(450, 840);
        await driver.pause(3000);
        return true;
    };

    // -------------------------------------------------------------------------
    // Check if Rider is Already Logged In
    // -------------------------------------------------------------------------
    console.log('Checking if Rider is already logged in (polling up to 10s for home render)...');
    const isRiderLoggedIn = async () => {
        const homeSelectors = [
            '~Where to go?',
            '~Where to?',
            '~Search your destination',
            '~Where are you going',
            '~Now',
            '~Book now',
            '//*[contains(@content-desc, "Where to")]',
            '//*[contains(@content-desc, "Now")]',
            '//*[contains(@content-desc, "Finding")]',
            '//*[contains(@content-desc, "Searching")]',
            '//*[contains(@content-desc, "OTP")]',
            '//*[contains(@content-desc, "Cancel trip")]',
        ];
        for (const sel of homeSelectors) {
            try {
                const el = await driver.$(sel);
                if (await el.isDisplayed()) return true;
            } catch {}
        }
        return false;
    };

    let riderLoggedIn = false;
    for (let t = 0; t < 10; t++) {
        if (await isRiderLoggedIn()) {
            riderLoggedIn = true;
            break;
        }
        try {
            const allowBtn = await driver.$('//*[@text="Allow" or @text="While using the app" or @text="ALLOW"]');
            if (await allowBtn.isDisplayed()) {
                console.log('Dismissing permission dialog during initial check');
                await allowBtn.click();
            }
        } catch {}
        await driver.pause(1000);
    }

    if (riderLoggedIn) {
        console.log('>>> Rider app is ALREADY LOGGED IN! Skipping login/signup and proceeding to booking. <<<');
    } else {
        // --- PHASE 1: LOGIN FLOW ---
        console.log('Rider not logged in. Executing Login Flow...');
        const hasEditText = await elementExists('//android.widget.EditText');
        if (!hasEditText) {
            console.log('No phone input field. Checking for "Get started" landing button...');
            let clickedGetStarted = false;
            try {
                const getStartedBtn = await driver.$('//*[contains(@content-desc, "Get started") or contains(@text, "Get started")]');
                if (await getStartedBtn.isDisplayed()) {
                    await getStartedBtn.click();
                    clickedGetStarted = true;
                    console.log('Clicked "Get started" button.');
                }
            } catch {}

            if (!clickedGetStarted) {
                if (await isRiderLoggedIn()) {
                    console.log('>>> Home screen appeared after wait! Skipping login. <<<');
                    riderLoggedIn = true;
                } else {
                    console.log('Retrying coordinate tap on "Get started" (x: 540, y: 2131)...');
                    try {
                        await driver.action('pointer').move({ duration: 0, x: 540, y: 2131 }).down().pause(100).up().perform();
                    } catch {}
                }
            }
            await driver.pause(3000);
        }

        if (!riderLoggedIn) {
            // Dismiss permission dialog if shown
            try {
                const allowBtn = await driver.$('//*[@text="Allow" or @text="While using the app" or @text="ALLOW"]');
                if (await allowBtn.isDisplayed()) {
                    console.log('Dismissing permission dialog');
                    await allowBtn.click();
                    await driver.pause(2000);
                }
            } catch (e) {}

            // Enter registered phone number
            const mobileField = await driver.$('//android.widget.EditText');
            await mobileField.waitForDisplayed({ timeout: 15000 });
        await mobileField.click();
        await driver.pause(300);
        try {
            await mobileField.clearValue();
        } catch (ce) {}
        await driver.pause(500);
        await driver.keys(USER_PHONE);
        console.log(`Entered registered phone: ${USER_PHONE}`);

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

        // Terms checkbox
        const checkbox = await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ImageView[3]');
        if (await checkbox.isDisplayed().catch(() => false)) {
            await checkbox.click();
        } else {
            await driver.action('pointer').move({ duration: 0, x: 99, y: 1952 }).down().pause(100).up().perform();
        }
        await driver.pause(1000);

        // Verify button
        console.log('Clicking Verify button...');
        let clickedVerify = false;
        try {
            const verifyBtn = await driver.$('//*[@content-desc="Verify" or @text="Verify"]');
            if (await verifyBtn.isDisplayed()) {
                await verifyBtn.click();
                clickedVerify = true;
            }
        } catch (e) {}
        if (!clickedVerify) {
            await driver.action('pointer').move({ duration: 0, x: 540, y: 2134 }).down().pause(100).up().perform();
        }
        await driver.pause(2000);

        // Helper to detect if OTP screen is active
        const isRiderOtpScreen = async () => {
            return (
                (await elementExists('//*[contains(@content-desc, "sent you a code") or contains(@text, "sent you a code")]')) ||
                (await elementExists('//*[contains(@content-desc, "Your OTP") or contains(@text, "Your OTP")]')) ||
                (await elementExists('//*[contains(@content-desc, "Enter the code") or contains(@text, "Enter the code")]')) ||
                (await elementExists('//*[contains(@content-desc, "Resend it") or contains(@text, "Resend it")]'))
            );
        };

        // Wait for OTP screen
        console.log('Waiting for Rider OTP verification screen to appear...');
        for (let i = 0; i < 20; i++) {
            try {
                const notifDialog = await driver.$('//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button" or @text="Allow" or @text="ALLOW"]');
                if (await notifDialog.isDisplayed()) {
                    await notifDialog.click();
                    await driver.pause(1000);
                }
            } catch (e) {}

            if (await isRiderOtpScreen()) {
                console.log(`>>> Rider OTP verification screen reached! (check ${i + 1}) <<<`);
                break;
            }
            await driver.pause(1000);
        }

        // --- OTP VERIFICATION ---
        console.log(`Entering OTP: ${USER_OTP}...`);
        await driver.pause(1000);

        let otpEntered = false;
        try {
            const autoFillOtpBtn = await driver.$(`//*[contains(@content-desc, "Your OTP is") or contains(@content-desc, "${USER_OTP}") or contains(@text, "${USER_OTP}")]`);
            if (await autoFillOtpBtn.isDisplayed()) {
                await autoFillOtpBtn.click();
                otpEntered = true;
                console.log(`Tapped OTP autofill element (${USER_OTP}).`);
                await driver.pause(1000);
            }
        } catch (e) {}

        if (!otpEntered) {
            console.log('Tapping OTP autofill chip via coordinates (x: 540, y: 1050)...');
            await driver.action('pointer').move({ duration: 0, x: 540, y: 1050 }).down().pause(100).up().perform();
            await driver.pause(1000);
            otpEntered = true;
        }

        try {
            if (await driver.isKeyboardShown()) {
                await driver.hideKeyboard();
            }
        } catch (e) {
            try { await driver.pressKeyCode(4); } catch (e2) {}
        }
        await driver.pause(1000);

        // Click Proceed button
        console.log('Clicking "Proceed" button on OTP screen...');
        let clickedProceed = false;
        try {
            const proceedBtn = await driver.$('//*[@content-desc="Proceed" or @text="Proceed"]');
            if (await proceedBtn.isDisplayed()) {
                await proceedBtn.click();
                clickedProceed = true;
            }
        } catch (e) {}

        if (!clickedProceed) {
            await driver.action('pointer').move({ duration: 0, x: 540, y: 2134 }).down().pause(100).up().perform();
        }
        console.log('Clicked Proceed. Waiting for login transition to Home screen...');
        await driver.pause(8000);

        // Dismiss permission dialog if prompted after login
        try {
            const locAllow = await driver.$('//*[@text="While using the app" or @text="Only this time" or @text="Allow" or @text="ALLOW"]');
            if (await locAllow.isDisplayed()) {
                await locAllow.click();
                await driver.pause(2000);
            }
        } catch (e) {}
        }
    }



    // --- PHASE 2: ON-DEMAND BOOKING FLOW ---
    console.log('Reached Home screen. Starting On-Demand Booking flow...');
    await captureScreen('step_01_rider_home');

    if (await elementExists('//*[@text="While using the app"]')) {
        await (await driver.$('//*[@text="While using the app"]')).click();
        await driver.pause(2000);
    }

    try {
        if (await elementExists('~Where to?')) {
            console.log('Clicking "~Where to?"...');
            await (await driver.$('~Where to?')).click();
        } else if (await elementExists('//*[contains(@content-desc, "Where to") or contains(@text, "Where to")]')) {
            console.log('Clicking "Where to?" by selector...');
            await (await driver.$('//*[contains(@content-desc, "Where to") or contains(@text, "Where to")]')).click();
        } else if (await elementExists('~Search your destination')) {
            console.log('Clicking "~Search your destination"...');
            await (await driver.$('~Search your destination')).click();
        } else {
            console.log('Tapping "Where to go?" search bar via coordinates (225, 212)...');
            await pointerTap(225, 212);
        }
    } catch {
        console.log('Fallback: Tapping "Where to go?" search bar via coordinates (225, 212)...');
        await pointerTap(225, 212);
    }
    await driver.pause(3000);
    await captureScreen('step_02_search_destination_opened');

    // Enter Drop Location
    console.log('Entering Drop Location: Mattuthavani madurai');
    // Drop location box is Box 2 at X: 450, Y: 615
    console.log('Focusing drop location input (Box 2 at X: 450, Y: 615)...');
    try {
        const dropLocationBtn = await driver.$('~Enter drop location');
        if (await dropLocationBtn.isDisplayed().catch(() => false)) {
            await dropLocationBtn.click();
        } else {
            await pointerTap(450, 615);
        }
    } catch {
        await pointerTap(450, 615);
    }
    await driver.pause(1000);

    // Clear any pre-filled/default location text completely before typing without causing visual flicker
    console.log('Ensuring drop location field is cleared of any pre-filled text...');
    try {
        const inputFields: any = await driver.$$('//android.widget.EditText');
        const activeInput = inputFields.length > 1 ? inputFields[1] : (inputFields[0] || null);
        if (activeInput) {
            await activeInput.clearValue().catch(() => {});
        }
    } catch {}

    // Type character by character to trigger autocomplete predictions smoothly
    const textToType = 'Mattuthavani madurai';
    console.log(`Typing destination: ${textToType}...`);
    for (const char of textToType) {
        await driver.keys(char);
        await driver.pause(40);
    }
    await driver.pause(3000);
    await captureScreen('step_03_destination_typed');

    await clickPrediction('Mattuthavani');
    await driver.pause(3000);
    await captureScreen('step_04_prediction_selected');

    console.log('Navigating through Confirm Location and Done screens...');
    let maxLoops = 15;
    while (maxLoops > 0) {
        const categoryScreenVisible = await elementExists('//*[contains(@content-desc, "Choose a ride") or contains(@text, "Choose a ride") or contains(@content-desc, "Micro") or contains(@text, "Micro") or contains(@content-desc, "Book now") or contains(@text, "Book now")]');

        if (categoryScreenVisible) {
            console.log('Category selection page reached! Breaking loop.');
            break;
        }

        const whereToGoVisible = await elementExists('//*[contains(@content-desc, "Where to go") or contains(@text, "Where to go") or contains(@content-desc, "Done") or contains(@text, "Done")]');
        if (whereToGoVisible) {
            console.log('Where to go page appeared! Tapping Done button at bottom (540, 2145)...');
            await pointerTap(540, 2145);
            await driver.pause(3000);
            maxLoops--;
            continue;
        }

        const confirmLocationVisible = (await elementExists('//*[contains(@content-desc, "Confirm location") or contains(@text, "Confirm location")]'));
        if (confirmLocationVisible) {
            console.log('Map page appeared! Clicking Confirm location...');
            try {
                const confLocBtn = await driver.$('//*[contains(@content-desc, "Confirm location") or contains(@text, "Confirm location")]');
                if (await confLocBtn.isDisplayed().catch(() => false)) {
                    await confLocBtn.click();
                } else {
                    await pointerTap(540, 2145);
                }
            } catch {
                await pointerTap(540, 2145);
            }
            await driver.pause(3000);
            maxLoops--;
            continue;
        }

        console.log('Waiting for destination screens, tapping Done/Confirm coordinate (540, 2145)...');
        await pointerTap(540, 2145);
        await driver.pause(2500);
        maxLoops--;
    }

    // Category Selection
    console.log('Choosing vehicle category...');
    await driver.pause(2000);
    await captureScreen('step_05_category_selection_screen');

    // Category 1 (Micro): select Micro
    console.log('Selecting Category 1 (Micro)...');
    try {
        const microEl = await driver.$('//*[contains(@content-desc, "Micro") or contains(@text, "Micro")]');
        if (await microEl.isDisplayed().catch(() => false)) {
            await microEl.click();
        } else {
            await pointerTap(540, 980);
        }
    } catch {
        await pointerTap(540, 980);
    }
    await driver.pause(1500);
    await captureScreen('step_06_micro_selected');

    // Click "Book now" button (bounds: y 2085 to 2235, center x: 540, y: 2160)
    console.log('Tapping "Book now" button (x: 540, y: 2160)...');
    let bookNowTapped = false;
    for (let attempt = 0; attempt < 5; attempt++) {
        try {
            const bookNowEl = await driver.$('//*[contains(@content-desc, "Book now") or contains(@text, "Book now")]');
            if (await bookNowEl.isDisplayed().catch(() => false)) {
                await bookNowEl.click();
            } else {
                await pointerTap(540, 2160);
            }
        } catch {
            await pointerTap(540, 2160);
        }
        await driver.pause(2500);

        // Check if transition occurred (Payment sheet Cash/Payment method, or Precaution sheet Proceed/Safety)
        const paymentVisible = (await elementExists('//*[contains(@content-desc, "Payment method") or contains(@text, "Payment method") or contains(@content-desc, "Cash") or contains(@text, "Cash")]'));
        const precautionVisible = (await elementExists('//*[contains(@content-desc, "Proceed") or contains(@text, "Proceed") or contains(@content-desc, "Safety") or contains(@text, "Safety")]'));

        if (paymentVisible || precautionVisible) {
            console.log(`Transition from category screen succeeded on attempt ${attempt + 1}!`);
            bookNowTapped = true;
            break;
        }

        console.log(`Category screen still visible. Re-selecting Category 1 (Micro) and re-tapping Book now...`);
        try {
            const microEl = await driver.$('//*[contains(@content-desc, "Micro") or contains(@text, "Micro")]');
            if (await microEl.isDisplayed().catch(() => false)) await microEl.click();
            else await pointerTap(540, 980);
        } catch {
            await pointerTap(540, 980);
        }
        await driver.pause(1000);
    }
    await captureScreen('step_07_after_book_now');

    // --- PAYMENT METHOD SELECTION BOTTOM SHEET ---
    console.log('Handling Payment Method bottom sheet...');
    await driver.pause(1000);
    const hasPaymentSheet = (await elementExists('//*[contains(@content-desc, "Payment method") or contains(@text, "Payment method") or contains(@content-desc, "Cash") or contains(@text, "Cash")]'));

    if (hasPaymentSheet) {
        await captureScreen('step_08_payment_sheet');
        await PaymentManager.handleBookingPayment(driver);
        await captureScreen('step_09_after_payment_confirm');
    }

    // --- PRECAUTION NOTIFICATION BOTTOM SHEET ---
    console.log('Handling Precaution Notification bottom sheet...');
    await driver.pause(1000);
    const hasPrecautionSheet = (await elementExists('//*[contains(@content-desc, "Proceed") or contains(@text, "Proceed")]')) ||
                              (await elementExists('//*[contains(@content-desc, "Passenger Safety") or contains(@text, "Passenger Safety") or contains(@content-desc, "Precaution") or contains(@content-desc, "Safety")]'));

    if (hasPrecautionSheet) {
        await captureScreen('step_10_precaution_sheet');
        console.log('Tapping Proceed button at (790, 2160)...');
        try {
            const proceedBtn = await driver.$('//*[contains(@content-desc, "Proceed") or contains(@text, "Proceed")]');
            if (await proceedBtn.isDisplayed().catch(() => false)) {
                await proceedBtn.click();
            } else {
                await pointerTap(790, 2160);
            }
        } catch {
            await pointerTap(790, 2160);
        }
        await driver.pause(3000);
        await captureScreen('step_11_after_proceed');
    }

    // --- CONNECTING / SEARCHING DRIVER SCREEN ---
    console.log('Verifying Searching Driver screen (waiting up to 30s)...');
    let isSearchingDriver = false;
    for (let c = 0; c < 15; c++) {
        // 1. Check if Driver App Trip Request modal or active trip has popped up over Rider app
        const driverPopupVisible = (await elementExists('//*[contains(@text, "Accept") or contains(@content-desc, "Accept") or contains(@text, "Decline") or contains(@content-desc, "Decline")]')) ||
                                  (await elementExists('//*[contains(@text, "LOCATION REACHED") or contains(@text, "reached") or contains(@content-desc, "reached")]'));
        if (driverPopupVisible) {
            console.log(`>>> Driver App Trip Request / Active Trip detected on screen! Ride request successfully dispatched and received! (check ${c + 1}) <<<`);
            isSearchingDriver = true;
            break;
        }

        // 2. Check if Rider Searching Screen is active
        isSearchingDriver = (await elementExists('~Connecting you to nearby drivers')) ||
                            (await elementExists('~Connecting...')) ||
                            (await elementExists('//*[contains(@text, "Connecting")]')) ||
                            (await elementExists('//*[contains(@content-desc, "Connecting")]')) ||
                            (await elementExists('//*[contains(@text, "nearby drivers")]')) ||
                            (await elementExists('//*[contains(@content-desc, "nearby drivers")]')) ||
                            (await elementExists('~Cancel request')) ||
                            (await elementExists('//*[contains(@text, "Cancel request")]')) ||
                            (await elementExists('//*[contains(@content-desc, "Cancel request")]'));

        if (isSearchingDriver) {
            console.log(`>>> "Connecting you to nearby drivers" screen active! (check ${c + 1}) <<<`);
            break;
        }

        // If Precaution bottom sheet is visibly open, tap Proceed
        if (await elementExists('//*[contains(@content-desc, "Proceed") or contains(@text, "Proceed") or contains(@content-desc, "Safety") or contains(@text, "Safety")]')) {
            console.log('Precaution sheet still visible, re-tapping Proceed button at (780, 2170)...');
            await pointerTap(780, 2170);
            try { execSync('adb shell input tap 780 2170', { stdio: 'ignore' }); } catch {}
        }

        // If Payment method sheet Confirm button is still visible, re-tap Confirm
        if (await elementExists('//*[contains(@content-desc, "Confirm") or contains(@text, "Confirm")]')) {
            console.log('Payment method Confirm button still visible, re-tapping (540, 2100)...');
            await pointerTap(540, 2100);
            try { execSync('adb shell input tap 540 2100', { stdio: 'ignore' }); } catch {}
        }

        await driver.pause(2000);
    }

    await captureScreen('step_12_searching_drivers_state');
    console.log(`Searching driver screen active: ${isSearchingDriver}`);

    if (!isSearchingDriver) {
        throw new Error('Rider booking failed: Ride request was not dispatched to "Connecting you to nearby drivers" state!');
    }

    console.log('========================================================================');
    console.log('✅ On-demand booking completed successfully and ride is actively searching!');
    console.log('Keeping the Rider app in foreground on Searching Driver screen.');
    console.log('========================================================================');
}

main().catch(async (e) => {
    console.error(e);
    process.exit(1);
});
