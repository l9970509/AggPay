import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ALL_CHANNELS, buildUri, channelById, isCodeDeepLink, launchParamsOf, PayChannel, PayMode } from '../model/PayChannel';
import { PayLauncher } from '../service/PayLauncher';
import { ScanService } from '../service/ScanService';
import { SettingsStore } from '../common/SettingsStore';
import { Haptics } from '../common/Haptics';
import { ChannelCard } from '../view/ChannelCard';
import { QuickAction } from '../view/QuickAction';

const TAG: string = 'IndexPage';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct Index {
  @StorageProp('topAvoidHeight') topAvoid: number = 38;
  @StorageLink('defaultChannelId') defaultChannelId: string = 'wechat';
  @StorageLink('hapticEnabled') hapticEnabled: boolean = true;
  @StorageLink('pendingChannel') pendingChannel: string = '';
  @StorageLink('pendingMode') pendingMode: string = '';
  @StorageLink('pendingTick') @Watch('onPendingChanged') pendingTick: number = 0;

  @State currentIndex: number = 0;
  @State showWechatGuide: boolean = false;
  @State guideMode: PayMode = PayMode.CODE;
  @State busy: boolean = false;
  /** 跳转过渡层：点击瞬间就铺上，遮住目标应用冷启动的空档 */
  @State launching: boolean = false;
  @State launchingName: string = '';
  @State launchingBrand: string = '#07C160';

  private swiperController: SwiperController = new SwiperController();

  aboutToAppear(): void {
    const idx: number = ALL_CHANNELS.findIndex((c: PayChannel) => c.id === this.defaultChannelId);
    this.currentIndex = idx >= 0 ? idx : 0;
    if (this.pendingChannel !== '') {
      this.consumePending();
    }
  }

  onPageShow(): void {
    // 从目标应用返回时收起过渡层
    this.launching = false;
    // 从设置页返回后同步默认渠道
    const idx: number = ALL_CHANNELS.findIndex((c: PayChannel) => c.id === this.defaultChannelId);
    if (idx >= 0 && this.pendingChannel === '') {
      this.currentIndex = idx;
    }
  }

  onPendingChanged(): void {
    if (this.pendingChannel === '') {
      return;
    }
    this.consumePending();
  }

  /** 处理来自桌面快捷方式 / 服务卡片 / 外部的直达参数 */
  private consumePending(): void {
    const channelId: string = this.pendingChannel;
    const mode: string = this.pendingMode;
    this.pendingChannel = '';
    this.pendingMode = '';

    if (mode === PayMode.SCAN) {
      this.handleScan();
      return;
    }
    const channel: PayChannel = channelById(channelId);
    const idx: number = ALL_CHANNELS.findIndex((c: PayChannel) => c.id === channel.id);
    if (idx >= 0) {
      this.currentIndex = idx;
    }
    const payMode: PayMode = mode === PayMode.COLLECT ? PayMode.COLLECT : PayMode.CODE;
    this.handlePay(channel, payMode);
  }

  /** 铺过渡层，用当前渠道的品牌色做转圈 */
  private showLaunchMask(channel: PayChannel): void {
    this.launchingName = channel.name;
    this.launchingBrand = channel.brand;
    this.launching = true;
  }

  private hideLaunchMask(): void {
    this.launching = false;
  }

  @Builder
  launchMask() {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(34)
        .height(34)
        .color(this.launchingBrand)

      Text(`正在调起${this.launchingName}`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_bg'))
    .transition(TransitionEffect.OPACITY.animation({ duration: 120, curve: Curve.EaseOut }))
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2200 });
  }

  private async handlePay(channel: PayChannel, mode: PayMode): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    if (this.hapticEnabled) {
      Haptics.tap();
    }

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.guideMode = mode;

    // 先把过渡层铺上再发起跳转：目标应用冷启动的 200~600ms 由它兜住，
    // 用户看到的是「正在调起」，而不是点完没反应的静止画面。
    this.showLaunchMask(channel);

    // 两条渠道都走「快捷方式同款 Want 参数」直达，比 scheme 少一次链接解析。
    const params: Record<string, string> = launchParamsOf(channel.id, mode);
    if (Object.keys(params).length > 0) {
      const direct: boolean = await PayLauncher.launchWithParams(context, channel.bundleName, 'EntryAbility', 'entry', params);
      this.busy = false;
      if (direct) {
        // 微信没有给「收款码」单独注册入口，落在收付款页后仍需点一次「二维码收款」
        if (mode === PayMode.COLLECT) {
          this.toast('已打开微信收付款，点「二维码收款」即可');
        }
        return;
      }
      hilog.warn(DOMAIN, TAG, 'param path failed, fallback to deep link: %{public}s', channel.id);
    }

    const uri: string = buildUri(channel.id, mode);
    // 走到这里说明参数路径没生效（应用改版等），微信需按引导手动进入
    const needsManual: boolean = !isCodeDeepLink(channel.id) || channel.id === 'wechat';

    const result = await PayLauncher.launch(context, uri, channel.bundleName, needsManual);
    this.busy = false;
    // 兜底路径无法确定目标页，收起过渡层，把引导交给用户
    this.hideLaunchMask();

    if (!result.success) {
      this.hideLaunchMask();
      this.toast(result.message);
      hilog.warn(DOMAIN, TAG, 'launch failed for %{public}s', channel.id);
      return;
    }

    if (needsManual && !SettingsStore.hasSeenWechatGuide()) {
      SettingsStore.markWechatGuideSeen();
      this.showWechatGuide = true;
    }
  }

  private async handleScan(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    if (this.hapticEnabled) {
      Haptics.tap();
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const outcome = await ScanService.start(context);
    this.busy = false;
    if (outcome === undefined || outcome.raw === '') {
      return;
    }
    try {
      await this.getUIContext().getRouter().pushUrl({
        url: 'pages/ScanResultPage',
        params: { raw: outcome.raw }
      });
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'pushUrl failed: %{public}s', e.message);
    }
  }

  private setDefault(channel: PayChannel): void {
    if (this.defaultChannelId === channel.id) {
      this.toast(`${channel.name}已经是默认方式`);
      return;
    }
    this.defaultChannelId = channel.id;
    SettingsStore.setDefaultChannel(channel.id);
    if (this.hapticEnabled) {
      Haptics.success();
    }
    this.toast(`已将「${channel.name}」设为默认支付方式`);
  }

  private showAddWidgetGuide(): void {
    this.getUIContext().showAlertDialog({
      title: '添加到桌面',
      message: '1. 回到桌面，双指捏合或长按空白处\n2. 点击「服务卡片 / 窗口小工具」\n3. 找到「聚合支付」，选择 2×2 卡片拖到桌面\n\n也可以长按桌面上的应用图标，直接使用「微信付款码」「支付宝付款码」「扫一扫」快捷菜单。',
      confirm: {
        value: '知道了',
        action: () => {
        }
      }
    });
  }

  @Builder
  headerBar() {
    Row() {
      Column({ space: 4 }) {
        Text('聚合支付')
          .fontSize(27)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('一步直达，不用再翻应用')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Stack() {
        Image($r('app.media.ic_settings'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_primary'))
      }
      .width(42)
      .height(42)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(21)
      .onClick(() => {
        this.getUIContext().getRouter().pushUrl({ url: 'pages/SettingsPage' });
      })
    }
    .width('100%')
    .margin({ bottom: 18 })
  }

  @Builder
  channelSwiper() {
    Swiper(this.swiperController) {
      ForEach(ALL_CHANNELS, (channel: PayChannel) => {
        ChannelCard({
          channel: channel,
          isDefault: this.defaultChannelId === channel.id,
          onPay: () => {
            this.handlePay(channel, PayMode.CODE);
          },
          onLongPress: () => {
            this.setDefault(channel);
          }
        })
      }, (channel: PayChannel) => channel.id)
    }
    .width('100%')
    .height(298)
    .index(this.currentIndex)
    .loop(false)
    .indicator(new DotIndicator()
      .itemWidth(6)
      .itemHeight(6)
      .selectedItemWidth(20)
      .selectedItemHeight(6)
      .color('#C9CDD6')
      .selectedColor($r('app.color.text_primary'))
      .bottom(0))
    .onChange((index: number) => {
      if (this.currentIndex !== index) {
        this.currentIndex = index;
        if (this.hapticEnabled) {
          Haptics.tap();
        }
      }
    })
  }

  @Builder
  quickActions() {
    Row({ space: 12 }) {
      QuickAction({
        title: '扫一扫',
        icon: $r('app.media.ic_scan'),
        accent: '#5B5BF7',
        tint: '#EEEEFE',
        onTap: () => {
          this.handleScan();
        }
      })
        .layoutWeight(1)

      QuickAction({
        title: '收款码',
        icon: $r('app.media.ic_collect'),
        accent: '#07C160',
        tint: '#E8F9F0',
        onTap: () => {
          // 跟随当前展示的卡片，而不是默认渠道，避免「看到微信却跳到支付宝」
          this.handlePay(ALL_CHANNELS[this.currentIndex], PayMode.COLLECT);
        }
      })
        .layoutWeight(1)

      QuickAction({
        title: '桌面卡片',
        icon: $r('app.media.ic_widget'),
        accent: '#F59E0B',
        tint: '#FEF4E6',
        onTap: () => {
          this.showAddWidgetGuide();
        }
      })
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 28 })
  }

  @Builder
  tipCard() {
    Row({ space: 10 }) {
      Image($r('app.media.ic_tips'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.text_tertiary'))
        .margin({ top: 1 })

      Text('左右滑动切换渠道，长按卡片设为默认；桌面长按应用图标可直接进入付款码。')
        .fontSize(11.5)
        .lineHeight(18)
        .fontColor($r('app.color.text_tertiary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg_sub'))
    .borderRadius(16)
    .margin({ top: 14 })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  wechatGuideSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#7A000000')
        .onClick(() => {
          this.showWechatGuide = false;
        })

      Column() {
        Column()
          .width(38)
          .height(4)
          .borderRadius(2)
          .backgroundColor('#33000000')
          .margin({ bottom: 20 })

        Row({ space: 10 }) {
          Stack() {
            Circle()
              .width(40)
              .height(40)
              .fill('#E8F9F0')
            Image($r('app.media.ic_wechat'))
              .width(22)
              .height(22)
              .fillColor('#07C160')
          }

          Text(this.guideMode === PayMode.COLLECT ? '微信收款码多一步' : '微信付款码多一步')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .margin({ bottom: 14 })

        Text(this.guideMode === PayMode.COLLECT
          ? '微信未开放收款码的直达链接，已为你打开微信。进入后按下面路径切换：'
          : '微信未开放付款码的直达链接，已为你打开微信。进入后按下面的路径：')
          .fontSize(13.5)
          .lineHeight(21)
          .fontColor($r('app.color.text_secondary'))

        Column({ space: 10 }) {
          Row({ space: 12 }) {
            Text('1')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .backgroundColor('#07C160')
              .borderRadius(10)
            Text('点击底部「我」')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')

          Row({ space: 12 }) {
            Text('2')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .backgroundColor('#07C160')
              .borderRadius(10)
            Text(this.guideMode === PayMode.COLLECT
              ? '进入「服务」→「收付款」→ 点「二维码收款」'
              : '进入「服务」→「收付款」，默认就是付款码')
              .layoutWeight(1)
              .lineHeight(20)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg_sub'))
        .borderRadius(16)
        .margin({ top: 16 })

        Text('兜底提示：微信新版已支持直达，这里是备用路径。也可以长按微信图标添加「收付款」服务卡片，或点收付款页底部的「添加到桌面」。支付宝本身支持直达。')
          .fontSize(11.5)
          .lineHeight(17)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 12 })

        Button('知道了')
          .width('100%')
          .height(46)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.text_primary'))
          .borderRadius(23)
          .margin({ top: 20 })
          .onClick(() => {
            this.showWechatGuide = false;
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 28 })
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius({ topLeft: 28, topRight: 28 })
      .transition(TransitionEffect.translate({ y: 320 }).animation({ duration: 260, curve: Curve.FastOutSlowIn }))
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack() {
      // 背景与顶部光晕
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.page_bg'))

      Column()
        .width(420)
        .height(420)
        .radialGradient({
          center: ['50%', '50%'],
          radius: 210,
          colors: [['#1A07C160', 0.0], ['#0007C160', 1.0]]
        })
        .position({ x: '46%', y: -170 })

      Scroll() {
        Column() {
          this.headerBar()
          this.channelSwiper()
          this.quickActions()
          this.tipCard()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: this.topAvoid + 10, bottom: 34 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      if (this.showWechatGuide) {
        this.wechatGuideSheet()
      }

      if (this.launching) {
        this.launchMask()
      }
    }
    .width('100%')
    .height('100%')
  }
}
