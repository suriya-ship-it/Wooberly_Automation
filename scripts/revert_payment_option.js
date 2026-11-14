#!/usr/bin/env node
const { execSync } = require('child_process');
try {
  execSync('git checkout -- tests/e2e/wooberly_combined_driver_rider_flow.ts', { stdio: 'inherit' });
  console.log('✅ Payment‑option changes reverted.');
} catch (e) {
  console.error('❌ Revert failed:', e);
  process.exit(1);
}
