import { ALL_CHANNELS, PayChannel } from '../model/PayChannel';
import { SettingsStore } from '../common/SettingsStore';
import { Haptics } from '../common/Haptics';

@Entry
@Component
struct SettingsPage {
  @StorageProp('topAvoidHeight') topAvoid: number = 38;
  @StorageLink('defaultChannelId') defaultChannelId: string = 'wechat';
  @StorageLink('hapticEnabled') hapticEnabled: boolean = true;
  @State showCardGuide: boolean = false;

  private pickDefault(channel: PayChannel): void {
    this.defaultChannelId = channel.id;
    SettingsStore.setDefaultChannel(channel.id);
    if (this.hapticEnabled) {
      Haptics.tap();
    }
    this.getUIContext().getPromptAction().showToast({ message: `默认方式：${channel.name}` });
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

      Text('设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Blank()
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  @Builder
  spacer(height: number) {
    Row()
      .width('100%')
      .height(height)
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_tertiary'))
      .letterSpacing(0.6)
      .width('100%')
      .padding({ left: 4, bottom: 8 })
  }

  @Builder
  channelOption(channel: PayChannel) {
    Row({ space: 12 }) {
      Stack() {
        Circle()
          .width(36)
          .height(36)
          .fill(channel.id === 'wechat' ? '#E8F9F0' : '#E7F0FF')
        Image(channel.icon)
          .width(20)
          .height(20)
          .fillColor(channel.brand)
      }

      Column({ space: 2 }) {
        Text(channel.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(channel.id === 'alipay' ? '支持直达付款码' : '付款码需在微信内二次点击')
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      if (this.defaultChannelId === channel.id) {
        Image($r('app.media.ic_check'))
          .width(18)
          .height(18)
          .fillColor(channel.brand)
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 13, bottom: 13 })
    .borderRadius(14)
    .backgroundColor(this.defaultChannelId === channel.id ? $r('app.color.card_bg_sub') : Color.Transparent)
    .onClick(() => {
      this.pickDefault(channel);
    })
  }

  @Builder
  cardGuideSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#7A000000')
        .onClick(() => {
          this.showCardGuide = false;
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
            Image($r('app.media.ic_widget'))
              .width(22)
              .height(22)
              .fillColor('#07C160')
          }

          Text('微信也能一键出码')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .margin({ bottom: 14 })

        Text('本应用已能直接跳到微信收付款页。若某次微信更新导致直达失效，可以用微信自己的入口兜底 —— 微信也把「收付款」注册成了系统快捷方式，效果一样。')
          .fontSize(13.5)
          .lineHeight(21)
          .fontColor($r('app.color.text_secondary'))

        Column({ space: 12 }) {
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
            Text('长按桌面微信图标，点「服务卡片」')
              .fontSize(14)
              .lineHeight(20)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

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
            Text('选择「收付款」样式，添加到桌面')
              .fontSize(14)
              .lineHeight(20)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Row({ space: 12 }) {
            Text('3')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .backgroundColor('#07C160')
              .borderRadius(10)
            Text('以后点亮屏幕，点卡片直接出付款码')
              .fontSize(14)
              .lineHeight(20)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg_sub'))
        .borderRadius(16)
        .margin({ top: 16 })

        Row({ space: 8 }) {
          Image($r('app.media.ic_tips'))
            .width(14)
            .height(14)
            .fillColor('#BA7517')
            .margin({ top: 2 })
          Text('更简单的方式：微信「收付款」页底部直接有「添加到桌面」，加一个图标即可。支付宝用本应用卡片即直达，无需这一步。')
            .fontSize(11.5)
            .lineHeight(18)
            .fontColor($r('app.color.text_tertiary'))
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ top: 14 })

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
            this.showCardGuide = false;
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
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Scroll() {
          Column() {
            this.navBar()

            this.sectionTitle('默认支付方式')
            Column() {
              ForEach(ALL_CHANNELS, (channel: PayChannel) => {
                this.channelOption(channel)
              }, (channel: PayChannel) => channel.id)
            }
            .width('100%')
            .padding(6)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(20)

            this.spacer(22)
            this.sectionTitle('更快一步')

            Row({ space: 12 }) {
              Stack() {
                Circle()
                  .width(36)
                  .height(36)
                  .fill('#E8F9F0')
                Image($r('app.media.ic_widget'))
                  .width(20)
                  .height(20)
                  .fillColor('#07C160')
              }

              Column({ space: 3 }) {
                Text('直达失效时的备用方案')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Text('用微信自带图标，一样一点出码')
                  .fontSize(11)
                  .fontColor($r('app.color.text_tertiary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Image($r('app.media.ic_arrow_right'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(20)
            .onClick(() => {
              if (this.hapticEnabled) {
                Haptics.tap();
              }
              this.showCardGuide = true;
            })

            this.spacer(22)
            this.sectionTitle('交互')

            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text('触感反馈')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Text('点击、切换渠道时轻微振动')
                  .fontSize(11)
                  .fontColor($r('app.color.text_tertiary'))
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.hapticEnabled })
                .selectedColor('#07C160')
                .onChange((isOn: boolean) => {
                  this.hapticEnabled = isOn;
                  SettingsStore.setHapticEnabled(isOn);
                  if (isOn) {
                    Haptics.tap();
                  }
                })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(20)

            this.spacer(22)
            this.sectionTitle('关于直达能力')

            Column({ space: 10 }) {
              Row({ space: 8 }) {
                Text('支付宝')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1677FF')
                  .width(48)
                Text('付款码 / 扫一扫 / 收款码 均可直达')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .layoutWeight(1)
              }
              .width('100%')

              Row({ space: 8 }) {
                Text('微信')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#07C160')
                  .width(48)
                Text('收付款 / 扫一扫 均可直达（复用微信快捷方式参数）；收款码进页面后点一次「二维码收款」')
                  .fontSize(12)
                  .lineHeight(18)
                  .fontColor($r('app.color.text_secondary'))
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)

              Text('以上跳转均通过系统深链完成，聚合支付不读取、不存储任何支付信息。')
                .fontSize(11)
                .lineHeight(17)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .margin({ top: 2 })
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(20)
            .alignItems(HorizontalAlign.Start)

            Text('聚合支付 for HarmonyOS  ·  v1.0.0')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 26, bottom: 10 })
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

      if (this.showCardGuide) {
        this.cardGuideSheet()
      }
    }
    .width('100%')
    .height('100%')
  }
}
