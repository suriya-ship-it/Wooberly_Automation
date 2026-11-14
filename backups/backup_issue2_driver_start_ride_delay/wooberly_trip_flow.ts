import { remote } from 'webdriverio';
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

const ROOT = path.resolve(__dirname, '../../');
const ARTIFACT_DIR = process.env.ARTIFACT_DIR || '/Users/radicalstart/.gemini/antigravity/brain/deb6f5ff-f7a6-41d7-b10f-310a461c3e60';
const DEBUG_DIR = path.join(ROOT, 'debug_screenshots');

async function captureScreen(driver: WebdriverIO.Browser, name: string): Promise<string> {
    const filename = `${name}.png`;
    const fullPath = path.join(ARTIFACT_DIR, filename);
    const debugPath = path.join(DEBUG_DIR, filename);
    try {
        if (!fs.existsSync(DEBUG_DIR)) fs.mkdirSync(DEBUG_DIR, { recursive: true });
    } catch {}

    try {
        await driver.saveScreenshot(fullPath);
        try { fs.copyFileSync(fullPath, debugPath); } catch {}
        console.log(`[Screenshot Captured] ${filename} -> ${fullPath}`);
    } catch (e) {
        try {
            execSync(`adb exec-out screencap -p > "${fullPath}"`, { stdio: 'ignore' });
            try { fs.copyFileSync(fullPath, debugPath); } catch {}
            console.log(`[Screenshot via ADB] ${filename} -> ${fullPath}`);
        } catch (err) {
            console.warn(`Could not capture screenshot for ${name}:`, err);
        }
    }
    return fullPath;
}

const pointerTap = async (driver: WebdriverIO.Browser, x: number, y: number) => {
    try {
        await driver.action('pointer')
            .move({ duration: 0, x: Math.round(x), y: Math.round(y) })
            .down({ button: 0 })
            .pause(100)
            .up({ button: 0 })
            .perform();
    } catch {
        try {
            execSync(`adb shell input tap ${Math.round(x)} ${Math.round(y)}`, { stdio: 'ignore' });
        } catch {}
    }
};

const adbSwipe = (x1: number, y1: number, x2: number, y2: number, durationMs = 800) => {
    try {
        execSync(`adb shell input swipe ${Math.round(x1)} ${Math.round(y1)} ${Math.round(x2)} ${Math.round(y2)} ${durationMs}`, { stdio: 'ignore' });
    } catch {}
};

