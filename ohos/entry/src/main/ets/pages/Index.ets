import { curves, LengthMetrics, SymbolGlyphModifier, uiMaterial, uiObserver } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { HdsAnimationMode, hdsMaterial, HdsTabs, HdsNavigation, HdsTabsController, ScrollEffectType } from '@kit.UIDesignKit';
import common from '@ohos.app.ability.common';
import image from '@ohos.multimedia.image';
import window from '@ohos.window';
import { FlutterPage } from '@ohos/flutter_ohos';
import { windowChrome } from '../window/WindowChrome';
import { WindowTitleBar } from '../window/WindowTitleBar';

let storage = LocalStorage.getShared();

const TAG = 'Index';
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';
const EVENT_TAB_SWITCH = 'EVENT_TAB_SWITCH';
const EVENT_CHANGE_TAB = 'EVENT_CHANGE_TAB';
const EVENT_TOP_SEARCH = 'EVENT_TOP_SEARCH';
const EVENT_TOP_MSG = 'EVENT_TOP_MSG';
const EVENT_TOP_MINE = 'EVENT_TOP_MINE';
const EVENT_HOME_TAB_CHANGE = 'EVENT_HOME_TAB_CHANGE';

const NAV_UNSELECTED = $r('sys.color.comp_focused_primary');
const BOTTOM_NORMAL_AVOID_AREA_VALUE = 1;
const BOTTOM_SPECIAL_AVOID_AREA_VALUE = 12;
const TOP_BAR_BLUR_RADIUS = 25;
const TOP_BAR_FRACTION_STOPS: [number, number][] = [[0, 0], [0.92, 0.1], [1, 1]];
const BOTTOM_BAR_BLUR_RADIUS = 25;
const BOTTOM_BAR_FRACTION_STOPS: [number, number][] = [[0, 0], [0.55, 0.35], [1, 1]];
const BOTTOM_BAR_MASK_EXTRA_HEIGHT = 48;
const TOP_BAR_COLLAPSED_HEIGHT = 80;
const TOP_BAR_EXPANDED_HEIGHT = 144;
const TOP_BAR_WIDE_EXPANDED_HEIGHT = 116;
const WIDE_TOP_BAR_MIN_WIDTH = 600;
const WIDE_SEARCH_BAR_WIDTH = 220;
const WIDE_TOP_ITEM_HEIGHT = 56;
const TOP_BAR_MASK_EXTRA_HEIGHT = 36;
const HOVER_BG_COLOR = '#24888888';
/// 顶栏收缩曲线：重减速的三次贝塞尔，起步轻、尾段长距离滑停，
/// 比对称的 EaseInOut 柔和。裁剪容器/内容容器/搜索行三处高度共用同一条
/// 曲线与时长，避免各自为政导致的错位；数值需与 Flutter 侧
/// NativeTopSpacer 的留白动画保持一致。
const TOP_BAR_MOTION_DURATION = 300;
const TOP_BAR_MOTION_CURVE: ICurve = curves.cubicBezierCurve(0.2, 0, 0, 1);
/// 搜索行淡出/淡入：收起时抢在高度压扁之前淡出，展开时等高度让出空间后
/// 再淡入，避免文字在被压扁的行内闪现（旧实现同时做，观感发硬）
const TOP_BAR_FADE_DURATION = 120;
const TOP_BAR_FADE_IN_DELAY = 48;
/// API 23~25 顶栏：消息按钮（单页签 HdsTabs 悬浮栏）边长，与 API 26+ 的
/// 44vp 圆形按钮一致
const HDS_MSG_BUTTON_SIZE = 44;
const CATEGORY_TABS_HEIGHT = 32;
/// 转屏动画参数
const ROTATION_MASK_FADE_DURATION = 130;
const ROTATION_MASK_FADE_DELAY = 75;
const ROTATION_MASK_MAX_LIFETIME = 2000;

function topBarMaterial(interactive: boolean): uiMaterial.ImmersiveMaterial {
  return new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    interactive: interactive,
    lightEffect: {}
  });
}

/// Navbar 页签类型（与 Flutter NavigationBarType.values 顺序一致）→ 符号
function navTabSymbol(typeIndex: number): Resource {
  switch (typeIndex) {
    case 0:
      return $r('sys.symbol.house_fill');
    case 1:
      return $r('sys.symbol.discover_fill');
    case 2:
      return $r('sys.symbol.person_crop_circle_fill_1');
    default:
      return $r('sys.symbol.house_fill');
  }
}

/// Navbar 页签类型 → 文案（与 Flutter NavigationBarType.label 一致）
function navTabLabel(typeIndex: number): string {
  switch (typeIndex) {
    case 0:
      return '首页';
    case 1:
      return '动态';
    case 2:
      return '我的';
    default:
      return '';
  }
}

