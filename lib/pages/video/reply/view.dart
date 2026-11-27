import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/skeleton/video_reply.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo, MainListReply;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/fab_mixin.dart';
import 'package:PiliPlus/pages/common/reply/reply_footer_mixin.dart';
import 'package:PiliPlus/pages/common/reply/vote/reply_vote_item.dart';
import 'package:PiliPlus/pages/video/reply/controller.dart';
import 'package:PiliPlus/pages/video/reply/widgets/reply_item_grpc.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VideoReplyPanel extends StatefulWidget {
  const VideoReplyPanel({
    super.key,
    this.replyLevel = 1,
    required this.heroTag,
    required this.isNested,
  });

  final int replyLevel;
  final String heroTag;
  final bool isNested;

  @override
  State<VideoReplyPanel> createState() => _VideoReplyPanelState();
}

class _VideoReplyPanelState extends State<VideoReplyPanel>
    with
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin,
        BaseFabMixin,
        FabMixin,
        ReplyFooterMixin<VideoReplyPanel, MainListReply> {
  @override
  late ColorScheme colorScheme;
  @override
  late VideoReplyController controller;

  String get heroTag => widget.heroTag;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<VideoReplyController>(tag: heroTag);
    if (controller.loadingState.value is Loading) {
      controller.queryData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.didChangeDependencies(context);
    colorScheme = ColorScheme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return fabAnimWrapper(
      child: refreshIndicator(
        onRefresh: controller.onRefresh,
        isClampingScrollPhysics: widget.isNested,
        child: ScaffoldLayout(
          body: CustomScrollView(
            controller: widget.isNested ? null : controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            key: const PageStorageKey(_VideoReplyPanelState),
            slivers: [
              SliverFloatingHeaderWidget(
                backgroundColor: Colors.transparent,
                child: Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Padding(
                      padding: const .fromLTRB(12, 4, 12, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: RepaintBoundary(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.only(left: 14, right: 6),
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
                                Radius.circular(18),
                              ),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.13)
                                    : Colors.white.withValues(alpha: 0.94),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.20 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Obx(() {
                              final sortType = controller.sortType.value;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    sortType.desc,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    width: 0.8,
                                    height: 14,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.12),
                                  ),
                                  Material(
                                    type: MaterialType.transparency,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(14),
                                      ),
                                      hoverColor:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.06),
                                      onTap: controller.queryBySort,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          spacing: 4,
                                          children: [
                                            Icon(
                                              Icons.sort,
                                              size: 15,
                                              color: colorScheme.primary,
                                            ),
                                            Text(
                                              sortType.descShort,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Obx(() => _buildBody(controller.loadingState.value)),
            ],
          ),
          fab: SlideTransition(
            position: fabAnimation,
            child: Padding(
              padding: .only(
                right: kFloatingActionButtonMargin,
                bottom: kFloatingActionButtonMargin + padding.bottom,
              ),
              child: Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.36 : 0.14,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF23252A)
                                      .withValues(alpha: 0.78)
                                : Colors.white.withValues(alpha: 0.84),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.94),
                              width: 0.9,
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              hoverColor:
                                  (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.08),
                              onTap: () {
                                feedBack();
                                controller.onReply(
                                  null,
                                  oid: controller.videoCtr.aid,
                                  replyType: controller.replyType,
                                  mentionItem: controller.mentionItem,
                                );
                              },
                              child: Center(
                                child: Icon(
                                  Icons.reply,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<ReplyInfo>?> loadingState) {
    switch (loadingState) {
      case Loading():
        return const SliverPrototypeExtentList(
          prototypeItem: VideoReplySkeleton(),
          delegate: SliverSingleChildDelegate(
            count: 5,
            child: VideoReplySkeleton(),
          ),
        );
      case Success(:final response):
        if (response != null && response.isNotEmpty) {
          var count = response.length + 1;
          final voteCard = controller.voteCard;
          final hasVote = voteCard != null;
          if (hasVote) {
            count++;
          }
          return SliverList.builder(
            itemBuilder: (context, index) {
              if (hasVote) {
                if (index == 0) {
                  return buildVoteCard(context, colorScheme, voteCard);
                } else {
                  index--;
                }
              }
              if (index == response.length) {
                return buildFooter();
              } else {
                final item = response[index];
                final child = ReplyItemGrpc(
                  replyItem: item,
                  replyLevel: widget.replyLevel,
                  replyReply: controller.replyReply,
                  onReply: controller.onReply,
                  onDelete: (item, subIndex) =>
                      controller.onRemove(index, item, subIndex),
                  upMid: controller.upMid,
                  getTag: () => heroTag,
                  onCheckReply: controller.onCheckReply,
                  onToggleTop: (item) => controller.onToggleTop(
                    item,
                    index,
                    controller.videoCtr.aid,
                    controller.replyType,
                  ),
                );
                if (item.id == controller.targetRootRpId) {
                  return controller.colorAnimWrapper(
                    colorScheme,
                    child,
                  );
                }
                return child;
              }
            },
            itemCount: count,
          );
        }

        final child = emptyWidget();
        if (controller.voteCard case final voteCard?) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: buildVoteCard(context, colorScheme, voteCard),
              ),
              child,
            ],
          );
        }
        return child;
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: controller.onReload,
        );
    }
  }
}
