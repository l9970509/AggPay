import { common, Want } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { classify, ScanKind, ScanVerdict } from '../service/ScanRouter';
import { PayLauncher } from '../service/PayLauncher';
import { Haptics } from '../common/Haptics';

const TAG: string = 'ScanResultPage';
const DOMAIN: number = 0x0001;

interface ScanParams {
  raw: string;
}

@Entry
@Component
struct ScanResultPage {
  @StorageProp('topAvoidHeight') topAvoid: number = 38;
  @StorageLink('hapticEnabled') hapticEnabled: boolean = true;

  @State private verdict: ScanVerdict = classify('');
  @State private rawText: string = '';
  @State private busy: boolean = false;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as ScanParams;
    if (params !== undefined && params !== null) {
      this.rawText = params.raw ?? '';
    }
    this.verdict = classify(this.rawText);
  }

  private accentColor(): string {
    switch (this.verdict.kind) {
      case ScanKind.WECHAT_PAY:
      case ScanKind.WECHAT_SCHEME:
        return '#07C160';
      case ScanKind.ALIPAY_PAY:
      case ScanKind.ALIPAY_SCHEME:
        return '#1677FF';
      default:
        return '#5B5BF7';
    }
  }

  private iconRes(): Resource {
    switch (this.verdict.kind) {
      case ScanKind.WECHAT_PAY:
      case ScanKind.WECHAT_SCHEME:
        return $r('app.media.ic_wechat');
      case ScanKind.ALIPAY_PAY:
      case ScanKind.ALIPAY_SCHEME:
        return $r('app.media.ic_alipay');
      case ScanKind.WEB:
        return $r('app.media.ic_link');
      default:
        return $r('app.media.ic_text');
    }
  }

  private async copyText(): Promise<void> {
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.rawText);
      await pasteboard.getSystemPasteboard().setData(data);
      this.getUIContext().getPromptAction().showToast({ message: '已复制' });
      if (this.hapticEnabled) {
        Haptics.success();
      }
    } catch (err) {
      this.getUIContext().getPromptAction().showToast({ message: '复制失败' });
    }
  }

  private async openTarget(): Promise<void> {
    if (this.busy) {
      return;
    }
    if (this.verdict.kind === ScanKind.PLAIN) {
      await this.copyText();
      return;
    }
    this.busy = true;
    if (this.hapticEnabled) {
      Haptics.tap();
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    if (this.verdict.kind === ScanKind.WEB) {
      try {
        const want: Want = {
          action: 'ohos.want.action.viewData',
          entities: ['entity.system.browsable'],
          uri: this.verdict.uri
        };
        await context.startAbility(want);
      } catch (err) {
        const e = err as BusinessError;
        hilog.warn(DOMAIN, TAG, 'open browser failed: %{public}s', e.message);
        this.getUIContext().getPromptAction().showToast({ message: '没有可用的浏览器' });
      }
      this.busy = false;
      return;
    }

    const bundleName: string = this.verdict.kind === ScanKind.WECHAT_PAY || this.verdict.kind === ScanKind.WECHAT_SCHEME
      ? 'com.tencent.wechat'
      : 'com.alipay.mobile.client';
    const result = await PayLauncher.launch(context, this.verdict.uri, bundleName, false);
    this.busy = false;
    if (!result.success) {
      this.getUIContext().getPromptAction().showToast({ message: result.message });
    }
  }

  @Builder
  navBar() {
    Row({ space: 12 }) {
      Stack() {
        Image($r('app.media.ic_arrow_left'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_primary'))
      }
      .width(40)
      .height(40)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(20)
      .onClick(() => {
        this.getUIContext().getRouter().back();
      })

      Text('扫码结果')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Blank()
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.navBar()

          // 结果主卡
          Column({ space: 14 }) {
            Stack() {
              Circle()
                .width(64)
                .height(64)
                .fill(this.accentColor())
                .opacity(0.1)
              Image(this.iconRes())
                .width(30)
                .height(30)
                .fillColor(this.accentColor())
            }

            Text(this.verdict.title)
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))

            Text(this.verdict.hint)
              .fontSize(12.5)
              .lineHeight(19)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .padding({ left: 12, right: 12 })
          }
          .width('100%')
          .padding({ top: 30, bottom: 28, left: 20, right: 20 })
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(24)
          .alignItems(HorizontalAlign.Center)

          // 原文
          Column({ space: 8 }) {
            Row() {
              Text('识别内容')
                .fontSize(11)
                .fontColor($r('app.color.text_tertiary'))
              Blank()
              Text('长按可复制')
                .fontSize(11)
                .fontColor($r('app.color.text_tertiary'))
            }
            .width('100%')

            Text(this.verdict.display)
              .fontSize(13)
              .lineHeight(20)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .copyOption(CopyOptions.LocalDevice)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_bg_sub'))
          .borderRadius(18)
          .margin({ top: 14 })
          .alignItems(HorizontalAlign.Start)

          // 主操作
          Button(this.verdict.actionLabel)
            .width('100%')
            .height(48)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor(this.accentColor())
            .borderRadius(24)
            .margin({ top: 22 })
            .enabled(!this.busy)
            .opacity(this.busy ? 0.6 : 1)
            .onClick(() => {
              this.openTarget();
            })

          if (this.verdict.kind !== ScanKind.PLAIN) {
            Button('复制内容')
              .width('100%')
              .height(46)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(23)
              .margin({ top: 10 })
              .onClick(() => {
                this.copyText();
              })
          }

          Button('继续扫')
            .width('100%')
            .height(46)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .margin({ top: 6 })
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: this.topAvoid + 8, bottom: 30 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
