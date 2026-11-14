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

    const getStartedBtn = await driver.$('~Get started');
    await getStartedBtn.waitForDisplayed({ timeout: 15000 });
    await getStartedBtn.click();
    await driver.pause(2000);
    
    const mobileField = await driver.$('//android.widget.EditText');
    await mobileField.waitForDisplayed({ timeout: 15000 });
    await mobileField.click();
    await driver.pause(500);
    await driver.keys('9876543210'); // Same number as before to BYPASS PROFILE!
    
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
    
    await driver.deleteSession();
}
main().catch(console.error);
