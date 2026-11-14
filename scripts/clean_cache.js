const { execSync } = require('child_process');
try {
  console.log('Cleaning node_modules/.cache and .tsx cache...');
  execSync('rm -rf node_modules/.cache .tsx_cache', { stdio: 'inherit' });
  console.log('Clean complete.');
} catch (e) {
  console.error('Clean failed:', e);
  process.exit(1);
}
