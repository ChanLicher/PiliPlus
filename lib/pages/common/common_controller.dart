import 'dart:async';

import 'package:PiliPlus/common/utils/status_bar_tap.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/widgets.dart'
    show
        DragScrollActivity,
        GlobalKey,
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

  double? _wheelTarget;
  int _wheelLastMs = 0;

  @override
  void beginActivity(ScrollActivity? newActivity) {
    if (newActivity is DragScrollActivity) {
      _wheelTarget = null;
    }
    super.beginActivity(newActivity);
  }

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = (_wheelTarget != null && now - _wheelLastMs < 260)
        ? _wheelTarget!
        : pixels;
    _wheelLastMs = now;
    final target = (base + delta * 1.15).clamp(
      minScrollExtent,
      maxScrollExtent,
    );
    if ((target - pixels).abs() < 0.5) {
      _wheelTarget = null;
      return;
    }
    _wheelTarget = target;
    animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}
