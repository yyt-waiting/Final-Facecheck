import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';
import { AdminClass, Course, DataStatus } from '../models/OrganizationModel';
import { Logger } from '../utils/Logger';

export class OrganizationDao {
  private getStore(): relationalStore.RdbStore {
    return DatabaseManager.getInstance().getStore();
  }

  async insertClass(name: string, grade: string = '', major: string = ''): Promise<number> {
    const now = Date.now();
    return await this.getStore().insert('admin_classes', {
      'name': name.trim(),
      'grade': grade.trim(),
      'major': major.trim(),
      'status': DataStatus.ACTIVE,
      'created_at': now,
      'updated_at': now
    });
  }

  async ensureClass(name: string): Promise<number> {
    const normalized = name.trim() || '未分班';
    const existing = await this.getClassByName(normalized);
    if (existing) {
      if (existing.status === DataStatus.ARCHIVED) {
        await this.updateClassStatus(existing.id, DataStatus.ACTIVE);
      }
      return existing.id;
    }
    return await this.insertClass(normalized);
  }

  async getClassByName(name: string): Promise<AdminClass | null> {
    const resultSet = await this.getStore().querySql(
      'SELECT * FROM admin_classes WHERE name = ? LIMIT 1',
      [name]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return this.mapClass(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getClassById(id: number): Promise<AdminClass | null> {
    const predicates = new relationalStore.RdbPredicates('admin_classes');
    predicates.equalTo('id', id);
    const resultSet = await this.getStore().query(predicates);
    try {
      if (resultSet.goToFirstRow()) {
        return this.mapClass(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getClasses(includeArchived: boolean = false): Promise<AdminClass[]> {
    const predicates = new relationalStore.RdbPredicates('admin_classes');
    if (!includeArchived) {
      predicates.equalTo('status', DataStatus.ACTIVE);
    }
    predicates.orderByAsc('name');
    const resultSet = await this.getStore().query(predicates);
    const classes: AdminClass[] = [];
    try {
      while (resultSet.goToNextRow()) {
        classes.push(this.mapClass(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return classes;
  }

  async updateClassStatus(id: number, status: DataStatus): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('admin_classes');
    predicates.equalTo('id', id);
    await this.getStore().update({
      'status': status,
      'updated_at': Date.now()
    }, predicates);
  }

  async insertCourse(code: string, name: string): Promise<number> {
    const now = Date.now();
    return await this.getStore().insert('courses', {
      'code': code.trim().toUpperCase(),
      'name': name.trim(),
      'status': DataStatus.ACTIVE,
      'created_at': now,
      'updated_at': now
    });
  }

  async getCourses(includeArchived: boolean = false): Promise<Course[]> {
    const predicates = new relationalStore.RdbPredicates('courses');
    if (!includeArchived) {
      predicates.equalTo('status', DataStatus.ACTIVE);
    }
    predicates.orderByAsc('code');
    const resultSet = await this.getStore().query(predicates);
    const courses: Course[] = [];
    try {
      while (resultSet.goToNextRow()) {
        courses.push(this.mapCourse(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return courses;
  }

  async getCourseById(id: number): Promise<Course | null> {
    const predicates = new relationalStore.RdbPredicates('courses');
    predicates.equalTo('id', id);
    const resultSet = await this.getStore().query(predicates);
    try {
      if (resultSet.goToFirstRow()) {
        return this.mapCourse(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getDefaultCourseId(): Promise<number> {
    const resultSet = await this.getStore().querySql(
      `SELECT id FROM courses
       WHERE status = 1
       ORDER BY CASE WHEN code = 'DEFAULT' THEN 0 ELSE 1 END, id
       LIMIT 1`
    );
    try {
      return resultSet.goToFirstRow() ? resultSet.getLong(0) : 0;
    } finally {
      resultSet.close();
    }
  }

  async updateCourseStatus(id: number, status: DataStatus): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('courses');
    predicates.equalTo('id', id);
    await this.getStore().update({
      'status': status,
      'updated_at': Date.now()
    }, predicates);
  }

  async setUserEnrollments(userId: number, courseIds: number[]): Promise<void> {
    const store = this.getStore();
    store.beginTransaction();
    try {
      await store.executeSql(
        'UPDATE course_enrollments SET status = 0 WHERE user_id = ?',
        [userId]
      );
      for (const courseId of courseIds) {
        await store.executeSql(
          `INSERT OR REPLACE INTO course_enrollments(course_id, user_id, status, created_at)
           VALUES(?, ?, 1, ?)`,
          [courseId, userId, Date.now()]
        );
      }
      store.commit();
    } catch (error) {
      store.rollBack();
      Logger.error('更新用户选课关系失败: %{public}s', JSON.stringify(error));
      const caughtError = error as Error;
      throw new Error(caughtError.message);
    }
  }

  async archiveUserEnrollments(userId: number): Promise<void> {
    await this.getStore().executeSql(
      'UPDATE course_enrollments SET status = 0 WHERE user_id = ?',
      [userId]
    );
  }

  async getCourseIdsForUser(userId: number): Promise<number[]> {
    const resultSet = await this.getStore().querySql(
      `SELECT course_id FROM course_enrollments
       WHERE user_id = ? AND status = 1
       ORDER BY course_id`,
      [userId]
    );
    const ids: number[] = [];
    try {
      while (resultSet.goToNextRow()) {
        ids.push(resultSet.getLong(0));
      }
    } finally {
      resultSet.close();
    }
    return ids;
  }

  async getEnrollmentCount(courseId: number): Promise<number> {
    const resultSet = await this.getStore().querySql(
      `SELECT COUNT(*)
       FROM course_enrollments e
       INNER JOIN users u ON u.id = e.user_id
       WHERE e.course_id = ? AND e.status = 1 AND u.status = 1`,
      [courseId]
    );
    try {
      return resultSet.goToFirstRow() ? resultSet.getLong(0) : 0;
    } finally {
      resultSet.close();
    }
  }

  private mapClass(resultSet: relationalStore.ResultSet): AdminClass {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      name: resultSet.getString(resultSet.getColumnIndex('name')),
      grade: resultSet.getString(resultSet.getColumnIndex('grade')),
      major: resultSet.getString(resultSet.getColumnIndex('major')),
      status: resultSet.getLong(resultSet.getColumnIndex('status')) as DataStatus,
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    };
  }

  private mapCourse(resultSet: relationalStore.ResultSet): Course {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      code: resultSet.getString(resultSet.getColumnIndex('code')),
      name: resultSet.getString(resultSet.getColumnIndex('name')),
      status: resultSet.getLong(resultSet.getColumnIndex('status')) as DataStatus,
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    };
  }
}
