/**
 * 用户数据模型
 */
export interface UserModel {
  id: number;
  studentNo: string;
  name: string;
  classId: number;
  className: string;
  faceImagePath: string;
  faceEnrolled: boolean;
  status: number;
  createdAt: number;
  updatedAt: number;
}

/**
 * 用户表单数据（创建/编辑时使用）
 */
export interface UserFormData {
  studentNo: string;
  name: string;
  classId?: number;
  className: string;
  courseIds?: number[];
}

/**
 * 用户列表项（列表展示用，包含签到状态）
 */
export interface UserListItem extends UserModel {
  todayCheckedIn?: boolean;
}
