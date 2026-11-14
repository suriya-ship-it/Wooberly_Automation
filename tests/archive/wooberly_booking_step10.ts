import { remote } from 'webdriverio';

async function main() {
    const driver = await remote({
        path: '/',
        port: 4723,
        capabilities: {
            platformName: 'Android',
            'appium:automationName': 'UiAutomator2',
            'appium:noReset': true,
        }
    });

    await driver.pressKeyCode(4);
    await driver.pause(1000);
    await driver.pressKeyCode(4);
    await driver.pause(1000);
    
    // relaunch our app
    await driver.execute('mobile: activateApp', { appId: 'com.radicalstart.wooberly' });
    
    await driver.deleteSession();
}
main().catch(console.error);
