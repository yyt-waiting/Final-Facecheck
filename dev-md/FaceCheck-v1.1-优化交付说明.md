# FaceCheck v1.1 优化交付说明

## 1. 本次优化范围

本次开发依据 `modify.md` 完成了数据模型、核心业务、横竖屏响应式界面、活体检测时序、报表与隐私能力的整体升级。

### 数据与业务

- 数据库升级为 v3，新增 `admin_classes`、`courses`、`course_enrollments`、`session_members`。
- `users` 增加 `class_id` 和软删除 `status`。
- `attendance_sessions` 增加 `course_id`。
- 创建签到场次时，从选课关系生成不可变的 `SessionMember` 应到名单快照。
- 场次统计分母改为 `SessionMember`，不再使用全量用户数。
- 班级、课程、用户均采用归档机制，历史考勤数据不被物理删除。
- 旧数据库数据会无损迁移到默认课程“鸿蒙应用开发”。

### 人脸与活体

- 保留已验证成功的 Vision Kit 两阶段活体流程：
  1. `startLivenessDetection()` 拉起检测页。
  2. 页面返回后调用 `getInteractiveLivenessResult()`。
- 活体开始前记录当前屏幕方向并锁定竖屏，结束、取消或失败后恢复进入前方向。
- 活体返回后等待 Core Vision Kit 检测器和比对器初始化完成，再继续人脸比对。
- 签到流程增加五阶段进度：权限、活体、图像质量、人脸比对、结果。
- 人脸匹配阈值可在设置页配置。

### 界面与响应式

- 取消应用全局横屏锁定，普通页面跟随系统自动旋转。
- `< 600vp`：单列布局，签到主操作固定在内容底部。
- `600vp - 839vp`：双栏布局。
- `>= 840vp`：首页三栏工作台，记录页使用展开报表。
- 全部主页面统一为白色内容面、`#F1F3F5` 页面底色、6-8vp 圆角和细分隔线。
- Emoji 导航替换为统一 SVG 线性图标。
- 新增“教学组织”页面，管理班级和课程。
- 人员编辑支持班级单选、课程多选。

### 报表与隐私

- 考勤记录支持筛选后导出 UTF-8 BOM CSV，可直接用表格软件打开中文内容。
- 设置页增加“清除全部人脸与考勤数据”危险操作入口。
- 清理操作保留班级、课程和人员基本信息，只删除人脸照片、签到场次和签到记录。

## 2. 主要文件

- 数据库迁移：`entry/src/main/ets/database/DatabaseManager.ets`
- 教学关系 DAO：`entry/src/main/ets/database/OrganizationDao.ets`
- 场次快照 DAO：`entry/src/main/ets/database/SessionMemberDao.ets`
- 签到业务：`entry/src/main/ets/services/AttendanceService.ets`
- 活体适配：`entry/src/main/ets/kits/LivenessAdapter.ets`
- 响应式首页：`entry/src/main/ets/pages/Index.ets`
- 教学组织页：`entry/src/main/ets/pages/OrganizationPage.ets`
- 统一导航：`entry/src/main/ets/components/AppBottomNav.ets`

## 3. 构建验证

构建命令：

```powershell
$env:DEVECO_SDK_HOME='F:\DevEco Studio\sdk'
$env:JAVA_HOME='F:\DevEco Studio\jbr'
& 'F:\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default --no-daemon
```

构建结果：`BUILD SUCCESSFUL`

签名 HAP：

`entry/build/default/outputs/default/entry-default-signed.hap`

## 4. 真机回归清单

1. 保留旧应用数据覆盖安装，确认数据库自动迁移且原有人脸照片仍可显示。
2. 横屏和竖屏分别打开首页、人员、教学、记录、设置页面。
3. 新建班级和课程，为学生设置班级与选课关系。
4. 发起课程签到，确认应到人数等于该课程当前选课人数。
5. 发起后修改学生班级或选课，确认当前场次应到名单不变化。
6. 开启活体检测，从横屏进入，确认检测页竖屏，返回后恢复横屏。
7. 完成活体、人脸质量评估、比对和签到写入，确认五阶段进度与记录一致。
8. 导出 CSV，确认姓名、课程、场次、匹配度与状态可正确打开。
9. 归档人员、课程或班级，确认历史记录仍可查看。

## 5. 2026-06-09 真机验证结果

- 华为 Pad 设备 `5KLBB25B07200745` 已连接并完成覆盖安装。
- 应用版本为 `1.1.0`，数据库 v3 迁移成功。
- 竖屏 1600 x 2560 下，人员列表、添加人员弹窗、课程多选与底部导航显示正常。
- Core Vision Kit 人脸检测器与人脸比对器均初始化成功。
- 活体检测返回 `passed=true`，现场图像为 480 x 640，方向恢复成功。
- 现场人脸检测通过，人脸比对相似度为 `0.9186484455`。
- 当前阈值为 `0.6`，判定为同一人并成功写入签到记录。
- FaceCheck 业务日志中未出现失败、异常或错误。

真机截图：`facecheck-v11-device.jpeg`
