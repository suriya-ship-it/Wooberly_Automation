/**
 * WOOBERLY VISUAL DEBUG SCRIPT
 * ─────────────────────────────────────────────────────────────────
 * Walks through the FULL flow step-by-step, taking a screenshot
 * after every meaningful action so we can see exactly what the
 * app is doing vs what we expect.
 *
 * Usage:  npx tsx tests/e2e/wooberly_visual_debug.ts
 *
 * Screenshots are saved to:
 *   /tmp/wdebug/step_NNN_<label>.png
 * And also pulled to the local dir for review.
 * ─────────────────────────────────────────────────────────────────
 */

import { remote } from 'webdriverio';
import { execSync, spawn } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

// ── Helpers ──────────────────────────────────────────────────────

const SCREENSHOT_DIR = path.resolve(__dirname, '../../debug_screenshots');
if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });

let stepCounter = 0;

async function shot(driver: WebdriverIO.Browser, label: string) {
    stepCounter++;
    const filename = `step_${String(stepCounter).padStart(3, '0')}_${label.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.png`;
    const localPath = path.join(SCREENSHOT_DIR, filename);
    const devicePath = `/sdcard/wdbg_${filename}`;
    try {
        // Appium screenshot
        const b64 = await driver.takeScreenshot();
        fs.writeFileSync(localPath, Buffer.from(b64, 'base64'));
        console.log(`📸 [${stepCounter}] ${label} → ${filename}`);
    } catch {
        try {
            execSync(`adb shell screencap -p ${devicePath} && adb pull ${devicePath} "${localPath}" && adb shell rm ${devicePath}`, { stdio: 'ignore' });
            console.log(`📸 [${stepCounter}] ${label} (adb) → ${filename}`);
        } catch { console.warn(`⚠️  Could not capture screenshot for: ${label}`); }
    }
}

function adbTap(x: number, y: number) {
    try { execSync(`adb shell input tap ${Math.round(x)} ${Math.round(y)}`, { stdio: 'ignore' }); } catch {}
}

function adbText(text: string) {
    const safe = text.replace(/ /g, '%s');
    try { execSync(`adb shell input text "${safe}"`, { stdio: 'ignore' }); } catch {}
}

function adbSwipe(x1: number, y1: number, x2: number, y2: number, ms = 800) {
    try { execSync(`adb shell input swipe ${Math.round(x1)} ${Math.round(y1)} ${Math.round(x2)} ${Math.round(y2)} ${ms}`, { stdio: 'ignore' }); } catch {}
}

async function tap(driver: WebdriverIO.Browser, x: number, y: number) {
    try {
        await driver.action('pointer')
            .move({ duration: 0, x: Math.round(x), y: Math.round(y) })
            .down({ button: 0 }).pause(100).up({ button: 0 }).perform();
    } catch { adbTap(x, y); }
    adbTap(x, y);
}

async function swipe(driver: WebdriverIO.Browser, x1: number, y1: number, x2: number, y2: number, ms = 800) {
    try {
        await driver.action('pointer')
            .move({ duration: 0, x: Math.round(x1), y: Math.round(y1) })
            .down({ button: 0 }).pause(ms)
            .move({ duration: ms, x: Math.round(x2), y: Math.round(y2) })
            .up({ button: 0 }).perform();
    } catch { adbSwipe(x1, y1, x2, y2, ms); }
}

async function exists(driver: WebdriverIO.Browser, sel: string): Promise<boolean> {
    try {
        const el = await driver.$(sel);
        return await el.isDisplayed();
    } catch { return false; }
}

async function clickSel(driver: WebdriverIO.Browser, selector: string, fbX: number, fbY: number) {
    try {
        const el = await driver.$(selector);
        if (await el.isDisplayed()) {
            const loc = await el.getLocation();
            const sz = await el.getSize();
            await tap(driver, loc.x + sz.width / 2, loc.y + sz.height / 2);
            return true;
        }
    } catch {}
    await tap(driver, fbX, fbY);
    return false;
}

async function waitFor(driver: WebdriverIO.Browser, selectors: string[], timeoutMs = 15000): Promise<boolean> {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
        for (const s of selectors) {
            if (await exists(driver, s)) return true;
        }
        await driver.pause(1000);
    }
    return false;
}

async function dumpPageSource(driver: WebdriverIO.Browser, label: string) {
    try {
        const src = await driver.getPageSource();
        const fname = path.join(SCREENSHOT_DIR, `dump_${String(stepCounter).padStart(3, '0')}_${label.replace(/[^a-z0-9]/gi, '_')}.xml`);
        fs.writeFileSync(fname, src);
        console.log(`  📄 Page source saved: ${path.basename(fname)}`);
    } catch {}
}

