/**
 * 桌面服务卡片：2x2 四宫格，点击直达对应渠道与动作。
 * 通过 postCardAction(router) 把参数带进 EntryAbility，冷启动 / 热启动都能命中。
 */

@Entry
@Component
struct PayWidget {
  @Builder
  entryCell(icon: Resource, label: string, tint: string, accent: string, channel: string, mode: string) {
    Column({ space: 5 }) {
      Stack() {
        Circle()
          .width(34)
          .height(34)
          .fill(tint)
        Image(icon)
          .width(17)
          .height(17)
          .fillColor(accent)
      }

      Text(label)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          channel: channel,
          mode: mode
        }
      });
    })
  }

  build() {
    Column() {
      Row() {
        Text('聚合支付')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text('一键直达')
          .fontSize(9)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .padding({ left: 2, right: 2 })

      Column() {
        Row() {
          this.entryCell($r('app.media.ic_wechat'), '微信付款', '#E8F9F0', '#07C160', 'wechat', 'code')
          this.entryCell($r('app.media.ic_alipay'), '支付宝付款', '#E7F0FF', '#1677FF', 'alipay', 'code')
        }
        .layoutWeight(1)

        Row() {
          this.entryCell($r('app.media.ic_scan'), '扫一扫', '#EEEEFE', '#5B5BF7', 'any', 'scan')
          this.entryCell($r('app.media.ic_collect'), '收款码', '#FEF4E6', '#F59E0B', 'current', 'collect')
        }
        .layoutWeight(1)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(20)
  }
}
