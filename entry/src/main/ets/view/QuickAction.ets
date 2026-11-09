@Component
export struct QuickAction {
  title: string = '';
  subtitle: string = '';
  icon: Resource = $r('app.media.ic_scan');
  accent: string = '#5B5BF7';
  tint: string = '#EEEEFE';
  onTap: () => void = () => {
  };

  @State private pressed: boolean = false;

  build() {
    Column() {
      Stack() {
        Circle()
          .width(42)
          .height(42)
          .fill(this.tint)
        Image(this.icon)
          .width(21)
          .height(21)
          .fillColor(this.accent)
      }
      .margin({ bottom: 8 })

      Text(this.title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      if (this.subtitle !== '') {
        Text(this.subtitle)
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 2 })
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
    .scale({ x: this.pressed ? 0.95 : 1, y: this.pressed ? 0.95 : 1 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onClick(() => {
      this.onTap();
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}
