import { remote } from 'webdriverio';
import * as fs from 'fs';
import * as path from 'path';
import { DeviceManager } from '../../services/DeviceManager';
import { PlayStorePage } from '../../pages/PlayStorePage';
import { VideoRecorder } from '../../services/VideoRecorder';

const ROOT = path.resolve(__dirname, '../../');
const ARTIFACT_DIR = process.env.ARTIFACT_DIR || '/Users/radicalstart/.gemini/antigravity/brain/126f99c7-a5bf-4b42-8f1c-38b58afc2632';
const DEBUG_DIR = path.join(ROOT, 'debug_screenshots');

async function captureScreen(driver: any, name: string): Promise<string> {
    const filename = `${name}.png`;
    const fullPath = path.join(ARTIFACT_DIR, filename);
    const debugPath = path.join(DEBUG_DIR, filename);
    try {
        if (!fs.existsSync(DEBUG_DIR)) fs.mkdirSync(DEBUG_DIR, { recursive: true });
        if (!fs.existsSync(ARTIFACT_DIR)) fs.mkdirSync(ARTIFACT_DIR, { recursive: true });
    } catch {}

    try {
        if (driver) {
            await driver.saveScreenshot(debugPath);
            try { fs.copyFileSync(debugPath, fullPath); } catch {}
            console.log(`[Screenshot Captured] ${filename} -> ${debugPath}`);
            return debugPath;
        }
    } catch {}

    try {
        DeviceManager.runAdb(`exec-out screencap -p > "${debugPath}"`);
        try { fs.copyFileSync(debugPath, fullPath); } catch {}
        console.log(`[Screenshot via ADB] ${filename} -> ${debugPath}`);
    } catch {}
    return debugPath;
}

// Parse .env file manually so it works reliably across all runners
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

const RIDER_STORE_URL = process.env.PLAYSTORE_RIDER_URL || 'https://play.google.com/store/apps/details?id=com.radicalstart.wooberly';
const DRIVER_STORE_URL = process.env.PLAYSTORE_DRIVER_URL || 'https://play.google.com/store/apps/details?id=com.radicalstart.wooberlydriver';
const CLEAN_INSTALL = process.env.STORE_CLEAN_INSTALL === 'true';
const TIMEOUT_SEC = parseInt(process.env.STORE_INSTALL_TIMEOUT_SEC || '180', 10);

function extractPackageName(storeUrl: string): string {
    try {
        const url = new URL(storeUrl);
        const pkg = url.searchParams.get('id');
        if (pkg) return pkg;
    } catch {}
    const match = storeUrl.match(/id=([a-zA-Z0-9._]+)/);
    return match ? match[1] : '';
}

async function sleep(ms: number): Promise<void> {
    return new Promise(res => setTimeout(res, ms));
}

