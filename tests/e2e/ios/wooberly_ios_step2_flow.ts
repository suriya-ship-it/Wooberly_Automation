import * as path from 'path';
import * as fs from 'fs';
import { iOSDeviceManager } from '../../../services/iOSDeviceManager';
import { iOSVisualAnalyzer } from '../../../services/iOSVisualAnalyzer';
import { runIOSStoreInstallFlow } from './wooberly_ios_store_install_flow';

const ROOT = path.resolve(__dirname, '../../../');
const RIDER_BUNDLE = process.env.IOS_RIDER_BUNDLE_ID || 'com.radicalstart.wooberly';
const DRIVER_BUNDLE = process.env.IOS_DRIVER_BUNDLE_ID || 'com.radicalstart.wooberlydriver';

async function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

async function handleAppScreenLifecycle(appName: string, bundleId: string, prefix: string): Promise<boolean> {
  console.log(`\n========================================================================`);
  console.log(`📱 [iOS Lifecycle] Launching & Analyzing ${appName} (${bundleId})`);
  console.log(`========================================================================`);

  const launched = iOSDeviceManager.launchApp(bundleId, undefined, true);
  console.log(`[iOS Lifecycle] Launch invocation status: ${launched ? 'SUCCESS' : 'FAILED'}`);
  await sleep(4000);

  // 1. Analyze initial app launch screenshot
  const initialAnalysis = iOSVisualAnalyzer.analyzeCurrentScreen(`${prefix}_01_launched`);

  // 2. Self-healing check: Grant any system permission alerts (Location, Notifications, etc.)
  let handledPermission = iOSVisualAnalyzer.autoHandlePermissions(`${prefix}_launch`);
  if (handledPermission) {
    await sleep(2000);
    iOSVisualAnalyzer.analyzeCurrentScreen(`${prefix}_02_post_permission`);
  } else if (initialAnalysis.screenType === 'SYSTEM_PERMISSION') {
    console.log(`\n👉 [iOS Permission] System permission dialog detected on iPhone.`);
    console.log(`   Please tap "Allow" or "Allow While Using App" on your device screen if prompted.\n`);
    for (let i = 0; i < 5; i++) {
      await sleep(2000);
      const recheck = iOSVisualAnalyzer.analyzeCurrentScreen(`${prefix}_02_perm_check_${i + 1}`);
      if (recheck.screenType !== 'SYSTEM_PERMISSION') {
        console.log(`✅ Permission dismissed! Continuing flow.`);
        break;
      }
    }
  }

  // 3. Check for Onboarding / "Get started" screen
  const elements = iOSVisualAnalyzer.getVisibleElements();
  const hasGetStarted = elements.some((e) => {
    const c = e.caption.toLowerCase();
    return c.includes('get started') || c === 'continue' || c === 'welcome';
  });

  if (hasGetStarted) {
    console.log(`[iOS Lifecycle] Detected "Get started" onboarding screen on ${appName}. Proceeding...`);
    iOSVisualAnalyzer.tapElement('get started|continue');
    await sleep(3000);

    // Analyze post-get-started screen & dismiss any new location prompts
    iOSVisualAnalyzer.autoHandlePermissions(`${prefix}_post_get_started`);
    iOSVisualAnalyzer.analyzeCurrentScreen(`${prefix}_03_after_get_started`);
  }

  // 4. Final verification screenshot for this app
  const finalAnalysis = iOSVisualAnalyzer.analyzeCurrentScreen(`${prefix}_04_ready`);
  console.log(`✅ [iOS Lifecycle] ${appName} lifecycle processed: ${finalAnalysis.screenType}`);
  return true;
}

async function main() {
  const startTime = Date.now();
  console.log('\n========================================================================');
  console.log('🚀  STARTING MASTER iOS AUTOMATION WORKFLOW (STEP #2 - iPhone 15)');
  console.log('    Visual Screenshot Analysis & Self-Healing Permission Flow');
  console.log('========================================================================\n');

  iOSVisualAnalyzer.startKeepAwake(1800);

  try {
    // Stage 1: Device Connectivity Check & Unlock State
    console.log('📱 Stage 1: Verifying physical iPhone 15 connection & unlock state...');
    if (!iOSDeviceManager.isDeviceConnected()) {
      throw new Error('iPhone 15 is not connected over USB or trusted by this Mac.');
    }

    const unlocked = await iOSDeviceManager.waitForUnlock(30);
    if (!unlocked) {
      throw new Error('iPhone 15 remained locked. Please unlock the iPhone screen with your passcode and set Auto-Lock to Never in Settings.');
    }

    // Capture and analyze initial device baseline
    iOSVisualAnalyzer.analyzeCurrentScreen('step2_ios_00_initial_device_state');
    iOSVisualAnalyzer.autoHandlePermissions('initial');

    // Stage 2: Store Verification & Installation
    console.log('\n📦 Stage 2: Verifying Rider and Driver apps on iPhone 15...');
    const storeOk = await runIOSStoreInstallFlow();
    if (!storeOk) {
      console.warn('⚠️ One or more apps are still pending installation on the device.');
    }

    // Stage 3: Launching Driver Application & Handling Permissions / Onboarding
    if (iOSDeviceManager.isAppInstalled(DRIVER_BUNDLE)) {
      await handleAppScreenLifecycle('Wooberly Driver', DRIVER_BUNDLE, 'step2_ios_driver');
    } else {
      console.log('ℹ️ Driver app not yet installed on iPhone; skipping in-app lifecycle.');
    }
    await sleep(3000);

    // Stage 4: Launching Rider Application & Handling Permissions / Onboarding
    if (iOSDeviceManager.isAppInstalled(RIDER_BUNDLE)) {
      await handleAppScreenLifecycle('Wooberly Rider', RIDER_BUNDLE, 'step2_ios_rider');
    } else {
      console.log('ℹ️ Rider app not yet installed on iPhone; skipping in-app lifecycle.');
    }
    await sleep(2000);

    // Stage 5: Master Flow Completed Screenshot
    iOSVisualAnalyzer.analyzeCurrentScreen('step2_ios_99_flow_completed');

    const totalSec = Math.round((Date.now() - startTime) / 1000);
    console.log('\n========================================================================');
    console.log(`🎉  iOS AUTOMATION STEP #2 FLOW COMPLETED SUCCESSFULLY (${totalSec}s)!`);
    console.log('========================================================================\n');
  } finally {
    iOSVisualAnalyzer.stopKeepAwake();
  }
}

main().catch((err) => {
  console.error('\n❌ Fatal error in iOS Step #2 flow:', err);
  process.exit(1);
});
