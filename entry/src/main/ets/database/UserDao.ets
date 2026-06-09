import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';
import { UserModel, UserFormData } from '../models/UserModel';
import { DataStatus } from '../models/OrganizationModel';
import { Logger } from '../utils/Logger';

const TABLE_NAME: string = 'users';

export class UserDao {
  private getStore(): relationalStore.RdbStore {
    return DatabaseManager.getInstance().getStore();
  }

  async insert(formData: UserFormData): Promise<number> {
    const now = Date.now();
    try {
      return await this.getStore().insert(TABLE_NAME, {
        'student_no': formData.studentNo,
        'name': formData.name,
        'class_id': formData.classId ?? 0,
        'class_name': formData.className,
        'face_image_path': '',
        'face_enrolled': 0,
        'status': DataStatus.ACTIVE,
        'created_at': now,
        'updated_at': now
      });
    } catch (error) {
      Logger.error('添加用户失败: %{public}s', JSON.stringify(error));
      const caughtError = error as Error;
      throw new Error(caughtError.message);
    }
  }

  async update(id: number, formData: UserFormData): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    await this.getStore().update({
      'student_no': formData.studentNo,
      'name': formData.name,
      'class_id': formData.classId ?? 0,
      'class_name': formData.className,
      'updated_at': Date.now()
    }, predicates);
  }

  async updateFaceImage(id: number, imagePath: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    await this.getStore().update({
      'face_image_path': imagePath,
      'face_enrolled': 1,
      'updated_at': Date.now()
    }, predicates);
  }

  async archive(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    await this.getStore().update({
      'status': DataStatus.ARCHIVED,
      'updated_at': Date.now()
    }, predicates);
  }

  async restore(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    await this.getStore().update({
      'status': DataStatus.ACTIVE,
      'updated_at': Date.now()
    }, predicates);
  }

  async getById(id: number): Promise<UserModel | null> {
    return await this.queryOne('WHERE u.id = ?', [id]);
  }

  async getByStudentNo(studentNo: string): Promise<UserModel | null> {
    return await this.queryOne('WHERE u.student_no = ?', [studentNo]);
  }

  async getAll(includeArchived: boolean = false): Promise<UserModel[]> {
    const where = includeArchived ? '' : 'WHERE u.status = 1';
    return await this.queryUsers(`${where} ORDER BY u.student_no`, []);
  }

  async getByClassId(classId: number): Promise<UserModel[]> {
    return await this.queryUsers(
      'WHERE u.class_id = ? AND u.status = 1 ORDER BY u.student_no',
      [classId]
    );
  }

  async getByCourseId(courseId: number): Promise<UserModel[]> {
    return await this.queryUsers(
      `INNER JOIN course_enrollments e ON e.user_id = u.id
       WHERE e.course_id = ? AND e.status = 1 AND u.status = 1
       ORDER BY u.student_no`,
      [courseId]
    );
  }

  async search(keyword: string): Promise<UserModel[]> {
    const pattern = `%${keyword}%`;
    return await this.queryUsers(
      `WHERE u.status = 1
       AND (u.student_no LIKE ? OR u.name LIKE ?)
       ORDER BY u.student_no`,
      [pattern, pattern]
    );
  }

  async getCount(): Promise<number> {
    return await this.getScalar(
      'SELECT COUNT(*) FROM users WHERE status = 1',
      []
    );
  }

  async getEnrolledCount(): Promise<number> {
    return await this.getScalar(
      'SELECT COUNT(*) FROM users WHERE status = 1 AND face_enrolled = 1',
      []
    );
  }

  private async queryOne(whereSql: string, args: relationalStore.ValueType[]): Promise<UserModel | null> {
    const users = await this.queryUsers(`${whereSql} LIMIT 1`, args);
    return users.length > 0 ? users[0] : null;
  }

  private async queryUsers(joinAndWhereSql: string, args: relationalStore.ValueType[]): Promise<UserModel[]> {
    const sql =
      `SELECT u.*, COALESCE(c.name, u.class_name, '') AS resolved_class_name
       FROM users u
       LEFT JOIN admin_classes c ON c.id = u.class_id
       ${joinAndWhereSql}`;
    try {
      const resultSet = await this.getStore().querySql(sql, args);
      const users: UserModel[] = [];
      try {
        while (resultSet.goToNextRow()) {
          users.push(this.mapResultSetToUser(resultSet));
        }
      } finally {
        resultSet.close();
      }
      return users;
    } catch (error) {
      Logger.error('查询用户失败: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  private async getScalar(sql: string, args: relationalStore.ValueType[]): Promise<number> {
    try {
      const resultSet = await this.getStore().querySql(sql, args);
      try {
        return resultSet.goToFirstRow() ? resultSet.getLong(0) : 0;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      Logger.error('查询用户统计失败: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  private mapResultSetToUser(resultSet: relationalStore.ResultSet): UserModel {
    return {
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
    };
  }
}