async function runStoreInstallFlow() {
    const totalStartTime = Date.now();
    console.log('########################################################################');
    console.log('#   WOOBERLY HIGH-SPEED PLAY STORE APP INSTALLATION FLOW               #');
    console.log('########################################################################');
    console.log(`Rider Store URL:   ${RIDER_STORE_URL}`);
    console.log(`Driver Store URL:  ${DRIVER_STORE_URL}`);
    console.log(`Clean Install:     ${CLEAN_INSTALL}`);
    console.log(`Timeout:           ${TIMEOUT_SEC}s\n`);

    const riderPackage = extractPackageName(RIDER_STORE_URL) || 'com.radicalstart.wooberly';
    const driverPackage = extractPackageName(DRIVER_STORE_URL) || 'com.radicalstart.wooberlydriver';

    console.log(`Target Rider Package:  ${riderPackage}`);
    console.log(`Target Driver Package: ${driverPackage}\n`);

    // Step 1: Compound wake and unlock (Single-batch execution)
    DeviceManager.ensureDeviceReady();
    await VideoRecorder.startRecording({
        testName: 'wooberly_store_install_flow',
        outputDir: path.join(ROOT, 'Test reference'),
    });

    // Optional Clean Install mode
    if (CLEAN_INSTALL) {
        console.log('\n[Clean Install Mode] Removing existing packages prior to Play Store test...');
        DeviceManager.uninstallPackage(riderPackage);
        DeviceManager.uninstallPackage(driverPackage);
    }

    // Step 2: Initialize Appium connection targeting Google Play Store
    console.log('\nConnecting Appium session to Google Play Store (com.android.vending)...');
    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:appPackage': 'com.android.vending',
        'appium:appActivity': 'com.google.android.finsky.activities.MainActivity',
        'appium:noReset': true,
        'appium:dontStopAppOnReset': true,
        'appium:autoGrantPermissions': true,
    };

    let driver;
    try {
        driver = await remote({
            path: '/',
            port: 4723,
            capabilities,
        });

        // Speed Optimization: Zero implicit wait & disable animation idling
        await driver.setTimeout({ implicit: 0 });
        await driver.updateSettings({
            waitForIdleTimeout: 0,
            waitForSelectorTimeout: 150,
            ignoreUnimportantViews: true,
        });
        console.log('⚡ High-speed Appium UiAutomator2 profile applied.');
    } catch (err: any) {
        console.error('❌ Failed to establish Appium session. Please verify Appium server is running at port 4723.');
        throw err;
    }

    const playStorePage = new PlayStorePage(driver);

    try {
        // ======================================================================
        // STAGE 1: RIDER APP PLAY STORE INSTALLATION
        // ======================================================================
        console.log('\n========================================================================');
        console.log('▶ STAGE 1: NAVIGATING TO PLAY STORE FOR RIDER APPLICATION');
        console.log('========================================================================');
        const riderStageStart = Date.now();
        DeviceManager.openPlayStoreUrl(RIDER_STORE_URL);
        await sleep(1000);
        await captureScreen(driver, 'store_01_rider_page');

        console.log('⚡ Eagerly detecting Rider store page action buttons...');
        const riderInstallStatus = await playStorePage.initiateInstallation(riderPackage);
        await captureScreen(driver, 'store_02_rider_action');

        if (riderInstallStatus === 'INSTALLING' || !DeviceManager.isPackageInstalled(riderPackage)) {
            await playStorePage.waitForInstallationCompletion(TIMEOUT_SEC, riderPackage);
        }

        // Quick verification via OS PackageManager
        const isRiderInstalled = DeviceManager.isPackageInstalled(riderPackage);
        const riderDuration = Math.round((Date.now() - riderStageStart) / 1000);
        console.log(`Verification: ${riderPackage} installed? -> ${isRiderInstalled ? '✅ YES' : '❌ NO'} (${riderDuration}s total)`);
        await captureScreen(driver, 'store_03_rider_verified');

        // ======================================================================
        // STAGE 2: DRIVER APP PLAY STORE INSTALLATION (DIRECT INTENT SWITCH)
        // ======================================================================
        console.log('\n========================================================================');
        console.log('▶ STAGE 2: DIRECT INTENT SWITCH TO DRIVER APPLICATION');
        console.log('========================================================================');
        const driverStageStart = Date.now();
        // Zero delay: Directly launch Driver intent into active Play Store stack
        DeviceManager.openPlayStoreUrl(DRIVER_STORE_URL);
        await sleep(1000);
        await captureScreen(driver, 'store_04_driver_page');

        console.log('⚡ Eagerly detecting Driver store page action buttons...');
        const driverInstallStatus = await playStorePage.initiateInstallation(driverPackage);
        await captureScreen(driver, 'store_05_driver_action');

        if (driverInstallStatus === 'INSTALLING' || !DeviceManager.isPackageInstalled(driverPackage)) {
            await playStorePage.waitForInstallationCompletion(TIMEOUT_SEC, driverPackage);
        }

        // Quick verification via OS PackageManager
        const isDriverInstalled = DeviceManager.isPackageInstalled(driverPackage);
        const driverDuration = Math.round((Date.now() - driverStageStart) / 1000);
        console.log(`Verification: ${driverPackage} installed? -> ${isDriverInstalled ? '✅ YES' : '❌ NO'} (${driverDuration}s total)`);
        await captureScreen(driver, 'store_06_driver_verified');

        // Navigate back to Home screen at the completion of both installations
        console.log('\nAll installations finished. Navigating to Android home screen...');
        DeviceManager.pressHome();
        await sleep(1000);
        await captureScreen(driver, 'store_07_home_screen');

        // ======================================================================
        // FINAL SUMMARY REPORT
        // ======================================================================
        const totalDuration = Math.round((Date.now() - totalStartTime) / 1000);
        console.log('\n========================================================================');
        console.log('               PLAY STORE INSTALLATION SUMMARY REPORT                   ');
        console.log('========================================================================');
        console.log(`1. Rider App  (${riderPackage}):  ${DeviceManager.isPackageInstalled(riderPackage) ? '✅ INSTALLED' : '❌ NOT FOUND'}`);
        console.log(`2. Driver App (${driverPackage}): ${DeviceManager.isPackageInstalled(driverPackage) ? '✅ INSTALLED' : '❌ NOT FOUND'}`);
        console.log(`Total Execution Time: ${totalDuration}s`);
        console.log('========================================================================\n');

        const riderReady = DeviceManager.isPackageInstalled(riderPackage);
        const driverReady = DeviceManager.isPackageInstalled(driverPackage);

        if (riderReady && driverReady) {
            console.log('🎉 SUCCESS: Both applications verified and ready on the device!');
            // Pre-grant essential runtime permissions to ensure smooth automation
            try {
                console.log('Granting runtime location, background location & overlay permissions via ADB...');
                DeviceManager.runAdb(`shell pm grant ${riderPackage} android.permission.ACCESS_FINE_LOCATION`);
                DeviceManager.runAdb(`shell pm grant ${riderPackage} android.permission.ACCESS_COARSE_LOCATION`);
                DeviceManager.runAdb(`shell pm grant ${riderPackage} android.permission.POST_NOTIFICATIONS`);
                DeviceManager.runAdb(`shell pm grant ${driverPackage} android.permission.ACCESS_FINE_LOCATION`);
                DeviceManager.runAdb(`shell pm grant ${driverPackage} android.permission.ACCESS_COARSE_LOCATION`);
                DeviceManager.runAdb(`shell pm grant ${driverPackage} android.permission.ACCESS_BACKGROUND_LOCATION`);
                DeviceManager.runAdb(`shell pm grant ${driverPackage} android.permission.POST_NOTIFICATIONS`);
                DeviceManager.runAdb(`shell appops set ${driverPackage} SYSTEM_ALERT_WINDOW allow`);
            } catch {}
        } else {
            const missing = [];
            if (!riderReady) missing.push(`Rider (${riderPackage})`);
            if (!driverReady) missing.push(`Driver (${driverPackage})`);
            throw new Error(`Required applications are not installed on device after Play Store flow: ${missing.join(', ')}`);
        }

    } finally {
        await VideoRecorder.stopRecording();
        console.log('Closing Appium Play Store session...');
        try {
            await driver.deleteSession();
        } catch {}
    }
}

if (require.main === module) {
    runStoreInstallFlow().catch((err) => {
        console.error('\n❌ Play Store installation flow encountered an error:', err?.message ?? err);
        process.exit(1);
    });
}
