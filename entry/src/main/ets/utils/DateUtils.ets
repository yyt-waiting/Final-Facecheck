/**
 * 日期时间工具类
 */
export class DateUtils {
  /**
   * 格式化时间戳为日期字符串
   */
  static formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = DateUtils.padZero(date.getMonth() + 1);
    const day = DateUtils.padZero(date.getDate());
    return `${year}-${month}-${day}`;
  }

  /**
   * 格式化时间戳为时间字符串
   */
  static formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = DateUtils.padZero(date.getHours());
    const minutes = DateUtils.padZero(date.getMinutes());
    const seconds = DateUtils.padZero(date.getSeconds());
    return `${hours}:${minutes}:${seconds}`;
  }

  /**
   * 格式化时间戳为完整日期时间字符串
   */
  static formatDateTime(timestamp: number): string {
    return `${DateUtils.formatDate(timestamp)} ${DateUtils.formatTime(timestamp)}`;
  }

  /**
   * 获取今天的开始时间戳
   */
  static getTodayStart(): number {
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    return now.getTime();
  }

  /**
   * 获取今天的结束时间戳
   */
  static getTodayEnd(): number {
    const now = new Date();
    now.setHours(23, 59, 59, 999);
    return now.getTime();
  }

  /**
   * 补零
   */
  private static padZero(num: number): string {
    return num < 10 ? `0${num}` : `${num}`;
  }
}
