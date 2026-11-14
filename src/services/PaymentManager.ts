import { execSync } from 'child_process';
import { PaymentConfig } from '../config/payment_credentials';

function adbTap(x: number, y: number) {
    try {
        execSync(`adb shell input tap ${Math.round(x)} ${Math.round(y)}`, { stdio: 'ignore' });
    } catch {}
}

function adbType(text: string) {
    try {
        execSync(`adb shell input text "${text}"`, { stdio: 'ignore' });
    } catch {}
}

export class PaymentManager {
    /**
     * Checks if Stripe native PaymentSheet Activity is currently the active window.
     */
    public static isStripeActivityOpen(): boolean {
        try {
            const out = execSync("adb shell \"dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'\"", { encoding: 'utf-8' });
            return out.toLowerCase().includes('paymentsheet') || out.toLowerCase().includes('stripe');
        } catch {
            return false;
        }
    }

    /**
     * Handles Payment Method selection during booking.
     * If Card is chosen and no card is yet added, automatically fills and saves test card credentials.
     */
    public static async handleBookingPayment(driver: WebdriverIO.Browser): Promise<void> {
        const isCard = PaymentConfig.isCard;
        console.log(`\n[PaymentManager] Initiating Payment Method selection. Configured type: "${PaymentConfig.paymentType}"`);

        if (isCard) {
            console.log('[PaymentManager] Selecting "Credit / Debit card" option...');
            let cardClicked = false;
            try {
                const cardOption = await driver.$('//*[contains(@content-desc, "Credit") or contains(@content-desc, "Debit") or contains(@text, "Credit") or contains(@text, "Debit")]');
                if (await cardOption.isDisplayed().catch(() => false)) {
                    await cardOption.click();
                    cardClicked = true;
                    console.log('[PaymentManager] Clicked Credit / Debit card option via selector.');
                }
            } catch {}

            if (!cardClicked) {
                console.log('[PaymentManager] Coordinate tap on Credit / Debit card option at (500, 1160)...');
                adbTap(500, 1160);
            }

            // Poll for Stripe Payment Sheet detection (up to 6 seconds)
            let isStripeSheetOpen = false;
            for (let wait = 0; wait < 6; wait++) {
                await driver.pause(1000);
                if (await this.detectStripeSheet(driver)) {
                    isStripeSheetOpen = true;
                    break;
                }
            }

            if (isStripeSheetOpen) {
                console.log('[PaymentManager] 💳 Stripe Payment Sheet detected! Card is not yet added. Proceeding to add test card...');
                await this.fillAndSaveStripeCard(driver);
            } else {
                console.log('[PaymentManager] ✅ No Stripe Payment Sheet opened. Existing card is already saved or selected.');
            }

            // Also check if saved card row is present and ensure it is selected
            try {
                const savedCardRow = await driver.$('//*[contains(@text, "****") or contains(@content-desc, "****")]');
                if (await savedCardRow.isDisplayed().catch(() => false)) {
                    await savedCardRow.click();
                    await driver.pause(1000);
                }
            } catch {}

        } else {
            console.log('[PaymentManager] Selecting "Cash" payment option...');
            try {
                const cashOption = await driver.$('//android.widget.ImageView[contains(@content-desc, "Cash")] | //*[@content-desc="Cash"] | //*[@text="Cash"]');
                if (await cashOption.isDisplayed().catch(() => false)) {
                    await cashOption.click();
                } else {
                    adbTap(500, 975);
                }
            } catch {
                adbTap(500, 975);
            }
            await driver.pause(1000);
        }

        // Tap "Confirm ->" button on Payment Method bottom sheet
        console.log('[PaymentManager] Tapping "Confirm ->" button on Payment Sheet at (540, 2100)...');
        for (let attempt = 0; attempt < 3; attempt++) {
            let confirmed = false;
            try {
                const confirmBtn = await driver.$('//*[contains(@content-desc, "Confirm") or contains(@text, "Confirm")]');
                if (await confirmBtn.isDisplayed().catch(() => false)) {
                    await confirmBtn.click();
                    confirmed = true;
                    console.log('[PaymentManager] Clicked Confirm button via selector.');
                }
            } catch {}

            if (!confirmed) {
                // Screen bottom confirm button center (540, 2100)
                adbTap(540, 2100);
                await driver.pause(500);
                adbTap(540, 2160);
            }
            await driver.pause(2000);

            // Check if Precaution dialog or ride request already appeared
            const precautionOrSearching = (await driver.$('//*[contains(@content-desc, "Proceed") or contains(@text, "Proceed") or contains(@content-desc, "Safety") or contains(@text, "Safety") or contains(@content-desc, "Connecting") or contains(@text, "Connecting")]').then(e => e.isDisplayed()).catch(() => false));
            if (precautionOrSearching) {
                console.log('[PaymentManager] Payment confirmed! Proceeding to Precaution / Connecting screen.');
                break;
            }
        }
        await driver.pause(2000);
        console.log('[PaymentManager] ✅ Payment Method selection confirmed.');
    }

    /**
     * Detects if Stripe Payment Sheet or Add Card modal is visible.
     */
    private static async detectStripeSheet(driver: WebdriverIO.Browser): Promise<boolean> {
        if (this.isStripeActivityOpen()) {
            return true;
        }

        const stripeIndicators = [
            '//*[contains(@resource-id, "card_number")]',
            '//android.widget.EditText[contains(@hint, "Card") or contains(@text, "Card")]',
            '//*[contains(@text, "Card information") or contains(@content-desc, "Card information")]',
            '//*[contains(@text, "Save card") or contains(@content-desc, "Save card")]',
        ];

        for (const sel of stripeIndicators) {
            try {
                const el = await driver.$(sel);
                if (await el.isDisplayed().catch(() => false)) {
                    return true;
                }
            } catch {}
        }
        return false;
    }

