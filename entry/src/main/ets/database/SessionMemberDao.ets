import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';
import { UserModel } from '../models/UserModel';

export class SessionMemberDao {
  private getStore(): relationalStore.RdbStore {
    return DatabaseManager.getInstance().getStore();
  }

  async createSnapshot(sessionId: number, courseId: number): Promise<number> {
    const store = this.getStore();
    await store.executeSql(
      `INSERT OR IGNORE INTO session_members(session_id, user_id, class_id, course_id, created_at)
       SELECT ?, u.id, u.class_id, ?, ?
       FROM course_enrollments e
       INNER JOIN users u ON u.id = e.user_id
       WHERE e.course_id = ? AND e.status = 1 AND u.status = 1`,
      [sessionId, courseId, Date.now(), courseId]
    );
    return await this.getCount(sessionId);
  }

  async getCount(sessionId: number): Promise<number> {
    const resultSet = await this.getStore().querySql(
      'SELECT COUNT(*) FROM session_members WHERE session_id = ?',
      [sessionId]
    );
    try {
      return resultSet.goToFirstRow() ? resultSet.getLong(0) : 0;
    } finally {
      resultSet.close();
    }
  }

  async isMember(sessionId: number, userId: number): Promise<boolean> {
    const resultSet = await this.getStore().querySql(
      'SELECT 1 FROM session_members WHERE session_id = ? AND user_id = ? LIMIT 1',
      [sessionId, userId]
    );
    try {
      return resultSet.goToFirstRow();
    } finally {
      resultSet.close();
    }
  }

  async getMembers(sessionId: number): Promise<UserModel[]> {
    const resultSet = await this.getStore().querySql(
      `SELECT u.*, COALESCE(c.name, u.class_name, '') AS resolved_class_name
       FROM session_members sm
       INNER JOIN users u ON u.id = sm.user_id
       LEFT JOIN admin_classes c ON c.id = sm.class_id
       WHERE sm.session_id = ?
       ORDER BY u.student_no`,
      [sessionId]
    );
    const users: UserModel[] = [];
    try {
      while (resultSet.goToNextRow()) {
        users.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          studentNo: resultSet.getString(resultSet.getColumnIndex('student_no')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          classId: resultSet.getLong(resultSet.getColumnIndex('class_id')),
          className: resultSet.getString(resultSet.getColumnIndex('resolved_class_name')),
          faceImagePath: resultSet.getString(resultSet.getColumnIndex('face_image_path')),
          faceEnrolled: resultSet.getLong(resultSet.getColumnIndex('face_enrolled')) === 1,
          status: resultSet.getLong(resultSet.getColumnIndex('status')),
          createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
          updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
        });
      }
    } finally {
      resultSet.close();
    }
    return users;
  }

  async deleteBySessionId(sessionId: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('session_members');
    predicates.equalTo('session_id', sessionId);
    await this.getStore().delete(predicates);
  }
}
