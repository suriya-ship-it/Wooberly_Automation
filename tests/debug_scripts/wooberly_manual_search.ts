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
    await driver.execute('mobile: activateApp', { appId: 'com.radicalstart.wooberly' });
    await driver.pause(5000);

    const el = await driver.$('~Search your destination');
    if (await el.isDisplayed()) {
        await el.click();
        await driver.pause(2000);
        
        const drop = await driver.$('~Enter drop location');
        await drop.click();
        await driver.pause(2000);
        
        const input = await driver.$('//*[@focused="true"]');
        await input.click();
        await driver.keys('Meenakshi');
        await driver.pause(4000);
        
        const pred = await driver.$(`//android.widget.ImageView[contains(@content-desc, "Meenakshi")]`);
        await pred.click();
        await driver.pause(4000);
        
        const source = await driver.getPageSource();
        fs.writeFileSync('./debug_map.xml', source);
        await driver.saveScreenshot('./screenshots/debug_map.png');
    }
    
    await driver.deleteSession();
}

main().catch(console.error);
