import { execSync, spawn, ChildProcess } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

const ROOT = path.resolve(__dirname, '../');
const ARTIFACT_DIR = process.env.ARTIFACT_DIR || '/Users/radicalstart/.gemini/antigravity/brain/126f99c7-a5bf-4b42-8f1c-38b58afc2632';
const DEBUG_DIR = path.join(ROOT, 'debug_screenshots');
const SCRIPT_PATH = path.join(ROOT, 'scripts/ios_visual_engine.py');

export interface VisibleElement {
  caption: string;
  id?: string;
  estimated_uid?: string;
}

export type IOSScreenType =
  | 'SYSTEM_PERMISSION'
  | 'APP_STORE'
  | 'LANDING_SCREEN'
  | 'PHONE_INPUT'
  | 'OTP_INPUT'
  | 'DRIVER_ONLINE'
  | 'RIDER_HOME'
  | 'TRIP_LIFECYCLE'
  | 'UNKNOWN';

export interface ScreenAnalysis {
  screenType: IOSScreenType;
  screenshotPath: string;
  elements: VisibleElement[];
  detectedFeatures: string[];
}

export class iOSVisualAnalyzer {
  private static keepAwakeProcess: ChildProcess | null = null;

  /**
   * Prevents the iPhone display from sleeping during test automation.
   */
  public static startKeepAwake(durationSec: number = 1800) {
    if (this.keepAwakeProcess) return;
    try {
      const child = spawn('python3', [SCRIPT_PATH, 'keep_awake', String(durationSec)], {
        cwd: ROOT,
        stdio: 'ignore',
        detached: false,
      });
      this.keepAwakeProcess = child;
      console.log('💡 [iOS Visual Analyzer] Screen keep-awake power assertion activated.');
    } catch (err) {
      console.warn('[iOS Visual Analyzer] Failed to start keep-awake assertion:', err);
    }
  }

  /**
   * Releases screen keep-awake assertion.
   */
  public static stopKeepAwake() {
    if (this.keepAwakeProcess) {
      try {
        this.keepAwakeProcess.kill('SIGTERM');
      } catch {}
      this.keepAwakeProcess = null;
      console.log('💡 [iOS Visual Analyzer] Screen keep-awake released.');
    }
  }

  /**
   * Captures a native screenshot from the iPhone 15 and persists to debug & artifact directories.
   */
  public static captureScreen(stepName: string): string {
    const filename = `${stepName}.png`;
    const debugPath = path.join(DEBUG_DIR, filename);
    const artifactPath = path.join(ARTIFACT_DIR, filename);

    try {
      if (!fs.existsSync(DEBUG_DIR)) fs.mkdirSync(DEBUG_DIR, { recursive: true });
      if (!fs.existsSync(ARTIFACT_DIR)) fs.mkdirSync(ARTIFACT_DIR, { recursive: true });
    } catch {}

    try {
      execSync(`python3 "${SCRIPT_PATH}" screenshot "${debugPath}"`, {
        cwd: ROOT,
        stdio: 'pipe',
        env: process.env,
        timeout: 35000,
      });

      try {
        fs.copyFileSync(debugPath, artifactPath);
      } catch {}

      console.log(`📸 [iOS Visual Analyzer] Screenshot saved: ${filename}`);
      return debugPath;
    } catch (err) {
      console.warn(`[iOS Visual Analyzer] Failed to capture screenshot for ${stepName}:`, err);
      return '';
    }
  }

  /**
   * Retrieves all interactive accessibility elements currently visible on the iPhone screen.
   */
  public static getVisibleElements(): VisibleElement[] {
    try {
      const output = execSync(`python3 "${SCRIPT_PATH}" list`, {
        cwd: ROOT,
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe'],
        env: process.env,
        timeout: 35000,
      });
      return JSON.parse(output.trim());
    } catch (err) {
      console.warn('[iOS Visual Analyzer] Failed to retrieve visible elements:', err);
      return [];
    }
  }

  /**
   * Automatically inspects the current screen for iOS system permission alerts and grants them.
   */
  public static autoHandlePermissions(contextLabel = 'step'): boolean {
    try {
      const output = execSync(`python3 "${SCRIPT_PATH}" permissions`, {
        cwd: ROOT,
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe'],
        env: process.env,
        timeout: 35000,
      });
      const res = JSON.parse(output.trim());
      if (res && res.handled) {
        console.log(`🛡️  [iOS Permission Handler] Automatically granted permission: "${res.action}"`);
        this.captureScreen(`ios_permission_granted_${contextLabel}`);
        return true;
      }
    } catch {}
    return false;
  }

