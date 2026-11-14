const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const BACKUP_DIR = path.join(REPO_ROOT, 'backups/backup_smart_install_and_drop_fix');

console.log('========================================================================');
console.log('🔄 REVERTING SMART INSTALL & DROP LOCATION FIX');
console.log('========================================================================\n');

if (!fs.existsSync(BACKUP_DIR)) {
  console.error('❌ Backup directory not found:', BACKUP_DIR);
  process.exit(1);
}

const filesToRestore = [
  { backup: 'server.ts', target: 'bridge/server.ts' },
  { backup: 'wooberly_step1_flow.ts', target: 'tests/e2e/wooberly_step1_flow.ts' },
  { backup: 'wooberly_step2_flow.ts', target: 'tests/e2e/wooberly_step2_flow.ts' },
  { backup: 'wooberly_login_e2e_flow.ts', target: 'tests/e2e/wooberly_login_e2e_flow.ts' },
  { backup: 'wooberly_combined_driver_rider_flow.ts', target: 'tests/e2e/wooberly_combined_driver_rider_flow.ts' },
];

for (const item of filesToRestore) {
  const bPath = path.join(BACKUP_DIR, item.backup);
  const tPath = path.join(REPO_ROOT, item.target);
  if (fs.existsSync(bPath)) {
    fs.copyFileSync(bPath, tPath);
    console.log(`✅ Restored: ${item.target}`);
  } else {
    console.warn(`⚠️ Backup file missing: ${item.backup}`);
  }
}

console.log('\n========================================================================');
console.log('🎉 REVERT COMPLETE: Files restored to previous state.');
console.log('   Restart the bridge server if running (npm run bridge)');
console.log('========================================================================\n');
