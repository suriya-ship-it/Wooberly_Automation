import { execSync } from 'child_process';
import * as path from 'path';

export class DeviceManager {
    /**
     * Resolves the adb execution environment ensuring platform-tools is present in PATH.
     */
    private static getAdbEnv() {
        const env = { ...process.env };
        const sdkPlatformTools = path.join(
            process.env.HOME || '/Users/radicalstart',
            'Library/Android/sdk/platform-tools'
        );
        if (!env.PATH || !env.PATH.includes(sdkPlatformTools)) {
            env.PATH = `${sdkPlatformTools}:${env.PATH || ''}`;
        }
        return env;
    }

    /**
     * Executes an adb shell command safely.
     */
    public static runAdb(cmd: string): string {
        try {
            return execSync(`adb ${cmd}`, {
                env: this.getAdbEnv(),
                encoding: 'utf-8',
                stdio: ['ignore', 'pipe', 'ignore'],
            }).trim();
        } catch (err: any) {
            return err?.stdout ? String(err.stdout).trim() : '';
        }
    }

    /**
     * Fast-paths device wake and unlock in a single compound ADB call.
     */
    public static ensureDeviceReady(): boolean {
        console.log('[DeviceManager] Checking device status & waking screen...');
        // Execute compound shell commands in a single OS process
        this.runAdb('shell "input keyevent 224; wm dismiss-keyguard; input keyevent 82"');
        return true;
    }

    /**
     * Presses the Android HOME button (KEYCODE_HOME = 3).
     */
    public static pressHome(): void {
        console.log('[DeviceManager] Pressing HOME button...');
        this.runAdb('shell input keyevent 3');
    }

    /**
     * Checks if a package is currently installed on the device.
     */
    public static isPackageInstalled(packageName: string): boolean {
        const output = this.runAdb(`shell pm list packages ${packageName}`);
        return output.split('\n').some(line => line.trim() === `package:${packageName}`);
    }

    /**
     * Uninstalls a package from the device.
     */
    public static uninstallPackage(packageName: string): boolean {
        console.log(`[DeviceManager] Uninstalling existing package ${packageName}...`);
        const output = this.runAdb(`uninstall ${packageName}`);
        return output.includes('Success');
    }

    /**
     * Launches the Google Play Store directly with a deep link or market URL.
     */
    public static openPlayStoreUrl(urlOrPackage: string): void {
        let marketUrl = urlOrPackage;
        if (urlOrPackage.startsWith('http')) {
            try {
                const urlObj = new URL(urlOrPackage);
                const packageId = urlObj.searchParams.get('id');
                if (packageId) {
                    marketUrl = `market://details?id=${packageId}`;
                }
            } catch {}
        } else if (!urlOrPackage.startsWith('market://')) {
            marketUrl = `market://details?id=${urlOrPackage}`;
        }

        console.log(`[DeviceManager] Fast launching Play Store intent: ${marketUrl}`);
        this.runAdb(`shell am start -a android.intent.action.VIEW -d "${marketUrl}" com.android.vending`);
    }

    /**
     * Completely resets device state to clean baseline for auto-retry or re-initiation:
     * - Force-stops Rider and Driver apps
     * - Dismisses popups and keyboards, presses HOME
     * - Ensures device screen is awake and unlocked
     */
    public static async cleanSlateReset(): Promise<void> {
        console.log('\n[DeviceManager] 🧹 Performing Clean Slate Reset before flow initiation...');
        try {
            // Force stop both target apps
            this.runAdb('shell am force-stop com.radicalstart.wooberly');
            this.runAdb('shell am force-stop com.radicalstart.wooberlydriver');

            // Dismiss soft keyboard and return to home screen
            this.runAdb('shell input keyevent 4'); // BACK
            this.runAdb('shell input keyevent 3'); // HOME

            // Ensure screen is awake and unlocked
            this.ensureDeviceReady();
        } catch (err) {
            console.warn('[DeviceManager] Clean slate reset warning:', err);
        }
        console.log('[DeviceManager] ✅ Clean Slate Reset complete.\n');
    }
}
