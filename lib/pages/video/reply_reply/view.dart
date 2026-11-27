import 'package:PiliPlus/common/skeleton/video_reply.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/mini_scaffold.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/simple_colored_box.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_pinned_header.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/reply/reply_footer_mixin.dart';
import 'package:PiliPlus/pages/common/slide/common_slide_page.dart';
import 'package:PiliPlus/pages/video/reply/widgets/reply_item_grpc.dart';
import 'package:PiliPlus/pages/video/reply_reply/controller.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/extension/widget_ext.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:fixnum/fixnum.dart' show Int64;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class VideoReplyReplyPanel extends CommonSlidePage {
  const VideoReplyReplyPanel({
    super.key,
    super.enableSlide,
    this.id,
    required this.oid,
    required this.rpid,
    this.dialog,
    this.firstFloor,
    required this.isVideoDetail,
    required this.replyType,
    this.isNested = false,
    this.upMid,
  });
  final int? id;
  final int oid;
  final int rpid;
  final int? dialog;
  final ReplyInfo? firstFloor;
  final bool isVideoDetail;
  final int replyType;
  final bool isNested;
  final Int64? upMid;

  static Future<void>? toReply({
    required int oid,
    required int rootId,
    int? rpId,
    required int type,
    Uri? uri,
  }) {
    return Get.to(
      arguments: {
        'oid': oid,
        'rpid': rootId,
        'id': ?rpId,
        'type': type,
        'enterUri': ?uri?.toString(), // save panel
      },
      () => SimpleScaffold(
        appBar: AppBar(
          title: const Text('评论详情'),
          actions: [
            IconButton(
              tooltip: '前往',
              onPressed: uri == null
                  ? null
                  : () => PiliScheme.routePush(uri, businessId: type),
              icon: const Icon(Icons.open_in_browser),
            ),
          ],
        ),
        body: ViewSafeArea(
          child: VideoReplyReplyPanel(
            enableSlide: false,
            oid: oid,
            rpid: rootId,
            isVideoDetail: false,
            replyType: type,
            firstFloor: null,
            id: rpId,
          ),
        ).constraintWidth(),
      ),
    );
  }

  @override
  State<VideoReplyReplyPanel> createState() => _VideoReplyReplyPanelState();
}