function loadEnv() {
    const envPath = path.resolve(__dirname, '../../.env');
    if (fs.existsSync(envPath)) {
        const lines = fs.readFileSync(envPath, 'utf-8').split('\n');
        for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith('#')) continue;
            const idx = trimmed.indexOf('=');
            if (idx !== -1) {
                const k = trimmed.slice(0, idx).trim();
                const v = trimmed.slice(idx + 1).trim();
                if (!process.env[k]) process.env[k] = v;
            }
        }
    }
}

loadEnv();

const DRIVER_PHONE = process.env.DRIVER_PHONE || '7639699826';
const DRIVER_OTP   = process.env.DRIVER_OTP   || '1234';

// ── Appium bootstrap ─────────────────────────────────────────────

async function ensureAppium() {
    try {
        const res = await fetch('http://127.0.0.1:4723/status');
        const j = await res.json() as any;
        if (j?.value?.ready) { console.log('✅ Appium server ready'); return; }
    } catch {}
    console.log('Starting Appium server...');
    const p = spawn('appium', ['--address', '127.0.0.1', '--port', '4723'], { detached: true, stdio: 'ignore' });
    p.unref();
    for (let i = 0; i < 15; i++) {
        await new Promise(r => setTimeout(r, 1000));
        try {
            const res = await fetch('http://127.0.0.1:4723/status');
            const j = await res.json() as any;
            if (j?.value?.ready) { console.log('✅ Appium started'); return; }
        } catch {}
    }
    console.warn('⚠️ Appium may not be ready — proceeding anyway');
}

// ── PHASE 1: Driver Go Online ─────────────────────────────────────

async function phase1_driverOnline(driver: WebdriverIO.Browser) {
    console.log('\n════════════════════════════════════════');
    console.log('PHASE 1: Driver App → Go Online');
    console.log('════════════════════════════════════════');

    await driver.pause(3000);
    await shot(driver, 'phase1_launch');
    await dumpPageSource(driver, 'phase1_launch');

    // ── Handle "Get started" landing page ────────────────────────
    if (await exists(driver, '//*[contains(@text,"Get started") or contains(@content-desc,"Get started")]')) {
        console.log('→ "Get started" page detected');
        await shot(driver, 'phase1_get_started');
        await clickSel(driver, '//*[contains(@text,"Get started") or contains(@content-desc,"Get started")]', 540, 2131);
        await driver.pause(3000);
        await shot(driver, 'phase1_after_get_started');
        await dumpPageSource(driver, 'phase1_after_get_started');
    }

    // ── Permission dialogs ────────────────────────────────────────
    const permSels = [
        '//*[@text="Allow" or @text="ALLOW" or @text="While using the app"]',
        '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button"]',
        '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_foreground_only_button"]',
    ];
    for (const s of permSels) {
        if (await exists(driver, s)) {
            console.log(`→ Dismissing permission: ${s}`);
            await clickSel(driver, s, 540, 1400);
            await driver.pause(1500);
            await shot(driver, 'phase1_perm_allow');
        }
    }

    // ── Check if already logged in (map/online screen) ────────────
    const alreadyOnlineSelectors = [
        '//*[contains(@text,"online") or contains(@content-desc,"online")]',
        '//*[contains(@text,"Online") or contains(@content-desc,"Online")]',
        '//*[contains(@text,"offline") or contains(@content-desc,"offline")]',
        '//*[@content-desc="Go" or @text="Go"]',
    ];
    if (await waitFor(driver, alreadyOnlineSelectors, 5000)) {
        console.log('→ Driver already logged in — checking online status');
        await shot(driver, 'phase1_already_logged_in');
        // Check if already online
        if (await exists(driver, '//*[contains(@text,"online") or contains(@content-desc,"online") or contains(@text,"Online")]')) {
            console.log('✅ Driver is ALREADY ONLINE — skipping go-online step');
            return;
        }
        // Try to go online
        await goOnline(driver);
        return;
    }

    // ── Login flow ────────────────────────────────────────────────
    console.log('→ Need to log in');

    // OTP screen check
    if (await exists(driver, '//*[contains(@text,"sent you") or contains(@text,"OTP") or contains(@text,"code")]')) {
        console.log('→ Already on OTP screen');
        await enterOTP(driver, DRIVER_OTP);
        await goOnline(driver);
        return;
    }

    // Phone number screen
    if (await exists(driver, '//android.widget.EditText')) {
        console.log('→ Phone number screen');
        await shot(driver, 'phase1_phone_screen');
    } else {
        // Wait for phone screen
        await waitFor(driver, ['//android.widget.EditText'], 10000);
        await shot(driver, 'phase1_phone_screen');
    }

    // Tap phone field and type number
    await clickSel(driver, '//android.widget.EditText', 500, 535);
    await driver.pause(500);
    try { await driver.keys(DRIVER_PHONE); } catch { adbText(DRIVER_PHONE); }
    await driver.pause(500);
    await shot(driver, 'phase1_phone_typed');

    // Dismiss keyboard
    try { await driver.hideKeyboard(); } catch {}
    await driver.pause(1000);

    // Terms checkbox
    const checkboxSels = [
        '//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ImageView[3]',
        '//*[@resource-id="checkbox"]',
    ];
    for (const s of checkboxSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 90, 1952);
            break;
        }
    }
    await tap(driver, 90, 1952); // coord fallback
    await driver.pause(500);
    await shot(driver, 'phase1_checkbox_ticked');

    // Verify button
    await clickSel(driver, '//*[contains(@text,"Verify") or contains(@content-desc,"Verify")]', 540, 2131);
    await driver.pause(4000);
    await shot(driver, 'phase1_after_verify');
    await dumpPageSource(driver, 'phase1_after_verify');

    // OTP screen
    if (await exists(driver, '//android.widget.EditText')) {
        console.log('→ OTP screen appeared');
        await enterOTP(driver, DRIVER_OTP);
    }

    // Wait for home map screen
    await waitFor(driver, alreadyOnlineSelectors, 20000);
    await shot(driver, 'phase1_home_screen');
    await goOnline(driver);
}

