import { UserDao } from '../database/UserDao';
import { OrganizationDao } from '../database/OrganizationDao';
import { UserModel, UserFormData } from '../models/UserModel';
import { UserStats } from '../models/AttendanceModel';
import { CameraAdapter } from '../kits/CameraAdapter';

/**
 * 用户业务服务
 */
export class UserService {
  private userDao: UserDao = new UserDao();
  private organizationDao: OrganizationDao = new OrganizationDao();

  /**
   * 注册新用户
   */
  async registerUser(formData: UserFormData): Promise<number> {
    const classId = formData.classId && formData.classId > 0
      ? formData.classId
      : await this.organizationDao.ensureClass(formData.className);
    const classInfo = await this.organizationDao.getClassById(classId);
    const normalized: UserFormData = {
      studentNo: formData.studentNo.trim(),
      name: formData.name.trim(),
      classId: classId,
      className: classInfo?.name ?? formData.className.trim(),
      courseIds: formData.courseIds
    };
    if (normalized.studentNo === '') {
      throw new Error('学号不能为空');
    }
    if (normalized.name === '') {
      throw new Error('姓名不能为空');
    }

    const existing = await this.userDao.getByStudentNo(normalized.studentNo);
    if (existing) {
      throw new Error(`学号 ${normalized.studentNo} 已被注册`);
    }

    const userId = await this.userDao.insert(normalized);
    let courseIds = normalized.courseIds ?? [];
    if (courseIds.length === 0) {
      const defaultCourseId = await this.organizationDao.getDefaultCourseId();
      if (defaultCourseId > 0) {
        courseIds = [defaultCourseId];
      }
    }
    await this.organizationDao.setUserEnrollments(userId, courseIds);
    return userId;
  }

  /**
   * 更新用户信息
   */
  async updateUser(id: number, formData: UserFormData): Promise<void> {
    const classId = formData.classId && formData.classId > 0
      ? formData.classId
      : await this.organizationDao.ensureClass(formData.className);
    const classInfo = await this.organizationDao.getClassById(classId);
    const normalized: UserFormData = {
      studentNo: formData.studentNo.trim(),
      name: formData.name.trim(),
      classId: classId,
      className: classInfo?.name ?? formData.className.trim(),
      courseIds: formData.courseIds
    };
    if (normalized.studentNo === '') {
      throw new Error('学号不能为空');
    }
    if (normalized.name === '') {
      throw new Error('姓名不能为空');
    }

    const existing = await this.userDao.getByStudentNo(normalized.studentNo);
    if (existing && existing.id !== id) {
      throw new Error(`学号 ${normalized.studentNo} 已被其他用户使用`);
    }

    await this.userDao.update(id, normalized);
    if (normalized.courseIds) {
      await this.organizationDao.setUserEnrollments(id, normalized.courseIds);
    }
  }

  /**
   * 删除用户
   */
  async deleteUser(id: number): Promise<void> {
    await this.userDao.archive(id);
    await this.organizationDao.archiveUserEnrollments(id);
  }

  /**
   * 获取用户详情
   */
  async getUserById(id: number): Promise<UserModel | null> {
    return await this.userDao.getById(id);
  }

  /**
   * 获取所有用户
   */
  async getAllUsers(includeArchived: boolean = false): Promise<UserModel[]> {
    return await this.userDao.getAll(includeArchived);
  }

  /**
   * 搜索用户
   */
  async searchUsers(keyword: string): Promise<UserModel[]> {
    if (!keyword || keyword.trim() === '') {
      return await this.userDao.getAll();
    }
    return await this.userDao.search(keyword);
  }

  /**
   * 更新用户人脸照片
   */
  async updateFaceImage(id: number, imagePath: string): Promise<void> {
    const user = await this.userDao.getById(id);
    try {
      await this.userDao.updateFaceImage(id, imagePath);
    } catch (error) {
      CameraAdapter.deleteFile(imagePath);
      const caughtError = error as Error;
      throw new Error(caughtError.message);
    }

    if (user && user.faceImagePath && user.faceImagePath !== imagePath) {
      CameraAdapter.deleteFile(user.faceImagePath);
    }
  }

  /**
   * 获取用户统计数据
   */
  async getUserStats(): Promise<UserStats> {
    const total = await this.userDao.getCount();
    const enrolled = await this.userDao.getEnrolledCount();
    const stats: UserStats = {
      total: total,
      enrolled: enrolled
    };
    return stats;
  }
}