class _VideoReplyReplyPanelState extends State<VideoReplyReplyPanel>
    with SingleTickerProviderStateMixin, CommonSlideMixin, ReplyFooterMixin {
  @override
  late final VideoReplyReplyController controller;
  late final _tag = Utils.makeHeroTag('${widget.rpid}${widget.dialog}');
  @override
  ColorScheme get colorScheme => theme.colorScheme;
  late final bool isDialogue = widget.dialog != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollSontroller = PrimaryScrollController.of(context);
    controller
      ..didChangeDependencies(context)
      ..nestedController = scrollSontroller is ExtendedNestedScrollController
          ? scrollSontroller
          : null;
  }

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      VideoReplyReplyController(
        hasRoot: widget.firstFloor != null,
        id: widget.id,
        oid: widget.oid,
        rpid: widget.rpid,
        dialog: widget.dialog,
        replyType: widget.replyType,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<VideoReplyReplyController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget buildPage() {
    Widget child() => enableSlide ? slideList() : buildList();
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F6F8);
    return SimpleColoredBox(
      color: pageBg,
      child: MiniScaffold(
        body: widget.isVideoDetail
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    child: RepaintBoundary(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.only(left: 14, right: 4),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              isDialogue ? '对话列表' : '评论详情',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                hoverColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.08),
                                onTap: Get.back,
                                child: const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Icon(Icons.close, size: 19),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: child()),
                ],
              )
            : child(),
      ),
    );
  }

  ReplyInfo? get firstFloor => widget.firstFloor ?? controller.firstFloor.value;

  ScrollController get scrollController =>
      controller.nestedController ?? controller.scrollController;

  @override
  Widget buildList() {
    return refreshIndicator(
      onRefresh: controller.onRefresh,
      isClampingScrollPhysics: widget.isNested,
      child: CustomScrollView(
        key: ValueKey(scrollController.hashCode),
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (!isDialogue) ...[
            if ((widget.firstFloor ?? controller.firstFloor.value)
                case final firstFloor?)
              _header(firstFloor)
            else
              Obx(() {
                final firstFloor = controller.firstFloor.value;
                if (firstFloor == null) {
                  return const SliverToBoxAdapter();
                }
                return _header(firstFloor);
              }),
            _sortWidget(theme.colorScheme),
          ],
          Obx(
            () => _buildBody(controller.loadingState.value),
          ),
        ],
      ),
    );
  }

  Widget _header(ReplyInfo firstFloor) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: ReplyItemGrpc(
            replyItem: firstFloor,
            replyLevel: 2,
            needDivider: false,
            onReply: (replyItem) => controller.onReply(replyItem, index: -1),
            upMid: widget.upMid ?? controller.upMid,
            onCheckReply: controller.onCheckReply,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
      ],
    );
  }

  Widget _sortWidget(ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    return SliverPinnedHeader(
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const .fromLTRB(10, 4, 10, 6),
        child: RepaintBoundary(
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 12, right: 6),
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
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.13)
                    : Colors.white.withValues(alpha: 0.94),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              spacing: 6,
              children: [
                Obx(
                  () {
                    final count = controller.count.value;
                    return count != -1
                        ? Text(
                            '相关回复共${NumUtils.numFormat(count)}条',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
                Obx(() {
                  controller.replyTree.value;
                  final active = controller.showReplyTree;
                  return Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      hoverColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08),
                      onTap: () {
                        if (controller.replyTree.rawValue != null) {
                          controller
                            ..showReplyTree = !controller.showReplyTree
                            ..replyTree.refresh();
                          return;
                        }

                        if (controller.isEnd && controller.foldCard == null) {
                          controller.buildTree();
                        } else if (controller.inFetchReply) {
                          SmartDialog.showToast('正在拉取评论，请稍后');
                        } else {
                          if (controller.foldCard != null) {
                            controller.nextReplyRound();
                            return;
                          }
                          final count = controller.count.rawValue;
                          if (count != -1) {
                            final total = (count / 20).ceil();
                            final remain = total - (controller.page - 1);
                            if (remain < 5) {
                              controller.nextReplyRound();
                              return;
                            }
                          }
                          showConfirmDialog(
                            context: context,
                            title: const Text('是否加载全部评论以显示线程化评论？'),
                            content: const Text('这将消耗一定流量\n且可能导致IP或账号风控'),
                            onConfirm: controller.nextReplyRound,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Icon(
                          Icons.view_comfortable_outlined,
                          size: 19,
                          color: active
                              ? colorScheme.primary
                              : colorScheme.outline,
                        ),
                      ),
                    ),
                  );
                }),
                Expanded(
                  child: Obx(
                    () => LinearProgressIndicator(
                      // ignore: deprecated_member_use
                      year2023: true,
                      borderRadius: const .all(.circular(4)),
                      value: controller.progress.value,
                      stopIndicatorColor: Colors.transparent,
                    ),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    hoverColor: (isDark ? Colors.white : Colors.black)
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
                          Obx(
                            () => Text(
                              controller.sortType.value.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<ReplyInfo>?> loadingState) {
    final jumpIndex = controller.index.value;
    switch (loadingState) {
      case Loading():
        return const SliverPrototypeExtentList(
          prototypeItem: VideoReplySkeleton(),
          delegate: SliverSingleChildDelegate(
            count: 8,
            child: VideoReplySkeleton(),
          ),
        );
      case Success(:final response!):
        if (controller.replyTree.value case final tree?
            when controller.showReplyTree) {
          return SuperSliverList.builder(
            listController: controller.listController,
            itemCount: tree.length + 1,
            itemBuilder: (context, index) {
              if (index == tree.length) {
                return buildEndItem();
              }

              final node = tree[index];
              final child = ReplyItemGrpc(
                replyItem: node.reply,
                replyLevel: 2,
                upMid: controller.upMid,
                onCheckReply: controller.onCheckReply,
                needDivider: false,
                depth: node.depth,
                reason: node.reason,
                onReply: (reply) => controller.onReplyByTreeNode(index, reply),
                onDelete: (reply, _) =>
                    controller.onRemoveByTreeNode(index, reply),
                collapsed: node.collapsed,
                toggleCollapse: node.isLeaf
                    ? null
                    : () => controller.toggleCollapseTree(index),
                onScrollLeft: node.depth > 0
                    ? () => controller.setIndexByTreeNode(index, node.parent)
                    : null,
              );
              if (jumpIndex == index) {
                return controller.colorAnimWrapper(colorScheme, child);
              }
              return child;
            },
          );
        } else {
          return SuperSliverList.builder(
            listController: controller.listController,
            itemBuilder: (context, index) {
              if (index == response.length) {
                return buildFooter();
              }

              final child = _replyItem(context, response[index], index);
              if (jumpIndex == index) {
                return controller.colorAnimWrapper(theme.colorScheme, child);
              }
              return child;
            },
            itemCount: response.length + 1,
          );
        }
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: controller.onReload,
        );
    }
  }

  Widget _replyItem(BuildContext context, ReplyInfo replyItem, int index) {
    return ReplyItemGrpc(
      replyItem: replyItem,
      replyLevel: isDialogue ? 3 : 2,
      onReply: (replyItem) => controller.onReply(replyItem, index: index),
      onDelete: (item, subIndex) => controller.onRemove(index, item, subIndex),
      upMid: controller.upMid,
      dialogueCallback: isDialogue
          ? _onJumpToParent
          : (replyItem) => _showDialogue(context, replyItem),
      getReplyChain: () => controller.getParentChain(index, firstFloor),
      onCheckReply: controller.onCheckReply,
    );
  }

  void _onJumpToParent(ReplyInfo replyItem) {
    if (!controller.setIndexById(replyItem.parent)) {
      SmartDialog.showToast('评论可能已被删除');
    }
  }

  void _showDialogue(BuildContext context, ReplyInfo replyItem) {
    MiniScaffold.of(context).showBottomSheet(
      constraints: const BoxConstraints(),
      (context) => VideoReplyReplyPanel(
        oid: replyItem.oid.toInt(),
        rpid: replyItem.root.toInt(),
        dialog: replyItem.dialog.toInt(),
        replyType: widget.replyType,
        isVideoDetail: true,
        isNested: widget.isNested,
      ),
    );
  }
}
