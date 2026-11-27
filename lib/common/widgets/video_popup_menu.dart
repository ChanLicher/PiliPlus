import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/video/ai_conclusion/view.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class _VideoCustomAction {
  final String title;
  final Widget icon;
  final VoidCallback onTap;
  const _VideoCustomAction(this.title, this.icon, this.onTap);
}

class VideoPopupMenu extends StatelessWidget {
  final double? iconSize;
  final double menuItemHeight;
  final BaseSimpleVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoPopupMenu({
    super.key,
    required this.iconSize,
    required this.videoItem,
    this.onRemove,
    this.menuItemHeight = 42,
  });

  List<_VideoCustomAction> _buildActions(BuildContext context) {
    return [
      if (videoItem.bvid?.isNotEmpty == true) ...[
        _VideoCustomAction(
          videoItem.bvid!,
          const Icon(CustomIcons.identifier_circle, size: 16),
          () => Utils.copyText(videoItem.bvid!),
        ),
        if (Accounts.main.isLogin)
          _VideoCustomAction(
            '稍后再看',
            const Icon(MdiIcons.clockTimeEightOutline, size: 16),
            () => UserHttp.toViewLater(bvid: videoItem.bvid),
          ),
        if (videoItem.cid != null && Pref.enableAi)
          _VideoCustomAction(
            'AI总结',
            const Icon(CustomIcons.ai_circle, size: 16),
            () async {
              final res = await UgcIntroController.getAiConclusion(
                videoItem.bvid!,
                videoItem.cid!,
                videoItem.owner.mid,
              );
              if (res != null && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Padding(
                      padding: const .symmetric(vertical: 14),
                      child: AiConclusionPanel.buildContent(
                        context,
                        Theme.of(context),
                        res,
                        tap: false,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
      ],
      if (videoItem is! SpaceArchiveItem) ...[
        _VideoCustomAction(
          '访问：${videoItem.owner.name}',
          const Icon(MdiIcons.accountCircleOutline, size: 16),
          () => Get.toNamed('/member?mid=${videoItem.owner.mid}'),
        ),
        _VideoCustomAction(
          '不感兴趣',
          const Icon(MdiIcons.thumbDownOutline, size: 16),
          () {
            final rcmd = Accounts.get(.recommend);
            if (rcmd.accessKey == null || rcmd.accessKey == "") {
              SmartDialog.showToast(
                rcmd.isLogin ? '请退出账号后重新登录' : '账号未登录',
              );
              return;
            }
            if (videoItem case final RcmdVideoItemAppModel item) {
              ThreePoint? tp = item.threePoint;
              if (tp == null) {
                SmartDialog.showToast("未能获取threePoint");
                return;
              }
              if (tp.dislikeReasons == null && tp.feedbacks == null) {
                SmartDialog.showToast(
                  "未能获取dislikeReasons或feedbacks",
                );
                return;
              }
              Widget actionButton(Reason? r, Reason? f) {
                return SearchText(
                  text: r?.name ?? f?.name ?? '未知',
                  onTap: (_) async {
                    Get.back();
                    SmartDialog.showLoading(msg: '正在提交');
                    final res = await VideoHttp.feedDislike(
                      reasonId: r?.id,
                      feedbackId: f?.id,
                      id: item.param!,
                      goto: item.goto!,
                    );
                    SmartDialog.dismiss();
                    if (res.isSuccess) {
                      SmartDialog.showToast(
                        r?.toast ?? f!.toast!,
                      );
                      onRemove?.call();
                    } else {
                      res.toast();
                    }
                  },
                );
              }

              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    contentPadding: const .fromLTRB(24, 16, 24, 24),
                    children: [
                      if (tp.dislikeReasons != null) ...[
                        const Text('我不想看'),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: tp.dislikeReasons!
                              .map((item) => actionButton(item, null))
                              .toList(),
                        ),
                      ],
                      if (tp.feedbacks != null) ...[
                        const SizedBox(height: 5),
                        const Text('反馈'),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: tp.feedbacks!
                              .map((item) => actionButton(null, item))
                              .toList(),
                        ),
                      ],
                      const Divider(),
                      Center(
                        child: FilledButton.tonal(
                          onPressed: () async {
                            SmartDialog.showLoading(
                              msg: '正在提交',
                            );
                            final res = await VideoHttp.feedDislikeCancel(
                              id: item.param!,
                              goto: item.goto!,
                            );
                            SmartDialog.dismiss();
                            SmartDialog.showToast(
                              res.isSuccess ? "成功" : res.toString(),
                            );
                            Get.back();
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text("撤销"),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  contentPadding: const .all(24),
                  children: [
                    const Center(child: Text("web端暂不支持精细选择")),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5.0,
                      runSpacing: 2.0,
                      alignment: .center,
                      children: [
                        FilledButton.tonal(
                          onPressed: () async {
                            Get.back();
                            SmartDialog.showLoading(msg: '正在提交');
                            final res = await VideoHttp.dislikeVideo(
                              bvid: videoItem.bvid!,
                              type: true,
                            );
                            SmartDialog.dismiss();
                            if (res.isSuccess) {
                              SmartDialog.showToast('点踩成功');
                              onRemove?.call();
                            } else {
                              res.toast();
                            }
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: .compact,
                          ),
                          child: const Text("点踩"),
                        ),
                        FilledButton.tonal(
                          onPressed: () async {
                            Get.back();
                            SmartDialog.showLoading(msg: '正在提交');
                            final res = await VideoHttp.dislikeVideo(
                              bvid: videoItem.bvid!,
                              type: false,
                            );
                            SmartDialog.dismiss();
                            SmartDialog.showToast(
                              res.isSuccess ? '取消踩' : res.toString(),
                            );
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: .compact,
                          ),
                          child: const Text("撤销"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        ),
        _VideoCustomAction(
          '拉黑：${videoItem.owner.name}',
          const Icon(MdiIcons.cancel, size: 16),
          () => showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('提示'),
                content: Text(
                  '确定拉黑:${videoItem.owner.name}(${videoItem.owner.mid})?'
                  '\n\n注：被拉黑的Up可以在隐私设置-黑名单管理中解除',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                      Pref.setBlackMid(videoItem.owner.mid!);
                      onRemove?.call();
                    },
                    child: const Text('本地屏蔽'),
                  ),
                  TextButton(
                    onPressed: Get.back,
                    child: Text(
                      '取消',
                      style: TextStyle(
                        color: ColorScheme.of(context).outline,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Get.back();
                      final res = await VideoHttp.relationMod(
                        mid: videoItem.owner.mid!,
                        act: 5,
                        reSrc: 11,
                      );
                      if (res.isSuccess) {
                        onRemove?.call();
                      } else {
                        res.toast();
                      }
                    },
                    child: const Text('确认'),
                  ),
                ],
              );
            },
          ),
        ),
      ],
      _VideoCustomAction(
        "${MineController.anonymity.value ? '退出' : '进入'}无痕模式",
        MineController.anonymity.value
            ? const Icon(MdiIcons.incognitoOff, size: 16)
            : const Icon(MdiIcons.incognito, size: 16),
        MineController.onChangeAnonymity,
      ),
    ];
  }

  void _openGlassMenu(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    if (button == null || overlay == null) return;

    final Offset topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Rect anchorRect = topLeft & button.size;
    final actions = _buildActions(context);

    Navigator.of(context, rootNavigator: true).push(
      _GlassVideoMenuRoute(
        anchorRect: anchorRect,
        actions: actions,
        menuItemHeight: menuItemHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _openGlassMenu(context),
        customBorder: const CircleBorder(),
        hoverColor: (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.08,
        ),
        splashColor: (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.12,
        ),
        child: Center(
          child: Icon(
            Icons.more_vert_outlined,
            color: theme.colorScheme.outline,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _GlassVideoMenuRoute extends PopupRoute<void> {
  _GlassVideoMenuRoute({
    required this.anchorRect,
    required this.actions,
    required this.menuItemHeight,
  });

  final Rect anchorRect;
  final List<_VideoCustomAction> actions;
  final double menuItemHeight;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 130);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final estimatedHeight = actions.length * menuItemHeight + 14.0;
    final spaceBelow =
        mediaQuery.size.height - mediaQuery.padding.bottom - anchorRect.bottom;
    final openAbove =
        spaceBelow < estimatedHeight + 12 &&
        anchorRect.top - mediaQuery.padding.top > spaceBelow;
    final alignRight = anchorRect.center.dx > mediaQuery.size.width * 0.5;
    final scaleAlignment = Alignment(
      alignRight ? 1.0 : -1.0,
      openAbove ? 1.0 : -1.0,
    );

    final curved = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.2, 0, 0, 1),
      reverseCurve: Curves.easeIn,
    );

    return CustomSingleChildLayout(
      delegate: _GlassMenuPositionDelegate(
        anchorRect: anchorRect,
        safePadding: mediaQuery.padding,
        openAbove: openAbove,
        alignRight: alignRight,
      ),
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          alignment: scaleAlignment,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1D1E22).withValues(alpha: 0.78)
                        : Colors.white.withValues(alpha: 0.80),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.92),
                      width: 0.9,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 168,
                      maxWidth: 256,
                    ),
                    child: IntrinsicWidth(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: actions.map((action) {
                            return Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(11),
                                ),
                                hoverColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.08),
                                splashColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.12),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  action.onTap();
                                },
                                child: SizedBox(
                                  height: menuItemHeight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconTheme(
                                          data: IconThemeData(
                                            size: 16,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.82),
                                          ),
                                          child: action.icon,
                                        ),
                                        const SizedBox(width: 9),
                                        Flexible(
                                          child: Text(
                                            action.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMenuPositionDelegate extends SingleChildLayoutDelegate {
  _GlassMenuPositionDelegate({
    required this.anchorRect,
    required this.safePadding,
    required this.openAbove,
    required this.alignRight,
  });

  final Rect anchorRect;
  final EdgeInsets safePadding;
  final bool openAbove;
  final bool alignRight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth = (constraints.maxWidth - 20).clamp(168.0, 268.0);
    final maxHeight =
        (constraints.maxHeight - safePadding.top - safePadding.bottom - 20)
            .clamp(80.0, constraints.maxHeight);
    return BoxConstraints.loose(Size(maxWidth, maxHeight));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double edgeMargin = 10.0;
    double x = alignRight
        ? anchorRect.right - childSize.width
        : anchorRect.left;
    x = x.clamp(
      safePadding.left + edgeMargin,
      (size.width - safePadding.right - childSize.width - edgeMargin).clamp(
        safePadding.left + edgeMargin,
        size.width,
      ),
    );

    double y = openAbove
        ? anchorRect.top - childSize.height - 6
        : anchorRect.bottom + 6;
    y = y.clamp(
      safePadding.top + edgeMargin,
      (size.height - safePadding.bottom - childSize.height - edgeMargin).clamp(
        safePadding.top + edgeMargin,
        size.height,
      ),
    );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_GlassMenuPositionDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        safePadding != oldDelegate.safePadding ||
        openAbove != oldDelegate.openAbove ||
        alignRight != oldDelegate.alignRight;
  }
}
