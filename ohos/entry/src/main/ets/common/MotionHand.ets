import { motion } from '@kit.MultimodalAwarenessKit';

type HandHandler = (isLeft: boolean, fromOperating: boolean) => void;

/**
 * 智感握姿：握持手 + 操作手监听
 * （SystemCapability.MultimodalAwareness.Motion，握持手 API 20+、操作手 API 15+）。
 * 握持手反映真实握持变化；操作手在触屏时上报，响应更快，两者互补。
 * 不支持的设备（801 / canIUse false）静默降级为不订阅。
 */
export class MotionHand {
  private static instance: MotionHand | null = null;
  private readonly holdingHandCallback = (status: motion.HoldingHandStatus): void => {
    if (status === motion.HoldingHandStatus.LEFT_HAND_HELD) {
      if (this.fabEnabled) {
        this.handler?.(true, false);
      }
      if (this.bottomBarEnabled) {
        AppStorage.setOrCreate('bottomBarHandSide', -1);
      }
    } else if (status === motion.HoldingHandStatus.RIGHT_HAND_HELD) {
      if (this.fabEnabled) {
        this.handler?.(false, false);
      }
      if (this.bottomBarEnabled) {
        AppStorage.setOrCreate('bottomBarHandSide', 1);
      }
    } else if (this.bottomBarEnabled) {
      // NOT_HELD / BOTH_HANDS_HELD / UNKNOWN_STATUS：底栏回中，FAB 保持当前侧
      AppStorage.setOrCreate('bottomBarHandSide', 0);
    }
  };
  private readonly operatingHandCallback = (status: motion.OperatingHandStatus): void => {
    if (status === motion.OperatingHandStatus.LEFT_HAND_OPERATED) {
      if (this.fabEnabled) {
        this.handler?.(true, true);
      }
      if (this.bottomBarEnabled) {
        AppStorage.setOrCreate('bottomBarHandSide', -1);
      }
    } else if (status === motion.OperatingHandStatus.RIGHT_HAND_OPERATED) {
      if (this.fabEnabled) {
        this.handler?.(false, true);
      }
      if (this.bottomBarEnabled) {
        AppStorage.setOrCreate('bottomBarHandSide', 1);
      }
    }
  };
  private handler: HandHandler | null = null;
  private fabEnabled: boolean = false;
  private bottomBarEnabled: boolean = false;
  private holdingSubscribed: boolean = false;
  private operatingSubscribed: boolean = false;

  private static getInstance(): MotionHand {
    if (MotionHand.instance === null) {
      MotionHand.instance = new MotionHand();
    }
    return MotionHand.instance;
  }

  static setMonitor(enable: boolean, onChange: HandHandler | null): void {
    MotionHand.getInstance().setFabMonitorInner(enable, onChange);
  }

  static setBottomBarMonitor(enable: boolean): void {
    MotionHand.getInstance().setBottomBarMonitorInner(enable);
  }

  private setFabMonitorInner(enable: boolean, onChange: HandHandler | null): void {
    this.fabEnabled = enable;
    this.handler = enable ? onChange : null;
    this.syncSubscription();
  }

  private setBottomBarMonitorInner(enable: boolean): void {
    this.bottomBarEnabled = enable;
    if (!enable) {
      AppStorage.setOrCreate('bottomBarHandSide', 0);
    }
    this.syncSubscription();
  }

  private syncSubscription(): void {
    if (this.fabEnabled || this.bottomBarEnabled) {
      this.subscribeInner();
    } else {
      this.unsubscribeInner();
    }
  }

  private subscribeInner(): void {
    const supported = canIUse('SystemCapability.MultimodalAwareness.Motion');
    if (!this.holdingSubscribed && supported) {
      try {
        motion.on('holdingHandChanged', this.holdingHandCallback);
        this.holdingSubscribed = true;
      } catch (err) {
        console.warn(`MotionHand holdingHand on failed: ${err}`);
      }
    }
    if (!this.operatingSubscribed) {
      try {
        motion.on('operatingHandChanged', this.operatingHandCallback);
        this.operatingSubscribed = true;
      } catch (err) {
        // 801：设备不支持操作手感知，仅降级此通道
        console.warn(`MotionHand operatingHand on failed: ${err}`);
      }
    }
  }

  private unsubscribeInner(): void {
    if (this.holdingSubscribed) {
      try {
        motion.off('holdingHandChanged', this.holdingHandCallback);
      } catch (err) {
        console.warn(`MotionHand holdingHand off failed: ${err}`);
      }
      this.holdingSubscribed = false;
    }
    if (this.operatingSubscribed) {
      try {
        motion.off('operatingHandChanged', this.operatingHandCallback);
      } catch (err) {
        console.warn(`MotionHand operatingHand off failed: ${err}`);
      }
      this.operatingSubscribed = false;
    }
    this.handler = null;
  }
}