async function enterOTP(driver: WebdriverIO.Browser, otp: string) {
    console.log(`→ Entering OTP: ${otp}`);
    await driver.pause(1000);
    await shot(driver, 'phase1_otp_screen');
    await dumpPageSource(driver, 'phase1_otp_screen');
    try {
        const inputs: any = await driver.$$('//android.widget.EditText');
        const count = inputs.length;
        if (count >= 4) {
            for (let i = 0; i < 4; i++) {
                await inputs[i].click();
                await driver.pause(200);
                await inputs[i].setValue(otp[i]);
                await driver.pause(200);
            }
        } else {
            await tap(driver, 150, 1850);
            await driver.pause(300);
            adbText(otp);
        }
    } catch {
        await tap(driver, 150, 1850);
        await driver.pause(300);
        adbText(otp);
    }
    await driver.pause(1000);
    await shot(driver, 'phase1_otp_entered');
    // Verify button
    await clickSel(driver, '//*[contains(@text,"Verify") or contains(@content-desc,"Verify")]', 540, 2131);
    await driver.pause(5000);
    await shot(driver, 'phase1_after_otp_verify');
}

async function goOnline(driver: WebdriverIO.Browser) {
    await driver.pause(3000);
    await shot(driver, 'phase1_before_go_online');
    await dumpPageSource(driver, 'phase1_before_go_online');

    // Handle any permission dialogs for location
    const locationPermSelectors = [
        '//*[contains(@text,"Allow all the time") or contains(@text,"Always allow")]',
        '//*[contains(@text,"While using") or contains(@text,"while using")]',
        '//*[@text="Allow" or @text="ALLOW"]',
        '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_always_button"]',
        '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_foreground_only_button"]',
    ];
    for (const s of locationPermSelectors) {
        if (await exists(driver, s)) {
            console.log(`→ Location permission: ${s}`);
            await clickSel(driver, s, 540, 1400);
            await driver.pause(2000);
            await shot(driver, 'phase1_location_perm_granted');
        }
    }

    // Background location — needs Settings redirect
    if (await exists(driver, '//*[contains(@text,"Change to") or contains(@text,"setting") or contains(@text,"Setting")]')) {
        console.log('→ Background location — needs Settings');
        await shot(driver, 'phase1_bg_location_prompt');
        await clickSel(driver, '//*[contains(@text,"Change to") or contains(@text,"Allow all the time")]', 540, 1500);
        await driver.pause(3000);
        await shot(driver, 'phase1_in_settings');
        // In Settings — tap "Allow all the time"
        await clickSel(driver, '//*[contains(@text,"Allow all the time")]', 540, 800);
        await driver.pause(1500);
        // Press back
        try { execSync('adb shell input keyevent 4', { stdio: 'ignore' }); } catch {}
        await driver.pause(2000);
        await shot(driver, 'phase1_back_from_settings');
    }

    // Proceed button (if any)
    if (await exists(driver, '//*[contains(@text,"Proceed") or contains(@content-desc,"Proceed")]')) {
        console.log('→ Tapping Proceed');
        await clickSel(driver, '//*[contains(@text,"Proceed") or contains(@content-desc,"Proceed")]', 540, 1500);
        await driver.pause(2000);
    }

    // Go Online toggle
    await shot(driver, 'phase1_go_online_attempt');
    const goSelectors = [
        '//*[@content-desc="Go" or @text="Go"]',
        '//*[contains(@content-desc,"Go online") or contains(@text,"Go online")]',
        '//android.widget.Button[contains(@text,"Go")]',
    ];
    for (const s of goSelectors) {
        if (await exists(driver, s)) {
            console.log(`→ Tapping Go Online: ${s}`);
            await clickSel(driver, s, 540, 1200);
            await driver.pause(3000);
            await shot(driver, 'phase1_after_go_online_tap');
            break;
        }
    }
    // Coord fallback
    await tap(driver, 540, 1200);
    await driver.pause(3000);
    await shot(driver, 'phase1_online_status');
    await dumpPageSource(driver, 'phase1_online_status');
    console.log('✅ PHASE 1 COMPLETE — Driver should be online');
}

