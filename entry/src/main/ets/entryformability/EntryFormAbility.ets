import { formBindingData, FormExtensionAbility } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryFormAbility';
const DOMAIN: number = 0x0001;

/**
 * 桌面卡片宿主。卡片为静态入口，点击通过 postCardAction(router) 直接
 * 把 channel/mode 参数带进 EntryAbility，因此 onAddForm 无需准备数据。
 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN, TAG, 'onAddForm');
    return formBindingData.createFormBindingData({});
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN, TAG, 'onFormEvent: %{public}s', message);
  }
}
