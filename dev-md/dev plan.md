FaceCheck 完整开发计划
一、总体路线
采用“开源项目业务框架 + 鸿蒙原生 AI 能力”的整合方案：

开源签到项目
提取页面、数据模型、签到规则和交互流程
                    ↓
CodeGenie 辅助重塑为 ArkTS
                    ↓
ArkUI + ArkData + Camera Kit
                    ↓
Core Vision Kit 人脸检测/比对
                    ↓
Vision Kit 活体检测
                    ↓
华为 Pad 离线运行
Core Vision Kit 官方提供人脸位置、特征点、朝向检测，以及两张人脸的比对和置信度结果；Vision Kit 活体控件可以端侧运行，并在成功后返回图片，适合继续做人脸核验。(developer.huawei.com)

二、功能范围
必做 MVP
用户信息注册、编辑、删除和展示。
Pad 前置摄像头采集人脸。
检测无人脸、多人脸、侧脸等异常。
选择学号后进行 1:1 人脸比对签到。
防止同一场次重复签到。
本地保存用户与签到记录。
按日期、姓名、班级查看记录。
进阶功能
Vision Kit 交互式活体检测。
不选择学号的 1:N 自动识别。
签到场次、迟到规则和统计。
CSV 签到记录导出。
数据备份、人脸照片清理和管理员验证。
三、开源项目利用方式
来源	借鉴内容	不直接移植内容
Face Attendance	用户、管理员、签到、1:N流程、数据表	React、Next.js、Supabase、face-api.js
React Native Facial Recognition	移动端录入、验证、匹配结果模型	Expo、ONNX Runtime、Vision Camera
Facenox	防重复签到、迟到、活体交互、报表	Electron、FastAPI、Python模型
华为官方示例	人脸检测、比对、活体的实际 ArkTS 接入	示例页面需要重构
原则是：复制业务思想和纯 TypeScript 逻辑，替换所有 Web、Python、React Native 平台依赖。

四、技术栈
层级	技术
开发工具	DevEco Studio 6.x、HarmonyOS SDK 6.x
语言/UI	ArkTS、ArkUI、Stage模型、UIAbility
页面导航	Navigation
相机	Camera Kit，第一版也可先采用系统拍照能力
图片处理	Image Kit、PixelMap
人脸检测/比对	Core Vision Kit
活体检测	Vision Kit Interactive Liveness
数据库	ArkData relationalStore
简单设置	Preferences
文件管理	Core File Kit、应用沙箱目录
AI辅助	CodeGenie：迁移、生成、测试、排错
测试	ArkTS单元测试、DevEco测试、Pad实机测试
官方当前文档将 ArkTS 作为鸿蒙优选语言，并提供 Camera Kit、ArkData、Core Vision Kit 与 Vision Kit。(developer.huawei.com)

五、代码架构
entry/src/main/ets/
├── entryability/EntryAbility.ets
├── pages/
│   ├── HomePage.ets
│   ├── UserListPage.ets
│   ├── UserEditPage.ets
│   ├── FaceEnrollPage.ets
│   ├── CheckInPage.ets
│   ├── RecordListPage.ets
│   └── SettingsPage.ets
├── components/
│   ├── CameraPanel.ets
│   ├── UserForm.ets
│   ├── CheckInResult.ets
│   └── RecordTable.ets
├── viewmodels/
│   ├── UserViewModel.ets
│   ├── EnrollViewModel.ets
│   └── CheckInViewModel.ets
├── services/
│   ├── UserService.ets
│   ├── AttendanceService.ets
│   └── SettingsService.ets
├── kits/
│   ├── CameraAdapter.ets
│   ├── FaceVisionAdapter.ets
│   └── LivenessAdapter.ets
├── database/
│   ├── DatabaseManager.ets
│   ├── UserDao.ets
│   ├── SessionDao.ets
│   └── AttendanceDao.ets
├── models/
└── utils/
kits 层隔离华为 API。以后接口变化或替换模型，只改适配器，不改页面和签到业务。

六、核心接口框架
interface FaceVisionService {
  detect(faceImage: PixelMap): Promise<FaceDetectionResult>;
  compare(registered: PixelMap, captured: PixelMap): Promise<FaceCompareResult>;
}

