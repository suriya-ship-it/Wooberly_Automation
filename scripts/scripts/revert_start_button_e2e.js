const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const BACKUP_DIR = path.join(REPO_ROOT, 'backups/backup_start_button_e2e');

console.log('========================================================================');
console.log('🔄 REVERTING START BUTTON BEHAVIOR: RESTORING ORIGINAL BRIDGE SERVER');
console.log('========================================================================\n');

if (!fs.existsSync(BACKUP_DIR)) {
  console.error('❌ Backup directory not found:', BACKUP_DIR);
  process.exit(1);
}

// 1. Revert bridge/server.ts
const serverFile = path.join(REPO_ROOT, 'bridge/server.ts');
const backupServer = path.join(BACKUP_DIR, 'server.ts');
if (fs.existsSync(backupServer)) {
  fs.copyFileSync(backupServer, serverFile);
  console.log('✅ Restored original: bridge/server.ts');
} else {
  console.error('❌ Backup server file not found:', backupServer);
  process.exit(1);
}

console.log('\n========================================================================');
console.log('🎉 REVERT COMPLETE: Start button restored to original configuration.');
console.log('   Please restart the bridge server if running (npm run bridge)');
console.log('========================================================================\n');
