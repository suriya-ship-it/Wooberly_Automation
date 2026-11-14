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

    // 1. Click 'Enter stop'
    const enterStop = await driver.$('~Enter stop');
    if (await enterStop.isDisplayed()) {
        await enterStop.click();
        console.log('Clicked "Enter stop"');
        await driver.pause(1500);

        // 2. We should be on CitySearch page. The EditText should be focused or we need to tap it.
        const searchInput = await driver.$('//android.widget.EditText');
        await searchInput.click();
        await driver.pause(500);
        await driver.keys('Madurai Railway Station');
        console.log('Entered "Madurai Railway Station"');
        
        await driver.pause(4000);
        
        // 3. Click the prediction
        const prediction = await driver.$('~Madurai Railway Station, Railway Station Road, Periyar, Madurai Main, Madurai, Tamil Nadu, India');
        // Let's just click the first prediction. 
        // We know it is bounds=[0,752][1080,963] roughly based on previous structure
        await driver.action('pointer')
            .move({ duration: 0, x: 500, y: 850 })
            .down()
            .pause(100)
            .up()
            .perform();
        console.log('Tapped the first prediction.');
        await driver.pause(3000);
    }
    
    // Now let's add the SECOND stop! 
    // We need to click the '+' button again. Which + button?
    // Let's get page source to see the layout after adding the first stop.
    const pageSource = await driver.getPageSource();
    fs.writeFileSync('./after_stop_1_source.xml', pageSource);
    console.log('Saved page source to after_stop_1_source.xml');

    await driver.deleteSession();
}

main().catch(console.error);
