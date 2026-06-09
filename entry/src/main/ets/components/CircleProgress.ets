/**
 * CircleProgress.ets — 圆环进度条组件
 * 用于出勤率展示（首页 statsPanel）和比对分数展示（签到结果）
 */
import { Colors } from '../utils/DesignTokens';

@Component
export struct CircleProgress {
  @Prop value: number = 0;        // 0.0 ~ 1.0
  @Prop size: number = 80;        // 圆环直径 vp
  @Prop strokeWidth: number = 8;  // 圆环线宽 vp
  @Prop color: string = Colors.primary;
  @Prop label: string = '';       // 底部标签文字（可选）
  @Prop showPercent: boolean = true;

  build() {
    Column() {
      Stack() {
        Circle({ width: this.size, height: this.size })
          .fill(Color.Transparent)
          .stroke(Colors.border)
          .strokeWidth(this.strokeWidth)

        Circle({ width: this.size, height: this.size })
          .fill(Color.Transparent)
          .stroke(this.color)
          .strokeWidth(this.strokeWidth)
          .strokeDashArray([this.value * Math.PI * this.size, 1000])
          .strokeLineCap(StrokeLineCap.Round)
          .rotate({ angle: -90 })

        if (this.showPercent) {
          Text(`${Math.round(this.value * 100)}%`)
            .fontSize(Math.round(this.size * 0.22))
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
        }
      }
      .width(this.size)
      .height(this.size)

      if (this.label !== '') {
        Text(this.label)
          .fontSize(12)
          .fontColor(Colors.textTertiary)
          .margin({ top: 8 })
      }
    }
  }
}
