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

    // Assuming we are on the Where to? screen right now.
    // Tap Enter drop location
    const dropLocation = await driver.$('~Enter drop location');
    if (await dropLocation.isDisplayed()) {
        await dropLocation.click();
        console.log('Clicked "Enter drop location"');
    } else {
        console.log('Could not find "Enter drop location". Let us see where we are.');
    }
    
    await driver.pause(3000);
    
    // Save screen
    const screenshotPath = './screenshots/drop_location_search.png';
    await driver.saveScreenshot(screenshotPath);
    console.log(`Screenshot saved to ${screenshotPath}`);

    const pageSource = await driver.getPageSource();
    fs.writeFileSync('./drop_search_source.xml', pageSource);
    console.log('Saved page source to drop_search_source.xml');

    await driver.deleteSession();
}

main().catch(console.error);
