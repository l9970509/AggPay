import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'SettingsStore';
const DOMAIN: number = 0x0001;
const STORE_NAME: string = 'aggpay_settings';
const KEY_DEFAULT_CHANNEL: string = 'default_channel';
const KEY_HAPTIC: string = 'haptic_enabled';
const KEY_WECHAT_GUIDE: string = 'wechat_guide_shown';

/** 轻量偏好设置，基于首选项同步读写，供页面直接取值 */
export class SettingsStore {
  private static prefs: preferences.Preferences | undefined = undefined;

  static init(context: common.UIAbilityContext): void {
    try {
      SettingsStore.prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'init failed: %{public}s', (err as Error).message);
    }
  }

  static getDefaultChannel(): string {
    if (SettingsStore.prefs === undefined) {
      return 'wechat';
    }
    return SettingsStore.prefs.getSync(KEY_DEFAULT_CHANNEL, 'wechat') as string;
  }

  static setDefaultChannel(id: string): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    SettingsStore.prefs.putSync(KEY_DEFAULT_CHANNEL, id);
    SettingsStore.prefs.flush();
  }

  static isHapticEnabled(): boolean {
    if (SettingsStore.prefs === undefined) {
      return true;
    }
    return SettingsStore.prefs.getSync(KEY_HAPTIC, true) as boolean;
  }

  static setHapticEnabled(enabled: boolean): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    SettingsStore.prefs.putSync(KEY_HAPTIC, enabled);
    SettingsStore.prefs.flush();
  }

  static hasSeenWechatGuide(): boolean {
    if (SettingsStore.prefs === undefined) {
      return false;
    }
    return SettingsStore.prefs.getSync(KEY_WECHAT_GUIDE, false) as boolean;
  }

  static markWechatGuideSeen(): void {
    if (SettingsStore.prefs === undefined) {
      return;
    }
    SettingsStore.prefs.putSync(KEY_WECHAT_GUIDE, true);
    SettingsStore.prefs.flush();
  }
}
