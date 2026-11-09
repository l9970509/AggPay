import { scanBarcode, scanCore } from '@kit.ScanKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ScanService';
const DOMAIN: number = 0x0001;

export interface ScanOutcome {
  raw: string;
  scanType: string;
}

/**
 * 扫码能力封装，使用系统 Scan Kit 默认扫码界面：
 * 自动对焦/曝光/变焦由系统负责，并自带相册识码入口。
 */
export class ScanService {
  static async start(context: common.Context): Promise<ScanOutcome | undefined> {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    };
    try {
      const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(context, options);
      const raw: string = result.originalValue ?? '';
      const type: string = String(result.scanType ?? '');
      hilog.info(DOMAIN, TAG, 'scan ok, len=%{public}d', raw.length);
      return { raw: raw, scanType: type };
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'scan cancelled/failed: %{public}d %{public}s', e.code, e.message);
      return undefined;
    }
  }
}
