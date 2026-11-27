import 'dart:ui' show PointerDeviceKind;
import 'dart:math';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/native_top_spacer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/fav_type.dart';
import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/models_new/fav/fav_pgc/list.dart';
import 'package:PiliPlus/models_new/pgc/pgc_index_result/list.dart';
import 'package:PiliPlus/models_new/pgc/pgc_timeline/result.dart';
import 'package:PiliPlus/pages/pgc/controller.dart';
import 'package:PiliPlus/pages/pgc/widgets/pgc_card_v.dart';
import 'package:PiliPlus/pages/pgc/widgets/pgc_card_v_timeline.dart';
import 'package:PiliPlus/pages/pgc_index/controller.dart';
import 'package:PiliPlus/pages/pgc_index/view.dart';
import 'package:PiliPlus/pages/pgc_index/widgets/pgc_card_v_pgc_index.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

class PgcPage extends StatefulWidget {
  const PgcPage({
    super.key,
    required this.tabType,
  });

  final HomeTabType tabType;

  @override
  State<PgcPage> createState() => _PgcPageState();
}

class _PgcPageState extends State<PgcPage> with AutomaticKeepAliveClientMixin {
  late final PgcController controller;

  @override
  void initState() {
    controller = Get.put(
      PgcController(tabType: widget.tabType),
      tag: widget.tabType.name,
    );
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    return NativeTopRefreshIndicator(
      refreshKey: controller.refreshKey,
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 原生顶栏启用时顶部的可滚动留白（内容可滑入顶栏下方重合）
          const NativeTopSpacer(),
          _buildFollow(theme),
          if (controller.showPgcTimeline)
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    Grid.smallCardWidth / 2 / 0.75 +
                    MediaQuery.textScalerOf(context).scale(96),
                child: Obx(
                  () => _buildTimeline(theme, controller.timelineState.value),
                ),
              ),
            ),
          ..._buildRcmd(theme),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    ThemeData theme,
    LoadingState<List<TimelineResult>?> loadingState,
  ) => switch (loadingState) {
    Loading() => m3eLoading,
    Success(:final response) =>
      response != null && response.isNotEmpty
          ? Builder(
              builder: (context) {
                final initialIndex = max(
                  0,
                  response.indexWhere((item) => item.isToday == 1),
                );
                return DefaultTabController(
                  initialIndex: initialIndex,
                  length: response.length,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 12, 6),
                        child: Row(
                          children: [
                            Text(
                              '追番时间表',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: RepaintBoundary(
                                  child: Builder(
                                    builder: (context) {
                                      final isDark =
                                          theme.brightness == Brightness.dark;
                                      return Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: isDark
                                                ? [
                                                    Colors.white.withValues(
                                                      alpha: 0.10,
                                                    ),
                                                    Colors.white.withValues(
                                                      alpha: 0.06,
                                                    ),
                                                  ]
                                                : [
                                                    Colors.white.withValues(
                                                      alpha: 0.92,
                                                    ),
                                                    Colors.white.withValues(
                                                      alpha: 0.78,
                                                    ),
                                                  ],
                                          ),
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(18),
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.13,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.94,
                                                  ),
                                            width: 0.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: isDark ? 0.18 : 0.045,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(18),
                                          ),
                                          child: TabBar(
                                            isScrollable: true,
                                            tabAlignment: TabAlignment.start,
                                            dividerHeight: 0,
                                            overlayColor:
                                                const WidgetStatePropertyAll(
                                                  Colors.transparent,
                                                ),
                                            splashFactory:
                                                NoSplash.splashFactory,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            labelPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 2,
                                                ),
                                            indicatorPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 2,
                                                  vertical: 4,
                                                ),
                                            indicator: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.16,
                                                    )
                                                  : theme.colorScheme.primary
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    Radius.circular(15),
                                                  ),
                                            ),
                                            indicatorSize:
                                                TabBarIndicatorSize.tab,
                                            labelColor: isDark
                                                ? Colors.white
                                                : theme.colorScheme.primary,
                                            unselectedLabelColor: theme
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.65),
                                            labelStyle: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            unselectedLabelStyle:
                                                const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            dividerColor: Colors.transparent,
                                            tabs: response.map((item) {
                                              final text =
                                                  '${item.date} ${item.isToday == 1 ? '今天' : '周${const ['一', '二', '三', '四', '五', '六', '日'][item.dayOfWeek! - 1]}'}';
                                              return _PgcHoverTab(
                                                label: text,
                                                isDark: isDark,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: response.map((item) {
                            final episodes = item.episodes;
                            if (episodes == null || episodes.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: episodes.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: Grid.smallCardWidth / 2,
                                  margin: EdgeInsets.only(
                                    left: Style.safeSpace,
                                    right: index == episodes.length - 1
                                        ? Style.safeSpace
                                        : 0,
                                  ),
                                  child: PgcCardVTimeline(
                                    item: episodes[index],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    Error(:final errMsg) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.queryPgcTimeline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          errMsg ?? '',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  };

  List<Widget> _buildRcmd(ThemeData theme) => [
    _buildRcmdTitle(theme),
    SliverPadding(
      padding: const EdgeInsets.only(
        left: Style.safeSpace,
        right: Style.safeSpace,
        bottom: 100,
      ),
      sliver: Obx(
        () => _buildRcmdBody(controller.loadingState.value),
      ),
    ),
  ];

  Widget _buildRcmdTitle(ThemeData theme) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
        left: 16,
        right: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '推荐',
            style: theme.textTheme.titleMedium,
          ),
          moreTextButton(
            padding: const EdgeInsets.symmetric(vertical: 2),
            onTap: () {
              if (widget.tabType == HomeTabType.bangumi) {
                Get.to(const PgcIndexPage());
              } else {
                List<String> titles = const [
                  '全部',
                  '电影',
                  '电视剧',
                  '纪录片',
                  '综艺',
                ];
                List<int> types = const [102, 2, 5, 3, 7];
                Get.to(
                  SimpleScaffold(
                    appBar: AppBar(title: const Text('索引')),
                    body: DefaultTabController(
                      length: types.length,
                      child: Builder(
                        builder: (context) {
                          return Column(
                            children: [
                              ViewSafeArea(
                                child: TabBar(
                                  tabs: titles
                                      .map((title) => Tab(text: title))
                                      .toList(),
                                  onTap: (index) {
                                    try {
                                      if (!DefaultTabController.of(
                                        context,
                                      ).indexIsChanging) {
                                        Get.find<PgcIndexController>(
                                          tag: types[index].toString(),
                                        ).animateToTop();
                                      }
                                    } catch (_) {}
                                  },
                                ),
                              ),
                              Expanded(
                                child: tabBarView(
                                  children: types
                                      .map(
                                        (type) => PgcIndexPage(indexType: type),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            },
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    ),
  );

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth * 0.6,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(50),
  );

  Widget _buildRcmdBody(LoadingState<List<PgcIndexItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => const SliverToBoxAdapter(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  return PgcCardVPgcIndex(item: response[index]);
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

  Widget _buildFollow(ThemeData theme) => SliverToBoxAdapter(
    child: Obx(
      () => controller.accountService.isLogin.value
          ? Column(
              children: [
                _buildFollowTitle(theme),
                SizedBox(
                  height:
                      Grid.smallCardWidth / 2 / 0.75 +
                      MediaQuery.textScalerOf(context).scale(50),
                  child: Obx(
                    () => _buildFollowBody(controller.followState.value),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    ),
  );

  Widget _buildFollowTitle(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Row(
      children: [
        Obx(
          () => Text(
            '最近${widget.tabType == HomeTabType.bangumi ? '追番' : '追剧'}${controller.followCount.value == -1 ? '' : ' ${controller.followCount.value}'}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => controller
            ..followPage = 1
            ..followEnd = false
            ..queryPgcFollow(),
          icon: const Icon(
            Icons.refresh,
            size: 20,
          ),
        ),
        Obx(
          () => controller.accountService.isLogin.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: moreTextButton(
                    text: '查看全部',
                    onTap: () => Get.toNamed(
                      '/fav',
                      arguments: widget.tabType == HomeTabType.bangumi
                          ? FavTabType.bangumi.index
                          : FavTabType.cinema.index,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: theme.colorScheme.secondary,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  Widget _buildFollowBody(LoadingState<List<FavPgcItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => m3eLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? ListView.builder(
                controller: controller.followController,
                scrollDirection: Axis.horizontal,
                itemCount: response.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.queryPgcFollow(false);
                  }
                  return Container(
                    width: Grid.smallCardWidth / 2,
                    margin: EdgeInsets.only(
                      left: Style.safeSpace,
                      right: index == response.length - 1 ? Style.safeSpace : 0,
                    ),
                    child: PgcCardV(item: response[index]),
                  );
                },
              )
            : Center(
                child: Text(
                  '还没有${widget.tabType == HomeTabType.bangumi ? '追番' : '追剧'}',
                ),
              ),
      Error(:final errMsg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          errMsg ?? '',
          textAlign: TextAlign.center,
        ),
      ),
    };
  }
}

class _PgcHoverTab extends StatefulWidget {
  const _PgcHoverTab({
    required this.label,
    required this.isDark,
  });

  final String label;
  final bool isDark;

  @override
  State<_PgcHoverTab> createState() => _PgcHoverTabState();
}

class _PgcHoverTabState extends State<_PgcHoverTab> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 28,
      child: MouseRegion(
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
              scale: hovered ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: const Cubic(0.2, 0, 0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hovered
                      ? (widget.isDark ? Colors.white : Colors.black)
                            .withValues(alpha: widget.isDark ? 0.10 : 0.055)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: Text(widget.label),
        ),
      ),
    );
  }
}