/// 首页分类页签文案 → 鸿蒙系统图标（未知分类返回 null，自动回退文字）
function homeTabSymbol(name: string): Resource | null {
  switch (name) {
    case '直播':
      return $r('sys.symbol.dot_video_fill');
    case '推荐':
      return $r('sys.symbol.heart_fill');
    case '热门':
      return $r('sys.symbol.flame_fill');
    case '分区':
      return $r('sys.symbol.square_fill_grid_2x2');
    case '番剧':
      return $r('sys.symbol.TV_tv_fill');
    case '影视':
      return $r('sys.symbol.movie_fill');
    default:
      return null;
  }
}

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = "";
  @StorageLink('useNativeTabs') useNativeTabs: boolean = false;
  @StorageLink('shellBarsHidden') shellBarsHidden: boolean = false;
  @StorageLink('__scrollHidden') @Watch('onScrollHiddenChanged') shellBarsScrollHidden: boolean = false;
  /// 前景色与背景色均由 Dart 侧 AppearanceSync 统一下发，见 appearance/AppAppearance.ets。
  @StorageLink('tabSelectedColor') navSelected: string = '#3367D6';
  @StorageLink('tabSelectedSubColor') navSelectedSub: string = '#503367D6';
  @StorageLink('appBackgroundColor') appBackgroundColor: string = '';
  @StorageLink('useNativeTopBar') useNativeTopBar: boolean = false;
  @StorageLink('topBarHidden') topBarHidden: boolean = false;
  @StorageLink('topBarCollapsed') topBarCollapsed: boolean = false;
  @StorageLink('homeHideTopBar') homeHideTopBar: boolean = false;
  @StorageLink('homeSearchText') homeSearchText: string = '';
  @StorageLink('homeUnreadCount') homeUnreadCount: string = '';
  @StorageLink('homeFaceUrl') homeFaceUrl: string = '';
  @StorageLink('homeTabs') homeTabs: string[] = [];
  @StorageLink('homeActiveTabIndex') @Watch('onHomeTabIndexChanged') homeActiveTabIndex: number = 0;
  /// 底部 Navbar 页签（NavigationBarType 索引，由 Flutter 按设置内
  /// Navbar 编辑同步；默认 首页/动态/我的）
  @StorageLink('navTabs') navTabs: number[] = [0, 1, 2];
  /// 动态页签角标模式（与 Flutter DynamicBadgeMode 一致：0=隐藏 1=红点 2=数字）
  @StorageLink('dynBadgeMode') dynBadgeMode: number = 0;
  /// 动态页签角标数量（由 Flutter 按未读动态数同步）
  @StorageLink('dynBadgeCount') dynBadgeCount: number = 0;
  /// 沉浸光感底栏材质等级（Flutter 按设置下发；0=精美 1=轻柔 2=流畅 10=自适应）
  @StorageLink('tabMaterialLevel') tabMaterialLevel: number = 10;
  /// 智感握姿底栏开关及当前握持侧（-1=左 0=中 1=右）
  @StorageLink('enableHoldingHandBottomBar') enableHoldingHandBottomBar: boolean = true;
  @StorageLink('bottomBarHandSide') bottomBarHandSide: number = 0;
  /// 自绘标题带显隐与占位高度，由 WindowChrome 下发（自由窗口形态下为 true）
  @StorageLink('titleBarVisible') @Watch('onTitleBarVisibleChanged') titleBarVisible: boolean = false;
  @StorageLink('titleBarHeight') titleBarHeight: number = 0;
  /// 窗口是否处于自由窗口形态（2in1/PC、平板自由多窗、电脑模式）
  @StorageLink('windowFreeMode') windowFreeMode: boolean = false;
  /// 顶栏右侧需让出的系统三键宽度（vp）。
  ///
  /// 隐藏系统标题栏（setWindowDecorVisible(false)）后，右上角三键并不消失，
  /// 而是下沉到页面可绘制区顶部 —— 官方 FAQ 明确「设置隐藏后，标题栏中的
  /// 三键区域会下沉到页面区域中显示」，需由页面自行避让（getTitleButtonRect）。
  /// 自绘标题带会整条盖住这一区域，故只有未显示标题带时才让位。
  @State titleButtonInset: number = 0;
  /// 当前选中的底部 Navbar 页签索引（自定义 tabBar 需自行区分选中态）
  @State currentNavIndex: number = 0;
  @State statusBarHeight: number = 0;
  @State categoryCurrentIndex: number = 0;
  @State winWidth: number = 0;
  @State winHeight: number = 0;
  @State bottomAvoidAreaHeight: number = 0;
  @State hoveredNavIndex: number = -1;
  @State hoveredCatIndex: number = -1;
  @State hoveredTopAction: string = '';

  private categoryController: TabsController = new TabsController();
  private controller: HdsTabsController = new HdsTabsController();
  private win: window.Window | null = null;
  private sizeCallback: ((size: window.Size) => void) | null = null;
  private rectCallback: ((opts: window.RectChangeOptions) => void) | null = null;
  /// 显示大小缩放改变后，驱动根 Stack 重布局。
  private densityCallback: ((info: uiObserver.DensityInfo) => void) | null = null;

  /// 转屏旧画面遮罩
  @State rotationMask: image.PixelMap | null = null;
  @State rotationMaskOpacity: number = 1;
  private rotationCallback: ((info: window.RotationChangeInfo) => void) | null = null;
  private rotationMaskTimers: number[] = [];
  /// aboutToDisappear 早于 getLastWindow 回调时，避免继续装监听
  private disposed: boolean = false;
  private currentOrientation: number = 0;

  /// 背景色
  private isBlackBg: boolean = false;

  onHomeTabIndexChanged(): void {
    if (this.homeActiveTabIndex >= 0 && this.homeActiveTabIndex < this.homeTabs.length) {
      this.categoryCurrentIndex = this.homeActiveTabIndex;
    }
  }

  private isTopBarCollapsed(): boolean {
    return this.homeHideTopBar && this.topBarCollapsed;
  }

  private isWideSingleRowTopBar(): boolean {
    return this.winWidth >= WIDE_TOP_BAR_MIN_WIDTH && this.homeTabs.length > 1;
  }

  private wideSearchWidth(): number {
    return this.winWidth >= 960 ? WIDE_SEARCH_BAR_WIDTH : 168;
  }

  /// 宽屏单行时判断屏幕正居中放置分类胶囊是否与右侧搜索/通知/头像区冲突
  private canTrueCenterWideTopBar(): boolean {
    const capsuleWidth = this.homeTabs.length * 58 + 16;
    const rightWidth = this.wideSearchWidth() + WIDE_TOP_ITEM_HEIGHT * 2 + 24 + this.titleButtonInset + 14;
    return (this.winWidth - capsuleWidth) / 2 >= rightWidth + 12;
  }

  onScrollHiddenChanged(): void {
    if (!this.useNativeTabs || this.shellBarsHidden) {
      return;
    }
    if (this.shellBarsScrollHidden) {
      this.controller.applyHideAnimation(HdsAnimationMode.SCROLL_ANIMATION);
    } else {
      this.controller.applyShowAnimation(HdsAnimationMode.SCROLL_ANIMATION);
    }
  }

  private applySize(widthPx: number, heightPx: number): void {
    // 必须用 UIContext.px2vp：全局 px2vp 已废弃，UI 实例不明确时会退回
    // 默认屏密度，显示大小缩放变化后算出的 vp 与真实值不符。
    const uiContext = this.getUIContext();
    this.winWidth = uiContext.px2vp(widthPx);
    this.winHeight = uiContext.px2vp(heightPx);
    // 同步到 AppStorage，供 HarmonyChannel.syncTopBarWithShell
    // 按窗口宽高比分流顶栏（收起/隐藏/显示）
    AppStorage.setOrCreate('winWidth', this.winWidth);
    AppStorage.setOrCreate('winHeight', this.winHeight);
  }

  /// 显示大小缩放变化后重算根容器尺寸：窗口的 px 矩形没变，只有密度变了，
  /// 因此重新读一次 windowRect 并按新密度换算 vp，赋给 winWidth/winHeight
  /// 触发根 Stack 重布局，使其重新铺满窗口。
  private reapplyWindowSize(): void {
    if (this.win === null) {
      return;
    }
    try {
      const rect = this.win.getWindowProperties().windowRect;
      this.applySize(rect.width, rect.height);
    } catch (err) {
      console.error(TAG, `reapplyWindowSize failed: ${err}`);
    }
  }

  /// 屏幕旋转动画：模仿安卓CROSSFADE
  /// 旋转开始时捕获旧画面快照，新旧界面淡入淡出
  private RotatationAnimation(w: window.Window): void {
    // 更新遮罩前先释放上一张快照并清掉旧定时器，避免 PixelMap 被覆盖后
    // 无法回收造成图片资源泄露，也避免旧定时器误清新遮罩
    this.releaseRotationMask();
    this.clearRotationMaskTimers();
    try {
      this.rotationMask = w.snapshotSync();
      this.rotationMaskOpacity = 1;
      this.startRotationMaskFade();
    } catch (err) {
      console.error(TAG, `capture rotation mask failed: ${err}`);
      this.cleanupRotationMask();
    }
  }

  private startRotationMaskFade(): void {
    this.rotationMaskTimers.push(setTimeout(() => {
      this.rotationMaskOpacity = 0;
      this.rotationMaskTimers.push(setTimeout(() => {
        this.cleanupRotationMask();
      }, ROTATION_MASK_FADE_DURATION));
    }, ROTATION_MASK_FADE_DELAY));
    // 兜底：旋转流程异常中断时强制清理，避免遮罩残留
    this.rotationMaskTimers.push(setTimeout(() => {
      this.cleanupRotationMask();
    }, ROTATION_MASK_MAX_LIFETIME));
  }

  /// 释放遮罩 PixelMap：先判空、再判是否已释放，避免重复 release；
  /// release 抛错（如已被释放）时兜底忽略，不影响后续流程
  private releaseRotationMask(): void {
    const mask = this.rotationMask;
    if (mask === null) {
      return;
    }
    this.rotationMask = null;
    try {
      if (!mask.isReleased()) {
        mask.release();
      }
    } catch (err) {
      console.error(TAG, `release rotation mask failed: ${err}`);
    }
  }

  private cleanupRotationMask(): void {
    this.clearRotationMaskTimers();
    this.releaseRotationMask();
    this.rotationMaskOpacity = 1;
  }

  private clearRotationMaskTimers(): void {
    this.rotationMaskTimers.forEach((t: number) => clearTimeout(t));
    this.rotationMaskTimers = [];
  }

  aboutToAppear(): void {
    this.context.eventHub.on(EVENT_CHANGE_TAB, (index: number) => {
      this.currentNavIndex = index;
      this.controller.changeIndex(index);
    });

    window.getLastWindow(this.context).then((w: window.Window) => {
      if (this.disposed) {
        return;
      }
      this.win = w;
      // 页面已挂载并即将首帧布局：此时才是装饰栏接口（setWindowDecorVisible /
      // setWindowDecorHeight / setWindowTitleButtonVisible）的合法时机，
      // 通知 WindowChrome 正式下发「隐藏系统标题栏 + 三键」，内容区随之铺满整窗。
      windowChrome.onContentLoaded();
      this.refreshTitleButtonInset();
      let topAvoidArea = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      this.statusBarHeight = px2vp(topAvoidArea.topRect.height);
      w.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          this.statusBarHeight = px2vp(data.area.topRect.height);
        }
      });

      const rect = w.getWindowProperties().windowRect;
      this.applySize(rect.width, rect.height);
      this.sizeCallback = (size: window.Size) => {
        this.applySize(size.width, size.height);
      };
      w.on('windowSizeChange', this.sizeCallback);

      // 显示大小缩放变化,重算根容器 vp 尺寸（详见 densityCallback）
      try {
        this.densityCallback = (info: uiObserver.DensityInfo) => {
          console.info(TAG, `densityUpdate: density=${info.density}`);
          this.reapplyWindowSize();
        };
        this.getUIContext()
          .getUIObserver()
          .on('densityUpdate', this.densityCallback);
      } catch (err) {
        console.error(TAG, `densityUpdate listener failed: ${err}`);
      }

      try {
        this.rectCallback = (opts: window.RectChangeOptions) => {
          this.applySize(opts.rect.width, opts.rect.height);
        };
        w.on('windowRectChange', this.rectCallback);
      } catch (err) {
        console.error(TAG, `windowRectChange listener failed: ${err}`);
      }

      try {
        this.rotationCallback = (info: window.RotationChangeInfo) => {
          if (info.type === window.RotationChangeType.WINDOW_WILL_ROTATE) {
            // 旋转角为 90° 或 270°，播放转屏动画；以遮罩是否为 null 判断
            // 上一次动画是否已结束，仍在播时不重复截图覆盖
            if (((info.orientation+this.currentOrientation)&1) === 1 && this.rotationMask === null) {
              this.RotatationAnimation(w);
            }
          } else if (info.type === window.RotationChangeType.WINDOW_DID_ROTATE) {
            this.currentOrientation = info.orientation;
          }
        };
        w.on('rotationChange', this.rotationCallback);
      } catch (err) {
        console.error(TAG, `rotationChange listener failed: ${err}`);
      }

      let windowBottomAvoidArea = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      let uiContext = this.getUIContext();
      this.bottomAvoidAreaHeight = windowBottomAvoidArea.bottomRect.height === 0
        ? BOTTOM_SPECIAL_AVOID_AREA_VALUE
        : (uiContext.px2vp(windowBottomAvoidArea.bottomRect.height) + BOTTOM_NORMAL_AVOID_AREA_VALUE);

      w.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          this.bottomAvoidAreaHeight = data.area.bottomRect.height === 0
            ? BOTTOM_SPECIAL_AVOID_AREA_VALUE
            : (uiContext.px2vp(data.area.bottomRect.height) + BOTTOM_NORMAL_AVOID_AREA_VALUE);
        }
      });
    }).catch((err: Object) => {
      console.error(TAG, `getLastWindow failed: ${err}`);
    });

    setTimeout(() => {
      this.isBlackBg = true;
    }, 3000);
  }

  /// 自绘标题带显隐后，三键是否还露在内容区上方会变，需重算顶栏避让
  onTitleBarVisibleChanged(): void {
    this.refreshTitleButtonInset();
  }

  /// 读取系统三键区尺寸，用于顶栏右侧避让。
  /// 隐藏系统标题栏后三键并不消失，而是下沉到页面可绘制区右上角；
  /// 自绘标题带会整条盖住它（此时不需要让位），未显示标题带时必须让位，
  /// 否则顶栏的头像/消息按钮会与系统三键重叠。
  private refreshTitleButtonInset(): void {
    if (this.win === null) {
      this.titleButtonInset = 0;
      return;
    }
    if (!this.windowFreeMode) {
      this.titleButtonInset = 0;
      return;
    }
    try {
      const rect: window.TitleButtonRect = this.win.getTitleButtonRect();
      // titleBarVisible 时标题带压在顶部，三键被完全盖住，留给内容的是 0
      this.titleButtonInset = this.titleBarVisible ? 0 : this.getUIContext().px2vp(rect.width);
    } catch (err) {
      console.error(TAG, `getTitleButtonRect failed: ${err}`);
      this.titleButtonInset = 0;
    }
  }

  aboutToDisappear(): void {
    this.disposed = true;
    if (this.densityCallback !== null) {
      try {
        this.getUIContext()
          .getUIObserver()
          .off('densityUpdate', this.densityCallback);
      } catch (err) {
        console.error(TAG, `off densityUpdate failed: ${err}`);
      }
      this.densityCallback = null;
    }
    if (this.win !== null) {
      try {
        if (this.sizeCallback !== null) {
          this.win.off('windowSizeChange', this.sizeCallback);
        }
        if (this.rectCallback !== null) {
          this.win.off('windowRectChange', this.rectCallback);
        }
        if (this.rotationCallback !== null) {
          this.win.off('rotationChange', this.rotationCallback);
        }
      } catch (err) {
        console.error(TAG, `off window listeners failed: ${err}`);
      }
      this.sizeCallback = null;
      this.rectCallback = null;
      this.rotationCallback = null;
    }
    this.clearRotationMaskTimers();
  }

  @Builder
  categoryTabBuilder(index: number, name: string) {
    Text(name)
      .fontSize(15)
      .fontWeight(this.categoryCurrentIndex === index ? FontWeight.Bolder : FontWeight.Medium)
      .fontColor(this.categoryCurrentIndex === index ? this.navSelected : NAV_UNSELECTED)
      .height(28)
      .margin({
        left: index === 0 ? 8 : 3,
        right: index === this.homeTabs.length - 1 ? 8 : 3
      })
      .padding({ left: 15, right: 15 })
  }

  @Builder
  navTabBuilder(typeIndex: number, index: number) {
    Column() {
      if (typeIndex === 1 && this.dynBadgeCount > 0 && this.dynBadgeMode !== 0) {
        if (this.dynBadgeMode === 1) {
          // 红点角标
          Badge({
            value: '',
            position: BadgePosition.RightTop,
            style: { badgeSize: 8, badgeColor: this.navSelected, borderColor: $r('sys.color.comp_common_contrary') }
          }) {
            SymbolGlyph(navTabSymbol(typeIndex))
              .fontSize(28)
              .fontColor(
                [this.currentNavIndex === index ? this.navSelected : NAV_UNSELECTED,
                  this.currentNavIndex === index ? this.navSelectedSub : $r('sys.color.icon_tertiary')])
              .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
              .symbolEffect(new BounceSymbolEffect(), this.currentNavIndex === index)
          }
        } else {
          // 数字角标
          Badge({
            count: this.dynBadgeCount,
            position: BadgePosition.RightTop,
            style: {
              badgeSize: 13,
              fontSize: 8,
              fontWeight: FontWeight.Medium,
              badgeColor: this.navSelected,
              borderColor: $r('sys.color.comp_common_contrary'),
              color: $r('sys.color.comp_common_contrary')
            }
          }) {
            SymbolGlyph(navTabSymbol(typeIndex))
              .fontSize(28)
              .fontColor(
                [this.currentNavIndex === index ? this.navSelected : NAV_UNSELECTED,
                  this.currentNavIndex === index ? this.navSelectedSub : $r('sys.color.icon_tertiary')])
              .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
              .symbolEffect(new BounceSymbolEffect(), this.currentNavIndex === index)
          }
        }
      } else {
        SymbolGlyph(navTabSymbol(typeIndex))
          .fontSize(28)
          .fontColor(
            [this.currentNavIndex === index ? this.navSelected : NAV_UNSELECTED,
              this.currentNavIndex === index ? this.navSelectedSub : $r('sys.color.icon_tertiary')])
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
          .symbolEffect(new BounceSymbolEffect(), this.currentNavIndex === index)
      }
    }
    .width('100%')
    .height('100%')
    .borderRadius(24)
    .backgroundColor(this.hoveredNavIndex === index ? HOVER_BG_COLOR : Color.Transparent)
    .scale(this.hoveredNavIndex === index ? { x: 1.06, y: 1.06 } : { x: 1, y: 1 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .justifyContent(FlexAlign.Center)
    .hoverEffect(HoverEffect.Highlight)
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.hoveredNavIndex = index;
      } else if (this.hoveredNavIndex === index) {
        this.hoveredNavIndex = -1;
      }
    })
  }

  @Builder
  circleIconButton(icon: Resource, size: number, iconSize: number, hoverKey: string, onClick: () => void) {
    Stack() {
      SymbolGlyph(icon)
        .fontSize(iconSize)
        .width(iconSize)
        .height(iconSize)
        .fontColor([this.navSelected])
        .align(Alignment.Center)
    }
    .width(size)
    .height(size)
    .borderRadius(size / 2)
    .backgroundColor(this.hoveredTopAction === hoverKey ? HOVER_BG_COLOR : Color.Transparent)
    .scale(this.hoveredTopAction === hoverKey ? { x: 1.06, y: 1.06 } : { x: 1, y: 1 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .systemMaterial(topBarMaterial(true))
    .hoverEffect(HoverEffect.Highlight)
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.hoveredTopAction = hoverKey;
      } else if (this.hoveredTopAction === hoverKey) {
        this.hoveredTopAction = '';
      }
    })
    .onClick(onClick)
  }

  @Builder
  msgButton(size: number = 44) {
    Stack() {
      this.circleIconButton($r('sys.symbol.bell'), size, size >= 56 ? 26 : 22, 'msg', () => {
        this.context.eventHub.emit(EVENT_TOP_MSG);
      })
      if (this.homeUnreadCount !== '') {
        Text(this.homeUnreadCount)
          .fontSize(9)
          .fontColor(Color.White)
          .padding({
            left: 5,
            right: 5,
            top: 1,
            bottom: 1
          })
          .backgroundColor(this.navSelected)
          .borderRadius(8)
          .offset({ x: 8, y: -10 })
      }
    }
    .width(size)
    .height(size)
  }

  @Builder
  avatarButton(size: number = 44) {
    if (this.homeFaceUrl !== '') {
      Stack() {
        Image(this.homeFaceUrl)
          .width(size - 4)
          .height(size - 4)
          .borderRadius((size - 4) / 2)
      }
      .width(size)
      .height(size)
      .borderRadius(size / 2)
      .backgroundColor(this.hoveredTopAction === 'avatar' ? HOVER_BG_COLOR : Color.Transparent)
      .scale(this.hoveredTopAction === 'avatar' ? { x: 1.06, y: 1.06 } : { x: 1, y: 1 })
      .animation({ duration: 150, curve: Curve.EaseOut })
      .systemMaterial(topBarMaterial(true))
      .hoverEffect(HoverEffect.Highlight)
      .onHover((isHover: boolean) => {
        if (isHover) {
          this.hoveredTopAction = 'avatar';
        } else if (this.hoveredTopAction === 'avatar') {
          this.hoveredTopAction = '';
        }
      })
      .onClick(() => {
        this.context.eventHub.emit(EVENT_TOP_MINE);
      })
    } else {
      this.circleIconButton($r('sys.symbol.person_crop_circle_fill'), size, size >= 56 ? 28 : 26, 'avatar', () => {
        this.context.eventHub.emit(EVENT_TOP_MINE);
      })
    }
  }

  @Builder
  categoryIconItem(index: number, name: string, large: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      if (homeTabSymbol(name) !== null) {
        SymbolGlyph(homeTabSymbol(name) as Resource)
          .fontSize(large ? 26 : 20)
          .fontColor(
            [this.categoryCurrentIndex === index ? this.navSelected : NAV_UNSELECTED,
              this.categoryCurrentIndex === index ? this.navSelectedSub : $r('sys.color.icon_tertiary')])
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
          .symbolEffect(new BounceSymbolEffect(), this.categoryCurrentIndex === index)
      } else {
        Text(name)
          .fontSize(large ? 15 : 14)
          .fontWeight(this.categoryCurrentIndex === index ? FontWeight.Bolder : FontWeight.Medium)
          .fontColor(this.categoryCurrentIndex === index ? this.navSelected : NAV_UNSELECTED)
          .padding({ left: 10, right: 10 })
      }
    }
    .height(large ? 44 : 34)
    .constraintSize({ minWidth: large ? 54 : 42 })
    .borderRadius(large ? 22 : 17)
    .backgroundColor(
      this.categoryCurrentIndex === index
        ? this.navSelectedSub
        : (this.hoveredCatIndex === index ? HOVER_BG_COLOR : Color.Transparent)
    )
    .scale(this.hoveredCatIndex === index ? { x: 1.06, y: 1.06 } : { x: 1, y: 1 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .hoverEffect(HoverEffect.Highlight)
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.hoveredCatIndex = index;
      } else if (this.hoveredCatIndex === index) {
        this.hoveredCatIndex = -1;
      }
    })
    .onClick(() => {
      this.context.eventHub.emit(EVENT_HOME_TAB_CHANGE, index);
      this.categoryCurrentIndex = index;
    })
  }

  /// 首页分类栏（直播/推荐/热门/分区/番剧/影视），按按钮数量自适应宽度
  @Builder
  categoryTabs(large: boolean = false) {
    Row({ space: large ? 4 : 4 }) {
      ForEach(this.homeTabs, (tab: string, index: number) => {
        this.categoryIconItem(index, tab, large)
      }, (tab: string, index: number) => index + '_' + tab)
    }
    .height(large ? WIDE_TOP_ITEM_HEIGHT : CATEGORY_TABS_HEIGHT)
    .padding({ left: 6, right: 6 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  homeTopBar() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.isWideSingleRowTopBar() && this.canTrueCenterWideTopBar()) {
          // 屏幕水平绝对居中：高度与底栏一致（56vp），不受右侧搜索/通知/头像挤压偏左
          Row() {
            this.categoryTabs(true)
          }
          .height(WIDE_TOP_ITEM_HEIGHT)
          .borderRadius(WIDE_TOP_ITEM_HEIGHT / 2)
          .clip(true)
          .systemMaterial(topBarMaterial(true))

          Row({ space: 8 }) {
            Search({ value: this.homeSearchText, placeholder: '搜索' })
              .cancelButton({ style: CancelButtonStyle.INVISIBLE })
              .focusable(false)
              .enableKeyboardOnFocus(false)
              .searchIcon(new SymbolGlyphModifier($r('sys.symbol.magnifyingglass'))
                .fontColor([this.navSelected]).fontSize(18))
              .placeholderColor($r('app.color.placeholder_text'))
              .placeholderFont({ size: 16, weight: 600 })
              .fontColor($r('app.color.placeholder_text'))
              .textFont({ size: 16, weight: 600 })
              .backgroundColor(this.hoveredTopAction === 'search' ? HOVER_BG_COLOR : Color.Transparent)
              .borderRadius(WIDE_TOP_ITEM_HEIGHT / 2)
              .width(this.wideSearchWidth())
              .height(WIDE_TOP_ITEM_HEIGHT)
              .systemMaterial(topBarMaterial(true))
              .hoverEffect(HoverEffect.Highlight)
              .onHover((isHover: boolean) => {
                if (isHover) {
                  this.hoveredTopAction = 'search';
                } else if (this.hoveredTopAction === 'search') {
                  this.hoveredTopAction = '';
                }
              })
              .onClick(() => {
                this.context.eventHub.emit(EVENT_TOP_SEARCH);
              })
            this.msgButton(WIDE_TOP_ITEM_HEIGHT)
            this.avatarButton(WIDE_TOP_ITEM_HEIGHT)
          }
          .width('100%')
          .padding({
            left: 14,
            right: 14 + this.titleButtonInset,
          })
          .justifyContent(FlexAlign.End)
          .hitTestBehavior(HitTestMode.None)
        } else {
          Row({ space: 8 }) {
            if (this.isWideSingleRowTopBar()) {
              Row() {
                Row() {
                  this.categoryTabs(true)
                }
                .height(WIDE_TOP_ITEM_HEIGHT)
                .borderRadius(WIDE_TOP_ITEM_HEIGHT / 2)
                .clip(true)
                .systemMaterial(topBarMaterial(true))
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)

              Search({ value: this.homeSearchText, placeholder: '搜索' })
                .cancelButton({ style: CancelButtonStyle.INVISIBLE })
                .focusable(false)
                .enableKeyboardOnFocus(false)
                .searchIcon(new SymbolGlyphModifier($r('sys.symbol.magnifyingglass'))
                  .fontColor([this.navSelected]).fontSize(18))
                .placeholderColor($r('app.color.placeholder_text'))
                .placeholderFont({ size: 16, weight: 600 })
                .fontColor($r('app.color.placeholder_text'))
                .textFont({ size: 16, weight: 600 })
                .backgroundColor(this.hoveredTopAction === 'search' ? HOVER_BG_COLOR : Color.Transparent)
                .borderRadius(WIDE_TOP_ITEM_HEIGHT / 2)
                .width(this.wideSearchWidth())
                .height(WIDE_TOP_ITEM_HEIGHT)
                .systemMaterial(topBarMaterial(true))
                .hoverEffect(HoverEffect.Highlight)
                .onHover((isHover: boolean) => {
                  if (isHover) {
                    this.hoveredTopAction = 'search';
                  } else if (this.hoveredTopAction === 'search') {
                    this.hoveredTopAction = '';
                  }
                })
                .onClick(() => {
                  this.context.eventHub.emit(EVENT_TOP_SEARCH);
                })
              this.msgButton(WIDE_TOP_ITEM_HEIGHT)
              this.avatarButton(WIDE_TOP_ITEM_HEIGHT)
            } else {
              Search({ value: this.homeSearchText, placeholder: '搜索' })
                .cancelButton({ style: CancelButtonStyle.INVISIBLE })
                .focusable(false)
                .enableKeyboardOnFocus(false)
                .searchIcon(new SymbolGlyphModifier($r('sys.symbol.magnifyingglass'))
                  .fontColor([this.navSelected]).fontSize(16))
                .placeholderColor($r('app.color.placeholder_text'))
                .placeholderFont({ size: 16, weight: 600 })
                .fontColor($r('app.color.placeholder_text'))
                .textFont({ size: 16, weight: 600 })
                .backgroundColor(this.hoveredTopAction === 'search' ? HOVER_BG_COLOR : Color.Transparent)
                .borderRadius(22)
                .layoutWeight(1)
                .height(44)
                .systemMaterial(topBarMaterial(true))
                .hoverEffect(HoverEffect.Highlight)
                .onHover((isHover: boolean) => {
                  if (isHover) {
                    this.hoveredTopAction = 'search';
                  } else if (this.hoveredTopAction === 'search') {
                    this.hoveredTopAction = '';
                  }
                })
                .onClick(() => {
                  this.context.eventHub.emit(EVENT_TOP_SEARCH);
                })
              this.msgButton(44)
              this.avatarButton(44)
            }
          }
          .width('100%')
          .padding({
            left: 14,
            right: 14 + this.titleButtonInset,
          })
        }
      }
      .width('100%')
      .opacity(this.homeHideTopBar && this.topBarCollapsed ? 0 : 1)
      // .animation() 只作用于它之前、上一个 .animation() 之后的属性，
      // 故透明度与高度可以各走一套节奏
      .animation({
        duration: TOP_BAR_FADE_DURATION,
        curve: Curve.Sharp,
        delay: this.homeHideTopBar && this.topBarCollapsed ? 0 : TOP_BAR_FADE_IN_DELAY
      })
      .margin({
        top: this.homeTabs.length > 1 && !this.isWideSingleRowTopBar() ? 5 : 9,
        bottom: 5
      })
      .height(this.isWideSingleRowTopBar() ? WIDE_TOP_ITEM_HEIGHT : 44)
      .animation({ duration: TOP_BAR_MOTION_DURATION, curve: TOP_BAR_MOTION_CURVE })

      if (!this.isWideSingleRowTopBar() && this.homeTabs.length > 1) {
        Row() {
          Row() {
            this.categoryTabs()
          }
          .height(40)
          .borderRadius(20)
          .clip(true)
          .systemMaterial(topBarMaterial(true))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 14, right: 14 })
      }
    }
    .width('100%')
    .padding({ top: this.statusBarHeight})
    // 自绘标题带压在窗口最顶部（不吃布局），顶栏内容需整体下移一个标题带高度
    .margin({ top: this.titleBarHeight })
    .id('topBarContent')
    .hitTestBehavior(HitTestMode.Default)
    .align(Alignment.Top)
  }

  /// 沉浸式系统材质仅在 Navigation/NavDestination 标题栏或 BarPosition.End 的
  /// 底部 TabBar 内生效（API 26 正式版起校验，超范围时日志打印
  /// Material inactive: out of scope），故顶栏整体挂进一个只占顶栏高度的
  /// Navigation 标题栏，内容区留空，不遮挡下方 FlutterPage。
  ///
  /// 关键约束：Navigation 的属性链里不得出现任何状态变量。builder 作为组件
  /// 参数会被编译成闭包在宿主的 update 函数里传下去（见 .tabBar 的产物形态），
  /// 一旦 Navigation 的 update 函数因读到脏状态而重跑，.title() 就会以新闭包
  /// 再调一次，自定义标题栏整棵子树被重建——新节点没有上一帧的值可插值，
  /// 隐式 .animation() 与 animateTo 一律退化成跳变。
  /// 因此收缩动画与显隐一律由外层裁剪容器承担，Navigation 保持常量属性，
  /// 标题栏内部的节点才能回到原地更新，沿用既有的 .animation() 写法。
  /// 顶部沉浸光感栏渐进模糊衬底（与底部 hdsBottomBarMask 对称，消除硬分界线）
  @Builder
  hdsTopBarMask() {
    Column()
      .width('100%')
      .height((this.isWideSingleRowTopBar() ? TOP_BAR_WIDE_EXPANDED_HEIGHT : TOP_BAR_EXPANDED_HEIGHT) + TOP_BAR_MASK_EXTRA_HEIGHT)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          [$r('app.color.top_bar_mask_start'), 0],
          [$r('app.color.top_bar_mask_mid'), 0.6],
          [$r('app.color.top_bar_mask_end'), 0.92],
          [$r('app.color.top_bar_mask_end'), 1],
        ],
      })
      .linearGradientBlur(TOP_BAR_BLUR_RADIUS, {
        fractionStops: TOP_BAR_FRACTION_STOPS,
        direction: GradientDirection.Top
      })
      .opacity(this.topBarCollapsed ? 0 : 1)
      .animation({ duration: TOP_BAR_MOTION_DURATION, curve: TOP_BAR_MOTION_CURVE })
      .visibility(this.topBarHidden ? Visibility.None : Visibility.Visible)
      .align(Alignment.Top)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  homeTopBarHost() {
    HdsNavigation() {
      // 空内容区：BarStyle.STACK 下被标题栏完全覆盖，不参与触摸测试
      Column()
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
    }
    // 宽窗口下默认的 Auto 会分栏，强制 Stack 保持单栏标题栏布局
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .hideToolBar(true)
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: false,
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          backgroundStyle: {
            backgroundColor: '#00000000',
            blurRadius: 0
          }
        },
        systemMaterialEffect: {
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE,
          materialType: hdsMaterial.MaterialType.IMMERSIVE
        }
      },
      content: {
        stackBuilder: (): void => this.homeTopBar(),
      }
    })
    // 状态栏避让由顶栏内部的 statusBarHeight padding 负责，避免重复加一层
    .margin({
      top: this.topBarCollapsed
        ? (this.isWideSingleRowTopBar()
          ? -TOP_BAR_WIDE_EXPANDED_HEIGHT
          : TOP_BAR_COLLAPSED_HEIGHT - TOP_BAR_EXPANDED_HEIGHT)
        : 0
    })
    .animation({ duration: TOP_BAR_MOTION_DURATION, curve: TOP_BAR_MOTION_CURVE })
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .width('100%')
    .height(this.isWideSingleRowTopBar() ? TOP_BAR_WIDE_EXPANDED_HEIGHT : TOP_BAR_EXPANDED_HEIGHT)
    .visibility(this.topBarHidden ? Visibility.None : Visibility.Visible)
    .align(Alignment.Top)
    .clip(true)
  }

  /// Dart侧背景色，未同步时回落资源色。
  private getBackgroundColor(): ResourceColor {
    if (this.appBackgroundColor.length > 0) {
      return this.appBackgroundColor;
    }
    return $r('app.color.start_window_background');
  }

  private topBarHeight(): number {
    return this.isTopBarCollapsed()
      ? TOP_BAR_COLLAPSED_HEIGHT
      : TOP_BAR_EXPANDED_HEIGHT;
  }

  @Builder
  hdsMsgTabBuilder() {
    SymbolGlyph($r('sys.symbol.bell'))
      .fontSize(22)
      .width(22)
      .height(22)
      .fontColor([this.navSelected])
      .align(Alignment.Center)
  }

  /// API 23~25：消息按钮由一个只含单个页签的 HdsTabs 悬浮栏承载——悬浮栏
  /// 的 systemMaterialEffect 就是底栏在 6.1 上拿沉浸光感的同一套机制，
  /// 而且栏宽/栏高/边距全部可指定，几何完全可控（不像 HdsNavigation
  /// 标题栏有最小宽度和自带遮罩）。44×44 + barOverlap 使悬浮栏铺满组件，
  /// 圆角随栏高变成正圆。角标与 API 26+ 的 msgButton 同一画法。
  @Builder
  hdsMsgButton() {
    Stack() {
      HdsTabs() {
        TabContent() { // empty
        }
        .tabBar(this.hdsMsgTabBuilder())
      }
      .scrollable(false)
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .vertical(false)
      .barMode(BarMode.Fixed)
      .barHeight(HDS_MSG_BUTTON_SIZE)
      .barFloatingStyle({
        barWidth: {
          smallWidth: HDS_MSG_BUTTON_SIZE,
          mediumWidth: HDS_MSG_BUTTON_SIZE,
          largeWidth: HDS_MSG_BUTTON_SIZE
        },
        barSideMargin: 0,
        barBottomMargin: 0,
        // 不要悬浮栏底部默认的渐变遮罩（默认高度为组件高 + 32vp，会露出直角块）。
        // 注意不能写 Color.Transparent / 0：二者都是 falsy，HDS 会当作未设置而回退默认，
        // 主题切换后默认遮罩色未刷新就成了按钮旁的灰色方块
        gradientMask: { maskColor: '#00000000', maskHeight: 1 },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          // 浅色模式下 ADAPTIVE 几乎看不出材质，按钮很小，直接用最高等级
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      })
      .barBackgroundColor('#00000000')
      .onTabBarClick(() => {
        this.context.eventHub.emit(EVENT_TOP_MSG);
      })
      .width(HDS_MSG_BUTTON_SIZE)
      .height(HDS_MSG_BUTTON_SIZE)
      // 兜底：无论 HDS 在组件范围内画了什么底/遮罩，都裁成与悬浮栏同样的正圆
      .clipShape(new Circle({ width: HDS_MSG_BUTTON_SIZE, height: HDS_MSG_BUTTON_SIZE }))
      if (this.homeUnreadCount !== '') {
        Text(this.homeUnreadCount)
          .fontSize(9)
          .fontColor(Color.White)
          .padding({
            left: 5,
            right: 5,
            top: 1,
            bottom: 1
          })
          .backgroundColor(this.navSelected)
          .borderRadius(8)
          .offset({ x: 6, y: -8 })
      }
    }
    .width(HDS_MSG_BUTTON_SIZE)
    .height(HDS_MSG_BUTTON_SIZE)
    // 角标可能探出按钮右缘，压在后绘制的头像之上
    .zIndex(1)
  }

  /// API 23~25（鸿蒙 6.1）顶栏。ArkUI 通用组件的 systemMaterial / uiMaterial
  /// 要到 API 26 才有，6.1 上沉浸光感只在 HDS 组件内可用：消息按钮走
  /// hdsMsgButton（HdsTabs 悬浮栏）拿材质；搜索框用组件级模糊做半透明胶囊，头像是普通圆形
  /// 图片按钮。布局、收起动画与 homeTopBar 逐项对应，仅材质相关属性不同。
  @Builder
  homeTopBarHds() {
    RelativeContainer() {
      //渐变模糊底层
      Column() {
      }
      .constraintSize({ maxHeight: TOP_BAR_EXPANDED_HEIGHT })
      .linearGradient({
          direction: GradientDirection.Bottom, // 渐变方向
          colors: [
                [$r('app.color.top_bar_mask_start'), 0],
                [$r('app.color.top_bar_mask_mid'), 0.8],
                [$r('app.color.top_bar_mask_end'), 0.95],
                [$r('app.color.top_bar_mask_end'), 1],
              ],
        })
      .linearGradientBlur(TOP_BAR_BLUR_RADIUS, {
        fractionStops: TOP_BAR_FRACTION_STOPS,
        direction: GradientDirection.Top
      })
      .alignRules({
        top: { anchor: 'topBarContent', align: VerticalAlign.Top },
        bottom: { anchor: 'topBarContent', align: VerticalAlign.Bottom },
        left: { anchor: 'topBarContent', align: HorizontalAlign.Start },
        right: { anchor: 'topBarContent', align: HorizontalAlign.End }
      })
      .id('topBarBg')
      .hitTestBehavior(HitTestMode.Transparent)
      .align(Alignment.Top)

      Column() {
        Row({ space: 8 }) {
          Search({ value: this.homeSearchText, placeholder: '搜索' })
            .cancelButton({ style: CancelButtonStyle.INVISIBLE })
            .focusable(false)
            .enableKeyboardOnFocus(false)
            .searchIcon(new SymbolGlyphModifier($r('sys.symbol.magnifyingglass'))
              .fontColor([this.navSelected]).fontSize(16))
            .placeholderColor($r('app.color.placeholder_text'))
            .placeholderFont({ size: 16, weight: 600 })
            .fontColor($r('app.color.placeholder_text'))
            .textFont({ size: 16, weight: 600 })
            .backgroundColor(Color.Transparent)
            .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
            .borderRadius(22)
            .layoutWeight(1)
            .height(44)
            .onClick(() => {
              this.context.eventHub.emit(EVENT_TOP_SEARCH);
            })
          this.hdsMsgButton()
          if (this.homeFaceUrl !== '') {
            Image(this.homeFaceUrl)
              .width(41)
              .height(41)
              .borderRadius(20.5)
              .onClick(() => {
                this.context.eventHub.emit(EVENT_TOP_MINE);
              })
          } else {
            Stack() {
              SymbolGlyph($r('sys.symbol.person_crop_circle_fill'))
                .fontSize(26)
                .width(26)
                .height(26)
                .fontColor([this.navSelected])
                .align(Alignment.Center)
            }
            .width(44)
            .height(44)
            .borderRadius(22)
            .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
            .onClick(() => {
              this.context.eventHub.emit(EVENT_TOP_MINE);
            })
          }
        }
        .width('100%')
        .padding({
          left: 14,
          right: 14 + this.titleButtonInset,
        })
        .opacity(this.homeHideTopBar && this.topBarCollapsed ? 0 : 1)
        .animation({
          duration: TOP_BAR_FADE_DURATION,
          curve: Curve.Sharp,
          delay: this.homeHideTopBar && this.topBarCollapsed ? 0 : TOP_BAR_FADE_IN_DELAY
        })
        .margin({
          top: this.homeHideTopBar && this.topBarCollapsed ? 0 : 5,
          bottom: this.homeHideTopBar && this.topBarCollapsed ? -5 : 5
        })
        .height(this.homeHideTopBar && this.topBarCollapsed ? 0 : 44)
        .animation({ duration: TOP_BAR_MOTION_DURATION, curve: TOP_BAR_MOTION_CURVE })

        if (this.homeTabs.length > 1) {
          this.categoryTabs()
        }
      }
      .width('100%')
      .padding({ top: this.statusBarHeight})
      // 自绘标题带压在窗口最顶部（不吃布局），顶栏内容需整体下移一个标题带高度
      .margin({ top: this.titleBarHeight })
      .id('topBarContent')
      .hitTestBehavior(HitTestMode.Default)
      .align(Alignment.Top)
    }
    .height(this.topBarHeight())
    .animation({ duration: TOP_BAR_MOTION_DURATION, curve: TOP_BAR_MOTION_CURVE })
    .width('100%')
    .hitTestBehavior(HitTestMode.Default)
    .align(Alignment.Top)
  }

  /// API 23~25 顶栏宿主：与 API 26+ 宿主同样由外层裁剪容器承担收缩与显隐
  @Builder
  homeTopBarHdsHost() {
    Column() {
      this.homeTopBarHds()
    }
    .width('100%')
    .height(this.topBarHeight())
    .clip(true)
    .animation({ duration: TOP_BAR_MOTION_DURATION, curve: TOP_BAR_MOTION_CURVE })
    .visibility(this.topBarHidden ? Visibility.None : Visibility.Visible)
    .align(Alignment.Top)
  }

  /// 把 Flutter 下发的档位值映射为 hdsMaterial.MaterialLevel，非法值回退自适应
  private resolveMaterialLevel(): hdsMaterial.MaterialLevel {
    switch (this.tabMaterialLevel) {
      case 0:
        return hdsMaterial.MaterialLevel.EXQUISITE;
      case 1:
        return hdsMaterial.MaterialLevel.GENTLE;
      case 2:
        return hdsMaterial.MaterialLevel.SMOOTH;
      default:
        return hdsMaterial.MaterialLevel.ADAPTIVE;
    }
  }

  /// 底部沉浸光感栏衬底：渐进模糊 + 主题自适应渐变遮罩，
  /// 压柔底部视频封面杂色以提升悬浮胶囊可见度，不拦截触摸且随底栏同步显隐。
  @Builder
  hdsBottomBarMask() {
    Column() {
      Column()
        .width('100%')
        .height(56 + this.bottomAvoidAreaHeight + BOTTOM_BAR_MASK_EXTRA_HEIGHT)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [$r('app.color.top_bar_mask_start'), 0],
            [$r('app.color.top_bar_mask_mid'), 0.65],
            [$r('app.color.top_bar_mask_end'), 0.95],
            [$r('app.color.top_bar_mask_end'), 1],
          ],
        })
        .linearGradientBlur(BOTTOM_BAR_BLUR_RADIUS, {
          fractionStops: BOTTOM_BAR_FRACTION_STOPS,
          direction: GradientDirection.Bottom
        })
        .opacity(this.shellBarsScrollHidden ? 0 : 1)
        .animation({ duration: 200, curve: Curve.EaseOut })
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .visibility(this.navTabs.length <= 1 || this.shellBarsHidden
      ? Visibility.None
      : Visibility.Visible)
    .hitTestBehavior(HitTestMode.None)
  }

  private resolveBottomBarAlign(): FlexAlign {
    if (!this.enableHoldingHandBottomBar || this.bottomBarHandSide === 0) {
      return FlexAlign.Center;
    }
    return this.bottomBarHandSide < 0 ? FlexAlign.Start : FlexAlign.End;
  }

  private bottomBarCapsuleWidth(): number {
    const maxAllowed = this.winWidth > 32 ? this.winWidth - 32 : 328;
    const ideal = Math.min(328, Math.max(200, this.navTabs.length * 80));
    return Math.min(maxAllowed, ideal);
  }

  @Builder
  hdsMainTabs() {
    Row() {
      HdsTabs({ controller: this.controller }) {
        ForEach(this.navTabs, (typeIndex: number, index: number) => {
          TabContent() { // empty
          }
          .tabBar(this.navTabBuilder(typeIndex, index))
        }, (typeIndex: number, index: number) => index + '_' + typeIndex)
      }
      .onTabBarClick((index: number) => {
        this.currentNavIndex = index;
        this.context.eventHub.emit(EVENT_TAB_SWITCH, index);
      })
      .scrollable(false)
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .vertical(false)
      .barHeight(56)
      .barFloatingStyle({
        barBottomMargin: this.bottomAvoidAreaHeight,
        barSideMargin: this.enableHoldingHandBottomBar ? 0 : 16,
        adaptToHandedness: !this.enableHoldingHandBottomBar,
        gradientMask: this.enableHoldingHandBottomBar
          ? { maskColor: '#00000000', maskHeight: 1 }
          : { maskColor: this.getBackgroundColor(), maskHeight: 96 },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: this.resolveMaterialLevel()
        }
      })
      .width(this.enableHoldingHandBottomBar ? this.bottomBarCapsuleWidth() : '100%')
      .height(56 + this.bottomAvoidAreaHeight + 24)
      .clip(false)
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    .padding(this.enableHoldingHandBottomBar ? { left: 16, right: 16 } : { left: 0, right: 0 })
    .justifyContent(this.resolveBottomBarAlign())
    .alignItems(VerticalAlign.Bottom)
    .animation({ duration: 260, curve: Curve.EaseInOut })
    .visibility(this.navTabs.length <= 1 || this.shellBarsHidden
      ? Visibility.None
      : Visibility.Visible)
    .hitTestBehavior(HitTestMode.None)
  }


  build() {
    Stack({ alignContent: Alignment.Top }) {
      FlutterPage({ viewId: this.viewId, xComponentRenderFit: RenderFit.TOP})
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
      if (this.useNativeTabs && deviceInfo.sdkApiVersion >= 23) {
        this.hdsBottomBarMask()
        this.hdsMainTabs()
      }
      // API 26+：Navigation 标题栏 + ArkUI systemMaterial（全部元素带材质）
      // API 23~25：自绘顶栏，仅消息按钮（HdsTabs 悬浮栏）带 HDS 材质
      if (this.useNativeTopBar && deviceInfo.sdkApiVersion >= 26) {
        this.hdsTopBarMask()
        this.homeTopBarHost()
      } else if (this.useNativeTopBar && deviceInfo.sdkApiVersion >= 23) {
        this.homeTopBarHdsHost()
      }
      // 自绘标题带：自由窗口形态下替代被隐藏的系统标题栏，压在顶栏之上
      if (this.titleBarVisible) {
        WindowTitleBar()
          .align(Alignment.Top)
      }
      // 转屏遮罩
      if (this.rotationMask !== null) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor("#80000000")
          .opacity(this.rotationMaskOpacity)
          .animation({ duration: ROTATION_MASK_FADE_DURATION-30, curve: Curve.EaseOut })
        Image(this.rotationMask)
          .objectFit(ImageFit.TOP)
          .opacity(this.rotationMaskOpacity)
          .animation({ duration: ROTATION_MASK_FADE_DURATION, curve: Curve.EaseOut })
          .hitTestBehavior(HitTestMode.None)
          .syncLoad(true)
      }
    }
    .width(this.winWidth > 0 ? this.winWidth : '100%')
    .height(this.winHeight > 0 ? this.winHeight : '100%')
    .backgroundColor(this.isBlackBg ? Color.Black: $r("app.color.start_window_background"))
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
