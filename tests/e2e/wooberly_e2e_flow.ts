import { remote } from 'webdriverio';
import * as fs from 'fs';

async function main() {
    const capabilities = {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:appPackage': 'com.radicalstart.wooberly',
        'appium:appActivity': 'com.radicalstart.wooberly.MainActivity', 
        'appium:noReset': false, // FALSE means CLEAR DATA AND START FRESH
        'appium:autoGrantPermissions': true,
    };

    const driver = await remote({
        path: '/',
        port: 4723,
        capabilities
    });

    console.log('Appium session started. Fresh install state.');

    const elementExists = async (selector: string) => {
        try {
            const el = await driver.$(selector);
            return await el.isDisplayed();
        } catch {
            return false;
        }
    };

    const clickPrediction = async (searchTerm: string) => {
        try {
            const pred = await driver.$(`//android.widget.ImageView[contains(@content-desc, "${searchTerm}")]`);
            if (await pred.isDisplayed()) {
                await pred.click();
            } else {
                await driver.action('pointer').move({ duration: 0, x: 500, y: 830 }).down().pause(100).up().perform();
            }
        } catch(e) {
            await driver.action('pointer').move({ duration: 0, x: 500, y: 830 }).down().pause(100).up().perform();
        }
        await driver.pause(4000);
        return true;
    };

    // Use dynamic details to ensure we always hit the profile signup screen
    const randomPhone = '98' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
    const randomEmail = `suriya${Date.now()}@radicalstart.com`;

    // -------------------------------------------------------------------------
    // Check if Rider is Already Logged In
    // -------------------------------------------------------------------------
    console.log('Checking if Rider is already logged in...');
    const isRiderLoggedIn = async () => {
        return (
            (await elementExists('//android.widget.ImageView[@content-desc="Where to?"]')) ||
            (await elementExists('~Search your destination')) ||
            (await elementExists('~Where to?')) ||
            (await elementExists('//*[contains(@content-desc, "Where to")]')) ||
            (await elementExists('//*[contains(@content-desc, "Where are you going")]'))
        );
    };

    if (await isRiderLoggedIn()) {
        console.log('>>> Rider app is ALREADY LOGGED IN! Skipping signup/registration and proceeding to booking flows. <<<');
    } else {
        // --- PHASE 1: LOGIN / SIGNUP ---
        console.log('Executing Login/Signup Flow...');
        const getStartedBtn = await driver.$('//android.widget.ImageView[@content-desc="Get started"]');
        await getStartedBtn.waitForDisplayed({ timeout: 15000 }).catch(() => null);
        if (await getStartedBtn.isDisplayed().catch(() => false)) {
            await getStartedBtn.click();
            await driver.pause(3000);
        }
        
        // Handle potential permission dialogs before EditText
        try {
            const allowBtn = await driver.$('//*[@text="Allow" or @text="While using the app" or @text="ALLOW"]');
            if (await allowBtn.isDisplayed()) {
                console.log('Dismissing permission dialog');
                await allowBtn.click();
                await driver.pause(2000);
            }
        } catch(e) {}
        
        const mobileField = await driver.$('//android.widget.EditText');
        await mobileField.waitForDisplayed({ timeout: 15000 }); // ADDED WAIT HERE
        await mobileField.click();
        await driver.pause(500);
        await driver.keys(randomPhone);
        console.log(`Entered random phone: ${randomPhone}`);
        
        const doneBtn = await driver.$('~Done');
        await doneBtn.waitForDisplayed({ timeout: 5000 });
        await doneBtn.click();
        await driver.pause(1000);

        // Terms Checkbox - Exact XPATH
        const checkbox = await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.ImageView[3]');
        if (await elementExists(checkbox.selector as string)) {
            await checkbox.click();
        } else {
            await driver.action('pointer').move({ duration: 0, x: 100, y: 1500 }).down().pause(100).up().perform();
        }
        await driver.pause(1000);

        const verifyBtn = await driver.$('~Verify');
        await verifyBtn.waitForDisplayed({ timeout: 5000 });
        await verifyBtn.click();
        await driver.pause(3000);

        const autoFillOtpBtn = await driver.$('~Your OTP is 1234');
        await autoFillOtpBtn.waitForDisplayed({ timeout: 10000 });
        if (await autoFillOtpBtn.isDisplayed()) {
            await autoFillOtpBtn.click();
            await driver.pressKeyCode(66);
            await driver.pause(1000);
        }

        const proceedBtn = await driver.$('~Proceed');
        await proceedBtn.waitForDisplayed({ timeout: 5000 });
        await proceedBtn.click();
        await driver.pause(6000);

        // --- PHASE 2: FILL OUT THE DETAILS ---
        console.log('Filling out profile details...');
        
        // First Name
        const firstName = await driver.$('//android.view.View[@content-desc="Enter your details"]/following-sibling::android.widget.EditText[1]');
        await firstName.waitForDisplayed({ timeout: 15000 });
        await firstName.click();
        await driver.pause(500);
        await driver.keys('Suriya');
        await driver.pressKeyCode(4); // Hide keyboard
        await driver.pause(500);
        console.log('Entered First Name: Suriya');

        // Last Name (kbb instead of kb due to 3 char requirement length on backend validation sometimes)
        const lastName = await driver.$('//android.view.View[@content-desc="Enter your details"]/following-sibling::android.widget.EditText[2]');
        await lastName.waitForDisplayed({ timeout: 5000 });
        await lastName.click();
        await driver.pause(500);
        await driver.keys('kbb');
        await driver.pressKeyCode(4); // Hide keyboard
        await driver.pause(500);
        console.log('Entered Last Name: kbb');

        // Email
        const email = await driver.$('//android.view.View[@content-desc="Enter your details"]/following-sibling::android.widget.EditText[3]');
        await email.waitForDisplayed({ timeout: 5000 });
        await email.click();
        await driver.pause(500);
        await driver.keys(randomEmail);
        await driver.pressKeyCode(4); // Hide keyboard
        await driver.pause(500);
        console.log(`Entered Email: ${randomEmail}`);

        // Location / City Search
        const locationCity = await driver.$('//android.widget.ImageView[contains(@content-desc, "Madurai")] | //android.view.View[@content-desc="Enter your details"]/following-sibling::android.widget.ImageView[1]');
        await locationCity.waitForDisplayed({ timeout: 5000 });
        await locationCity.click();
        console.log('Clicked Location field, opening Google Places city search...');
        await driver.pause(3000);

        // Search in CitySearch screen
        const searchInput = await driver.$('//android.widget.EditText');
        await searchInput.waitForDisplayed({ timeout: 5000 });
        await searchInput.click();
        await driver.pause(500);
        await driver.keys('Madurai');
        console.log('Typed "Madurai" in Google Places search');
        await driver.pause(4000);

        // Select the first Google Place prediction
        console.log('Selecting prediction from list...');
        try {
            const prediction = await driver.$('//android.widget.ImageView[contains(@content-desc, "Madurai")]');
            if (await prediction.isDisplayed()) {
                await prediction.click();
                console.log('Selected prediction via content-desc match');
            } else {
                await driver.action('pointer').move({ duration: 0, x: 500, y: 350 }).down().pause(100).up().perform();
                console.log('Selected prediction via fallback coordinates');
            }
        } catch(e) {
            await driver.action('pointer').move({ duration: 0, x: 500, y: 350 }).down().pause(100).up().perform();
            console.log('Selected prediction via fallback coordinates (caught error)');
        }
        await driver.pause(3000);
        
        // Check for Map Page Confirmation here as well
        console.log('Checking for map page confirmation on Profile Details...');
        try {
            const confirmBtn = await driver.$('~Confirm location');
            if (await confirmBtn.isDisplayed()) {
                await confirmBtn.click();
                console.log('Clicked Confirm location on Profile Details map page');
            } else {
                const doneBtn = await driver.$('~Done');
                if (await doneBtn.isDisplayed()) {
                    await doneBtn.click();
                    console.log('Clicked Done on Profile Details map page');
                } else {
                    await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
                }
            }
        } catch(e) {
            await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
        }
        await driver.pause(2000);

        // Scroll down
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

    }
    
    // --- PHASE 3: ON DEMAND BOOKING WITH MULTI-STOP ---
    await driver.startRecordingScreen();
    console.log('Reached Home screen. Starting On-Demand Booking flow...');
    if (await elementExists('//*[@text="While using the app"]')) {
        await (await driver.$('//*[@text="While using the app"]')).click();
        await driver.pause(2000);
    }

    if (await elementExists('~Search your destination')) {
        await (await driver.$('~Search your destination')).click();
    } else {
        await driver.action('pointer').move({ duration: 0, x: 500, y: 900 }).down().pause(100).up().perform();
    }
    await driver.pause(3000);

    // Enter Drop Location
    console.log('Entering Drop Location 1: Mattuthavani madurai');
    const dropLocationBtn = await driver.$('~Enter drop location');
    if (await dropLocationBtn.isDisplayed()) {
        await dropLocationBtn.click();
    } else {
        // Fallback tap if accessibility ID is missing
        await driver.action('pointer').move({ duration: 0, x: 500, y: 500 }).down().pause(100).up().perform();
    }
    await driver.pause(2000);
    const ss1 = await driver.takeScreenshot();
    fs.writeFileSync('/Users/radicalstart/.gemini/antigravity/brain/deb6f5ff-f7a6-41d7-b10f-310a461c3e60/scratch/before_type.png', ss1, 'base64');
    

    // Type character by character to avoid clipboard paste crashes
    const textToType = 'Mattuthavani madurai';
    for (const char of textToType) {
        await driver.keys(char);
        await driver.pause(50);
    }
    await driver.pause(4000);
    const ss2 = await driver.takeScreenshot();
    fs.writeFileSync('/Users/radicalstart/.gemini/antigravity/brain/deb6f5ff-f7a6-41d7-b10f-310a461c3e60/scratch/after_type.png', ss2, 'base64');
    await clickPrediction('Mattuthavani');
    await driver.pause(3000);

    
    // Sometimes Keyboard is still closing, wait a bit
    await driver.pause(3000);

    console.log('Navigating through Confirm Location and Done screens...');
    let maxLoops = 15;
    while (maxLoops > 0) {
        if (await elementExists('~Book now') || await elementExists('~Confirm')) {
            console.log('Category selection page reached! Breaking loop.');
            break;
        } else if (await elementExists('~Confirm location')) {
            console.log('Map page appeared! Clicking Confirm location via coordinates...');
            await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
            await driver.pause(4000);
        } else if (await elementExists('~Done')) {
            console.log('Where to go page appeared! Clicking Done via coordinates...');
            await driver.action('pointer').move({ duration: 0, x: 500, y: 2100 }).down().pause(100).up().perform();
            await driver.pause(4000);
        } else {
            console.log('Neither Confirm location nor Done found. Waiting and retrying...');
            await driver.pause(2000);
        }
        maxLoops--;
    }

    
    // Category Selection
    console.log('Choosing vehicle category...');
    await driver.pause(3000);

    // Let's check for any vehicle categories or vehicle info tooltip
    // Available categories display an info icon (~vehicleInfoSvg or tooltip / vehicle details)
    let categoryChosen = false;
    try {
        const availableCategoryWithInfo = await driver.$$('//android.widget.ImageView[contains(@content-desc, "away") or contains(@content-desc, "mins") or contains(@content-desc, "Auto") or contains(@content-desc, "Micro") or contains(@content-desc, "Mini") or contains(@content-desc, "Luxury") or contains(@content-desc, "Prime")]');
        if (availableCategoryWithInfo.length > 0) {
            console.log(`Found ${availableCategoryWithInfo.length} category elements. Selecting the first available one...`);
            await availableCategoryWithInfo[0].click();
            categoryChosen = true;
        }
    } catch (e) {
        console.log('Error selecting category by selector, using coordinate fallback:', e);
    }

    if (!categoryChosen) {
        // Tap around vehicle category list items (middle of category card)
        console.log('Selecting category via coordinate tap...');
        await driver.action('pointer').move({ duration: 0, x: 500, y: 1450 }).down().pause(100).up().perform();
    }
    await driver.pause(2000);
    
    // Click "Book now" button
    console.log('Tapping "Book now" button...');
    if (await elementExists('~Book now')) {
        await (await driver.$('~Book now')).click();
    } else {
        // Coordinate fallback for bottom button
        await driver.action('pointer').move({ duration: 0, x: 500, y: 2050 }).down().pause(100).up().perform();
    }
    await driver.pause(3000);

    // --- PAYMENT METHOD SELECTION BOTTOM SHEET ---
    console.log('Handling Payment Method bottom sheet...');
    // Look for "Cash" option or "payment_method"
    let cashSelected = false;
    try {
        const cashOption = await driver.$('//android.widget.ImageView[contains(@content-desc, "Cash")] | //*[@content-desc="Cash"] | //*[@text="Cash"]');
        if (await cashOption.isDisplayed()) {
            await cashOption.click();
            cashSelected = true;
            console.log('Selected "Cash" payment method.');
        }
    } catch (e) {
        console.log('Could not click Cash directly by selector, checking alternatives...');
    }

    if (!cashSelected) {
        // Fallback: Cash is typically the top/first item in the payment methods list
        console.log('Tapping Cash position via coordinates...');
        await driver.action('pointer').move({ duration: 0, x: 500, y: 975 }).down().pause(100).up().perform();
    }
    await driver.pause(2000);

    // Click "Confirm" button on payment method section
    console.log('Confirming payment method...');
    if (await elementExists('~Confirm')) {
        await (await driver.$('~Confirm')).click();
    } else {
        await driver.action('pointer').move({ duration: 0, x: 500, y: 2050 }).down().pause(100).up().perform();
    }
    await driver.pause(3000);

    // --- PRECAUTION NOTIFICATION BOTTOM SHEET ---
    console.log('Handling Precaution Notification bottom sheet...');
    // Look for "Proceed" button
    if (await elementExists('~Proceed')) {
        await (await driver.$('~Proceed')).click();
        console.log('Clicked "Proceed" on Precaution bottom sheet.');
    } else {
        try {
            const proceedBtn = await driver.$('//*[@text="Proceed" or contains(@content-desc, "Proceed")]');
            if (await proceedBtn.isDisplayed()) {
                await proceedBtn.click();
                console.log('Clicked "Proceed" button via fallback selector.');
            } else {
                console.log('Proceed button not displayed via selector, tapping bottom right button...');
                await driver.action('pointer').move({ duration: 0, x: 750, y: 2050 }).down().pause(100).up().perform();
            }
        } catch {
            await driver.action('pointer').move({ duration: 0, x: 750, y: 2050 }).down().pause(100).up().perform();
        }
    }
    await driver.pause(5000);

    // --- CONNECTING / SEARCHING DRIVER SCREEN ---
    console.log('Verifying Searching Driver screen...');
    const isSearchingDriver = await elementExists('~Connecting you to nearby drivers') ||
                              await elementExists('~Connecting...') ||
                              await elementExists('//android.widget.TextView[contains(@text, "Connecting")]');
    console.log(`Searching driver screen active: ${isSearchingDriver}`);
    await driver.pause(5000);

    const video = await driver.stopRecordingScreen();
    fs.writeFileSync('/Users/radicalstart/.gemini/antigravity/brain/deb6f5ff-f7a6-41d7-b10f-310a461c3e60/scratch/phase3_video.mp4', video, 'base64');
    
    console.log('On-demand booking completed. Keeping the app in the foreground as requested.');
    console.log('App will remain open in foreground on Searching Driver screen. User can close manually.');
}

main().catch(async (e) => {
    console.error(e);
});