// ── PHASE 2: Rider Booking ────────────────────────────────────────

async function phase2_riderBooking(driver: WebdriverIO.Browser) {
    console.log('\n════════════════════════════════════════');
    console.log('PHASE 2: Rider App → Book a Ride');
    console.log('════════════════════════════════════════');

    // Switch to Rider app
    try { execSync('adb shell am start -n com.radicalstart.wooberly/.MainActivity', { stdio: 'ignore' }); } catch {}
    await driver.activateApp('com.radicalstart.wooberly');
    await driver.pause(4000);
    await shot(driver, 'phase2_rider_launch');
    await dumpPageSource(driver, 'phase2_rider_launch');

    // Permission dialogs
    const permSels = [
        '//*[@text="Allow" or @text="ALLOW" or @text="While using the app"]',
        '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_foreground_only_button"]',
        '//*[@resource-id="com.android.permissioncontroller:id/permission_allow_button"]',
    ];
    for (const s of permSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 540, 1500);
            await driver.pause(1500);
        }
    }

    // Wait for home screen
    const homeSelectors = [
        '~Search your destination', '~Where to?',
        '//*[contains(@content-desc,"Where") or contains(@text,"Where")]',
        '//*[contains(@content-desc,"Search") or contains(@text,"Search")]',
        '~Book now', '//*[contains(@text,"Book now")]',
    ];
    const homeReady = await waitFor(driver, homeSelectors, 15000);
    await shot(driver, 'phase2_rider_home');
    await dumpPageSource(driver, 'phase2_rider_home');

    if (!homeReady) {
        console.warn('⚠️ Rider home not detected');
    }

    // Tap search/destination field
    console.log('→ Tapping destination search');
    const destSelectors = [
        '~Search your destination',
        '//*[contains(@content-desc,"Search your destination")]',
        '//*[contains(@text,"Search your destination")]',
        '~Where to?',
        '//*[contains(@content-desc,"Where to")]',
    ];
    let tappedSearch = false;
    for (const s of destSelectors) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 540, 590);
            tappedSearch = true;
            break;
        }
    }
    if (!tappedSearch) await tap(driver, 540, 590);
    await driver.pause(2500);
    await shot(driver, 'phase2_search_tapped');
    await dumpPageSource(driver, 'phase2_search_tapped');

    // Look for drop-off field
    console.log('→ Typing destination: Mattuthavani');
    const dropSels = [
        '//*[contains(@content-desc,"Drop") or contains(@text,"Drop")]',
        '//android.widget.EditText[2]',
        '(//android.widget.EditText)[2]',
        '//android.widget.EditText[last()]',
    ];
    let typedDest = false;
    for (const s of dropSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 540, 450);
            await driver.pause(500);
            try { await driver.keys('Mattuthavani'); } catch { adbText('Mattuthavani'); }
            typedDest = true;
            break;
        }
    }
    if (!typedDest) {
        // Try tapping drop-off zone
        await tap(driver, 540, 450);
        await driver.pause(500);
        try { await driver.keys('Mattuthavani'); } catch { adbText('Mattuthavani'); }
    }
    await driver.pause(3000);
    await shot(driver, 'phase2_typed_destination');
    await dumpPageSource(driver, 'phase2_typed_destination');

    // Tap first prediction
    console.log('→ Selecting first autocomplete result');
    const predSels = [
        '//*[contains(@text,"Mattuthavani") or contains(@content-desc,"Mattuthavani")]',
        '(//android.widget.TextView[@text])[2]',
    ];
    let selectedPred = false;
    for (const s of predSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 540, 700);
            selectedPred = true;
            break;
        }
    }
    if (!selectedPred) await tap(driver, 540, 700);
    await driver.pause(4000);
    await shot(driver, 'phase2_destination_selected');
    await dumpPageSource(driver, 'phase2_destination_selected');

    // Vehicle category selection
    console.log('→ Selecting vehicle category (MiniCar/first option)');
    await driver.pause(2000);
    // Tap first vehicle card or "Mini" / category
    const catSels = [
        '//*[contains(@text,"Mini") or contains(@content-desc,"Mini")]',
        '//*[contains(@text,"Car") or contains(@content-desc,"Car")]',
        '(//android.view.View)[3]',
    ];
    for (const s of catSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 540, 1600);
            break;
        }
    }
    await driver.pause(2000);
    await shot(driver, 'phase2_category_selected');
    await dumpPageSource(driver, 'phase2_category_selected');

    // Dismiss info/detail modal
    const closeSels = [
        '//*[contains(@text,"Close") or contains(@content-desc,"Close")]',
        '//*[contains(@text,"×") or contains(@content-desc,"×")]',
        '//*[contains(@text,"Done") or contains(@content-desc,"Done")]',
    ];
    for (const s of closeSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 540, 900);
            await driver.pause(1000);
            break;
        }
    }

    // Book Now / Confirm
    console.log('→ Clicking Book Now / Confirm');
    const bookSels = [
        '//*[contains(@text,"Book now") or contains(@content-desc,"Book now")]',
        '//*[contains(@text,"Book") or contains(@content-desc,"Book")]',
        '//*[contains(@text,"Confirm") or contains(@content-desc,"Confirm")]',
        '//*[contains(@text,"Request") or contains(@content-desc,"Request")]',
    ];
    for (const s of bookSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 540, 2100);
            break;
        }
    }
    await driver.pause(3000);
    await shot(driver, 'phase2_after_book');
    await dumpPageSource(driver, 'phase2_after_book');

    // Cash / payment modal
    if (await exists(driver, '//*[contains(@text,"Cash") or contains(@content-desc,"Cash")]')) {
        console.log('→ Cash payment modal — confirming');
        await shot(driver, 'phase2_cash_modal');
        const cashConfirmSels = [
            '//*[contains(@text,"Confirm") or contains(@content-desc,"Confirm")]',
            '//*[contains(@text,"OK") or contains(@content-desc,"OK")]',
            '//*[contains(@text,"Yes") or contains(@content-desc,"Yes")]',
        ];
        for (const s of cashConfirmSels) {
            if (await exists(driver, s)) {
                await clickSel(driver, s, 540, 1500);
                break;
            }
        }
        await tap(driver, 540, 1500);
        await driver.pause(2000);
        await shot(driver, 'phase2_after_cash_confirm');
    }

    // Precaution / instruction modal
    if (await exists(driver, '//*[contains(@text,"Precaution") or contains(@content-desc,"Precaution") or contains(@text,"Safety")]')) {
        console.log('→ Precaution modal');
        await shot(driver, 'phase2_precaution_modal');
        await clickSel(driver, '//*[contains(@text,"OK") or contains(@text,"Got it") or contains(@text,"Proceed") or contains(@text,"Continue")]', 540, 1800);
        await driver.pause(2000);
        await shot(driver, 'phase2_after_precaution');
    }

    // Wait for "Connecting to drivers" / dispatch screen
    console.log('→ Waiting for dispatch / connecting screen');
    const connectSels = [
        '//*[contains(@text,"Connecting") or contains(@content-desc,"Connecting")]',
        '//*[contains(@text,"Looking") or contains(@content-desc,"Looking")]',
        '//*[contains(@text,"nearby") or contains(@content-desc,"nearby")]',
        '//*[contains(@text,"Finding") or contains(@content-desc,"Finding")]',
    ];
    const dispatched = await waitFor(driver, connectSels, 15000);
    await shot(driver, 'phase2_dispatch_screen');
    await dumpPageSource(driver, 'phase2_dispatch_screen');
    if (dispatched) {
        console.log('✅ PHASE 2 COMPLETE — Rider request dispatched');
    } else {
        console.warn('⚠️ Could not confirm dispatch screen — check screenshot');
    }
}

