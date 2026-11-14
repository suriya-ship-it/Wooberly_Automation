#!/usr/bin/env node
const { execSync } = require('child_process');
try {
  execSync('git checkout -- tests/e2e/wooberly_full_e2e_flow.ts', { stdio: 'inherit' });
  console.log('✅ Orchestrator payment‑option mapping reverted.');
} catch (e) {
  console.error('❌ Revert failed:', e);
  process.exit(1);
}
