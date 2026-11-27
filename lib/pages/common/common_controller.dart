import 'dart:async';
import 'dart:math' as math;

import 'package:PiliPlus/common/utils/status_bar_tap.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/widgets.dart'
    show
        GlobalKey,
        IdleScrollActivity,
        ScrollActivity,
        ScrollContext,
        ScrollController,
        ScrollPhysics,
        ScrollPosition,
        ScrollPositionWithSingleContext;
import 'package:get/get.dart';

mixin RefreshImplMixin on ScrollOrRefreshMixin {
  @override
  final GlobalKey<RefreshIndicatorState> refreshKey = .new();

  @override
  Future<void> showRefresh() => refreshKey.currentState?.show() ?? onRefresh();
}

mixin ScrollOrRefreshMixin {
  ScrollController get scrollController;

  GlobalKey<RefreshIndicatorState>? get refreshKey => null;

  void animateToTop() => scrollController.animToTop();

  Future<void> onRefresh();

  Future<void> showRefresh() => onRefresh();

  void toTopOrRefresh() {
    if (scrollController.hasClients) {
      if (scrollController.position.pixels == 0) {
        EasyThrottle.throttle(
          'topOrRefresh',
          const Duration(milliseconds: 500),
          showRefresh,
        );
      } else {
        animateToTop();
      }
    }
  }
}

abstract class CommonController<R, T> extends GetxController
    with ScrollOrRefreshMixin {
  @override
  final ScrollController scrollController = SmoothWheelScrollController();

  late final StatusBarTapObserver statusBarTap = StatusBarTapObserver(
    scrollController: scrollController,
    animateToTop: animateToTop,
  );

  bool isLoading = false;
  Rx<LoadingState> get loadingState;

  Future<LoadingState<R>> customGetData();

  Future<void> queryData([bool isRefresh = true]);

  bool customHandleResponse(bool isRefresh, Success<R> response) {
    return false;
  }

  bool handleError(String? errMsg) {
    return false;
  }

  @override
  Future<void> onRefresh() {
    return queryData();
  }

  Future<void> onLoadMore() {
    return queryData(false);
  }

  Future<void> onReload() {
    return onRefresh();
  }

  @override
  void onInit() {
    super.onInit();
    statusBarTap
      ..routeName = Get.currentRoute
      ..register();
  }

  @override
  void onClose() {
    statusBarTap.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

/// 鼠标滚轮平滑滚动控制器：在底层 ScrollPosition.pointerScroll 处拦截离散跳变，
/// 改为累加目标偏移 + easeOutCubic 平滑追赶，触屏拖动时自动让位给原生手势。
class SmoothWheelScrollController extends ScrollController {
  SmoothWheelScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SmoothWheelScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _SmoothWheelScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothWheelScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  /// 指数阻尼系数（越大跟手越快，越小惯性越绵长；13.5 接近桌面浏览器平滑滚动）
  static const double _damping = 13.5;

  Ticker? _wheelTicker;
  Duration? _lastTickElapsed;
  double? _wheelTarget;

  void _stopWheelTicker() {
    if (_wheelTicker?.isActive ?? false) {
      _wheelTicker!.stop();
    }
    _lastTickElapsed = null;
    _wheelTarget = null;
  }

  void _onWheelTick(Duration elapsed) {
    final target = _wheelTarget;
    if (target == null || !hasPixels) {
      _stopWheelTicker();
      return;
    }
    final clampedTarget = target.clamp(minScrollExtent, maxScrollExtent);
    _wheelTarget = clampedTarget;

    final prev = _lastTickElapsed;
    _lastTickElapsed = elapsed;
    final dt = prev == null
        ? 1 / 60.0
        : ((elapsed - prev).inMicroseconds / 1000000.0).clamp(0.002, 0.05);

    final diff = clampedTarget - pixels;
    if (diff.abs() < 0.35) {
      final finalPos = clampedTarget;
      _stopWheelTicker();
      if (finalPos != pixels) {
        setPixels(finalPos);
      }
      return;
    }

    final factor = 1.0 - math.exp(-dt * _damping);
    final next = (pixels + diff * factor).clamp(
      minScrollExtent,
      maxScrollExtent,
    );
    setPixels(next);
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    // 任何触屏拖拽、惯性甩滑或程序动画开始时立刻让位
    if (newActivity != null && newActivity is! IdleScrollActivity) {
      _stopWheelTicker();
    }
    super.beginActivity(newActivity);
  }

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0 || !hasPixels) return;
    if (activity != null && activity is! IdleScrollActivity) {
      goIdle();
    }
    final base = _wheelTarget ?? pixels;
    final target = (base + delta * 1.15).clamp(
      minScrollExtent,
      maxScrollExtent,
    );
    if ((target - pixels).abs() < 0.35) {
      _stopWheelTicker();
      return;
    }
    _wheelTarget = target;
    _wheelTicker ??= context.vsync.createTicker(_onWheelTick);
    if (!_wheelTicker!.isActive) {
      _lastTickElapsed = null;
      _wheelTicker!.start();
    }
  }

  @override
  void dispose() {
    _stopWheelTicker();
    _wheelTicker?.dispose();
    _wheelTicker = null;
    super.dispose();
  }
}
