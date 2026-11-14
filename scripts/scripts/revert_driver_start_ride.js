const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const BACKUP_DIR = path.join(REPO_ROOT, 'backups/backup_issue2_driver_start_ride_delay');

console.log('========================================================================');
console.log('🔄 REVERTING ISSUE #2: DRIVER START RIDE DELAY FIX');
console.log('========================================================================\n');

if (!fs.existsSync(BACKUP_DIR)) {
  console.error('❌ Backup directory not found:', BACKUP_DIR);
  process.exit(1);
}

// 1. Revert tests/e2e/wooberly_trip_flow.ts
const tripFile = path.join(REPO_ROOT, 'tests/e2e/wooberly_trip_flow.ts');
const backupTrip = path.join(BACKUP_DIR, 'wooberly_trip_flow.ts');
if (fs.existsSync(backupTrip)) {
  fs.copyFileSync(backupTrip, tripFile);
  console.log(`✅ Restored: tests/e2e/wooberly_trip_flow.ts`);
}

// 2. Revert tests/e2e/wooberly_combined_driver_rider_flow.ts start ride line
const combinedFile = path.join(REPO_ROOT, 'tests/e2e/wooberly_combined_driver_rider_flow.ts');
if (fs.existsSync(combinedFile)) {
  let content = fs.readFileSync(combinedFile, 'utf8');
  content = content.replace(
    "await swipeSlider('Start ride', ['START RIDE', 'START', 'Start', 'start'], 1713);",
    "await swipeSlider('Start ride', ['Start', 'START', 'start'], 1713);"
  );
  fs.writeFileSync(combinedFile, content, 'utf8');
  console.log(`✅ Restored Start ride call in: tests/e2e/wooberly_combined_driver_rider_flow.ts`);
}

console.log('\n========================================================================');
console.log('🎉 ISSUE #2 REVERT COMPLETE: Driver Start Ride delay logic restored.');
console.log('========================================================================\n');
