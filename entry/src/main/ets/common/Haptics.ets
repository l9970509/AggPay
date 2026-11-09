import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'Haptics';
const DOMAIN: number = 0x0001;

/** 触感反馈：任何异常都静默降级，不影响主流程 */
export class Haptics {
  static tap(): void {
    const effect: vibrator.VibrateEffect = { type: 'time', duration: 12 };
    const attribute: vibrator.VibrateAttribute = { id: 0, usage: 'touch' };
    try {
      vibrator.startVibration(effect, attribute).catch((err: BusinessError) => {
        hilog.debug(DOMAIN, TAG, 'vibrate skipped: %{public}s', err.message);
      });
    } catch (err) {
      hilog.debug(DOMAIN, TAG, 'vibrate unavailable');
    }
  }

  static success(): void {
    const effect: vibrator.VibrateEffect = { type: 'time', duration: 24 };
    const attribute: vibrator.VibrateAttribute = { id: 0, usage: 'touch' };
    try {
      vibrator.startVibration(effect, attribute).catch((err: BusinessError) => {
        hilog.debug(DOMAIN, TAG, 'vibrate skipped: %{public}s', err.message);
      });
    } catch (err) {
      hilog.debug(DOMAIN, TAG, 'vibrate unavailable');
    }
  }
}
