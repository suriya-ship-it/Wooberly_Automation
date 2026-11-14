import * as path from 'path';
import * as fs from 'fs';
import { DeviceManager } from './DeviceManager';

export interface PageResponse {
    step: number;
    page: string;
    status: 'LOADED' | 'DETECTED' | 'ACTION_TAKEN' | 'ERROR';
    details?: string;
    timestamp: string;
    screenshotFile?: string;
}

export class PageTracker {
    private static stepCounter = 0;
    private static debugDir = path.resolve(__dirname, '../debug_screenshots');

    /**
     * Resets the step counter at the beginning of a test or retry attempt.
     */
    public static resetCounter() {
        this.stepCounter = 0;
    }

    /**
     * Captures screenshot of current page state and logs standardized JSON response.
     */
    public static recordPage(
        pageName: string,
        status: 'LOADED' | 'DETECTED' | 'ACTION_TAKEN' | 'ERROR' = 'LOADED',
        details?: string
    ): PageResponse {
        this.stepCounter++;
        const timestamp = new Date().toISOString();
        const safeName = pageName.toLowerCase().replace(/[^a-z0-9_]/g, '_');
        const filename = `step_${String(this.stepCounter).padStart(2, '0')}_${safeName}.png`;
        const screenshotPath = path.join(this.debugDir, filename);

        try {
            if (!fs.existsSync(this.debugDir)) {
                fs.mkdirSync(this.debugDir, { recursive: true });
            }
            DeviceManager.runAdb(`exec-out screencap -p > "${screenshotPath}"`);
        } catch (err) {
            console.warn(`[PageTracker] Screenshot capture failed for ${pageName}:`, err);
        }

        const response: PageResponse = {
            step: this.stepCounter,
            page: pageName,
            status,
            details,
            timestamp,
            screenshotFile: filename,
        };

        console.log(`\n========================================================================`);
        console.log(`📸 [PageTracker] Step #${response.step} | Page: ${response.page} | Status: ${response.status}`);
        if (details) console.log(`   Details: ${details}`);
        console.log(`   Screenshot: debug_screenshots/${filename}`);
        console.log(`========================================================================\n`);

        return response;
    }
}
