import { PayChannel } from '../model/PayChannel';

/** 条形码示意条：用固定宽度序列模拟真实码面，避免每次都重排 */
const BAR_WIDTHS: number[] = [3, 2, 5, 2, 3, 6, 2, 3, 2, 5, 3, 2, 6, 2, 3, 3, 2, 5, 2, 4];
const BAR_HEIGHTS: number[] = [24, 20, 24, 17, 24, 24, 20, 24, 17, 24, 24, 17, 24, 20, 24, 24, 20, 24, 17, 22];

@Component
export struct ChannelCard {
  channel: PayChannel = {} as PayChannel;
  isDefault: boolean = false;
  onPay: () => void = () => {
  };
  onLongPress: () => void = () => {
  };

  @State private pressed: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 品牌渐变底
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(30)
        .linearGradient({
          angle: 145,
          colors: [[this.channel.brandStart, 0.0], [this.channel.brandEnd, 1.0]]
        })

      // 右上角柔光
      Circle()
        .width(220)
        .height(220)
        .fill('#22FFFFFF')
        .position({ x: '62%', y: -70 })

      Column() {
        // 顶部：品牌 + 默认标记
        Row() {
          Row({ space: 10 }) {
            Stack() {
              Circle()
                .width(38)
                .height(38)
                .fill('#33FFFFFF')
              Image(this.channel.icon)
                .width(22)
                .height(22)
                .fillColor(Color.White)
            }

            Column({ space: 1 }) {
              Text(this.channel.name)
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text(this.channel.slogan)
                .fontSize(10)
                .fontColor('#B3FFFFFF')
                .letterSpacing(1.2)
            }
            .alignItems(HorizontalAlign.Start)
          }

          Blank()

          if (this.isDefault) {
            Text('默认')
              .fontSize(11)
              .fontColor(Color.White)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('#33FFFFFF')
              .borderRadius(20)
          }
        }
        .width('100%')

        Blank()

        // 中部：付款码示意图标
        Row() {
          Column() {
            Row({ space: 3 }) {
              ForEach(BAR_WIDTHS, (w: number, i: number) => {
                Column()
                  .width(w)
                  .height(BAR_HEIGHTS[i])
                  .borderRadius(1)
                  .backgroundColor(this.channel.brand)
              }, (w: number, i: number) => `${i}-${w}`)
            }
            .height(24)

            Text('付款码')
              .fontSize(11)
              .fontColor('#8A000000')
              .margin({ top: 6 })
              .letterSpacing(2)
          }
          .width(164)
          .height(86)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(18)
          .shadow({ radius: 18, color: '#33000000', offsetY: 6 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Blank()

        // 底部：动作提示
        Row({ space: 6 }) {
          Text('出示付款码')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          Image($r('app.media.ic_arrow_right'))
            .width(14)
            .height(14)
            .fillColor(Color.White)
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 22, right: 22, top: 22, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .borderRadius(30)
    .clip(true)
    .shadow({ radius: 26, color: '#2A000000', offsetY: 10 })
    .scale({ x: this.pressed ? 0.972 : 1, y: this.pressed ? 0.972 : 1 })
    .animation({ duration: 140, curve: Curve.EaseOut })
    .onClick(() => {
      this.onPay();
    })
    .gesture(LongPressGesture({ repeat: false })
      .onAction(() => {
        this.onLongPress();
      }))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}
