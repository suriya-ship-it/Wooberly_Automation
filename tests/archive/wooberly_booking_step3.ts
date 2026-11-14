import { remote } from 'webdriverio';
import * as fs from 'fs';

async function main() {
    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:appPackage': 'com.radicalstart.wooberly',
        'appium:appActivity': 'com.radicalstart.wooberly.MainActivity', 
        'appium:noReset': true,
        'appium:autoGrantPermissions': true,
    };

    const driver = await remote({
        path: '/',
        port: 4723,
        capabilities
    });

    console.log('Appium session started.');

    // We should be on the screen where EditText with hint="Enter drop location" is focused.
    const dropInput = await driver.$('//android.widget.EditText');
    if (await dropInput.isDisplayed()) {
        await dropInput.click();
        await driver.pause(500);
        await driver.keys('Meenakshi Amman Temple');
        console.log('Entered "Meenakshi Amman Temple"');
    }
    
    await driver.pause(4000);
    
    const screenshotPath = './screenshots/drop_location_predictions.png';
    await driver.saveScreenshot(screenshotPath);
    console.log(`Screenshot saved to ${screenshotPath}`);

    const pageSource = await driver.getPageSource();
    fs.writeFileSync('./predictions_source.xml', pageSource);
    console.log('Saved page source to predictions_source.xml');

    await driver.deleteSession();
}

main().catch(console.error);