// ── PHASE 3: Driver Accepts ───────────────────────────────────────

async function phase3_driverAccept(driver: WebdriverIO.Browser) {
    console.log('\n════════════════════════════════════════');
    console.log('PHASE 3: Driver App → Accept Trip Request');
    console.log('════════════════════════════════════════');

    await driver.activateApp('com.radicalstart.wooberlydriver');
    await driver.pause(3000);
    await shot(driver, 'phase3_driver_after_switch');
    await dumpPageSource(driver, 'phase3_driver_after_switch');

    // Poll up to 40s for trip request modal
    console.log('→ Waiting for trip request modal (up to 40s)');
    const requestSels = [
        '//*[contains(@text,"Accept") or contains(@content-desc,"Accept")]',
        '//*[contains(@text,"New trip") or contains(@content-desc,"New trip")]',
        '//*[contains(@text,"Ride request") or contains(@content-desc,"Ride request")]',
        '//*[contains(@text,"Trip request") or contains(@content-desc,"Trip request")]',
    ];
    const gotRequest = await waitFor(driver, requestSels, 40000);
    await shot(driver, 'phase3_trip_request');
    await dumpPageSource(driver, 'phase3_trip_request');

    if (!gotRequest) {
        console.warn('⚠️ Trip request not detected — check screenshot');
    }

    console.log('→ Tapping Accept');
    // Try element first
    const acceptSels = [
        '//*[@text="Accept" or @content-desc="Accept"]',
        '//*[contains(@text,"Accept") or contains(@content-desc,"Accept")]',
    ];
    for (const s of acceptSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 800, 2200);
            break;
        }
    }
    await tap(driver, 800, 2200);
    await driver.pause(500);
    await tap(driver, 800, 2250);
    await driver.pause(3000);
    await shot(driver, 'phase3_after_accept');
    await dumpPageSource(driver, 'phase3_after_accept');
    console.log('✅ PHASE 3 COMPLETE — Accept tapped');
}

