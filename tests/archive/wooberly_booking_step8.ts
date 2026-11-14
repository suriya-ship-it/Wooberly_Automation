import { remote } from 'webdriverio';

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

    console.log('Appium session started. Sending back key to return to home.');
    await driver.pressKeyCode(4);
    await driver.pause(2000);
    await driver.pressKeyCode(4);
    await driver.pause(2000);

    const source = await driver.getPageSource();
    require('fs').writeFileSync('./current_state.xml', source);
    
    await driver.deleteSession();
}

main().catch(console.error);
