import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';
import { AttendanceSession, SessionStatus } from '../models/AttendanceModel';
import { Logger } from '../utils/Logger';

const TABLE_NAME: string = 'attendance_sessions';

export class SessionDao {
  private getStore(): relationalStore.RdbStore {
    return DatabaseManager.getInstance().getStore();
  }

  async insert(
    title: string,
    courseId: number,
    startTime: number,
    lateTime: number,
    endTime: number
  ): Promise<number> {
    try {
      return await this.getStore().insert(TABLE_NAME, {
        'title': title,
        'course_id': courseId,
        'start_time': startTime,
        'late_time': lateTime,
        'end_time': endTime,
        'status': SessionStatus.IN_PROGRESS
      });
    } catch (error) {
      Logger.error('创建签到场次失败: %{public}s', JSON.stringify(error));
      const caughtError = error as Error;
      throw new Error(caughtError.message);
    }
  }

  async updateStatus(id: number, status: SessionStatus): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    await this.getStore().update({ 'status': status }, predicates);
  }

  async endSession(id: number, endTime: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    await this.getStore().update({
      'status': SessionStatus.ENDED,
      'end_time': endTime
    }, predicates);
  }

  async getActiveSession(): Promise<AttendanceSession | null> {
    const sessions = await this.querySessions(
      'WHERE s.status = ? ORDER BY s.start_time DESC LIMIT 1',
      [SessionStatus.IN_PROGRESS]
    );
    return sessions.length > 0 ? sessions[0] : null;
  }

  async getById(id: number): Promise<AttendanceSession | null> {
    const sessions = await this.querySessions('WHERE s.id = ? LIMIT 1', [id]);
    return sessions.length > 0 ? sessions[0] : null;
  }

  async getAll(): Promise<AttendanceSession[]> {
    return await this.querySessions('ORDER BY s.start_time DESC', []);
  }

  async delete(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    await this.getStore().delete(predicates);
  }

  private async querySessions(
    suffixSql: string,
    args: relationalStore.ValueType[]
  ): Promise<AttendanceSession[]> {
    try {
      const resultSet = await this.getStore().querySql(
        `SELECT s.*, COALESCE(c.name, '') AS course_name
         FROM attendance_sessions s
         LEFT JOIN courses c ON c.id = s.course_id
         ${suffixSql}`,
        args
      );
      const sessions: AttendanceSession[] = [];
      try {
        while (resultSet.goToNextRow()) {
          sessions.push({
            id: resultSet.getLong(resultSet.getColumnIndex('id')),
            title: resultSet.getString(resultSet.getColumnIndex('title')),
            courseId: resultSet.getLong(resultSet.getColumnIndex('course_id')),
            courseName: resultSet.getString(resultSet.getColumnIndex('course_name')),
            startTime: resultSet.getLong(resultSet.getColumnIndex('start_time')),
            lateTime: resultSet.getLong(resultSet.getColumnIndex('late_time')),
            endTime: resultSet.getLong(resultSet.getColumnIndex('end_time')),
            status: resultSet.getLong(resultSet.getColumnIndex('status')) as SessionStatus
          });
        }
      } finally {
        resultSet.close();
      }
      return sessions;
    } catch (error) {
      Logger.error('查询签到场次失败: %{public}s', JSON.stringify(error));
      return [];
    }
  }
}
