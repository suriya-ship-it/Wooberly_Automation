import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { DeviceManager } from '../../services/DeviceManager';
import { VideoRecorder } from '../../services/VideoRecorder';
import { PageTracker } from '../../services/PageTracker';
import { EmailService } from '../../services/EmailService';

const ROOT = path.resolve(__dirname, '../../');
const MAX_ATTEMPTS = parseInt(process.env.AUTO_RETRY_ATTEMPTS || '3', 10);

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
    console.log('#   WOOBERLY STEP #2 END-TO-END ORCHESTRATION (SELF-HEALING SUITE)     #');
    console.log('#   Stage #1: Dynamic Play Store App Provisioning (Rider + Driver)     #');
    console.log('#   Stage #2: Step #1 Flow (Driver Online -> Rider Booking -> Trip)    #');
    console.log(`#   Max Auto-Reinitiate Attempts: ${MAX_ATTEMPTS}                                        #`);
    console.log('########################################################################\n');

    let succeeded = false;
    let lastError: any = null;

    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
        console.log('\n========================================================================');
        console.log(`🚀 [Self-Healing Engine] Starting Workflow Attempt ${attempt} of ${MAX_ATTEMPTS}`);
        console.log('========================================================================\n');

        // 1. Clean slate reset before starting attempt
        await DeviceManager.cleanSlateReset();
        PageTracker.resetCounter();

        // 2. Start video recording for this attempt
        await VideoRecorder.startRecording({
            testName: attempt === 1 ? 'wooberly_step2_full_workflow' : `wooberly_step2_attempt_${attempt}`,
            outputDir: path.join(ROOT, 'Test reference'),
        });

        try {
            PageTracker.recordPage('INITIAL_DEVICE_STATE', 'LOADED', `Attempt #${attempt} initialized`);

            // -------------------------------------------------------------------------
            // STAGE #1: Play Store Dynamic App Installation
            // -------------------------------------------------------------------------
            runCommand('Stage #1: Play Store Dynamic App Installation', 'npm run test:store-install');
            PageTracker.recordPage('STAGE1_STORE_INSTALL_COMPLETED', 'ACTION_TAKEN', 'Rider & Driver verified installed');

            const DELAY_SEC = 2;
            console.log(`Play Store installation succeeded. Waiting ${DELAY_SEC}s before starting Step #1 Flow...\n`);
            await new Promise((resolve) => setTimeout(resolve, DELAY_SEC * 1000));

            // -------------------------------------------------------------------------
            // STAGE #2: Step #1 Orchestration Flow (Driver Online + Rider Booking + Trip)
            // -------------------------------------------------------------------------
            runCommand('Stage #2: Step #1 Complete Booking & Trip Lifecycle Flow', 'npm run "test:step #1"');
            PageTracker.recordPage('STAGE2_TRIP_LIFECYCLE_COMPLETED', 'LOADED', 'Booking and full trip lifecycle completed');

            const totalSeconds = Math.round((Date.now() - workflowStartTime) / 1000);
            console.log('\n########################################################################');
            console.log(`#   🎉 STEP #2 COMPLETED: PLAY STORE PROVISIONING & FULL E2E SUCCESS!  #`);
            console.log(`#   Attempt #${attempt} succeeded! Total Duration: ${totalSeconds}s                              #`);
            console.log('########################################################################\n');

            succeeded = true;

            // Finalize video recording before dispatching email
            await VideoRecorder.stopRecording();

            // Dispatch automated email report with video attachment
            try {
                await EmailService.sendTestPassedReport();
            } catch (emailErr) {
                console.warn('[EmailService] Non-blocking email dispatch warning:', emailErr);
            }

            break; // Exit loop on success
        } catch (err: any) {
            lastError = err;
            console.error(`\n❌ [Self-Healing Engine] Attempt #${attempt} stopped due to unhandled error:`, err?.message ?? err);
            PageTracker.recordPage(`ATTEMPT_${attempt}_ERROR_STATE`, 'ERROR', err?.message ?? String(err));

            await VideoRecorder.stopRecording();

            if (attempt < MAX_ATTEMPTS) {
                console.log(`\n🔄 [Self-Healing Engine] Re-initiating the 'START' process (Attempt ${attempt + 1} of ${MAX_ATTEMPTS})...\n`);
                await new Promise((resolve) => setTimeout(resolve, 3000));
            }
        }
    }

    if (!succeeded) {
        console.error(`\n❌ All ${MAX_ATTEMPTS} attempts failed to complete. Last error:`, lastError?.message ?? lastError);
        process.exit(1);
    }
}

if (require.main === module) {
    main().catch((err) => {
        console.error('\n❌ Step #2 Orchestration failed fatal:', err?.message ?? err);
        process.exit(1);
    });
}
