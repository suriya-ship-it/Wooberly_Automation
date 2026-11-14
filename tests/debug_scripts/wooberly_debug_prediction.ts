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
    
    // Attempt to navigate to the location selection list and pick a prediction
    const clickPrediction = async (searchTerm: string) => {
        try {
            const pred = await driver.$(`//android.widget.ImageView[contains(@content-desc, "${searchTerm}")]`);
            if (await pred.isDisplayed()) {
                await pred.click();
                return true;
            }
        } catch(e) {}
        await driver.action('pointer').move({ duration: 0, x: 500, y: 1050 }).down().pause(100).up().perform();
        return true;
    };

    console.log('Ensure we are on Home page');
    for (let i = 0; i < 3; i++) {
        try { if (await (await driver.$('~Search your destination')).isDisplayed()) break; } catch(e) {}
        try { if (await (await driver.$('~Where are you going?')).isDisplayed()) break; } catch(e) {}
        await driver.pressKeyCode(4);
        await driver.pause(2000);
    }
    
    console.log('Clicking Search your destination');
    try { await (await driver.$('~Search your destination')).click(); } catch(e) {}
    await driver.pause(3000);

    console.log('Clicking Enter drop location');
    try { await (await driver.$('~Enter drop location')).click(); } catch(e) {}
    await driver.pause(2000);

    console.log('Typing query');
    let focusedInput = await driver.$('//*[@focused="true"]');
    try { await focusedInput.click(); } catch(e) {}
    await driver.pause(500);
    await driver.keys('Meenakshi Amman Temple');
    await driver.pause(4000);

    console.log('Clicking prediction');
    await clickPrediction('Meenakshi');
    await driver.pause(5000); // Wait for the "new map page" to load

    console.log('Taking screenshot of the new map page');
    const source = await driver.getPageSource();
    fs.writeFileSync('./debug_prediction.xml', source);
    await driver.saveScreenshot('./screenshots/debug_prediction.png');
    
    await driver.deleteSession();
}

main().catch(console.error);
