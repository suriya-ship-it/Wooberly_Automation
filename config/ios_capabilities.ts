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

const DEVICE_NAME = process.env.IOS_DEVICE_NAME || 'Iphone 15';
const UDID = process.env.IOS_UDID || '00008120-00066C6C2144A01E';
const PLATFORM_VERSION = process.env.IOS_PLATFORM_VERSION || '26.6.1';

export const iOSCommonCapabilities = {
  platformName: 'iOS',
  'appium:automationName': 'XCUITest',
  'appium:deviceName': DEVICE_NAME,
  'appium:udid': UDID,
  'appium:platformVersion': PLATFORM_VERSION,
  'appium:newCommandTimeout': 300,
  'appium:noReset': true,
  'appium:fullReset': false,
  'appium:autoAcceptAlerts': false,
  'appium:connectHardwareKeyboard': false,
  'appium:shouldTerminateApp': false,
};

export const iOSRiderCapabilities = {
  ...iOSCommonCapabilities,
  'appium:bundleId': process.env.IOS_RIDER_BUNDLE_ID || 'com.radicalstart.wooberly',
  'appium:wdaLocalPort': 8100,
};

export const iOSDriverCapabilities = {
  ...iOSCommonCapabilities,
  'appium:bundleId': process.env.IOS_DRIVER_BUNDLE_ID || 'com.radicalstart.wooberlydriver',
  'appium:wdaLocalPort': 8101,
};

export const iOSAppStoreCapabilities = {
  ...iOSCommonCapabilities,
  'appium:bundleId': 'com.apple.AppStore',
  'appium:wdaLocalPort': 8102,
};
