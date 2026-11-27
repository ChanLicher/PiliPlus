import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/native_top_spacer.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/pair.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_pinned_header.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/live/live_feed_index/card_data_list_item.dart';
import 'package:PiliPlus/models_new/live/live_feed_index/card_list.dart';
import 'package:PiliPlus/pages/live/controller.dart';
import 'package:PiliPlus/pages/live/widgets/live_item_app.dart';
import 'package:PiliPlus/pages/live/widgets/sliver_pinned_header.dart';
import 'package:PiliPlus/pages/live_area/view.dart';
import 'package:PiliPlus/pages/live_follow/view.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage>
    with AutomaticKeepAliveClientMixin {
  final LiveController controller = Get.put(LiveController());
  late TextScaler textScaler;
  late ColorScheme colorScheme;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    textScaler = MediaQuery.textScalerOf(context);
    colorScheme = ColorScheme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: Style.safeSpace),
      decoration: const BoxDecoration(borderRadius: Style.mdRadius),
      child: NativeTopRefreshIndicator(
        refreshKey: controller.refreshKey,
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 原生顶栏启用时顶部的可滚动留白（内容可滑入顶栏下方重合）
            const NativeTopSpacer(),
            Obx(() => _buildTop(controller.topState.value)),
            Obx(() => _buildBody(controller.loadingState.value)),
            const SliverPadding(padding: .only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTop(Pair<LiveCardList?, LiveCardList?> data) {
    final list = data.second?.cardData?.areaEntranceV3?.list;
    if (list == null) return const SliverToBoxAdapter();

    final areaHeight = 10.0 + textScaler.scale(14);
    final area = _buildLiveArea(list, areaHeight);

    final follow = data.first;
    if (follow != null) {
      return LiveSliverPinnedHeader(
        areaHeight: areaHeight + 24 /* padding */,
        backgroundColor: Colors.transparent,
        callback: controller.onTopHeightChanged,
        child: Column(
          children: [_buildFollowCard(follow), area],
        ),
      );
    }

    controller.onTopHeightChanged(0.0);
    return SliverPinnedHeader(
      backgroundColor: Colors.transparent,
      child: area,
    );
  }

  BoxDecoration _glassCapsuleDecoration(bool isDark, {double radius = 18}) {
    return BoxDecoration(
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
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.13)
            : Colors.white.withValues(alpha: 0.94),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildFollowCard(LiveCardList item) {
    final isDark = colorScheme.isDark;
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 2),
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
        decoration: _glassCapsuleDecoration(isDark, radius: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [..._buildFollowList(item)],
        ),
      ),
    );
  }

  Widget _buildLiveArea(List<CardLiveItem> list, double areaHeight) {
    final isDark = colorScheme.isDark;
    return Padding(
      padding: const .symmetric(vertical: 8.0),
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: _glassCapsuleDecoration(isDark, radius: 18),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  // 10+14*textScaler
                  height: areaHeight,
                  child: Obx(() {
                    final areaIndex = controller.areaIndex.value;
                    return ListView.separated(
                      scrollDirection: .horizontal,
                      padding: const .only(right: 8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final isFirst = index == 0;
                        late final item = list[index - 1];
                        final isCurr = index == areaIndex;
                        return SearchText(
                          height: 1,
                          fontSize: 13.5,
                          padding: const .symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          text: isFirst ? '推荐' : item.title!,
                          bgColor: isCurr
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      ))
                              : Colors.transparent,
                          textColor: isCurr
                              ? (isDark ? Colors.white : colorScheme.primary)
                              : colorScheme.onSurface.withValues(alpha: 0.72),
                          onTap: (_) => controller.onSelectArea(
                            index,
                            isFirst ? null : item,
                          ),
                        );
                      },
                      itemCount: list.length + 1,
                    );
                  }),
                ),
              ),
              Container(
                width: 0.8,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.12,
                ),
              ),
              iconButton(
                size: 28,
                iconSize: 18,
                context: context,
                icon: controller.showFirstFrame
                    ? const Icon(MdiIcons.alphaFBox)
                    : const Icon(MdiIcons.image),
                onPressed: () {
                  controller.showFirstFrame = !controller.showFirstFrame;
                  setState(() {});
                },
              ),
              const SizedBox(width: 4),
              iconButton(
                size: 28,
                iconSize: 16,
                context: context,
                icon: const Icon(Icons.gamepad),
                onPressed: () => Get.toNamed(
                  '/webview',
                  parameters: {
                    'uaType': 'mob',
                    'url':
                        'https://www.bilibili.com/h5/match/data/home?navhide=1&${ThemeUtils.themeUrl(colorScheme.isDark)}',
                  },
                ),
              ),
              const SizedBox(width: 4),
              iconButton(
                size: 28,
                iconSize: 16,
                context: context,
                icon: const Icon(Icons.widgets),
                onPressed: () => Get.to(const LiveAreaPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: textScaler.scale(90),
  );

  Widget _buildBody(LoadingState<List?> loadingState) {
    return switch (loadingState) {
      Loading() => SliverPadding(
        padding: const .only(top: Style.cardSpace),
        sliver: SliverGrid(
          gridDelegate: gridDelegate,
          delegate: const SliverSingleChildDelegate(
            child: VideoCardVSkeleton(),
            count: 10,
          ),
        ),
      ),
      Success(:final response) => SliverMainAxisGroup(
        slivers: [
          if (controller.newTags case final newTags? when newTags.isNotEmpty)
            SliverPinnedHeader(
              backgroundColor: Colors.transparent,
              child: Padding(
                padding: const .only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RepaintBoundary(
                    child: Container(
                      height: 18.0 + textScaler.scale(13),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: _glassCapsuleDecoration(
                        colorScheme.isDark,
                        radius: 16,
                      ),
                      child: Obx(() {
                        final isDark = colorScheme.isDark;
                        final tagIndex = controller.tagIndex.value;
                        return ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: .horizontal,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final item = newTags[index];
                            final isCurr = index == tagIndex;
                            return SearchText(
                              height: 1,
                              fontSize: 12.5,
                              padding: const .symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              text: item.name!,
                              bgColor: isCurr
                                  ? (isDark
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : colorScheme.primary.withValues(
                                            alpha: 0.12,
                                          ))
                                  : Colors.transparent,
                              textColor: isCurr
                                  ? (isDark
                                        ? Colors.white
                                        : colorScheme.primary)
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                              onTap: (value) =>
                                  controller.onSelectTag(index, item.sortType),
                            );
                          },
                          itemCount: newTags.length,
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          response != null && response.isNotEmpty
              ? SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    if (index == response.length - 1) {
                      controller.onLoadMore();
                    }
                    final item = response[index];
                    if (item is LiveCardList) {
                      return LiveCardVApp(
                        item: item.cardData!.smallCardV1!,
                        showFirstFrame: controller.showFirstFrame,
                      );
                    }
                    return LiveCardVApp(
                      item: item,
                      showFirstFrame: controller.showFirstFrame,
                    );
                  },
                  itemCount: response.length,
                )
              : HttpError(onReload: controller.onReload),
        ],
      ),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Iterable<Widget> _buildFollowList(LiveCardList item) sync* {
    final totalCount = item.cardData?.myIdolV1?.extraInfo?.totalCount ?? 0;
    final list = item.cardData?.myIdolV1?.list;
    final hasFollow = list != null && list.isNotEmpty;
    yield Padding(
      padding: hasFollow
          ? const .symmetric(vertical: 8.0)
          : const .only(top: 8),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '我的关注  '),
                TextSpan(
                  text: totalCount.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                  ),
                ),
                TextSpan(
                  text: '人正在直播',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          moreTextButton(
            onTap: () => Get.to(const LiveFollowPage()),
            color: colorScheme.outline,
          ),
        ],
      ),
    );
    if (hasFollow) {
      yield _buildFollowBody(list, totalCount);
    }
  }

  Widget _buildFollowBody(
    List<CardLiveItem> followList,
    int totalCount,
  ) {
    final listLength = followList.length;
    return SizedBox(
      // 3+4+45+6+2+12*textScaler
      height: 60.0 + textScaler.scale(12),
      child: CustomScrollView(
        scrollDirection: Axis.horizontal,
        controller: controller.followController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFixedExtentList.builder(
            itemExtent: 70,
            itemCount: totalCount > listLength ? listLength + 1 : listLength,
            itemBuilder: (context, index) {
              if (index == listLength) {
                return Align(
                  alignment: const Alignment(0, -0.3),
                  child: GestureDetector(
                    onTap: () => Get.to(const LiveFollowPage()),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: .circle,
                        color: colorScheme.onInverseSurface,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              final item = followList[index];
              return Padding(
                padding: const .only(right: 5),
                child: SizedBox(
                  width: 65,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => PageUtils.toLiveRoom(item.roomid),
                    onLongPress: () {
                      Feedback.forLongPress(context);
                      Get.toNamed('/member?mid=${item.uid}');
                    },
                    onSecondaryTap: PlatformUtils.isMobile
                        ? null
                        : () => Get.toNamed('/member?mid=${item.uid}'),
                    child: Column(
                      spacing: 6,
                      mainAxisSize: .min,
                      children: [
                        Container(
                          padding: const .all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.5,
                              color: colorScheme.primary,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                            shape: .circle,
                          ),
                          child: NetworkImgLayer(
                            type: .avatar,
                            width: 45,
                            height: 45,
                            src: item.face,
                          ),
                        ),
                        Text(
                          item.uname!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
