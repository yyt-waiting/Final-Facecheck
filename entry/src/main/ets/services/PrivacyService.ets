import { DatabaseManager } from '../database/DatabaseManager';
import { UserDao } from '../database/UserDao';
import { CameraAdapter } from '../kits/CameraAdapter';
import { Logger } from '../utils/Logger';

export class PrivacyService {
  private userDao: UserDao = new UserDao();

  async clearFaceAndAttendanceData(): Promise<void> {
    const users = await this.userDao.getAll(true);
    await DatabaseManager.getInstance().clearSensitiveData();
    users.forEach((user) => {
      if (user.faceImagePath) {
        try {
          CameraAdapter.deleteFile(user.faceImagePath);
        } catch (error) {
          Logger.warn('删除人脸文件失败: %{public}s', JSON.stringify(error));
        }
      }
    });
  }
}
