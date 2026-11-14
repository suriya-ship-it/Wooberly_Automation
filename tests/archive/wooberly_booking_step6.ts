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

    console.log('Appium session started.');
    
    // We are probably on the Where To page.
    const source = await driver.getPageSource();
    console.log("Got page source.");
    require('fs').writeFileSync('./current_state.xml', source);
    
    await driver.deleteSession();
}

main().catch(console.error);
