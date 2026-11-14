import { remote } from 'webdriverio';

async function main() {
    const driver = await remote({
        path: '/', port: 4723,
        capabilities: {
            platformName: 'Android',
            'appium:automationName': 'UiAutomator2',
            'appium:appPackage': 'com.radicalstart.wooberly',
            'appium:appActivity': 'com.radicalstart.wooberly.MainActivity', 
            'appium:noReset': true,
        }
    });

    console.log('App launched. Waiting for home screen...');
    await driver.pause(5000);

    // 1. Search destination
    const searchDestBtn = await driver.$('~Search your destination');
    if (await searchDestBtn.isDisplayed()) {
        await searchDestBtn.click();
        console.log('Tapped Search your destination');
    } else {
        await driver.action('pointer').move({ duration: 0, x: 500, y: 900 }).down().pause(100).up().perform();
        console.log('Tapped fallback for Search your destination');
    }
    await driver.pause(3000);

    // 2. Enter drop location
    const dropLocBtn = await driver.$('~Enter drop location');
    if (await dropLocBtn.isDisplayed()) {
        await dropLocBtn.click();
        console.log('Tapped Enter drop location');
    }
    await driver.pause(4000);

    // Output source of the MAP PAGE
    const source = await driver.getPageSource();
    const fs = require('fs');
    fs.writeFileSync('map_page_source.xml', source);
    console.log('Saved map page source to map_page_source.xml');

    await driver.deleteSession();
}

main().catch(console.error);
