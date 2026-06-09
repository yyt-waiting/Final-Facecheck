import { OrganizationDao } from '../database/OrganizationDao';
import { UserDao } from '../database/UserDao';
import { AdminClass, Course, DataStatus } from '../models/OrganizationModel';
import { UserModel } from '../models/UserModel';

export class OrganizationService {
  private organizationDao: OrganizationDao = new OrganizationDao();
  private userDao: UserDao = new UserDao();

  async getClasses(includeArchived: boolean = false): Promise<AdminClass[]> {
    return await this.organizationDao.getClasses(includeArchived);
  }

  async createClass(name: string, grade: string = '', major: string = ''): Promise<number> {
    if (name.trim() === '') {
      throw new Error('班级名称不能为空');
    }
    const existing = await this.organizationDao.getClassByName(name.trim());
    if (existing) {
      throw new Error('班级名称已存在');
    }
    return await this.organizationDao.insertClass(name, grade, major);
  }

  async archiveClass(id: number): Promise<void> {
    const users = await this.userDao.getByClassId(id);
    if (users.length > 0) {
      throw new Error('该班级仍有在读学生，请先调整学生班级');
    }
    await this.organizationDao.updateClassStatus(id, DataStatus.ARCHIVED);
  }

  async getCourses(includeArchived: boolean = false): Promise<Course[]> {
    return await this.organizationDao.getCourses(includeArchived);
  }

  async createCourse(code: string, name: string): Promise<number> {
    if (code.trim() === '' || name.trim() === '') {
      throw new Error('课程编号和名称不能为空');
    }
    return await this.organizationDao.insertCourse(code, name);
  }

  async archiveCourse(id: number): Promise<void> {
    await this.organizationDao.updateCourseStatus(id, DataStatus.ARCHIVED);
  }

  async getCourseMembers(courseId: number): Promise<UserModel[]> {
    return await this.userDao.getByCourseId(courseId);
  }

  async getUserCourseIds(userId: number): Promise<number[]> {
    return await this.organizationDao.getCourseIdsForUser(userId);
  }

  async setUserCourses(userId: number, courseIds: number[]): Promise<void> {
    await this.organizationDao.setUserEnrollments(userId, courseIds);
  }
}
