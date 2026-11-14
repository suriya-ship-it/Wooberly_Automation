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

    // Click the first prediction
    const prediction = await driver.$('~Meenakshi Amman Temple, Madurai Main, Madurai, Tamil Nadu, India');
    if (await prediction.isDisplayed()) {
        await prediction.click();
        console.log('Clicked prediction.');
    }
    
    await driver.pause(3000);
    
    // Find the "+" button. Let's assume it is the last ImageView before the "Add home" / "Add work" options.
    // In `predictions_source.xml`, it's an ImageView with index 4, after the EditText.
    // Or we can just click the screen location where it is. It was at [892,544][1013,665]. Center is ~950, 600.
    await driver.action('pointer')
        .move({ duration: 0, x: 950, y: 600 })
        .down()
        .pause(100)
        .up()
        .perform();
    console.log('Tapped the + button area to add a stop.');
    
    await driver.pause(2000);

    const screenshotPath = './screenshots/after_add_stop.png';
    await driver.saveScreenshot(screenshotPath);
    console.log(`Screenshot saved to ${screenshotPath}`);

    const pageSource = await driver.getPageSource();
    fs.writeFileSync('./after_add_stop_source.xml', pageSource);
    console.log('Saved page source to after_add_stop_source.xml');

    await driver.deleteSession();
}

main().catch(console.error);
