import { execSync } from 'child_process';
import * as path from 'path';

/**
 * Wooberly Full End-to-End Orchestrator
 * ─────────────────────────────────────────────────────────────────────────
 * Step #1  →  npm run test:driver-online
 *             Launches the Driver application, handles login/OTP if needed,
 *             handles all location permission dialogs, and brings the Driver
 *             to "online" status so the backend can dispatch ride requests.
 *
 * Step #2  →  npm run test:during-booking
 *             Opens a fresh Appium session starting on the Driver app,
 *             runs the full 4-stage booking + trip-lifecycle flow:
 *               Stage 1 – Bring Driver Online (sanity / already-online check)
 *               Stage 2 – Switch to Rider App & complete ride booking
 *               Stage 3 – Switch to Driver App & Accept incoming trip request
 *               Stage 4 – 13-step trip lifecycle:
 *                   1.  Swipe "Location reached" slider
 *                   2.  Expand bottom sheet → click Chat icon
 *                   3.  Type message → close keyboard → click Send
 *                   4.  Back from chat → collapse bottom sheet
 *                   5.  Swipe "Start ride" + OTP verification
 *                   6.  Swipe "Complete ride"
 *                   7.  Enter $1 toll fee → Done
 *                   8.  Driver holds on Cash confirmation modal
 *                   9.  Switch to Rider app
 *                   10. Click Confirm on Rider trip details
 *                   11. Submit Rider 5-star review → Done
 *                   12. Switch to Driver app → click Yes on cash modal
 *                   13. Submit Driver 5-star review → Done
 * ─────────────────────────────────────────────────────────────────────────
 */

const ROOT = path.resolve(__dirname, '../../');

function run(label: string, command: string): void {
    console.log('\n');
    console.log('████████████████████████████████████████████████████████████████████████');
    console.log(`▶  ${label}`);
    console.log('████████████████████████████████████████████████████████████████████████');
    console.log(`Running: ${command}`);
    console.log('');

    try {
        execSync(command, {
            cwd: ROOT,
            stdio: 'inherit',   // pipe stdout/stderr directly to terminal
            env: process.env,
        });
        console.log('\n');
        console.log('████████████████████████████████████████████████████████████████████████');
        console.log(`✅  ${label}  →  COMPLETED SUCCESSFULLY`);
        console.log('████████████████████████████████████████████████████████████████████████');
    } catch (err: any) {
        console.error('\n');
        console.error('████████████████████████████████████████████████████████████████████████');
        console.error(`❌  ${label}  →  FAILED`);
        console.error('████████████████████████████████████████████████████████████████████████');
        console.error('Error detail:', err?.message ?? err);
        // Rethrow so the process exits non-zero and Step #2 is NOT executed
        throw err;
    }
}

async function orchestrate(): Promise<void> {
    console.log('\n');
    console.log('╔══════════════════════════════════════════════════════════════════════╗');
    console.log('║       WOOBERLY FULL END-TO-END AUTOMATION  (test:full)              ║');
    console.log('║                                                                      ║');
    console.log('║  Step #1  →  test:driver-online  (bring Driver to online status)    ║');
    console.log('║  Step #2  →  test:during-booking (book ride + full trip lifecycle)  ║');
    console.log('╚══════════════════════════════════════════════════════════════════════╝');

    // ── Step #1 ─────────────────────────────────────────────────────────────
    run(
        'Step #1: Driver Online Flow  (npm run test:driver-online)',
        'npx tsx tests/e2e/wooberly_driver_online_flow.ts'
    );

    // ── Step #2 ─────────────────────────────────────────────────────────────
    // Pre-warm the Rider app while the Appium session gap is happening.
    // This tells Android to promote the Rider process to foreground priority
    // before the new Appium session starts, so the Flutter engine has already
    // rendered the home screen by the time test:during-booking activates it.
    console.log('\n⏳  Step #1 complete. Pre-warming Rider app via adb...\n');
    try {
        execSync('adb shell am start -n com.radicalstart.wooberly/.MainActivity', { stdio: 'ignore' });
        console.log('Rider app launched to foreground. Waiting 8 s for session cleanup + Rider render...\n');
    } catch {
        console.log('adb pre-warm skipped (adb not available). Waiting 8 s anyway...\n');
    }
    await new Promise(r => setTimeout(r, 8000));

    // ── Step #2 ─────────────────────────────────────────────────────────────
    run(
        'Step #2: During-Booking Flow  (npm run test:during-booking)',
        'npx tsx tests/e2e/wooberly_combined_driver_rider_flow.ts'
    );

    console.log('\n');
    console.log('╔══════════════════════════════════════════════════════════════════════╗');
    console.log('║  🎉  FULL END-TO-END FLOW COMPLETED SUCCESSFULLY!                   ║');
    console.log('╚══════════════════════════════════════════════════════════════════════╝\n');
}

orchestrate().catch((err) => {
    console.error('\n[ORCHESTRATOR] Fatal error — aborting full flow.', err);
    process.exit(1);
});
