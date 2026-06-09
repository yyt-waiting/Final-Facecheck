import { cameraPicker, camera } from '@kit.CameraKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { window } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';

/**
 * 相机适配器
 * 使用 CameraPicker 调用系统相机拍照（无需自行申请相机权限）
 * 返回 PixelMap 供后续人脸检测/比对使用
 */
export class CameraAdapter {
  private static isCapturing: boolean = false;

  private static async waitForWindowStable(delayMs: number): Promise<void> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, delayMs);
    });
  }

  /**
   * 使用前置摄像头拍照，返回 PixelMap
   * @param context 上下文
   * @returns PixelMap 或 undefined（用户取消或失败）
   */
  static async capturePhoto(context: Context): Promise<image.PixelMap | undefined> {
    if (CameraAdapter.isCapturing) {
      Logger.warn('系统相机正在运行，忽略重复拍照请求');
      return undefined;
    }

    CameraAdapter.isCapturing = true;
    let appWindow: window.Window | undefined = undefined;
    let previousOrientation: window.Orientation = window.Orientation.AUTO_ROTATION_UNSPECIFIED;
    let orientationLocked: boolean = false;

    try {
      try {
        appWindow = await window.getLastWindow(context);
        previousOrientation = appWindow.getPreferredOrientation();
        await appWindow.setPreferredOrientation(window.Orientation.LOCKED);
        orientationLocked = true;
        Logger.info('系统相机调用前锁定当前方向，原方向模式: %{public}s',
          previousOrientation.toString());
      } catch (error) {
        Logger.warn('系统相机调用前锁定方向失败，将继续拍照: %{public}s', JSON.stringify(error));
      }

      // 配置：使用前置摄像头
      const pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_FRONT
      };

      // 拉起系统相机拍照
      const pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(
        context,
        [cameraPicker.PickerMediaType.PHOTO],
        pickerProfile
      );

      Logger.info('拍照成功, URI: %{public}s', pickerResult.resultUri);

      if (pickerResult.resultUri) {
        // CameraPicker 返回媒体库 URI。先通过文件服务打开，再用 fd 解码，
        // 避免部分 HarmonyOS 设备无法将媒体 URI 直接解析为本地路径。
        const file = await fileIo.open(pickerResult.resultUri, fileIo.OpenMode.READ_ONLY);
        const imageSource = image.createImageSource(file.fd);
        try {
          return await imageSource.createPixelMap();
        } finally {
          await imageSource.release();
          await fileIo.close(file);
        }
      }

      Logger.warn('拍照返回空 URI');
      return undefined;
    } catch (error) {
      Logger.error('拍照失败: %{public}s', JSON.stringify(error));
      return undefined;
    } finally {
      if (orientationLocked && appWindow) {
        try {
          // 等待 CameraPicker 的窗口退出动画完成，避免恢复自动旋转时短暂露出桌面。
          await CameraAdapter.waitForWindowStable(600);
          await appWindow.setPreferredOrientation(previousOrientation);
          Logger.info('系统相机返回后恢复方向模式: %{public}s', previousOrientation.toString());
        } catch (error) {
          Logger.warn('系统相机返回后恢复方向失败: %{public}s', JSON.stringify(error));
        }
      }
      CameraAdapter.isCapturing = false;
    }
  }

  /**
   * 从文件路径加载 PixelMap
   * 用于加载已注册的人脸照片
   * @param filePath 图片文件路径或 URI
   * @returns PixelMap 或 undefined
   */
  static async loadPixelMap(filePath: string): Promise<image.PixelMap | undefined> {
    try {
      if (!filePath || filePath === '') {
        return undefined;
      }
      const imageSource = image.createImageSource(filePath);
      try {
        return await imageSource.createPixelMap();
      } finally {
        await imageSource.release();
      }
    } catch (error) {
      Logger.error('加载图片失败: %{public}s, path: %{public}s', JSON.stringify(error), filePath);
      return undefined;
    }
  }

  /**
   * 将 PixelMap 保存到应用沙箱目录
   * @param context 上下文
   * @param pixelMap 要保存的图片
   * @param fileName 文件名（不含路径）
   * @returns 保存后的完整文件路径
   */
  static async savePixelMap(context: Context, pixelMap: image.PixelMap, fileName: string): Promise<string> {
    try {
      const filesDir = context.filesDir;
      const filePath = `${filesDir}/${fileName}`;

      const packer = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: 'image/jpeg',
        quality: 90
      };
      const file = fileIo.openSync(
        filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC
      );
      try {
        await packer.packToFile(pixelMap, file.fd, packOptions);
      } finally {
        await packer.release();
        fileIo.closeSync(file);
      }

      Logger.info('图片保存成功: %{public}s', filePath);
      return filePath;
    } catch (error) {
      Logger.error('保存图片失败: %{public}s', JSON.stringify(error));
      const caughtError = error as Error;
      throw new Error(caughtError.message);
    }
  }

  /**
   * 删除应用沙箱中的图片文件。
   */
  static deleteFile(filePath: string): void {
    if (!filePath) {
      return;
    }
    try {
      if (fileIo.accessSync(filePath)) {
        fileIo.unlinkSync(filePath);
        Logger.info('图片删除成功: %{public}s', filePath);
      }
    } catch (error) {
      Logger.warn('删除图片失败: %{public}s, path: %{public}s', JSON.stringify(error), filePath);
    }
  }
}
