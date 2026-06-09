import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';
import { SettingsService } from '../services/SettingsService';

const DOMAIN = 0xFF00;
const TAG = 'FaceCheck';

export default class EntryAbility extends UIAbility {
  private initializationPromise: Promise<void> = Promise.resolve();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode: %{public}s', JSON.stringify(err));
    }

    this.initializationPromise = this.initializeServices();
  }

  private async initializeServices(): Promise<void> {
    try {
      await DatabaseManager.getInstance().initialize(this.context);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '数据库初始化失败: %{public}s', JSON.stringify(err));
    }

    try {
      await SettingsService.getInstance().initialize(this.context);
    } catch (err) {
      hilog.error(DOMAIN, TAG, '设置服务初始化失败: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    this.initializationPromise.then(() => {
      windowStage.getMainWindow().then((mainWindow: window.Window) => {
        return mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_UNSPECIFIED);
      }).then(() => {
        windowStage.loadContent('pages/Index', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(DOMAIN, TAG, 'Content loaded successfully');
        });
      }).catch((error: Error) => {
        hilog.error(DOMAIN, TAG, '设置自动旋转失败: %{public}s', error.message);
        windowStage.loadContent('pages/Index', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
          }
        });
      });
    }).catch((error: Error) => {
      hilog.error(DOMAIN, TAG, '初始化流程失败: %{public}s', error.message);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
