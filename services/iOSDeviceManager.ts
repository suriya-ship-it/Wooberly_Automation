import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

function loadEnv() {
  const envPath = path.resolve(__dirname, '../.env');
  if (fs.existsSync(envPath)) {
    const lines = fs.readFileSync(envPath, 'utf-8').split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const index = trimmed.indexOf('=');
      if (index !== -1) {
        const key = trimmed.slice(0, index).trim();
        const val = trimmed.slice(index + 1).trim();
        if (!process.env[key]) {
          process.env[key] = val;
        }
      }
    }
  }
}

loadEnv();

const XCODE_DEV_DIR = '/Applications/Xcode.app/Contents/Developer';
const DEFAULT_UDID = process.env.IOS_UDID || '00008120-00066C6C2144A01E';

export class iOSDeviceManager {
  private static udid = DEFAULT_UDID;

  public static setUdid(udid: string) {
    this.udid = udid;
  }

  public static getUdid(): string {
    return this.udid;
  }

  /**
   * Run devicectl or xcrun commands targeted at the connected iPhone
   */
  public static runDevicectl(subcommand: string): string {
    const cmd = `DEVELOPER_DIR="${XCODE_DEV_DIR}" xcrun devicectl ${subcommand}`;
    try {
      return execSync(cmd, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
    } catch (err: any) {
      const output = err.stdout?.toString() || err.stderr?.toString() || err.message;
      return output.trim();
    }
  }

  /**
   * Verify if the iPhone 15 is connected and reachable
   */
  public static isDeviceConnected(): boolean {
    const output = this.runDevicectl('list devices');
    return output.includes(this.udid) || output.includes('Iphone 15') || output.includes('connected');
  }

  /**
   * Check whether device is locked
   */
  public static isLocked(): boolean {
    const output = this.runDevicectl(`device info lockState --device ${this.udid}`);
    return output.includes('passcodeRequired: true') || output.includes('unlockedSinceBoot: false');
  }

  private static installedCache = new Set<string>();

  /**
   * Check if a specific bundle ID is installed on the iPhone (checks both developer & App Store apps)
   */
  public static isAppInstalled(bundleId: string): boolean {
    if (this.installedCache.has(bundleId)) return true;

    const devOutput = this.runDevicectl(`device info apps --device ${this.udid}`);
    const lines = devOutput.split('\n');
    const inDevApps = lines.some((line) => {
      const parts = line.trim().split(/\s{2,}/);
      return parts.length >= 2 && parts[1].trim() === bundleId.trim();
    });
    if (inDevApps) {
      this.installedCache.add(bundleId);
      return true;
    }

    // Check App Store production apps via pymobiledevice3
    try {
      const pmdOutput = execSync(`python3 -m pymobiledevice3 apps query "${bundleId}" --native`, {
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 20000,
      });
      if (pmdOutput.includes(bundleId) && pmdOutput.includes('CFBundleIdentifier')) {
        this.installedCache.add(bundleId);
        return true;
      }
    } catch {
      return false;
    }
    return false;
  }

  /**
   * Wait for the device to be unlocked with passcode (polls for up to timeoutSec seconds)
   */
  public static async waitForUnlock(timeoutSec: number = 30): Promise<boolean> {
    if (!this.isLocked()) return true;

    console.log('\n🔒 [iOSDeviceManager] iPhone 15 is currently locked with a passcode.');
    console.log('👉 ACTION REQUIRED: Please unlock your iPhone screen now using your passcode to allow automation to continue.');

    const start = Date.now();
    while ((Date.now() - start) / 1000 < timeoutSec) {
      await new Promise((r) => setTimeout(r, 2000));
      if (!this.isLocked()) {
        console.log('\n🔓 [iOSDeviceManager] iPhone 15 is now unlocked! Proceeding...\n');
        return true;
      }
      const remaining = Math.round(timeoutSec - (Date.now() - start) / 1000);
      process.stdout.write(`\r⏳ Waiting for iPhone unlock... (${remaining}s remaining)`);
    }
    console.log('\n⚠️ [iOSDeviceManager] Timed out waiting for iPhone unlock.');
    return false;
  }

  /**
   * Launch an app on the physical iPhone, optionally with a payload URL and terminating existing instance
   */
  public static launchApp(bundleId: string, payloadUrl?: string, terminateExisting: boolean = false): boolean {
    let cmd = `device process launch --device ${this.udid}`;
    if (terminateExisting) {
      cmd += ' --terminate-existing';
    }
    if (payloadUrl) {
      cmd += ` --payload-url "${payloadUrl}"`;
    }
    cmd += ` ${bundleId}`;
    const output = this.runDevicectl(cmd);
    return output.includes('Launched application') || !output.toLowerCase().includes('error');
  }

  /**
   * Launch the Apple App Store directly to an app's public page.
   * Uses both Safari universal link dispatch and itms-apps scheme for maximum reliability across iOS 17/18.
   */
  public static openAppStorePage(appStoreUrl: string): boolean {
    const match = appStoreUrl.match(/id(\d+)/);
    const appId = match ? match[1] : '';

    console.log(`[iOSDeviceManager] Navigating directly to App Store page for ${appStoreUrl}...`);

    // 1. Launch MobileSafari with the public App Store URL - Safari automatically triggers
    // Apple's Universal Link dispatcher and takes the user directly to the app's App Store product page.
    let opened = this.launchApp('com.apple.mobilesafari', appStoreUrl, false);

    // 2. Direct itms-apps scheme fallback
    if (!opened && appId) {
      const itmsUrl = `itms-apps://apps.apple.com/app/id${appId}`;
      opened = this.launchApp('com.apple.AppStore', itmsUrl, true);
    }

    return opened;
  }
}
