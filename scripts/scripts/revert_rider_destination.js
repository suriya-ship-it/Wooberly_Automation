const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const BACKUP_DIR = path.join(REPO_ROOT, 'backups/backup_issue1_rider_destination');

console.log('========================================================================');
console.log('🔄 REVERTING ISSUE #1: RIDER DESTINATION CLEAR LOGIC');
console.log('========================================================================\n');

if (!fs.existsSync(BACKUP_DIR)) {
  console.error('❌ Backup directory not found:', BACKUP_DIR);
  process.exit(1);
}

// 1. Revert tests/e2e/wooberly_login_e2e_flow.ts
const loginFile = path.join(REPO_ROOT, 'tests/e2e/wooberly_login_e2e_flow.ts');
const backupLogin = path.join(BACKUP_DIR, 'wooberly_login_e2e_flow.ts');
if (fs.existsSync(backupLogin)) {
  fs.copyFileSync(backupLogin, loginFile);
  console.log(`✅ Restored: tests/e2e/wooberly_login_e2e_flow.ts`);
}

// 2. Revert tests/e2e/wooberly_combined_driver_rider_flow.ts destination block
const combinedFile = path.join(REPO_ROOT, 'tests/e2e/wooberly_combined_driver_rider_flow.ts');
const backupCombined = path.join(BACKUP_DIR, 'wooberly_combined_driver_rider_flow.ts');
if (fs.existsSync(combinedFile) && fs.existsSync(backupCombined)) {
  const currentContent = fs.readFileSync(combinedFile, 'utf8');
  const backupContent = fs.readFileSync(backupCombined, 'utf8');

  // Extract the destination input block from backup
  const startMarker = '// Enter Drop Location';
  const endMarker = 'await captureScreen(';

  // Restore the original drop location logic
  const oldSnippet = `    // Enter Drop Location
    console.log('Focusing drop location input...');
    const dropLocationBtn = await driver.$('~Enter drop location');
    if (await dropLocationBtn.isDisplayed().catch(() => false)) {
        await dropLocationBtn.click();
    } else {
        const inputFields: any = await driver.$$('//android.widget.EditText');
        if (inputFields.length > 0) {
            const fieldToClick = inputFields[1] || inputFields[0];
            await fieldToClick.click();
        } else {
            await driver.action('pointer').move({ duration: 0, x: 500, y: 500 }).down().pause(100).up().perform();
        }
    }
    await driver.pause(2000);

    // Type character by character to avoid clipboard/IME crash
    const textToType = 'Mattuthavani madurai';
    console.log(\`Typing destination: \${textToType}\`);
    for (const char of textToType) {
        await driver.keys(char);
        await driver.pause(50);
    }
    await driver.pause(4000);`;

  const newSnippetPattern = /\/\/ Enter Drop Location[\s\S]*?await driver\.pause\(4000\);/;
  if (newSnippetPattern.test(currentContent)) {
    const updated = currentContent.replace(newSnippetPattern, oldSnippet);
    fs.writeFileSync(combinedFile, updated, 'utf8');
    console.log(`✅ Restored destination block in: tests/e2e/wooberly_combined_driver_rider_flow.ts`);
  }
}

console.log('\n========================================================================');
console.log('🎉 ISSUE #1 REVERT COMPLETE: Rider destination field logic restored.');
console.log('========================================================================\n');
