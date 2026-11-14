const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const BACKUP_DIR = path.join(REPO_ROOT, 'backups/backup_before_retry_and_email');

console.log('========================================================================');
console.log('🔄 REVERTING AUTO-RETRY & EMAIL CHANGES BACK TO ORIGINAL STATE');
console.log('========================================================================\n');

if (!fs.existsSync(BACKUP_DIR)) {
  console.error('❌ Backup directory not found:', BACKUP_DIR);
  process.exit(1);
}

const restoreMap = [
  { src: path.join(BACKUP_DIR, 'server.ts'), dest: path.join(REPO_ROOT, 'bridge/server.ts') },
  { src: path.join(BACKUP_DIR, 'wooberly_step2_flow.ts'), dest: path.join(REPO_ROOT, 'tests/e2e/wooberly_step2_flow.ts') },
  { src: path.join(BACKUP_DIR, 'DeviceManager.ts'), dest: path.join(REPO_ROOT, 'services/DeviceManager.ts') },
  { src: path.join(BACKUP_DIR, '.env'), dest: path.join(REPO_ROOT, '.env') },
  { src: path.join(BACKUP_DIR, 'package.json'), dest: path.join(REPO_ROOT, 'package.json') },
];

for (const item of restoreMap) {
  if (fs.existsSync(item.src)) {
    fs.copyFileSync(item.src, item.dest);
    console.log(`✅ Restored: ${path.relative(REPO_ROOT, item.dest)}`);
  } else {
    console.warn(`⚠️ Backup file missing: ${item.src}`);
  }
}

// Remove newly added service files if present
const newlyCreatedFiles = [
  path.join(REPO_ROOT, 'services/PageTracker.ts'),
  path.join(REPO_ROOT, 'services/EmailService.ts'),
];

for (const file of newlyCreatedFiles) {
  if (fs.existsSync(file)) {
    fs.unlinkSync(file);
    console.log(`🗑️ Removed new file: ${path.relative(REPO_ROOT, file)}`);
  }
}

console.log('\n========================================================================');
console.log('🎉 REVERT COMPLETE: All files restored to the exact previous state.');
console.log('========================================================================\n');
