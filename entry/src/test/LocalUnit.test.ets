import { describe, it, expect } from '@ohos/hypium';
import { DateUtils } from '../main/ets/utils/DateUtils';
import { AttendanceRules } from '../main/ets/utils/AttendanceRules';
import { CheckInStatus } from '../main/ets/models/AttendanceModel';

export default function localUnitTest() {
  describe('FaceCheckCoreRules', () => {
    it('formatsDateAndTime', 0, () => {
      const timestamp = new Date(2026, 0, 2, 3, 4, 5).getTime();
      expect(DateUtils.formatDate(timestamp)).assertEqual('2026-01-02');
      expect(DateUtils.formatTime(timestamp)).assertEqual('03:04:05');
    });

    it('marksCheckInAtDeadlineAsNormal', 0, () => {
      expect(AttendanceRules.resolveStatus(1000, 1000)).assertEqual(CheckInStatus.NORMAL);
    });

    it('marksCheckInAfterDeadlineAsLate', 0, () => {
      expect(AttendanceRules.resolveStatus(1001, 1000)).assertEqual(CheckInStatus.LATE);
    });

    it('supportsSessionsWithoutDeadline', 0, () => {
      expect(AttendanceRules.resolveStatus(1001, 0)).assertEqual(CheckInStatus.NORMAL);
    });
  });
}