interface LivenessService {
  start(): Promise<LivenessResult>;
}

interface AttendanceService {
  checkIn(userId: number, captured: PixelMap): Promise<CheckInResult>;
}
签到服务内部流程：

检查当前场次
→ 查询用户及注册照片
→ 活体检测（启用时）
→ 人脸检测及质量校验
→ Core Vision Kit 人脸比对
→ 判断官方匹配结果与分数
→ 检查重复签到
→ 写入记录
→ 返回成功/失败原因
不要一开始写死相似度阈值。先记录官方返回的匹配结果和分数，再通过同人、不同人、不同光照的实机样本确定阈值。

七、数据库设计
users
- id
- student_no UNIQUE
- name
- class_name
- face_image_path
- face_enrolled
- created_at
- updated_at

attendance_sessions
- id
- title
- start_time
- late_time
- end_time
- status

attendance_records
- id
- session_id
- user_id
- check_in_time
- compare_score
- liveness_passed
- status
- captured_image_path
为 (session_id, user_id) 建立唯一约束，数据库层直接防止重复签到。签到抓拍照片默认可以不长期保存，只保存注册照片、比对分数和结果，降低隐私风险。

八、页面设计
Pad 默认横屏，首页直接做签到工作台：

┌──────────────┬────────────────────────┬──────────────┐
│ 今日统计      │ 摄像头/活体/签到区域    │ 最近签到记录  │
│ 应到、实到    │ 人脸框和状态提示         │ 姓名、时间    │
└──────────────┴────────────────────────┴──────────────┘
底部或侧栏设置：签到、人员、记录、设置。用户管理和记录页面采用适合 Pad 扫描查看的表格或紧凑列表，不做营销式首页。

九、开发阶段
阶段	工作	验收结果
0. 可行性验证	在真实 Pad 运行官方检测、比对、活体示例	三项能力和系统版本明确
1. 工程骨架	Navigation、主题、权限、日志、异常处理	空应用可编译安装
2. 数据层	用户、场次、记录 DAO 和数据库迁移	重启后数据仍存在
3. 用户管理	注册、编辑、列表、详情、删除	学号唯一校验正常
4. 人脸录入	拍照、检测、单人/姿态检查、保存	合格照片可录入
5. 基础签到	选择用户、拍照、1:1比对、写记录	完成核心闭环
6. 记录管理	查询、筛选、统计、防重复	数据与页面一致
7. 活体检测	接入Vision Kit并串联人脸比对	照片/屏幕攻击被拦截
8. 优化测试	横屏布局、异常场景、阈值、性能	可稳定课堂演示
建议先完成阶段 0。若 Pad 不支持某个 Kit，越早发现越容易调整，避免页面全部完成后才发现核心接口不可用。

十、CodeGenie 使用安排
CodeGenie 重点用于：

将参考项目的 TypeScript模型和签到规则转换为 ArkTS。
生成 ArkData DAO、表结构与 CRUD。
根据官方示例封装 FaceVisionAdapter。
生成页面骨架、表单校验和测试用例。
分析编译错误并修改 ArkTS 严格类型问题。
为课程报告保留“提示词、生成结果、人工修改”的开发记录。
不要让 CodeGenie凭空编写鸿蒙 API。应把当前 SDK 官方示例代码连同需求交给它，每完成一个小模块立即编译。

十一、重点测试
必须覆盖：

拒绝相机权限。
没有人脸或同时出现多张人脸。
侧脸、遮挡、距离过远和弱光。
本人、非本人、相似面孔。
照片翻拍和屏幕翻拍。
连续重复签到。
数据库重启、删除用户、照片文件丢失。
活体中途取消。
横竖屏切换及 Pad 不同分辨率。
十二、最终交付物
可安装的 HAP。
完整 DevEco Studio ArkTS 工程。
用户、人脸录入、签到、记录查看演示。
Core Vision Kit 与 Vision Kit 接入说明。
数据库设计和系统架构图。
CodeGenie 使用记录。
测试报告及实机演示视频。
开源项目引用与许可证说明。
第一版明确采用 1:1 身份验证，保证作业能够完成；1:N 自动认人和活体检测作为进阶加分项。这样既满足原始要求，又不会让项目被模型移植或 Python 环境拖住。