  /**
   * Taps an element matching the given regex pattern or text.
   */
  public static tapElement(pattern: string): boolean {
    try {
      console.log(`👉 [iOS Action] Tapping element matching: "${pattern}"...`);
      execSync(`python3 "${SCRIPT_PATH}" tap "${pattern}"`, {
        cwd: ROOT,
        stdio: 'inherit',
        env: process.env,
        timeout: 35000,
      });
      return true;
    } catch (err) {
      console.warn(`[iOS Action] Failed to tap element matching "${pattern}"`);
      return false;
    }
  }

  /**
   * Performs comprehensive screenshot capture and visual state analysis of the active page.
   */
  public static analyzeCurrentScreen(stepName: string): ScreenAnalysis {
    console.log(`\n🔍 [iOS Visual Analyzer] Analyzing page: "${stepName}"...`);
    const screenshotPath = this.captureScreen(stepName);
    const elements = this.getVisibleElements();

    const captions = elements.map((e) => e.caption.toLowerCase());
    const detectedFeatures: string[] = [];
    let screenType: IOSScreenType = 'UNKNOWN';

    // 1. Check for iOS System Permission Alert
    const hasPermissionAlert = captions.some(
      (c) =>
        c.includes('allow while using app') ||
        c.includes('while using the app') ||
        c.includes('would like to send you notifications') ||
        c.includes('use your location')
    );
    if (hasPermissionAlert) {
      screenType = 'SYSTEM_PERMISSION';
      detectedFeatures.push('System Permission Prompt');
    }

    // 2. Check for App Store
    else if (captions.some((c) => c.includes('get, in-app purchases') || c.includes('redownload') || c.includes('what’s new') || c.includes('today, tab') || c.includes('today, button') || c.includes('app store') || c.includes('age rating'))) {
      screenType = 'APP_STORE';
      detectedFeatures.push('Apple App Store Page');
    }

    // 3. Check for Landing / Get Started Onboarding
    else if (captions.some((c) => c.includes('get started') || c.includes('continue') || c.includes('welcome'))) {
      screenType = 'LANDING_SCREEN';
      detectedFeatures.push('Get Started / Onboarding');
    }

    // 4. Check for Phone Number Input
    else if (captions.some((c) => c.includes('phone') || c.includes('mobile') || c.includes('+91') || c.includes('enter your mobile'))) {
      screenType = 'PHONE_INPUT';
      detectedFeatures.push('Phone Number Input Screen');
    }

    // 5. Check for OTP Input
    else if (captions.some((c) => c.includes('otp') || c.includes('verification') || c.includes('enter code') || c.includes('verify'))) {
      screenType = 'OTP_INPUT';
      detectedFeatures.push('OTP Verification Screen');
    }

    // 6. Check for Driver Dashboard / Go Online
    else if (captions.some((c) => c === 'go' || c.includes('go online') || c.includes('offline') || c.includes('you are offline'))) {
      screenType = 'DRIVER_ONLINE';
      detectedFeatures.push('Driver Dashboard / Go Online Screen');
    }

    // 7. Check for Rider Home / Booking
    else if (captions.some((c) => c.includes('where to') || c.includes('book now') || c.includes('choose a ride') || c.includes('pickup'))) {
      screenType = 'RIDER_HOME';
      detectedFeatures.push('Rider Home / Ride Booking Screen');
    }

    // 8. Check for Trip Lifecycle
    else if (captions.some((c) => c.includes('accept ride') || c.includes('arrived') || c.includes('start trip') || c.includes('end trip') || c.includes('rate your ride') || c.includes('trip complete'))) {
      screenType = 'TRIP_LIFECYCLE';
      detectedFeatures.push('Active Trip Lifecycle Screen');
    }

    console.log(`📋 [iOS Visual Analyzer] Screen Classified: ${screenType} (Detected: ${detectedFeatures.join(', ') || 'General UI'})`);
    return {
      screenType,
      screenshotPath,
      elements,
      detectedFeatures,
    };
  }
}