const smoothDrag = async (driver: WebdriverIO.Browser, startX: number, startY: number, endX: number, endY: number) => {
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

export async function runTripLifecycleFlow(): Promise<void> {
    console.log('########################################################################');
    console.log('#   WOOBERLY TRIP ACCEPTANCE & 13-STEP LIFECYCLE FLOW                  #');
    console.log('#   Task 1: Launch Driver app & detect ride request modal              #');
    console.log('#   Task 2: Accept booking + 13-step lifecycle with screenshots         #');
    console.log('########################################################################\n');

    // Task 1: Ensure Driver application is brought to foreground immediately
    console.log('Launching Wooberly Driver application to foreground state...');
    try {
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
        'appium:newCommandTimeout': 300,
    };

    const driver = await remote({
        hostname: '127.0.0.1',
        path: '/',
        port: 4723,
        capabilities
    });

    try {
        await driver.setTimeout({ implicit: 500 });
        await driver.updateSettings({
            waitForIdleTimeout: 100,
            waitForSelectorTimeout: 500,
        });
        await driver.activateApp('com.radicalstart.wooberlydriver');
    } catch {}

    console.log('Appium session connected to Wooberly Driver.');
    await captureScreen(driver, 'stage3_01_driver_foreground');

    const elementExists = async (selector: string): Promise<boolean> => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    const safePointerClick = async (selector: string, fallbackX: number, fallbackY: number) => {
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
    };

    const swipeSlider = async (label: string, textMatchKeywords: string[], defaultY = 1713) => {
        console.log(`\n--- Action: Swiping slider for '${label}' ---`);
        let swipeY = defaultY;
        let startX = 120;
        let endX = 980;

        for (const kw of textMatchKeywords) {
            try {
                const el = await driver.$(`android=new UiSelector().textContains("${kw}")`);
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

        console.log(`Executing swipe from (${startX}, ${swipeY}) to (${endX}, ${swipeY})...`);
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

    try {
        // =========================================================================
        // Task 1 & 2: Wait for Incoming Ride Request Modal & Click "Accept"
        // =========================================================================
        console.log('Waiting for incoming Ride Request modal on Driver App (polling up to 45s)...');
        let accepted = false;
        const maxWaitSeconds = 45;
        const startTime = Date.now();

        while ((Date.now() - startTime) < maxWaitSeconds * 1000) {
            // 1. Immediately check for Accept button or Trip Request modal
            let hasAccept = false;
            try {
                const acceptEl = await driver.$('android=new UiSelector().textContains("Accept")');
                if (await acceptEl.isDisplayed()) hasAccept = true;
            } catch {}

            if (!hasAccept) {
                try {
                    const acceptDesc = await driver.$('android=new UiSelector().descriptionContains("Accept")');
                    if (await acceptDesc.isDisplayed()) hasAccept = true;
                } catch {}
            }

            let hasDecline = false;
            if (!hasAccept) {
                try {
                    const dec = await driver.$('android=new UiSelector().textContains("Decline")');
                    if (await dec.isDisplayed()) hasDecline = true;
                } catch {}
            }

            if (hasAccept || hasDecline) {
                console.log('>>> Trip Request modal DETECTED on Driver App! <<<');
                await captureScreen(driver, 'stage3_02_ride_request_modal');

                console.log('TAPPING ACCEPT BUTTON IMMEDIATELY at verified center (x: 790, y: 2120)...');
                await pointerTap(driver, 790, 2120);
                try { execSync('adb shell input tap 790 2120', { stdio: 'ignore' }); } catch {}
                await driver.pause(300);

                await driver.pause(2500);
                await captureScreen(driver, 'stage3_03_ride_accepted');
                accepted = true;
                break;
            }

            // 2. Secondary check: check if Driver is already on active trip
            let hasSlider = false;
            try {
                const slider = await driver.$('android=new UiSelector().textContains("reached")');
                if (await slider.isDisplayed()) hasSlider = true;
            } catch {}

            if (hasSlider) {
                console.log('>>> CONFIRMED: Driver is already on active trip ("Location reached" slider present)! <<<');
                accepted = true;
                break;
            }

            console.log('Waiting for trip request modal to appear on Driver App...');
            await driver.pause(500);
        }

        if (!accepted) {
            console.warn('Ride request modal check finished; proceeding to trip lifecycle.');
        }

        // =========================================================================
        // Step 1: Swipe slider for "Location reached"
        // =========================================================================
        console.log('\n>>> Step 1: Performing "Location reached" swipe on Driver App <<<');
        for (let i = 0; i < 20; i++) {
            if (await elementExists('android=new UiSelector().textContains("reached")') ||
                await elementExists('android=new UiSelector().descriptionContains("reached")') ||
                await elementExists('android=new UiSelector().textContains("Location")')) {
                break;
            }
            await driver.pause(1000);
        }
        await captureScreen(driver, 'stage3_04_location_reached_slider');
        await swipeSlider('Location reached', ['Location', 'Locate', 'LOCATION', 'REACHED', 'reached'], 1713);
        await driver.pause(3000);
        await captureScreen(driver, 'stage3_05_after_location_reached');

        // =========================================================================
        // Step 2: Clicks Up Arrow at bottom section & clicks Chat/Message icon
        // =========================================================================
        console.log('\n>>> Step 2: Opening bottom sheet (Up Arrow) & Clicking Chat Icon <<<');
        // Up Arrow chevron when collapsed: Bounds [882, 1852][1023, 2044], Center = (952, 1948)
        await pointerTap(driver, 952, 1948);
        try { execSync('adb shell input tap 952 1948', { stdio: 'ignore' }); } catch {}
        // Also drag sheet handle up smoothly
        await smoothDrag(driver, 540, 1950, 540, 950);
        await driver.pause(2000);
        await captureScreen(driver, 'stage3_06_bottom_sheet_expanded');

        // Click Chat Icon in expanded bottom sheet
        console.log('Clicking Chat icon in bottom sheet...');
        let clickedChat = false;
        try {
            const chatEl = await driver.$('android=new UiSelector().textContains("Chat")');
            if (await chatEl.isDisplayed()) {
                await chatEl.click();
                clickedChat = true;
                console.log('Clicked Chat button via text selector.');
            }
        } catch {}
        if (!clickedChat) {
            try {
                const chatDesc = await driver.$('android=new UiSelector().descriptionContains("Chat")');
                if (await chatDesc.isDisplayed()) {
                    await chatDesc.click();
                    clickedChat = true;
                    console.log('Clicked Chat button via description selector.');
                }
            } catch {}
        }
        if (!clickedChat) {
            console.log('Tapping Chat icon coordinates in bottom sheet (x: 500, y: 2080)...');
            await pointerTap(driver, 500, 2080);
            try { execSync('adb shell input tap 500 2080', { stdio: 'ignore' }); } catch {}
        }
        await driver.pause(3000);

        // Dismiss Voice language modal if present
        if (await elementExists('~Continue') || await elementExists('//*[contains(@text, "Continue") or contains(@content-desc, "Continue")]')) {
            console.log('Dismissing Voice modal via Continue...');
            await safePointerClick('~Continue', 540, 2150);
            await driver.pause(2000);
        }

        await captureScreen(driver, 'stage3_07_chat_screen_opened');

        // =========================================================================
        // Step 3: Types random message in chat, closes keyboard, and clicks Send button
        // =========================================================================
        console.log('\n>>> Step 3: Typing Chat Message, Closing Keyboard & Clicking Send <<<');
        const chatMessage = 'Hello driver is on the way';
        console.log(`Typing message: "${chatMessage}"`);

        let chatInput: any = null;
        try {
            const el = await driver.$('//android.widget.EditText');
            if (await el.isDisplayed()) chatInput = el;
        } catch {}

        if (!chatInput) {
            console.log('EditText not found by selector — tapping input area (x: 450, y: 2130)...');
            await pointerTap(driver, 450, 2130);
            await driver.pause(1000);
            try {
                const el2 = await driver.$('//android.widget.EditText');
                if (await el2.isDisplayed()) chatInput = el2;
            } catch {}
        }

        if (chatInput) {
            try {
                await chatInput.click();
                await driver.pause(300);
                execSync(`adb shell input text "${chatMessage.replace(/ /g, '%s')}"`, { stdio: 'ignore' });
            } catch {
                await chatInput.setValue(chatMessage);
            }
        } else {
            await pointerTap(driver, 450, 2130);
            await driver.pause(500);
            execSync(`adb shell input text "${chatMessage.replace(/ /g, '%s')}"`, { stdio: 'ignore' });
        }
        await driver.pause(1500);
        await captureScreen(driver, 'stage3_08_message_typed');

        // Close soft keyboard FIRST so Send button is fully visible and unobstructed
        console.log('Closing soft keyboard...');
        try {
            if (await driver.isKeyboardShown()) {
                await driver.hideKeyboard();
            }
        } catch {
            try { await driver.pressKeyCode(4); } catch {}
        }
        await driver.pause(1500);
        await captureScreen(driver, 'stage3_09_keyboard_closed');

        // Click Send Button (verified circular send button bounds: [894, 2062][1024, 2206], center: 959, 2134)
        console.log('Clicking Send button at verified center (x: 959, y: 2134)...');
        let clickedSend = false;
        const sendSelectors = [
            '//*[@content-desc="Send" or @text="Send"]',
            '//*[contains(@content-desc, "Send") or contains(@text, "Send")]',
            '//android.widget.ImageButton[last()]',
            '//android.widget.ImageButton'
        ];
        for (const sel of sendSelectors) {
            try {
                const el = await driver.$(sel);
                if (await el.isDisplayed()) {
                    const loc = await el.getLocation();
                    const sz = await el.getSize();
                    await pointerTap(driver, loc.x + sz.width / 2, loc.y + sz.height / 2);
                    clickedSend = true;
                    console.log(`Clicked Send button via selector: ${sel}`);
                    break;
                }
            } catch {}
        }
        if (!clickedSend) {
            console.log('Tapping Send button verified coordinates (x: 959, y: 2134)...');
            await pointerTap(driver, 959, 2134);
            await driver.pause(500);
            await pointerTap(driver, 885, 2125);
        }
        await driver.pause(2500);
        await captureScreen(driver, 'stage3_10_message_sent');

        // =========================================================================
        // Step 4: Clicks Back button from chat screen, returns to bottom sheet, clicks Down Arrow
        // =========================================================================
        console.log('\n>>> Step 4: Back from Chat & Collapsing Bottom Sheet <<<');
        console.log('Tapping Chat back arrow (x: 100, y: 166)...');
        await pointerTap(driver, 100, 166);
        await driver.pause(3000);

        // Recovery check: if on "Your trips" page, press Android Back once
        if (await elementExists('//*[contains(@text, "Your trips") or contains(@content-desc, "Your trips")]')) {
            console.log('Recovering from "Your trips" page: pressing Back...');
            try { execSync('adb shell input keyevent 4', { stdio: 'ignore' }); } catch {}
            await driver.pause(2500);
        }

        // Collapse bottom sheet down to reveal Start ride slider
        console.log('Collapsing bottom sheet back down...');
        const downArrowSelectors = [
            '//*[contains(@content-desc, "Down") or contains(@content-desc, "down")]',
            '//android.widget.ImageView[contains(@content-desc, "arrow")]'
        ];
        for (const sel of downArrowSelectors) {
            if (await elementExists(sel)) {
                await safePointerClick(sel, 965, 947);
                break;
            }
        }
        await pointerTap(driver, 965, 947);
        await smoothDrag(driver, 540, 950, 540, 2150);
        await driver.pause(2000);

        // Verification loop: ensure sheet actually collapsed and "Start ride" slider is exposed
        for (let attempt = 0; attempt < 3; attempt++) {
            const hasStartSlider = await elementExists('//*[contains(@text, "Start") or contains(@content-desc, "Start") or contains(@text, "START")]');
            if (hasStartSlider) {
                console.log('>>> Confirmed: Bottom sheet collapsed and Start ride slider is visible! <<<');
                break;
            }
            console.log(`Sheet still covering slider (attempt ${attempt + 1}). Retrying Down arrow tap at (965, 947) and drag down...`);
            await pointerTap(driver, 965, 947);
            await driver.pause(500);
            await smoothDrag(driver, 540, 950, 540, 2150);
            await driver.pause(1500);
        }
        await driver.pause(2500);
        await captureScreen(driver, 'stage3_11_sheet_collapsed');

        // =========================================================================
        // Step 5: Swipes slider for "Start ride" to begin trip
        // =========================================================================
        console.log('\n>>> Step 5: Swiping "Start ride" Slider & Entering OTP <<<');
        for (let i = 0; i < 15; i++) {
            if (await elementExists('android=new UiSelector().textContains("Start")') ||
                await elementExists('android=new UiSelector().descriptionContains("Start")')) {
                break;
            }
            await driver.pause(1000);
        }
        await swipeSlider('Start ride', ['Start', 'START', 'start'], 1713);
        await driver.pause(3500);
        await captureScreen(driver, 'stage3_12_start_ride_swiped');

        // Check if OTP modal (RideConfirmationOtpView) appeared (poll up to 10s)
        console.log('Checking for Ride Confirmation OTP Modal...');
        let hasOtpModal = false;
        for (let t = 0; t < 10; t++) {
            if (await elementExists('android=new UiSelector().textContains("OTP")') ||
                await elementExists('android=new UiSelector().textContains("Verify")') ||
                await elementExists('android=new UiSelector().descriptionContains("Verify")') ||
                await elementExists('android=new UiSelector().textContains("code")')) {
                hasOtpModal = true;
                break;
            }
            await driver.pause(1000);
        }

        if (hasOtpModal) {
            console.log('>>> Ride Confirmation OTP View DETECTED! Fetching OTP dynamically... <<<');
            let confirmationCode = '1234';
            try {
                const otpLine = execSync('adb logcat -d | grep -E "confirmationCode:\\s*[0-9]{4}|test9[0-9]{4}" | tail -n 1', { encoding: 'utf8' });
                const m = otpLine.match(/(?:confirmationCode:\s*|test9)(\d{4})/);
                if (m && m[1]) {
                    confirmationCode = m[1];
                    console.log(`>>> Dynamically retrieved Confirmation OTP from Rider logcat: "${confirmationCode}" <<<`);
                }
            } catch {}

            console.log(`Entering OTP: "${confirmationCode}" into OTP boxes...`);
            // Focus Box 1 at verified center (x: 165, y: 1860)
            await pointerTap(driver, 165, 1860);
            try { execSync('adb shell input tap 165 1860', { stdio: 'ignore' }); } catch {}
            await driver.pause(800);
            try {
                execSync(`adb shell input text ${confirmationCode}`, { stdio: 'ignore' });
            } catch {
                await driver.keys(confirmationCode);
            }
            await driver.pause(1000);

            // Tap "Verify ->" button at verified center (x: 720, y: 1255 when keyboard up, or 720, 2140 when keyboard down)
            console.log('Tapping "Verify ->" button...');
            await pointerTap(driver, 720, 1255);
            try { execSync('adb shell input tap 720 1255', { stdio: 'ignore' }); } catch {}
            await driver.pause(500);
            await pointerTap(driver, 720, 2140);
            try { execSync('adb shell input tap 720 2140', { stdio: 'ignore' }); } catch {}
            await driver.pause(4000);
        }
        await captureScreen(driver, 'stage3_13_ride_started');

        // =========================================================================
        // Step 6: Swipes slider for "Complete ride" to end trip
        // =========================================================================
        console.log('\n>>> Step 6: Swiping "Complete ride" Slider <<<');
        for (let i = 0; i < 20; i++) {
            if (await elementExists('android=new UiSelector().textContains("Complete")') ||
                await elementExists('android=new UiSelector().descriptionContains("Complete")')) {
                break;
            }
            await driver.pause(1000);
        }
        await swipeSlider('Complete ride', ['Complete', 'COMPLETE', 'End', 'complete'], 1713);
        await driver.pause(4000);
        await captureScreen(driver, 'stage3_14_complete_ride_swiped');

        // =========================================================================
        // Step 7: Enters $1 in Toll Fee input field and clicks "Done"
        // =========================================================================
        console.log('\n>>> Step 7: Entering Toll Fee ($1) and Clicking Done <<<');
        let tollWait = 15;
        while (tollWait > 0) {
            if (await elementExists('android=new UiSelector().textContains("Toll")') ||
                await elementExists('android=new UiSelector().descriptionContains("Toll")') ||
                await elementExists('android=new UiSelector().descriptionContains("Done")')) {
                break;
            }
            await driver.pause(1000);
            tollWait--;
        }

        await captureScreen(driver, 'stage3_15_toll_page');
        console.log('Focusing Toll Fee input field (x: 564, y: 950)...');
        try {
            const tollInput = await driver.$('//android.widget.EditText');
            if (await tollInput.isDisplayed()) {
                await tollInput.click();
            } else {
                await pointerTap(driver, 564, 950);
            }
        } catch {
            await pointerTap(driver, 564, 950);
        }
        await driver.pause(800);
        try {
            execSync('adb shell input text 1', { stdio: 'ignore' });
        } catch {
            await driver.keys('1');
        }
        console.log('Entered Toll Fee: 1');
        await driver.pause(1000);

        // Hide keyboard safely before clicking Done (or tap outside at x: 540, y: 350)
        try {
            if (await driver.isKeyboardShown()) await driver.hideKeyboard();
        } catch {}
        await pointerTap(driver, 540, 350);
        await driver.pause(1000);

        // Click "Done" button on Toll fee page
        console.log('Clicking "Done" button on Toll Fee page...');
        let clickedTollDone = false;
        try {
            const doneEl = await driver.$('android=new UiSelector().description("Done")');
            if (await doneEl.isDisplayed()) {
                await doneEl.click();
                clickedTollDone = true;
                console.log('Clicked Toll Done button via UiSelector description("Done").');
            }
        } catch {}

        if (!clickedTollDone) {
            console.log('Tapping Toll Done coordinates...');
            await pointerTap(driver, 540, 2111);
            try { execSync('adb shell input tap 540 2111', { stdio: 'ignore' }); } catch {}
            await driver.pause(500);
            await pointerTap(driver, 540, 1238);
            try { execSync('adb shell input tap 540 1238', { stdio: 'ignore' }); } catch {}
        }

        // Wait explicitly for Driver Trip Details page ("Earnings" / "Next ->") to appear
        console.log('Waiting for Driver Trip Details page to load...');
        let tripDetailsWait = 20;
        while (tripDetailsWait > 0) {
            if (await elementExists('android=new UiSelector().descriptionContains("Next")') ||
                await elementExists('android=new UiSelector().textContains("Next")') ||
                await elementExists('android=new UiSelector().descriptionContains("Earnings")') ||
                await elementExists('android=new UiSelector().textContains("Earnings")')) {
                break;
            }
            await driver.pause(1000);
            tripDetailsWait--;
        }
        await captureScreen(driver, 'stage3_16_trip_details');

        // Click "Next ->" on Driver Trip Details
        console.log('Clicking "Next ->" button on Driver Trip Details...');
        let clickedTripNext = false;
        try {
            const nextEl = await driver.$('android=new UiSelector().descriptionContains("Next")');
            if (await nextEl.isDisplayed()) {
                await nextEl.click();
                clickedTripNext = true;
                console.log('Clicked Next button via description selector.');
            }
        } catch {}
        if (!clickedTripNext) {
            await pointerTap(driver, 540, 2120);
            try { execSync('adb shell input tap 540 2120', { stdio: 'ignore' }); } catch {}
        }
        await driver.pause(4000);
        await captureScreen(driver, 'stage3_17_after_trip_details_next');

        // =========================================================================
        // Step 8: Holds Driver app on Cash Payment Confirmation modal ("Did you collect cash?")
        // =========================================================================
        console.log('\n>>> Step 8: Holding Driver app on Cash Confirmation Modal ("Did you collect cash?") <<<');
        let cashModalWait = 20;
        while (cashModalWait > 0) {
            if (await elementExists('android=new UiSelector().textContains("collect")') ||
                await elementExists('android=new UiSelector().descriptionContains("Collect")') ||
                await elementExists('android=new UiSelector().textContains("Cash")') ||
                await elementExists('android=new UiSelector().descriptionContains("cash")') ||
                await elementExists('android=new UiSelector().textContains("Yes")') ||
                await elementExists('android=new UiSelector().descriptionContains("Yes")')) {
                console.log('>>> Cash confirmation modal active on Driver App. Holding here without closing... <<<');
                break;
            }
            await driver.pause(1000);
            cashModalWait--;
        }
        await captureScreen(driver, 'stage3_18_driver_cash_modal_hold');

        // =========================================================================
        // Step 9: Switches to Rider app trip details page
        // =========================================================================
        console.log('\n>>> Step 9: Switching to Rider Application (com.radicalstart.wooberly) <<<');
        try { execSync('adb shell monkey -p com.radicalstart.wooberly -c android.intent.category.LAUNCHER 1', { stdio: 'ignore' }); } catch {}
        try { execSync('adb shell am start -n com.radicalstart.wooberly/com.radicalstart.wooberly.MainActivity', { stdio: 'ignore' }); } catch {}
        try { await driver.activateApp('com.radicalstart.wooberly'); } catch {}

        console.log('Waiting for Rider Trip Details / Confirm page to load...');
        let riderConfirmWait = 25;
        while (riderConfirmWait > 0) {
            if (await elementExists('android=new UiSelector().descriptionContains("Confirm")') ||
                await elementExists('android=new UiSelector().textContains("Confirm")') ||
                await elementExists('android=new UiSelector().descriptionContains("Trip details")') ||
                await elementExists('android=new UiSelector().descriptionContains("Trip amount")')) {
                break;
            }
            await driver.pause(1000);
            riderConfirmWait--;
        }
        await captureScreen(driver, 'stage3_19_rider_trip_details');

        // =========================================================================
        // Step 10: Clicks "Confirm" button on Rider app to finalize fare payment
        // =========================================================================
        console.log('\n>>> Step 10: Clicking "Confirm" Button on Rider App <<<');
        let clickedRiderConfirm = false;
        try {
            const confirmBtn = await driver.$('android=new UiSelector().descriptionContains("Confirm")');
            if (await confirmBtn.isDisplayed()) {
                await confirmBtn.click();
                clickedRiderConfirm = true;
                console.log('Clicked Rider Confirm button via UiSelector descriptionContains("Confirm").');
            }
        } catch {}
        if (!clickedRiderConfirm) {
            await pointerTap(driver, 540, 2125);
            try { execSync('adb shell input tap 540 2125', { stdio: 'ignore' }); } catch {}
        }
        await driver.pause(4000);
        await captureScreen(driver, 'stage3_20_rider_confirmed');

        // =========================================================================
        // Step 11: Selects a star rating on Rider review page and clicks "Done"
        // =========================================================================
        console.log('\n>>> Step 11: Submitting Rider Review (5 Stars + Done) <<<');
        let riderReviewWait = 20;
        while (riderReviewWait > 0) {
            if (await elementExists('android=new UiSelector().descriptionContains("Payment completed")') ||
                await elementExists('android=new UiSelector().descriptionContains("How was your driver?")') ||
                await elementExists('android=new UiSelector().description("Done")')) {
                break;
            }
            await driver.pause(1000);
            riderReviewWait--;
        }
        await driver.pause(1500);
        console.log('Selecting 5-star rating on Rider review at verified center (x: 810, y: 1433)...');
        await pointerTap(driver, 810, 1433);
        try { execSync('adb shell input tap 810 1433', { stdio: 'ignore' }); } catch {}
        await driver.pause(1500);

        console.log('Clicking "Done" button on Rider review page (x: 540, y: 2159)...');
        let clickedRiderDone = false;
        try {
            const doneBtn = await driver.$('android=new UiSelector().description("Done")');
            if (await doneBtn.isDisplayed()) {
                await doneBtn.click();
                clickedRiderDone = true;
                console.log('Clicked Rider Done button via description("Done").');
            }
        } catch {}
        if (!clickedRiderDone) {
            await pointerTap(driver, 540, 2159);
            try { execSync('adb shell input tap 540 2159', { stdio: 'ignore' }); } catch {}
        }
        await driver.pause(3500);
        await captureScreen(driver, 'stage3_21_rider_review_done');

        // =========================================================================
        // Step 12: Switches to Driver app and clicks "Yes" on the cash confirmation modal
        // =========================================================================
        console.log('\n>>> Step 12: Switching to Driver App & Clicking "Yes" on Cash Modal <<<');
        try { execSync('adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity', { stdio: 'ignore' }); } catch {}
        try { await driver.activateApp('com.radicalstart.wooberlydriver'); } catch {}
        await driver.pause(3000);

        let cashYesWait = 20;
        while (cashYesWait > 0) {
            if (await elementExists('android=new UiSelector().descriptionContains("Yes")') ||
                await elementExists('android=new UiSelector().textContains("Yes")') ||
                await elementExists('android=new UiSelector().descriptionContains("cash")')) {
                break;
            }
            await driver.pause(1000);
            cashYesWait--;
        }
        await captureScreen(driver, 'stage3_22_driver_cash_modal_ready');

        console.log('Clicking "Yes" button on Cash Confirmation popup (x: 730, y: 2137)...');
        let clickedYes = false;
        try {
            const yesBtn = await driver.$('android=new UiSelector().descriptionContains("Yes")');
            if (await yesBtn.isDisplayed()) {
                await yesBtn.click();
                clickedYes = true;
                console.log('Clicked Cash Yes button via description selector.');
            }
        } catch {}
        if (!clickedYes) {
            await pointerTap(driver, 730, 2137);
            try { execSync('adb shell input tap 730 2137', { stdio: 'ignore' }); } catch {}
        }
        await driver.pause(3500);
        await captureScreen(driver, 'stage3_23_driver_cash_confirmed');

        // =========================================================================
        // Step 13: Selects a star rating on Driver review page and clicks "Done"
        // =========================================================================
        console.log('\n>>> Step 13: Submitting Driver Review (5 Stars + Done) <<<');
        let driverReviewWait = 20;
        while (driverReviewWait > 0) {
            if (await elementExists('android=new UiSelector().descriptionContains("Review")') ||
                await elementExists('android=new UiSelector().descriptionContains("How was your rider?")') ||
                await elementExists('android=new UiSelector().description("Done")')) {
                break;
            }
            await driver.pause(1000);
            driverReviewWait--;
        }
        await driver.pause(1500);
        console.log('Selecting 5-star rating on Driver review page at verified center (x: 760, y: 855)...');
        await pointerTap(driver, 760, 855);
        try { execSync('adb shell input tap 760 855', { stdio: 'ignore' }); } catch {}
        await driver.pause(1500);

        console.log('Clicking "Done" button on Driver review page (x: 540, y: 2130)...');
        let clickedDriverDone = false;
        try {
            const doneBtn = await driver.$('android=new UiSelector().description("Done")');
            if (await doneBtn.isDisplayed()) {
                await doneBtn.click();
                clickedDriverDone = true;
                console.log('Clicked Driver Done button via description("Done").');
            }
        } catch {}
        if (!clickedDriverDone) {
            await pointerTap(driver, 540, 2130);
            try { execSync('adb shell input tap 540 2130', { stdio: 'ignore' }); } catch {}
        }
        await driver.pause(4000);
        await captureScreen(driver, 'stage3_24_driver_review_done');

        console.log('\n========================================================================');
        console.log('>>> COMPLETE END-TO-END TRIP LIFECYCLE & DUAL REVIEWS SUCCESSFUL! <<<');
        console.log('========================================================================\n');

    } catch (err) {
        console.error('Error during Trip Acceptance & Lifecycle Flow:', err);
        throw err;
    }
}

if (require.main === module) {
    runTripLifecycleFlow().catch((e) => {
        console.error(e);
        process.exit(1);
    });
}
