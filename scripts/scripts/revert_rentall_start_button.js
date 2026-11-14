const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const BACKUP_DIR = path.join(REPO_ROOT, 'backups/backup_rentall_start_button');
const DASHBOARD_PRODUCTS = '/Users/radicalstart/Documents/daily-smoketesting/src/routes/_authenticated/products.tsx';

console.log('========================================================================');
console.log('🔄 REVERTING RENTALL START BUTTON CONFIGURATION');
console.log('========================================================================\n');

if (!fs.existsSync(BACKUP_DIR)) {
  console.error('❌ Backup directory not found:', BACKUP_DIR);
  process.exit(1);
}

// 1. Revert bridge/server.ts
const serverFile = path.join(REPO_ROOT, 'bridge/server.ts');
const backupServer = path.join(BACKUP_DIR, 'server.ts.bak');
if (fs.existsSync(backupServer)) {
  fs.copyFileSync(backupServer, serverFile);
  console.log('✅ Restored original: bridge/server.ts');
} else {
  console.error('❌ Backup server file not found:', backupServer);
}

// 2. Revert products.tsx
const backupProducts = path.join(BACKUP_DIR, 'products.tsx.bak');
if (fs.existsSync(backupProducts) && fs.existsSync(DASHBOARD_PRODUCTS)) {
  fs.copyFileSync(backupProducts, DASHBOARD_PRODUCTS);
  console.log('✅ Restored original: daily-smoketesting products.tsx');
} else {
  console.warn('⚠️ Backup products file not found or target directory missing.');
}

// 3. Revert RentALL package.json
const rentAllPackageJson = '/Users/radicalstart/Documents/PackageDemo/RentALL_V3.9.2/package.json';
const backupPackageJson = path.join(BACKUP_DIR, 'package.json.bak');
if (fs.existsSync(backupPackageJson) && fs.existsSync(rentAllPackageJson)) {
  fs.copyFileSync(backupPackageJson, rentAllPackageJson);
  console.log('✅ Restored original: RentALL_V3.9.2 package.json');
}

console.log('\n========================================================================');
console.log('🎉 REVERT COMPLETE: RentALL configuration restored to previous state.');
console.log('   Please restart the bridge server if running (npm run bridge)');
console.log('========================================================================\n');
