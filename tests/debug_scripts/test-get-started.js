import { remote } from 'webdriverio';
import fs from 'fs';

const capabilities = {
    platformName: 'Android',

    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': 'RZ8T7113KRM',
    'appium:udid': 'RZ8T7113KRM',

    'appium:appPackage': 'com.radicalstart.wooberly',
    'appium:appActivity': '.MainActivity',

    'appium:noReset': false,
    'appium:autoGrantPermissions': false
};

const driver = await remote({
    hostname: '127.0.0.1',
    port: 4723,
    path: '/',
    logLevel: 'error',
    capabilities
});

try {
    fs.mkdirSync('./screenshots', { recursive: true });

    // ==================================================
    // STEP 1: Handle Location Permission
    // ==================================================

    const permission = await driver.$(
        'android=new UiSelector().textContains("While using the app")'
    );

    if (await permission.isDisplayed().catch(() => false)) {
        await permission.click();
        await driver.pause(1500);
    }

    // ==================================================
    // STEP 2: Click Get Started
    // ==================================================

    const getStarted = await driver.$(
        'android=new UiSelector().description("Get started").clickable(true)'
    );

    await getStarted.waitForDisplayed({
        timeout: 15000
    });

    await driver.saveScreenshot(
        './screenshots/01-get-started-before-click.png'
    );

    await getStarted.click();

    // ==================================================
    // STEP 3: Wait for Mobile Number Page
    // ==================================================

    const mobileNumber = await driver.$(
        'android=new UiSelector().className("android.widget.EditText")'
    );

    await mobileNumber.waitForDisplayed({
        timeout: 10000
    });

    // ==================================================
    // STEP 4: Enter Mobile Number
    // ==================================================

    await mobileNumber.click();

    await mobileNumber.setValue('9876543210');

    await driver.hideKeyboard().catch(() => {});

    // ==================================================
    // STEP 5: Click Terms & Privacy Checkbox
    // ==================================================

    const checkbox = await driver.$(
        'android=new UiSelector()' +
        '.className("android.widget.ImageView")' +
        '.index(6)' +
        '.clickable(true)'
    );

    await checkbox.waitForDisplayed({
        timeout: 10000
    });

    await checkbox.click();

    await driver.pause(500);

    // ==================================================
    // STEP 6: Click Verify Button
    // ==================================================

    const verifyButton = await driver.$(
        'android=new UiSelector().description("Verify").clickable(true)'
    );

    await verifyButton.waitForDisplayed({
        timeout: 10000
    });

    await verifyButton.click();

    // ==================================================
    // STEP 7: Capture Result
    // ==================================================

    await driver.pause(2000);

    const OTP = await driver.$(
    'android=new UiSelector().description("Your OTP is 1234").clickable(true)'
);

 await driver.pause(2000);

const proceed = await driver.$(
    'android=new UiSelector().description("Proceed").clickable(true)'
);


    await driver.saveScreenshot(
        './screenshots/03-after-verify.png'
    );

    const source = await driver.getPageSource();

    fs.writeFileSync(
        './screenshots/03-after-verify-page-source.xml',
        source
    );

    console.log('✅ TC-001 PASSED');

} catch (error) {

    console.error('❌ TC-001 FAILED');
    console.error(error.message);

    await driver.saveScreenshot(
        './screenshots/TC001-error.png'
    ).catch(() => {});

// } finally {

//     await driver.deleteSession().catch(() => {});
}