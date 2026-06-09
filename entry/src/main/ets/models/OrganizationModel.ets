export enum DataStatus {
  ARCHIVED = 0,
  ACTIVE = 1
}

export interface AdminClass {
  id: number;
  name: string;
  grade: string;
  major: string;
  status: DataStatus;
  createdAt: number;
  updatedAt: number;
}

export interface Course {
  id: number;
  code: string;
  name: string;
  status: DataStatus;
  createdAt: number;
  updatedAt: number;
}

export interface CourseEnrollment {
  id: number;
  courseId: number;
  userId: number;
  status: DataStatus;
  createdAt: number;
}

export interface SessionMember {
  sessionId: number;
  userId: number;
  classId: number;
  courseId: number;
  createdAt: number;
}
