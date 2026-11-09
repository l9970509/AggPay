import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window, display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SettingsStore } from '../common/SettingsStore';

const TAG: string = 'EntryAbility';
const DOMAIN: number = 0x0001;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');

    SettingsStore.init(this.context);

    AppStorage.setOrCreate<string>('defaultChannelId', SettingsStore.getDefaultChannel());
    AppStorage.setOrCreate<boolean>('hapticEnabled', SettingsStore.isHapticEnabled());
    AppStorage.setOrCreate<string>('pendingChannel', '');
    AppStorage.setOrCreate<string>('pendingMode', '');
    AppStorage.setOrCreate<number>('pendingTick', 0);
    AppStorage.setOrCreate<number>('topAvoidHeight', 38);

    this.consumeWant(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant');
    this.consumeWant(want);
  }

  /**
   * 桌面快捷方式 / 服务卡片 / 外部拉起时，把参数写入 AppStorage，
   * 首页监听到变化后自动执行对应动作，实现「一步直达」。
   */
  private consumeWant(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined || params === null) {
      return;
    }
    let channel: string = params['channel'] as string;
    const mode: string = params['mode'] as string;
    if (channel === undefined || channel === '') {
      return;
    }
    // 卡片上的「收款码」等入口不带具体渠道，落到用户设定的默认渠道
    if (channel === 'current' || channel === 'default') {
      channel = SettingsStore.getDefaultChannel();
    }
    AppStorage.setOrCreate<string>('pendingChannel', channel);
    AppStorage.setOrCreate<string>('pendingMode', mode === undefined ? 'code' : mode);
    AppStorage.setOrCreate<number>('pendingTick', Date.now());
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      this.applyImmersive(windowStage);
    });
  }

  /** 沉浸式 + 记录状态栏高度，供页面顶部留白 */
  private applyImmersive(windowStage: window.WindowStage): void {
    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true);
      const avoidArea: window.AvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const topPx: number = avoidArea.topRect.height;
      const density: number = display.getDefaultDisplaySync().densityPixels;
      const topVp: number = density > 0 ? topPx / density : 38;
      AppStorage.setOrCreate<number>('topAvoidHeight', Math.max(24, Math.round(topVp)));
      hilog.info(DOMAIN, TAG, 'top avoid height vp: %{public}d', Math.round(topVp));
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'immersive skipped: %{public}s', (err as Error).message);
    }
  }
}
