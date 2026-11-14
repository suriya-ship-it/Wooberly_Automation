import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { DeviceManager } from '../../services/DeviceManager';
import { VideoRecorder } from '../../services/VideoRecorder';

const ROOT = path.resolve(__dirname, '../../');
const ARTIFACT_DIR = process.env.ARTIFACT_DIR || '/Users/radicalstart/.gemini/antigravity/brain/126f99c7-a5bf-4b42-8f1c-38b58afc2632';
const DEBUG_DIR = path.join(ROOT, 'debug_screenshots');

function captureScreen(name: string): string {
    const filename = `${name}.png`;
    const fullPath = path.join(ARTIFACT_DIR, filename);
    const debugPath = path.join(DEBUG_DIR, filename);
    try {
        if (!fs.existsSync(DEBUG_DIR)) fs.mkdirSync(DEBUG_DIR, { recursive: true });
        if (!fs.existsSync(ARTIFACT_DIR)) fs.mkdirSync(ARTIFACT_DIR, { recursive: true });
    } catch {}

    try {
        DeviceManager.runAdb(`exec-out screencap -p > "${debugPath}"`);
        try { fs.copyFileSync(debugPath, fullPath); } catch {}
        console.log(`[Screenshot Captured] ${filename} -> ${debugPath}`);
    } catch (err) {
        console.warn(`Could not capture screenshot for ${name}:`, err);
    }
    return debugPath;
}

function runCommand(label: string, cmd: string): void {
    console.log('\n');
    console.log('========================================================================');
    console.log(`▶  ${label}`);
    console.log('========================================================================');
    console.log(`Executing: ${cmd}\n`);

    execSync(cmd, {
        cwd: ROOT,
        stdio: 'inherit',
        env: process.env,
    });

    console.log('\n');
    console.log('========================================================================');
    console.log(`✅  ${label}  →  COMPLETED SUCCESSFULLY`);
    console.log('========================================================================\n');
}

async function main() {
    const workflowStartTime = Date.now();
    console.log('########################################################################');
    console.log('#   WOOBERLY STEP #2 END-TO-END ORCHESTRATION WORKFLOW                 #');
    console.log('#   Stage #1: Dynamic Play Store App Provisioning (Rider + Driver)     #');
    console.log('#   Stage #2: Step #1 Flow (Driver Online -> Rider Booking -> Trip)    #');
    console.log('########################################################################\n');

    // 1. Wake and unlock device
    DeviceManager.ensureDeviceReady();

    // 2. Start video recording immediately after phone wakeup
    await VideoRecorder.startRecording({
        testName: 'wooberly_step2_full_workflow',
        outputDir: path.join(ROOT, 'Test reference'),
    });

    try {
        // Capture initial device state screenshot
        captureScreen('step2_00_initial_device_state');

        // -------------------------------------------------------------------------
        // STAGE #1: Play Store Dynamic App Installation
        // -------------------------------------------------------------------------
        runCommand('Stage #1: Play Store Dynamic App Installation', 'npm run test:store-install');
        captureScreen('step2_01_store_install_completed');

        // Brief settling pause (2s) between store installation and driver startup
        const DELAY_SEC = 2;
        console.log(`Play Store installation succeeded. Waiting ${DELAY_SEC}s before starting Step #1 Flow...\n`);
        await new Promise((resolve) => setTimeout(resolve, DELAY_SEC * 1000));

        // -------------------------------------------------------------------------
        // STAGE #2: Step #1 Orchestration Flow (Driver Online + Rider Booking + Trip)
        // -------------------------------------------------------------------------
        runCommand('Stage #2: Step #1 Complete Booking & Trip Lifecycle Flow', 'npm run "test:step #1"');
        captureScreen('step2_02_trip_lifecycle_completed');

        const totalSeconds = Math.round((Date.now() - workflowStartTime) / 1000);
        console.log('\n########################################################################');
        console.log(`#   🎉 STEP #2 COMPLETED: PLAY STORE PROVISIONING & FULL E2E SUCCESS!  #`);
        console.log(`#   Total Duration: ${totalSeconds}s                                                #`);
        console.log('########################################################################\n');
    } finally {
        // Stop video recording and save final video reference into 'Test reference'
        await VideoRecorder.stopRecording();
    }
}

if (require.main === module) {
    main().catch((err) => {
        console.error('\n❌ Step #2 Orchestration failed:', err?.message ?? err);
        captureScreen('step2_error_state');
        process.exit(1);
    });
}
