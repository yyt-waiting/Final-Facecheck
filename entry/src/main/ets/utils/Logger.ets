import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0xFF00;
const TAG: string = 'FaceCheck';

/**
 * 日志工具类
 */
export class Logger {
  static debug(msg: string, ...args: string[]): void {
    hilog.debug(DOMAIN, TAG, msg, ...args);
  }

  static info(msg: string, ...args: string[]): void {
    hilog.info(DOMAIN, TAG, msg, ...args);
  }

  static warn(msg: string, ...args: string[]): void {
    hilog.warn(DOMAIN, TAG, msg, ...args);
  }

  static error(msg: string, ...args: string[]): void {
    hilog.error(DOMAIN, TAG, msg, ...args);
  }
}
