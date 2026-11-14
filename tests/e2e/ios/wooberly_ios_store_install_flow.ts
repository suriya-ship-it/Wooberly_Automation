import * as fs from 'fs';
import * as path from 'path';
import { iOSDeviceManager } from '../../../services/iOSDeviceManager';
import { iOSVisualAnalyzer } from '../../../services/iOSVisualAnalyzer';

function loadEnv() {
  const envPath = path.resolve(__dirname, '../../../.env');
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

const RIDER_STORE_URL = process.env.APPSTORE_RIDER_URL || 'https://apps.apple.com/us/app/wooberly/id1493271610';
const DRIVER_STORE_URL = process.env.APPSTORE_DRIVER_URL || 'https://apps.apple.com/us/app/wooberly-driver/id1487295710';
const RIDER_BUNDLE = process.env.IOS_RIDER_BUNDLE_ID || 'com.radicalstart.wooberly';
const DRIVER_BUNDLE = process.env.IOS_DRIVER_BUNDLE_ID || 'com.radicalstart.wooberlydriver';
const TIMEOUT_SEC = parseInt(process.env.STORE_INSTALL_TIMEOUT_SEC || '180', 10);

function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

async function verifyOrInstallApp(appName: string, bundleId: string, storeUrl: string, prefix: string): Promise<boolean> {
  console.log(`\n--------------------------------------------------------------`);
  console.log(`[iOS Store Flow] Verifying ${appName} (${bundleId})...`);
  console.log(`--------------------------------------------------------------`);

  // First dismiss any stray permission or notification alert
  iOSVisualAnalyzer.autoHandlePermissions(`${prefix}_precheck`);

  const alreadyInstalled = iOSDeviceManager.isAppInstalled(bundleId);
  if (alreadyInstalled) {
    console.log(`✅ ${appName} is already installed on the iPhone! Skipping download.`);
    iOSVisualAnalyzer.captureScreen(`${prefix}_already_installed`);
    return true;
  }

  console.log(`[iOS Store Flow] ${appName} is NOT installed. Navigating App Store to: ${storeUrl}`);
  iOSDeviceManager.openAppStorePage(storeUrl);
  await sleep(4000);

  // Capture & analyze the App Store page screenshot
  const pageAnalysis = iOSVisualAnalyzer.analyzeCurrentScreen(`${prefix}_store_page`);
  console.log(`[iOS Store Flow] Page analysis for ${appName}:`, pageAnalysis.detectedFeatures);

  // Attempt to tap "Get", "Redownload", "Download", or "Install" if present on screen
  const downloadButton = pageAnalysis.elements.find((e) => {
    const c = e.caption.toLowerCase();
    return (
      c.includes('get') ||
      c.includes('redownload') ||
      c.includes('download') ||
      c.includes('install') ||
      c.includes('cloud')
    );
  });

  if (downloadButton) {
    console.log(`[iOS Store Flow] Detected download option ("${downloadButton.caption}") on App Store page.`);
    iOSVisualAnalyzer.tapElement('get|redownload|re-download|download|install|cloud');
    await sleep(2000);
    // Handle any permission or confirmation alert
    iOSVisualAnalyzer.autoHandlePermissions(`${prefix}_install_prompt`);
  }

  console.log(`\n👉 NOTE: If a download confirmation or cloud download icon appears on your iPhone, please confirm it on your screen.`);
  console.log(`[iOS Store Flow] Waiting for ${appName} download & installation (timeout: ${TIMEOUT_SEC}s)...`);
  const startTime = Date.now();

  while ((Date.now() - startTime) / 1000 < TIMEOUT_SEC) {
    await sleep(4000);
    // Periodically check and auto-handle any permission prompt
    iOSVisualAnalyzer.autoHandlePermissions(`${prefix}_waiting`);

    const installed = iOSDeviceManager.isAppInstalled(bundleId);
    if (installed) {
      console.log(`\n✅ ${appName} successfully installed on iPhone!`);
      iOSVisualAnalyzer.captureScreen(`${prefix}_installed_successfully`);
      return true;
    }
    const elapsed = Math.round((Date.now() - startTime) / 1000);
    process.stdout.write(`\r⏳ Waiting for install... (${elapsed}s elapsed)`);
  }

  console.warn(`\n⚠️ Timeout waiting for ${appName} installation.`);
  iOSVisualAnalyzer.captureScreen(`${prefix}_install_timeout`);
  return false;
}

export async function runIOSStoreInstallFlow(): Promise<boolean> {
  console.log('========================================================================');
  console.log('🍎  iOS APP STORE VERIFICATION & INSTALLATION FLOW (iPhone 15)');
  console.log('========================================================================');

  if (!iOSDeviceManager.isDeviceConnected()) {
    throw new Error('iPhone 15 is not detected over USB. Make sure device is connected and trusted.');
  }

  await iOSDeviceManager.waitForUnlock(30);

  // Pre-flight visual capture
  iOSVisualAnalyzer.captureScreen('ios_store_00_initial_state');
  iOSVisualAnalyzer.autoHandlePermissions('store_start');

  const riderOk = await verifyOrInstallApp('Wooberly Rider', RIDER_BUNDLE, RIDER_STORE_URL, 'ios_rider');
  await sleep(2000);
  const driverOk = await verifyOrInstallApp('Wooberly Driver', DRIVER_BUNDLE, DRIVER_STORE_URL, 'ios_driver');

  console.log('\n========================================================================');
  if (riderOk && driverOk) {
    console.log('✅  iOS STORE INSTALLATION FLOW: ALL APPS READY');
  } else {
    console.log('⚠️  iOS STORE INSTALLATION FLOW: SOME APPS PENDING');
  }
  console.log('========================================================================\n');

  return riderOk && driverOk;
}

// Allow direct CLI execution: tsx wooberly_ios_store_install_flow.ts
if (require.main === module) {
  runIOSStoreInstallFlow()
    .then((ok) => process.exit(ok ? 0 : 1))
    .catch((err) => {
      console.error('Fatal error in iOS Store Flow:', err);
      process.exit(1);
    });
}
