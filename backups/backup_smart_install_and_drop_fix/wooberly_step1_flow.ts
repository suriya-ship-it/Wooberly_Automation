import { execSync } from 'child_process';
import * as path from 'path';
import { DeviceManager } from '../../services/DeviceManager';
import { VideoRecorder } from '../../services/VideoRecorder';

const ROOT = path.resolve(__dirname, '../../');

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
    console.log('########################################################################');
    console.log('#   WOOBERLY STEP #1 ORCHESTRATION FLOW                                #');
    console.log('#   Stage 1: Bring Driver Online (npm run test:driver-online)          #');
    console.log('#   Stage 2: Run Rider Login & Booking (npm run test:login)            #');
    console.log('########################################################################\n');

    // Clean slate reset and wake device
    await DeviceManager.cleanSlateReset();

    // Start video recording immediately after phone wakeup
    await VideoRecorder.startRecording({
        testName: 'wooberly_step1_orchestration_workflow',
        outputDir: path.join(ROOT, 'Test reference'),
    });

    try {
        // Ensure Driver app is opened in foreground at start
        console.log('Explicitly launching Wooberly Driver application into foreground before Stage 1...');
        try {
            execSync('adb shell monkey -p com.radicalstart.wooberlydriver -c android.intent.category.LAUNCHER 1', { stdio: 'ignore' });
            execSync('adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity', { stdio: 'ignore' });
        } catch {}

        // 1. Run Driver Online flow
        runCommand('Stage 1: Bring Driver Online', 'npm run test:driver-online');

        // Small delay (2 seconds) between driver online and rider login
        const DELAY_SEC = 2;
        console.log(`Driver online succeeded. Waiting ${DELAY_SEC} seconds before launching Rider login flow...\n`);
        await new Promise((resolve) => setTimeout(resolve, DELAY_SEC * 1000));

        // 2. Run Rider Login flow
        runCommand('Stage 2: Rider Login & Booking Flow', 'npm run test:login');

        // Task #1: Immediately launch Driver application into foreground without delay
        console.log('Task #1: Immediately launching Wooberly Driver application into foreground state...');
        try {
            execSync('adb shell am start -n com.radicalstart.wooberlydriver/com.radicalstart.wooberlydriver.MainActivity', { stdio: 'ignore' });
        } catch {}

        // 3. Task #2: Detect ride request, accept, and run 13-step lifecycle
        runCommand('Stage 3: Driver Ride Acceptance & 13-Step Trip Lifecycle Flow', 'npm run test:trip');

        console.log('\n########################################################################');
        console.log('#   ALL STAGES (DRIVER ONLINE, RIDER BOOKING & TRIP LIFECYCLE) DONE!   #');
        console.log('########################################################################\n');
    } finally {
        await VideoRecorder.stopRecording();
    }
}

if (require.main === module) {
    main().catch((err) => {
        console.error('\n❌ Step #1 Orchestration failed:', err?.message ?? err);
        process.exit(1);
    });
}