// ── PHASE 4: Trip Lifecycle ───────────────────────────────────────

async function phase4_tripLifecycle(driver: WebdriverIO.Browser) {
    console.log('\n════════════════════════════════════════');
    console.log('PHASE 4: Trip Lifecycle — 13 Steps');
    console.log('════════════════════════════════════════');

    // -- Step 1: Location reached swipe --
    console.log('\n▶ Step 1: Swipe "Location reached"');
    await driver.pause(3000);
    await shot(driver, 'phase4_step1_before_swipe');
    await dumpPageSource(driver, 'phase4_step1_before_swipe');
    await swipe(driver, 120, 1713, 980, 1713, 1000);
    await driver.pause(4000);
    await shot(driver, 'phase4_step1_after_swipe');

    // -- Step 2: Expand bottom sheet + click Chat --
    console.log('\n▶ Step 2: Expand bottom sheet → click Chat');
    // Tap up arrow
    await tap(driver, 890, 1970);
    await driver.pause(1000);
    await swipe(driver, 540, 2100, 540, 1100, 800);
    await driver.pause(2000);
    await shot(driver, 'phase4_step2_sheet_expanded');
    await dumpPageSource(driver, 'phase4_step2_sheet_expanded');

    // Chat icon - check what text/label is on screen
    const chatSels = [
        '//*[contains(@text,"Chat") or contains(@content-desc,"Chat")]',
        '//*[contains(@text,"Message") or contains(@content-desc,"Message")]',
        '//android.widget.TextView[contains(@text,"Chat")]',
    ];
    let chatFound = false;
    for (const s of chatSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 720, 2260);
            chatFound = true;
            console.log(`→ Chat button clicked via ${s}`);
            break;
        }
    }
    if (!chatFound) {
        console.log('→ Chat not found by selector — tapping coordinate (720, 2260)');
        await tap(driver, 720, 2260);
        await driver.pause(500);
        await tap(driver, 500, 1890); // fallback coords
    }
    await driver.pause(3000);
    await shot(driver, 'phase4_step2_after_chat_tap');
    await dumpPageSource(driver, 'phase4_step2_after_chat_tap');

    // AI Language modal
    if (await exists(driver, '//*[contains(@text,"Continue") or contains(@content-desc,"Continue")]')) {
        console.log('→ AI Language modal — clicking Continue');
        await clickSel(driver, '//*[contains(@text,"Continue") or contains(@content-desc,"Continue")]', 540, 2150);
        await driver.pause(2000);
        await shot(driver, 'phase4_step2_ai_lang_dismissed');
    }

    // -- Step 3: Type message and send --
    console.log('\n▶ Step 3: Type message → Send');
    await shot(driver, 'phase4_step3_chat_screen');
    await dumpPageSource(driver, 'phase4_step3_chat_screen');

    const chatMessage = 'Hello driver on the way';
    // Try to find EditText
    let chatInput: any = null;
    try {
        const el = await driver.$('//android.widget.EditText');
        if (await el.isDisplayed()) chatInput = el;
    } catch {}

    if (!chatInput) {
        // Tap near the bottom text input area
        await tap(driver, 450, 2260);
        await driver.pause(1500);
        await shot(driver, 'phase4_step3_after_input_tap');
        try {
            const el = await driver.$('//android.widget.EditText');
            if (await el.isDisplayed()) chatInput = el;
        } catch {}
    }

    if (chatInput) {
        try {
            await chatInput.clearValue();
            await chatInput.setValue(chatMessage);
            console.log(`→ Message set via setValue: "${chatMessage}"`);
        } catch {
            await chatInput.click();
            await driver.pause(300);
            adbText(chatMessage);
        }
    } else {
        console.log('→ No EditText found — using adb input text');
        adbText(chatMessage);
    }
    await driver.pause(2000);
    await shot(driver, 'phase4_step3_message_typed');
    await dumpPageSource(driver, 'phase4_step3_message_typed');

    // Click Send
    console.log('→ Clicking Send button');
    const sendSels = [
        '//*[@text="Send" or @content-desc="Send"]',
        '//*[contains(@text,"Send") or contains(@content-desc,"Send")]',
        '//android.widget.ImageButton[last()]',
        '//android.widget.ImageButton',
        '//android.widget.FloatingActionButton',
        '//android.widget.Button[contains(@content-desc,"Send")]',
    ];
    let sentMsg = false;
    for (const s of sendSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 1015, 1400);
            sentMsg = true;
            console.log(`→ Send button clicked via: ${s}`);
            break;
        }
    }
    if (!sentMsg) {
        console.log('→ Send button not found by selector — trying coordinate fallbacks');
        await tap(driver, 1015, 1400);
        await driver.pause(400);
        await tap(driver, 1015, 2260);
    }
    await driver.pause(2000);
    await shot(driver, 'phase4_step3_after_send');
    await dumpPageSource(driver, 'phase4_step3_after_send');

    // Dismiss keyboard
    try { await driver.hideKeyboard(); } catch {}
    await driver.pause(1000);

    // -- Step 4: Back from chat + collapse sheet --
    console.log('\n▶ Step 4: Back from chat → collapse sheet');
    // Flutter back arrow at (95, 165)
    await tap(driver, 95, 165);
    await driver.pause(3500);
    await shot(driver, 'phase4_step4_after_back');
    await dumpPageSource(driver, 'phase4_step4_after_back');

    // Recovery: if "Your trips" appeared
    if (await exists(driver, '//*[contains(@text,"Your trips") or contains(@text,"your trips")]')) {
        console.log('⚠️ Landed on "Your trips" — pressing Android BACK');
        try { execSync('adb shell input keyevent 4', { stdio: 'ignore' }); } catch {}
        await driver.pause(2500);
        await shot(driver, 'phase4_step4_recovered_from_trips');
    }

    // Collapse bottom sheet
    await swipe(driver, 540, 670, 540, 2100, 800);
    await driver.pause(3000);
    await shot(driver, 'phase4_step4_sheet_collapsed');
    await dumpPageSource(driver, 'phase4_step4_sheet_collapsed');

    // -- Step 5: Start ride --
    console.log('\n▶ Step 5: Swipe "Start ride"');
    await swipe(driver, 120, 1713, 980, 1713, 1000);
    await driver.pause(4000);
    await shot(driver, 'phase4_step5_start_ride_swipe');
    await dumpPageSource(driver, 'phase4_step5_start_ride_swipe');

    // OTP modal
    if (await exists(driver, '//*[contains(@text,"OTP") or contains(@text,"Verify") or contains(@text,"Ask")]')) {
        console.log('→ OTP modal detected');
        await shot(driver, 'phase4_step5_otp_modal');
        await tap(driver, 150, 1850);
        await driver.pause(300);
        adbText('1234');
        await driver.pause(1000);
        await clickSel(driver, '//*[contains(@text,"Verify") or contains(@content-desc,"Verify")]', 720, 1255);
        await driver.pause(4000);
        await shot(driver, 'phase4_step5_after_otp');
    }

    // -- Step 6: Complete ride --
    console.log('\n▶ Step 6: Swipe "Complete ride"');
    await swipe(driver, 120, 1713, 980, 1713, 1000);
    await driver.pause(4000);
    await shot(driver, 'phase4_step6_complete_ride');
    await dumpPageSource(driver, 'phase4_step6_complete_ride');

    // -- Step 7: Toll fee --
    console.log('\n▶ Step 7: Toll fee — enter $1');
    await waitFor(driver, [
        '//*[contains(@text,"Toll") or contains(@text,"toll") or contains(@text,"Charges")]',
        '//android.widget.EditText',
    ], 15000);
    await shot(driver, 'phase4_step7_toll_screen');
    await dumpPageSource(driver, 'phase4_step7_toll_screen');

    try {
        const tollInput = await driver.$('//android.widget.EditText');
        if (await tollInput.isDisplayed()) {
            await tollInput.click();
            await driver.pause(500);
            await tollInput.setValue('1');
        } else { await tap(driver, 500, 950); await driver.pause(300); adbText('1'); }
    } catch { await tap(driver, 500, 950); await driver.pause(300); adbText('1'); }

    try { await driver.hideKeyboard(); } catch {}
    await driver.pause(1000);
    await shot(driver, 'phase4_step7_toll_entered');

    // Done button
    await clickSel(driver, '//*[@text="Done" or @content-desc="Done"]', 540, 2110);
    await driver.pause(500);
    await tap(driver, 540, 2110);
    await driver.pause(3000);
    await shot(driver, 'phase4_step7_after_toll_done');
    await dumpPageSource(driver, 'phase4_step7_after_toll_done');

    // Next button
    if (await exists(driver, '//*[contains(@text,"Next") or contains(@content-desc,"Next")]')) {
        await clickSel(driver, '//*[contains(@text,"Next") or contains(@content-desc,"Next")]', 540, 2120);
        await driver.pause(4000);
        await shot(driver, 'phase4_step7_after_next');
    }

    // -- Step 8: Driver holds on Cash modal --
    console.log('\n▶ Step 8: Wait for Cash confirmation modal');
    const cashSels = [
        '//*[contains(@text,"collect") or contains(@text,"Cash")]',
        '//*[contains(@text,"Yes") or @content-desc="Yes"]',
    ];
    await waitFor(driver, cashSels, 20000);
    await shot(driver, 'phase4_step8_cash_modal');
    await dumpPageSource(driver, 'phase4_step8_cash_modal');
    await driver.pause(2000);

    // -- Step 9: Switch to Rider --
    console.log('\n▶ Step 9: Switch to Rider app');
    try { execSync('adb shell am start -n com.radicalstart.wooberly/.MainActivity', { stdio: 'ignore' }); } catch {}
    await driver.activateApp('com.radicalstart.wooberly');
    await driver.pause(4000);
    await shot(driver, 'phase4_step9_rider_app');
    await dumpPageSource(driver, 'phase4_step9_rider_app');

    // -- Step 10: Rider Confirm --
    console.log('\n▶ Step 10: Rider Confirm payment');
    const confirmSels = [
        '~Confirm', '//*[@text="Confirm" or @content-desc="Confirm"]',
        '//*[contains(@text,"Confirm") or contains(@content-desc,"Confirm")]',
    ];
    let riderConfirmed = false;
    for (let tries = 0; tries < 15; tries++) {
        for (const s of confirmSels) {
            if (await exists(driver, s)) {
                await clickSel(driver, s, 540, 2120);
                riderConfirmed = true;
                break;
            }
        }
        if (riderConfirmed) break;
        await driver.pause(1500);
    }
    if (!riderConfirmed) {
        console.log('→ Confirm button not found by selector — tapping coordinate');
        await tap(driver, 540, 2120);
    }
    await driver.pause(4000);
    await shot(driver, 'phase4_step10_after_confirm');
    await dumpPageSource(driver, 'phase4_step10_after_confirm');

    // -- Step 11: Rider Review --
    console.log('\n▶ Step 11: Rider star review → Done');
    await driver.pause(3000);
    await shot(driver, 'phase4_step11_rider_review');
    await dumpPageSource(driver, 'phase4_step11_rider_review');
    await tap(driver, 760, 1430);
    await driver.pause(1500);
    await clickSel(driver, '//*[@text="Done" or @content-desc="Done" or contains(@text,"Done")]', 540, 2120);
    await tap(driver, 540, 2120);
    await driver.pause(4000);
    await shot(driver, 'phase4_step11_after_rider_review');

    // -- Step 12: Driver Yes on cash --
    console.log('\n▶ Step 12: Switch to Driver → click Yes on cash modal');
    await driver.activateApp('com.radicalstart.wooberlydriver');
    await driver.pause(3000);
    await shot(driver, 'phase4_step12_driver_cash_modal');
    await dumpPageSource(driver, 'phase4_step12_driver_cash_modal');
    const yesSels = [
        '//*[@text="Yes" or @content-desc="Yes"]',
        '//android.widget.TextView[contains(@text,"Yes")]',
    ];
    for (const s of yesSels) {
        if (await exists(driver, s)) {
            await clickSel(driver, s, 730, 2140);
            break;
        }
    }
    await tap(driver, 730, 2140);
    await driver.pause(4000);
    await shot(driver, 'phase4_step12_after_yes');

    // -- Step 13: Driver Review --
    console.log('\n▶ Step 13: Driver star review → Done');
    await driver.pause(3000);
    await shot(driver, 'phase4_step13_driver_review');
    await dumpPageSource(driver, 'phase4_step13_driver_review');
    await tap(driver, 810, 855);
    await driver.pause(1500);
    await clickSel(driver, '//*[@text="Done" or @content-desc="Done" or contains(@text,"Done")]', 540, 2133);
    await tap(driver, 540, 2133);
    await driver.pause(2000);
    await shot(driver, 'phase4_step13_after_driver_review');

    console.log('\n✅ ✅ ✅ FULL E2E FLOW COMPLETED ✅ ✅ ✅');
}

