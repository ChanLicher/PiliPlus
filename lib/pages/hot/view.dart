import 'dart:ui' show PointerDeviceKind;

import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/native_top_spacer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/hot/controller.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

class HotPage extends StatefulWidget {
  const HotPage({super.key});

  @override
  State<HotPage> createState() => _HotPageState();
}

class _HotPageState extends State<HotPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  final HotController controller = Get.put(HotController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NativeTopRefreshIndicator(
      refreshKey: controller.refreshKey,
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: controller.scrollController,
        slivers: [
          // 原生顶栏启用时顶部的可滚动留白（内容可滑入顶栏下方重合）
          const NativeTopSpacer(),
          if (Pref.showHotRcmd)
            SliverToBoxAdapter(
              child: Padding(
                padding: const .fromLTRB(12, 10, 12, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.10),
                                  Colors.white.withValues(alpha: 0.06),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.92),
                                  Colors.white.withValues(alpha: 0.78),
                                ],
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.13)
                              : Colors.white.withValues(alpha: 0.94),
                          width: 0.85,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.20 : 0.05,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          _HotEntrancePill(
                            isDark: isDark,
                            iconUrl:
                                'https://i0.hdslb.com/bfs/archive/a3f11218aaf4521b4967db2ae164ecd3052586b9.png',
                            title: '排行榜',
                            onTap: () {
                              try {
                                final homeController =
                                    Get.find<HomeController>();
                                final index = homeController.tabs.indexOf(
                                  HomeTabType.rank,
                                );
                                if (index != -1) {
                                  homeController.tabController.animateTo(index);
                                } else {
                                  Get.to(
                                    SimpleScaffold(
                                      appBar: AppBar(
                                        title: const Text('排行榜'),
                                      ),
                                      body: const ViewSafeArea(
                                        child: RankPage(),
                                      ),
                                    ),
                                  );
                                }
                              } catch (_) {}
                            },
                          ),
                          _HotEntrancePill(
                            isDark: isDark,
                            iconUrl:
                                'https://i0.hdslb.com/bfs/archive/552ebe8c4794aeef30ebd1568b59ad35f15e21ad.png',
                            title: '每周必看',
                            onTap: () => Get.toNamed('/popularSeries'),
                          ),
                          _HotEntrancePill(
                            isDark: isDark,
                            iconUrl:
                                'https://i0.hdslb.com/bfs/archive/3693ec9335b78ca57353ac0734f36a46f3d179a9.png',
                            title: '入站必刷',
                            onTap: () => Get.toNamed('/popularPrecious'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 4, bottom: 100),
            sliver: Obx(
              () => _buildBody(controller.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<HotVideoItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  return VideoCardH(
                    videoItem: response[index],
                    onRemove: () => controller.loadingState
                      ..value.data!.removeAt(index)
                      ..refresh(),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }
}

class _HotEntrancePill extends StatefulWidget {
  const _HotEntrancePill({
    required this.isDark,
    required this.iconUrl,
    required this.title,
    required this.onTap,
  });

  final bool isDark;
  final String iconUrl;
  final String title;
  final VoidCallback onTap;

  @override
  State<_HotEntrancePill> createState() => _HotEntrancePillState();
}

class _HotEntrancePillState extends State<_HotEntrancePill> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (event) {
        if (event.kind == PointerDeviceKind.mouse && !_hovered.value) {
          _hovered.value = true;
        }
      },
      onExit: (_) {
        if (_hovered.value) _hovered.value = false;
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _hovered,
        builder: (context, hovered, child) {
          return AnimatedScale(
            scale: hovered ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: const Cubic(0.2, 0, 0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: hovered
                    ? (widget.isDark ? Colors.white : Colors.black).withValues(
                        alpha: widget.isDark ? 0.10 : 0.055,
                      )
                    : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: child,
            ),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  NetworkImgLayer(
                    width: 28,
                    height: 28,
                    type: ImageType.emote,
                    src: widget.iconUrl,
                  ),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
