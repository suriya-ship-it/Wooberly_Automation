import { remote } from 'webdriverio';
import * as fs from 'fs';

async function main() {
    const driver = await remote({
        path: '/',
        port: 4723,
        capabilities: {
            platformName: 'Android',
            'appium:automationName': 'UiAutomator2',
            'appium:appPackage': 'com.radicalstart.wooberly',
            'appium:appActivity': 'com.radicalstart.wooberly.MainActivity', 
            'appium:noReset': true,
        }
    });

    console.log('Appium session started.');
    
    // Relaunch app
    await driver.execute('mobile: terminateApp', { appId: 'com.radicalstart.wooberly' });
    await driver.pause(2000);
    await driver.execute('mobile: activateApp', { appId: 'com.radicalstart.wooberly' });
    await driver.pause(5000);

    // Get to home page if not already
    for (let i = 0; i < 3; i++) {
        try {
            const el = await driver.$('~Search your destination');
            if (await el.isDisplayed()) break;
        } catch(e) {}
        try {
            const el = await driver.$('~Where are you going?');
            if (await el.isDisplayed()) break;
        } catch(e) {}
        await driver.pressKeyCode(4);
        await driver.pause(2000);
    }
    
    console.log('Clicking Search your destination');
    try {
        await (await driver.$('~Search your destination')).click();
        await driver.pause(3000);
    } catch(e) {}

    console.log('Clicking Enter drop location');
    try {
        await (await driver.$('~Enter drop location')).click();
        await driver.pause(3000);
    } catch(e) {}

    const source = await driver.getPageSource();
    fs.writeFileSync('./debug_location.xml', source);
    await driver.saveScreenshot('./screenshots/debug_location.png');
    
    await driver.deleteSession();
}

main().catch(console.error);