// ── MAIN ──────────────────────────────────────────────────────────

async function main() {
    console.log('╔══════════════════════════════════════════════╗');
    console.log('║  WOOBERLY VISUAL DIAGNOSTIC DEBUG SCRIPT     ║');
    console.log(`║  Screenshots → ${SCREENSHOT_DIR}`);
    console.log('╚══════════════════════════════════════════════╝');

    await ensureAppium();

    const driver = await remote({
        hostname: '127.0.0.1',
        path: '/',
        port: 4723,
        capabilities: {
            platformName: 'Android',
            'appium:automationName': 'UiAutomator2',
            'appium:appPackage': 'com.radicalstart.wooberlydriver',
            'appium:appActivity': 'com.radicalstart.wooberlydriver.MainActivity',
            'appium:noReset': false,
            'appium:autoGrantPermissions': true,
            'appium:newCommandTimeout': 300,
        }
    });

    console.log('✅ Appium session created');

    try {
        await phase1_driverOnline(driver);
        await phase2_riderBooking(driver);
        await phase3_driverAccept(driver);
        await phase4_tripLifecycle(driver);
    } catch (err) {
        console.error('❌ Error during visual debug:', err);
        try { await shot(driver, 'ERROR_state'); } catch {}
        try {
            const src = await driver.getPageSource();
            fs.writeFileSync(path.join(SCREENSHOT_DIR, 'error_page_source.xml'), src);
        } catch {}
    } finally {
        console.log(`\n📁 All screenshots saved to: ${SCREENSHOT_DIR}`);
        await driver.deleteSession();
    }
}

main().catch(console.error);
