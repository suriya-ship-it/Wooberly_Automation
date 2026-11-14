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

    const source = await driver.getPageSource();
    fs.writeFileSync('./current_state_error.xml', source);
    await driver.saveScreenshot('./screenshots/current_state_error.png');
    
    await driver.deleteSession();
}

main().catch(console.error);
