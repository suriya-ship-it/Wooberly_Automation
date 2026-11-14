import { Browser } from 'webdriverio';
import { DeviceManager } from '../services/DeviceManager';

export class PlayStorePage {
    private driver: Browser;

    constructor(driver: Browser) {
        this.driver = driver;
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * Rapidly checks for Play Store confirmation modals (e.g. "Over any network" or "Skip account setup").
     * Only executed reactively when needed.
     */
    public async handlePopupsAndDialogs(): Promise<void> {
        try {
            // 1. "Download over any network" or "Data charges may apply" prompt
            const networkRadio = await this.driver.$(
                '//android.widget.RadioButton[contains(@text, "Over any network") or contains(@text, "Now")] | //android.widget.TextView[contains(@text, "Over any network") or contains(@text, "Now")]'
            );
            if (await networkRadio.isDisplayed().catch(() => false)) {
                console.log('[PlayStorePage] Detected network preference dialog, selecting "Over any network"...');
                await networkRadio.click();
                const okBtn = await this.driver.$(
                    '//android.widget.Button[@text="OK" or @text="Ok" or @text="Download"] | //android.widget.TextView[@text="OK" or @text="Ok" or @text="Download"]'
                );
                if (await okBtn.isDisplayed().catch(() => false)) {
                    await okBtn.click();
                    console.log('[PlayStorePage] Confirmed network preference dialog.');
                }
            }

            // 2. "Complete account setup" modal (Add payment method prompt)
            const skipBtn = await this.driver.$(
                '//android.widget.Button[@text="Skip" or @text="SKIP" or contains(@text, "Continue later")] | //android.widget.TextView[@text="Skip" or @text="SKIP"]'
            );
            if (await skipBtn.isDisplayed().catch(() => false)) {
                console.log('[PlayStorePage] Detected "Complete account setup" modal, clicking "Skip"...');
                await skipBtn.click();
            }

            // 3. Play Protect or Terms agreement prompt
            const acceptBtn = await this.driver.$(
                '//android.widget.Button[@text="Accept" or @text="ACCEPT" or @text="Continue" or @text="CONTINUE"]'
            );
            if (await acceptBtn.isDisplayed().catch(() => false)) {
                console.log('[PlayStorePage] Detected agreement modal, clicking "Accept/Continue"...');
                await acceptBtn.click();
            }
        } catch {}
    }

    /**
     * Eagerly queries the primary action button (Install, Update, or Open) in a single unified XPath.
     * Accurately distinguishes between genuinely installed apps and in-progress/pending downloads.
     */
    public async initiateInstallation(targetPackageName?: string): Promise<'INSTALLING' | 'ALREADY_INSTALLED' | 'NOT_FOUND'> {
        const unifiedActionSelector = 
            '//android.widget.Button[@text="Install" or @content-desc="Install" or @text="Update" or @content-desc="Update" or @text="Open" or @content-desc="Open"] | ' +
            '//android.widget.TextView[@text="Install" or @content-desc="Install" or @text="Update" or @content-desc="Update" or @text="Open" or @content-desc="Open"]';
        const cancelSelector = '//android.widget.Button[@text="Cancel" or @content-desc="Cancel"]';
        const pendingSelector = '//*[contains(@text, "Pending") or contains(@text, "Installing") or contains(@text, "Downloading")]';

        const startTime = Date.now();
        // Give up to 10 seconds for store page metadata to load over network
        while (Date.now() - startTime < 10000) {
            try {
                // 1. Check if installation or download is already actively underway
                const cancelBtn = await this.driver.$(cancelSelector);
                const hasCancel = await cancelBtn.isDisplayed().catch(() => false);
                const pendingEl = await this.driver.$(pendingSelector);
                const isPending = await pendingEl.isDisplayed().catch(() => false);

                if (hasCancel || isPending) {
                    console.log('[PlayStorePage] ⚡ Active download or pending state detected. Proceeding to wait for completion...');
                    return 'INSTALLING';
                }

                // 2. Query action button
                const actionBtn = await this.driver.$(unifiedActionSelector);
                if (await actionBtn.isDisplayed().catch(() => false)) {
                    const btnText = (await actionBtn.getText().catch(() => '')) || 
                                    (await actionBtn.getAttribute('content-desc').catch(() => '')) || '';
                    const label = btnText.toLowerCase();

                    if (label.includes('open')) {
                        const isEnabled = await actionBtn.isEnabled().catch(() => false);
                        const isPkgInstalled = targetPackageName ? DeviceManager.isPackageInstalled(targetPackageName) : true;

                        if (isEnabled && !hasCancel && isPkgInstalled) {
                            console.log('[PlayStorePage] ⚡ "Open" button is active and package is verified on device. Application is already installed and up to date!');
                            return 'ALREADY_INSTALLED';
                        } else {
                            console.log('[PlayStorePage] ⚡ "Open" button is disabled or package installation is in progress. Waiting for installation...');
                            return 'INSTALLING';
                        }
                    }

                    if (label.includes('update')) {
                        console.log('[PlayStorePage] ⚡ "Update" button found. Clicking "Update"...');
                        await actionBtn.click();
                        await this.sleep(300);
                        await this.handlePopupsAndDialogs();
                        return 'INSTALLING';
                    }

                    if (label.includes('install')) {
                        console.log('[PlayStorePage] ⚡ "Install" button found. Clicking "Install"...');
                        await actionBtn.click();
                        await this.sleep(300);
                        await this.handlePopupsAndDialogs();
                        return 'INSTALLING';
                    }
                }
            } catch {}

            // If action button was not immediately found, check if a blocking modal is present
            await this.handlePopupsAndDialogs();
            await this.sleep(300);
        }

        console.warn('[PlayStorePage] ⚠️ Neither Install, Update, nor Open button was found on the page within 10s.');
        return 'NOT_FOUND';
    }

    /**
     * High-frequency polling until "Open" or "Uninstall" appears, or package is verified by OS PackageManager.
     */
    public async waitForInstallationCompletion(timeoutSec: number = 180, targetPackageName?: string): Promise<boolean> {
        console.log(`[PlayStorePage] Fast-polling for installation completion (timeout: ${timeoutSec}s)...`);
        const startTime = Date.now();
        const timeoutMs = timeoutSec * 1000;

        const completionSelector = 
            '//android.widget.Button[@text="Open" or @content-desc="Open" or @text="Uninstall" or @content-desc="Uninstall"] | ' +
            '//android.widget.TextView[@text="Open" or @content-desc="Open"]';
        const cancelSelector = '//android.widget.Button[@text="Cancel" or @content-desc="Cancel"]';

        while (Date.now() - startTime < timeoutMs) {
            try {
                // 1. OS-level package verification check
                if (targetPackageName && DeviceManager.isPackageInstalled(targetPackageName)) {
                    const elapsed = Math.round((Date.now() - startTime) / 1000);
                    console.log(`\n[PlayStorePage] ✅ Package "${targetPackageName}" confirmed installed via PackageManager in ~${elapsed}s!`);
                    await this.sleep(1000);
                    return true;
                }

                // 2. Play Store UI check (enabled Open button without active Cancel)
                const openBtn = await this.driver.$(completionSelector);
                const cancelBtn = await this.driver.$(cancelSelector);
                const hasCancel = await cancelBtn.isDisplayed().catch(() => false);
                const isOpenDisplayed = await openBtn.isDisplayed().catch(() => false);
                const isOpenEnabled = isOpenDisplayed ? await openBtn.isEnabled().catch(() => false) : false;

                if (isOpenDisplayed && isOpenEnabled && !hasCancel) {
                    const elapsed = Math.round((Date.now() - startTime) / 1000);
                    console.log(`\n[PlayStorePage] ✅ Installation completed in ~${elapsed}s! "Open" button is active.`);
                    return true;
                }

                await this.handlePopupsAndDialogs();
            } catch {}

            // High-frequency 600ms polling interval
            await this.sleep(600);
        }

        // Final fallback check via PackageManager before declaring failure
        if (targetPackageName && DeviceManager.isPackageInstalled(targetPackageName)) {
            console.log(`\n[PlayStorePage] ✅ Package "${targetPackageName}" confirmed installed on device after timeout window.`);
            return true;
        }

        console.log('\n[PlayStorePage] ⚠️ Timeout reached while waiting for installation in Play Store UI.');
        return false;
    }
}
