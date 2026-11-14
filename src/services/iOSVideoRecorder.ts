import * as fs from 'fs';
import * as path from 'path';

const ROOT = path.resolve(__dirname, '../');
const TEST_REF_DIR = path.join(ROOT, 'Test reference');

export class iOSVideoRecorder {
  private static isRecording = false;

  public static async start(driver: any): Promise<boolean> {
    try {
      if (!fs.existsSync(TEST_REF_DIR)) {
        fs.mkdirSync(TEST_REF_DIR, { recursive: true });
      }

      console.log('[iOSVideoRecorder] Starting Appium native screen recording for iOS...');
      await driver.startRecordingScreen({
        videoType: 'mp4',
        timeLimit: '1800', // 30 minutes max
        videoQuality: 'medium',
        fps: 30,
      });
      this.isRecording = true;
      return true;
    } catch (err) {
      console.warn('[iOSVideoRecorder] Failed to start native iOS recording:', err);
      this.isRecording = false;
      return false;
    }
  }

  public static async stop(driver: any, filename = 'latest_ios_execution.mp4'): Promise<string | null> {
    if (!this.isRecording) {
      console.log('[iOSVideoRecorder] No active recording to stop.');
      return null;
    }

    try {
      console.log('[iOSVideoRecorder] Stopping screen recording and extracting video buffer...');
      const base64Data = await driver.stopRecordingScreen();
      this.isRecording = false;

      if (!base64Data) {
        console.warn('[iOSVideoRecorder] Empty video data returned from driver.');
        return null;
      }

      const filePath = path.join(TEST_REF_DIR, filename);
      const buffer = Buffer.from(base64Data, 'base64');
      fs.writeFileSync(filePath, buffer);

      console.log(`[iOSVideoRecorder] Video saved successfully (${(buffer.length / (1024 * 1024)).toFixed(2)} MB) -> ${filePath}`);
      return filePath;
    } catch (err) {
      console.error('[iOSVideoRecorder] Failed to stop recording or save video:', err);
      this.isRecording = false;
      return null;
    }
  }
}
