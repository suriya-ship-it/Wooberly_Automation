import { remote } from 'webdriverio';

async function main() {
    const driver = await remote({
        path: '/', port: 4723,
        capabilities: {
            platformName: 'Android',
            'appium:automationName': 'UiAutomator2',
            'appium:appPackage': 'com.radicalstart.wooberly',
            'appium:appActivity': 'com.radicalstart.wooberly.MainActivity', 
            'appium:noReset': false,
            'appium:autoGrantPermissions': true,
        }
    });

    // 1. Get started
    const getStartedBtn = await driver.$('~Get started');
    await getStartedBtn.waitForDisplayed({ timeout: 15000 });
    await getStartedBtn.click();
    await driver.pause(3000);
    
    // 2. Handle potential permission dialogs before EditText
    try {
        const allowBtn = await driver.$('//*[@text="Allow" or @text="While using the app" or @text="ALLOW"]');
        if (await allowBtn.isDisplayed()) {
            console.log('Dismissing permission dialog');
            await allowBtn.click();
            await driver.pause(2000);
        }
    } catch(e) {}

    // Now find the mobile input
    const mobileField = await driver.$('//android.widget.EditText');
    await mobileField.waitForDisplayed({ timeout: 15000 });
    await mobileField.click();
    await driver.pause(500);
    await driver.keys('9876543210'); 
    
    await (await driver.$('~Done')).click();
    await driver.pause(1000);

    await driver.action('pointer').move({ duration: 0, x: 100, y: 1500 }).down().pause(100).up().perform();
    await driver.pause(1000);

    await (await driver.$('~Verify')).click();
    await driver.pause(3000);

    const autoFillOtpBtn = await driver.$('~Your OTP is 1234');
    await autoFillOtpBtn.waitForDisplayed({ timeout: 10000 });
    if (await autoFillOtpBtn.isDisplayed()) {
        await autoFillOtpBtn.click();
        await driver.pressKeyCode(66);
    }

    await (await driver.$('~Proceed')).click();
    await driver.pause(8000);
    
    // Check if we reached Home Page
    const searchDest = await driver.$('~Search your destination');
    if (await searchDest.isDisplayed()) {
        console.log("HOME PAGE REACHED");
        await searchDest.click();
        await driver.pause(3000);
        
        const dropLocBtn = await driver.$('~Enter drop location');
        await dropLocBtn.click();
        await driver.pause(2000);
        
        const input = await driver.$('//*[@focused="true"]');
        await input.click();
        await driver.keys('Meenakshi');
        await driver.pause(4000);
        
        // click prediction
        const pred = await driver.$(`//android.widget.ImageView[contains(@content-desc, "Meenakshi")]`);
        await pred.click();
        await driver.pause(4000);
        
        console.log("NOW ON THE MAP CONFIRMATION PAGE.");
        // Try to click "Confirm location"
        try {
            const confirmLoc = await driver.$('~Confirm location');
            if (await confirmLoc.isDisplayed()) {
                console.log("Clicked Confirm Location!");
                await confirmLoc.click();
            } else {
                console.log("Confirm location not found, tapping at bottom");
                await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
            }
        } catch(e) {
            console.log("Confirm location catch, tapping at bottom");
            await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
        }
        await driver.pause(3000);
    }

    await driver.deleteSession();
}
main().catch(console.error);
