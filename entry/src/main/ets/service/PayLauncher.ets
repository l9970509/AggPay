import { common, bundleManager, OpenLinkOptions, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PayLauncher';
const DOMAIN: number = 0x0001;

export interface LaunchResult {
  success: boolean;
  uri: string;
  /** 是否需要在目标应用内再走一步（微信付款码没有公开深链） */
  needsManualStep: boolean;
  message: string;
}

/**
 * 跨应用跳转能力封装。
 *
 * 策略：openLink(deep link) 优先 -> startAbility(显式包名) 兜底 -> 失败上报。
 * 依赖 module.json5 的 querySchemes 声明，否则系统会以 17700056 拦截。
 */
export class PayLauncher {
  /** 目标应用是否可能处理该深链（不保证一定能跳成功） */
  static canResolve(uri: string): boolean {
    try {
      return bundleManager.canOpenLink(uri);
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'canOpenLink failed: %{public}s', e.message);
      return false;
    }
  }

  static async launch(context: common.UIAbilityContext, uri: string,
    bundleName: string, needsManualStep: boolean): Promise<LaunchResult> {
    if (await PayLauncher.tryOpenLink(context, uri)) {
      return { success: true, uri, needsManualStep, message: '' };
    }
    if (await PayLauncher.tryStartAbility(context, uri, bundleName)) {
      return { success: true, uri, needsManualStep, message: '' };
    }
    return {
      success: false,
      uri,
      needsManualStep,
      message: '未能拉起目标应用，请确认已安装并更新到最新版本'
    };
  }

  private static async tryOpenLink(context: common.UIAbilityContext, uri: string): Promise<boolean> {
    try {
      const options: OpenLinkOptions = { appLinkingOnly: false };
      await context.openLink(uri, options);
      hilog.info(DOMAIN, TAG, 'openLink ok: %{public}s', uri);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'openLink failed: %{public}d %{public}s', e.code, e.message);
      return false;
    }
  }

  private static async tryStartAbility(context: common.UIAbilityContext, uri: string,
    bundleName: string): Promise<boolean> {
    try {
      const want: Want = {
        bundleName: bundleName,
        action: 'ohos.want.action.viewData',
        uri: uri
      };
      await context.startAbility(want);
      hilog.info(DOMAIN, TAG, 'startAbility ok with bundle: %{public}s', bundleName);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'startAbility failed: %{public}d %{public}s', e.code, e.message);
      return false;
    }
  }

  /**
   * 用目标应用「快捷方式」同款的 Want 参数直达指定页面。
   *
   * 微信：shortCutKey = shortCutPay / shortCutScan
   * 支付宝：appId = 20000056 / 10000007 / 20000123 + source = Harmony3DTouch
   *
   * 这类参数由目标应用自己解析，不做签名校验，所以显式拉起时带上同样参数即落到同一页。
   * 相对于 scheme，少一次 App Linking 解析，且不会因为 scheme 未注册而失败。
   */
  static async launchWithParams(context: common.UIAbilityContext, bundleName: string,
    abilityName: string, moduleName: string, parameters: Record<string, string>): Promise<boolean> {
    try {
      const want: Want = {
        bundleName: bundleName,
        moduleName: moduleName,
        abilityName: abilityName,
        parameters: parameters
      };
      await context.startAbility(want);
      hilog.info(DOMAIN, TAG, 'param launch ok: %{public}s (params=%{public}d)', bundleName, Object.keys(parameters).length);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'param launch failed: %{public}d %{public}s', e.code, e.message);
      return false;
    }
  }

  /** 供「添加桌面卡片」等场景打开系统设置页 */
  static async openWidgetSettings(context: common.UIAbilityContext): Promise<void> {
    try {
      const want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          settingsParamBundleName: 'com.aggpay.harmony'
        }
      };
      await context.startAbility(want);
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'open settings failed: %{public}s', e.message);
    }
  }
}