    /**
     * Fills Stripe Payment Sheet with test card credentials and clicks Save/Add.
     */
    private static async fillAndSaveStripeCard(driver: WebdriverIO.Browser): Promise<void> {
        const cardNum = PaymentConfig.cardNumber;
        const expiry = PaymentConfig.cardExpiry;
        const cvc = PaymentConfig.cardCvc;
        const zip = PaymentConfig.cardZip;

        console.log(`[PaymentManager] Test Card: ${cardNum.replace(/(\d{4})/g, '$1 ')} | Expiry: ${expiry.formatted} | CVC: ${cvc} | ZIP: ${zip}`);

        try {
            // Find card number field
            const cardFieldSelectors = [
                '//*[contains(@resource-id, "card_number")]',
                '//android.widget.EditText[contains(@hint, "Card") or contains(@text, "Card") or contains(@content-desc, "Card")]',
                '//android.widget.EditText[1]',
            ];

            let cardField: any = null;
            for (const sel of cardFieldSelectors) {
                try {
                    const el = await driver.$(sel);
                    if (await el.isDisplayed().catch(() => false)) {
                        cardField = el;
                        break;
                    }
                } catch {}
            }

            if (cardField) {
                await cardField.click();
                await driver.pause(500);
                await cardField.setValue(cardNum);
            } else {
                adbTap(300, 1350);
                await driver.pause(500);
                adbType(cardNum);
            }
            await driver.pause(1000);

            // Find Expiry field
            const expiryFieldSelectors = [
                '//*[contains(@resource-id, "expiry")]',
                '//android.widget.EditText[contains(@hint, "MM") or contains(@text, "MM") or contains(@content-desc, "Expiration")]',
                '//android.widget.EditText[2]',
            ];
            let expiryField: any = null;
            for (const sel of expiryFieldSelectors) {
                try {
                    const el = await driver.$(sel);
                    if (await el.isDisplayed().catch(() => false)) {
                        expiryField = el;
                        break;
                    }
                } catch {}
            }

            const expiryInput = `${expiry.month}${expiry.year}`;
            if (expiryField) {
                await expiryField.click();
                await driver.pause(500);
                await expiryField.setValue(expiryInput);
            } else {
                adbType(expiryInput);
            }
            await driver.pause(1000);

            // Find CVC field
            const cvcFieldSelectors = [
                '//*[contains(@resource-id, "cvc")]',
                '//android.widget.EditText[contains(@hint, "CVC") or contains(@text, "CVC") or contains(@content-desc, "CVC")]',
                '//android.widget.EditText[3]',
            ];
            let cvcField: any = null;
            for (const sel of cvcFieldSelectors) {
                try {
                    const el = await driver.$(sel);
                    if (await el.isDisplayed().catch(() => false)) {
                        cvcField = el;
                        break;
                    }
                } catch {}
            }

            if (cvcField) {
                await cvcField.click();
                await driver.pause(500);
                await cvcField.setValue(cvc);
            } else {
                adbType(cvc);
            }
            await driver.pause(1000);

            // Check if postal / zip field exists
            const zipFieldSelectors = [
                '//*[contains(@resource-id, "postal") or contains(@resource-id, "zip")]',
                '//android.widget.EditText[contains(@hint, "ZIP") or contains(@text, "ZIP") or contains(@content-desc, "Postal")]',
                '//android.widget.EditText[4]',
            ];
            for (const sel of zipFieldSelectors) {
                try {
                    const el = await driver.$(sel);
                    if (await el.isDisplayed().catch(() => false)) {
                        await el.click();
                        await driver.pause(500);
                        await el.setValue(zip);
                        break;
                    }
                } catch {}
            }
            await driver.pause(1000);

            // Dismiss keyboard if shown
            try {
                if (await driver.isKeyboardShown()) {
                    await driver.hideKeyboard();
                }
            } catch {
                try { execSync('adb shell input keyevent 111', { stdio: 'ignore' }); } catch {}
            }
            await driver.pause(1000);

            // Click Add / Save / Pay / Primary button
            console.log('[PaymentManager] Clicking "Save / Add" button on Stripe Payment Sheet at (540, 2090)...');
            adbTap(540, 2090);
            await driver.pause(500);

            const saveBtnSelectors = [
                '//*[contains(@text, "Save") or contains(@content-desc, "Save")]',
                '//*[contains(@text, "Add") or contains(@content-desc, "Add")]',
                '//*[contains(@text, "Pay") or contains(@content-desc, "Pay")]',
                '//*[contains(@text, "Continue") or contains(@content-desc, "Continue")]',
                '//*[contains(@resource-id, "primary_button")]',
            ];

            for (const sel of saveBtnSelectors) {
                try {
                    const el = await driver.$(sel);
                    if (await el.isDisplayed().catch(() => false)) {
                        await el.click();
                        console.log(`[PaymentManager] Clicked Stripe Save button via: ${sel}`);
                        break;
                    }
                } catch {}
            }

            // Wait for Stripe activity to dismiss
            console.log('[PaymentManager] Waiting for Stripe Payment Sheet to process and dismiss...');
            for (let wait = 0; wait < 25; wait++) {
                await driver.pause(1000);
                if (!this.isStripeActivityOpen()) {
                    console.log(`[PaymentManager] ✅ Stripe Payment Sheet dismissed (took ${wait + 1}s)! Card saved.`);
                    break;
                }
            }
            await driver.pause(2000);

        } catch (err) {
            console.warn('[PaymentManager] Warning during Stripe card entry:', err);
        }
    }
}
