import { remote } from 'webdriverio';
import * as fs from 'fs';

async function main() {
    // Appium server capabilities
    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        // Make sure to match your device UUID if required, or leave it to auto-detect
        // 'appium:udid': 'RZ8T7113KRM', 
        'appium:appPackage': 'com.radicalstart.wooberly',
        'appium:appActivity': 'com.radicalstart.wooberly.MainActivity', 
        'appium:noReset': true, // Keeps app data
        'appium:autoGrantPermissions': true, // Automatically handle permission dialogs
    };

    const driver = await remote({
        path: '/', // Path for Appium 2.x
        port: 4723,
        capabilities
    });

    console.log('Appium session started. Opening Wooberly app...');

    // 1. Click 'Get started'
    const getStartedBtn = await driver.$('//android.widget.ImageView[@content-desc="Get started"]');
    await getStartedBtn.waitForDisplayed({ timeout: 30000 });
    await getStartedBtn.click();
    console.log('Clicked "Get started"');

    // 2. Enter mobile number
    const mobileField = await driver.$('//android.widget.EditText');
    await mobileField.waitForDisplayed({ timeout: 10000 });
    await mobileField.setValue('9876543210');
    console.log('Entered mobile number');

    // 3. Click 'Done' on keyboard
    const doneBtn = await driver.$('~Done'); // ~ is accessibility id in WebdriverIO
    await doneBtn.waitForDisplayed({ timeout: 5000 });
    await doneBtn.click();
    console.log('Clicked "Done"');

    // 4. Click the terms Checkbox
    // Note: The UI may contain an ImageView for the checkbox; using XPath from inspection
    const checkbox = await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ImageView[3]');
    await checkbox.waitForDisplayed({ timeout: 5000 });
    await checkbox.click();
    console.log('Selected terms checkbox');

    // 5. Click 'Verify'
    const verifyBtn = await driver.$('~Verify');
    await verifyBtn.waitForDisplayed({ timeout: 5000 });
    await verifyBtn.click();
    console.log('Clicked "Verify"');

    // 6. Wait for OTP screen
    await driver.pause(3000); 

    // 7. Click auto-fill OTP button
    const autoFillOtpBtn = await driver.$('~Your OTP is 1234');
    await autoFillOtpBtn.waitForDisplayed({ timeout: 10000 });
    await autoFillOtpBtn.click();
    console.log('Tapped auto-fill OTP');

    // Hide keyboard by pressing Enter (or Back)
    await driver.pressKeyCode(66);
    await driver.pause(1000);

    // 8. Click 'Proceed'
    const proceedBtn = await driver.$('~Proceed');
    await proceedBtn.waitForDisplayed({ timeout: 5000 });
    await proceedBtn.click();
    console.log('Clicked "Proceed"');

    // Wait for Profile details screen and take screenshot
    await driver.pause(4000);
    const screenshotPath = './screenshots/profile_details_screen.png';
    
    // Ensure directory exists
    if (!fs.existsSync('./screenshots')) {
        fs.mkdirSync('./screenshots');
    }
    await driver.saveScreenshot(screenshotPath);
    console.log(`Screenshot saved to ${screenshotPath}`);
    // 8. Profile Details Screen
    console.log('Filling out profile details...');
    
    // First Name
    const firstName = await driver.$('//android.view.View[@content-desc="Enter your details"]/following-sibling::android.widget.EditText[1]');
    await firstName.waitForDisplayed({ timeout: 10000 });
    await firstName.click();
    await driver.pause(500);
    await driver.keys('Suriya');
    await driver.pressKeyCode(4); // Hide keyboard
    await driver.pause(500);
    console.log('Entered First Name: Suriya');

    // Last Name
    // Note: App validation requires 3 to 50 characters for last name. Using 'kbb' as 'kb' is only 2 chars.
    const lastName = await driver.$('//android.view.View[@content-desc="Enter your details"]/following-sibling::android.widget.EditText[2]');
    await lastName.waitForDisplayed({ timeout: 5000 });
    await lastName.click();
    await driver.pause(500);
    await driver.keys('kbb');
    await driver.pressKeyCode(4); // Hide keyboard
    await driver.pause(500);
    console.log('Entered Last Name: kbb');

    // Gender
    const genderDropdown = await driver.$('//android.widget.ScrollView/android.view.View[2]');
    await genderDropdown.waitForDisplayed({ timeout: 5000 });
    await genderDropdown.click();
    await driver.pause(1000);
    const maleOption = await driver.$('~Male');
    await maleOption.waitForDisplayed({ timeout: 5000 });
    await maleOption.click();
    await driver.pause(500);
    console.log('Selected Gender: Male');

    // Email
    const email = await driver.$('//android.view.View[@content-desc="What\'s your email?"]/following-sibling::android.widget.EditText[1]');
    await email.waitForDisplayed({ timeout: 5000 });
    await email.click();
    await driver.pause(500);
    await driver.keys('suriya@radicalstart.com');
    await driver.pressKeyCode(4); // Hide keyboard
    await driver.pause(500);
    console.log('Entered Email: suriya@radicalstart.com');

    // Location (opens City Search via Google Places)
    const locationField = await driver.$('//android.view.View[@content-desc="What\'s your location?"]/following-sibling::android.view.View[1]');
    await locationField.waitForDisplayed({ timeout: 5000 });
    await locationField.click();
    console.log('Opened City Search');
    await driver.pause(1500);

    // City Search Input
    const citySearchInput = await driver.$('//android.widget.EditText');
    await citySearchInput.waitForDisplayed({ timeout: 10000 });
    await citySearchInput.click();
    await driver.pause(500);
    await driver.keys('Madurai, India');
    console.log('Typed "Madurai, India" in search');
    await driver.pause(3000);

    // Select the first autocomplete prediction
    const maduraiPrediction = await driver.$('~Madurai, Tamil Nadu, India');
    await maduraiPrediction.waitForDisplayed({ timeout: 10000 });
    await maduraiPrediction.click();
    console.log('Selected Autopopulate Location: Madurai, Tamil Nadu, India');
    await driver.pause(2000);

    // Scroll down to ensure Password and Confirm Password are in view
    await driver.action('pointer')
        .move({ duration: 0, x: 500, y: 1800 })
        .down()
        .move({ duration: 300, x: 500, y: 1200 })
        .up()
        .perform();
    await driver.pause(1000);

    // Password
    const password = await driver.$('//android.view.View[@content-desc="Set your password"]/following-sibling::android.widget.EditText[1]');
    await password.waitForDisplayed({ timeout: 5000 });
    await password.click();
    await driver.pause(500);
    await driver.keys('qwerty123');
    await driver.pressKeyCode(4); // Hide keyboard
    await driver.pause(500);
    console.log('Entered Password: qwerty123');

    // Confirm Password
    const confirmPassword = await driver.$('//android.view.View[@content-desc="Set your password"]/following-sibling::android.widget.EditText[2]');
    await confirmPassword.waitForDisplayed({ timeout: 5000 });
    await confirmPassword.click();
    await driver.pause(500);
    await driver.keys('qwerty123');
    await driver.pressKeyCode(4); // Hide keyboard
    await driver.pause(500);
    console.log('Entered Confirm Password: qwerty123');

    // Finish
    const finishBtn = await driver.$('~Finish');
    await finishBtn.waitForDisplayed({ timeout: 5000 });
    await finishBtn.click();
    console.log('Clicked "Finish" button');

    // Wait for the Explore / Home screen to load
    await driver.pause(6000);

    const exploreScreenshotPath = './screenshots/explore_page.png';
    await driver.saveScreenshot(exploreScreenshotPath);
    console.log(`Screenshot saved to ${exploreScreenshotPath}`);

    // End session
    await driver.deleteSession();
    console.log('Test completed successfully.');
}

main().catch(console.error);
