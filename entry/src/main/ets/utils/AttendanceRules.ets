import { CheckInStatus } from '../models/AttendanceModel';

/**
 * 不依赖设备能力的签到规则，便于单元测试和复用。
 */
export class AttendanceRules {
  static resolveStatus(checkInTime: number, lateTime: number): CheckInStatus {
    if (lateTime > 0 && checkInTime > lateTime) {
      return CheckInStatus.LATE;
    }
    return CheckInStatus.NORMAL;
  }
}
