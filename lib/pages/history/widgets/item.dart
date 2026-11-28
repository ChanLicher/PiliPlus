import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/select_mask.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_transition.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:PiliPlus/pages/article/view.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HistoryItem extends StatefulWidget {
  final HistoryItemModel item;
  final MultiSelectBase ctr;
  final void Function(int kid, String business) onDelete;

  const HistoryItem({
    super.key,
    required this.item,
    required this.ctr,
    required this.onDelete,
  });

  @override
  State<HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<HistoryItem> {
  bool _hovered = false;
  final _menuBtnKey = GlobalKey();

  bool get _isNormalVideo {
    final b = widget.item.history.business;
    return b?.contains('article') != true &&
        b != 'live' &&
        b != 'pgc' &&
        b != 'cheese';
  }

  void _showGlassMenu(BuildContext context, String? business) {
    final item = widget.item;
    final box = _menuBtnKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final media = MediaQuery.of(context);
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    final entries = <({IconData icon, String label, VoidCallback onTap})>[
      if (item.authorMid != null && item.authorName?.isNotEmpty == true)
        (
          icon: MdiIcons.accountCircleOutline,
          label: '访问：${item.authorName}',
          onTap: () => Get.toNamed('/member?mid=${item.authorMid}'),
        ),
      if (business != 'pgc' &&
          item.badge != '番剧' &&
          item.tagName?.contains('动画') != true &&
          business != 'live' &&
          business?.contains('article') != true)
        (
          icon: Icons.watch_later_outlined,
          label: '稍后再看',
          onTap: () => UserHttp.toViewLater(bvid: item.history.bvid),
        ),
      (
        icon: Icons.close_outlined,
        label: '删除记录',
        onTap: () => widget.onDelete(item.kid!, business!),
      ),
    ];

    late OverlayEntry entry;
    void dismiss() {
      if (entry.mounted) entry.remove();
    }

    const menuWidth = 176.0;
    final estHeight = entries.length * 40.0 + 12.0;
    double left = pos.dx + size.width - menuWidth;
    left = left.clamp(12.0, media.size.width - menuWidth - 12.0);
    double top = pos.dy + size.height + 4;
    if (top + estHeight > media.size.height - media.padding.bottom - 12) {
      top = (pos.dy - estHeight - 4).clamp(
        media.padding.top + 12,
        media.size.height - estHeight - 12,
      );
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        const radius = BorderRadius.all(Radius.circular(16));
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
                onSecondaryTap: dismiss,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.42 : 0.14,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xCC1E1F24)
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: radius,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.95),
                          width: 0.9,
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final e in entries)
                                InkWell(
                                  onTap: () {
                                    dismiss();
                                    e.onTap();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    child: Row(
                                      spacing: 8,
                                      children: [
                                        Icon(e.icon, size: 16),
                                        Expanded(
                                          child: Text(
                                            e.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ctr = widget.ctr;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDuration = item.hasDuration;
    final business = item.history.business;
    final enableMultiSelect = ctr.enableMultiSelect.value;
    const radius = BorderRadius.all(Radius.circular(14));
    final heroTag = 'history_${item.history.oid}_${item.viewAt}';
    final cardSurface = isDark
        ? const Color(0xFF1A1B1F)
        : const Color(0xFFFFFFFF);

    final onLongPress = enableMultiSelect
        ? null
        : () => ctr
            ..enableMultiSelect.value = true
            ..onSelect(item);

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: _hovered ? 0.085 : 0.055)
            : Colors.white.withValues(alpha: _hovered ? 0.93 : 0.85),
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: _hovered ? 0.17 : 0.10)
              : Colors.white.withValues(alpha: 0.95),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? (_hovered ? 0.28 : 0.18)
                  : (_hovered ? 0.08 : 0.04),
            ),
            blurRadius: _hovered ? 14 : 9,
            offset: Offset(0, _hovered ? 5 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enableMultiSelect
                ? () => ctr.onSelect(item)
                : () => onPushHistory(
                    item,
                    heroTag: _isNormalVideo ? heroTag : null,
                    context: _isNormalVideo ? context : null,
                  ),
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: Style.aspectRatio,
                        child: LayoutBuilder(
                          builder: (context, boxConstraints) {
                            double maxWidth = boxConstraints.maxWidth;
                            double maxHeight = boxConstraints.maxHeight;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                NetworkImgLayer(
                                  src: item.cover?.isNotEmpty == true
                                      ? item.cover
                                      : item.covers?.firstOrNull ?? '',
                                  width: maxWidth,
                                  height: maxHeight,
                                ),
                                ?item.label,
                                if (hasDuration)
                                  ...item.progressIndicator(theme.colorScheme),
                                Positioned.fill(
                                  child: selectMask(
                                    theme.colorScheme,
                                    item.checked,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      content(theme),
                    ],
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 4,
                  width: 30,
                  height: 30,
                  child: IconButton(
                    key: _menuBtnKey,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    onPressed: () => _showGlassMenu(context, business),
                    icon: Icon(
                      Icons.more_vert_outlined,
                      color: theme.colorScheme.outline,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_isNormalVideo && !enableMultiSelect) {
      card = VideoCardHero(
        tag: heroTag,
        surfaceColor: cardSurface,
        cornerRadius: 14,
        child: card,
      );
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Style.safeSpace,
          vertical: 4,
        ),
        child: MouseRegion(
          onHover: (e) {
            if (e.kind == PointerDeviceKind.mouse && !_hovered) {
              setState(() => _hovered = true);
            }
          },
          onExit: (_) {
            if (_hovered) setState(() => _hovered = false);
          },
          child: card,
        ),
      ),
    );
  }

  Widget content(ThemeData theme) {
    final item = widget.item;
    return Expanded(
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title!,
            style: TextStyle(
              fontSize: theme.textTheme.bodyMedium!.fontSize,
              height: 1.42,
              letterSpacing: 0.3,
            ),
            maxLines: item.videos! > 1 ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.history.business == 'pgc' &&
              item.showTitle?.isNotEmpty == true)
            Text(
              item.showTitle!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.outline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          if (item.authorName?.isNotEmpty == true)
            Text(
              item.authorName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: theme.textTheme.labelMedium!.fontSize,
                color: theme.colorScheme.outline,
              ),
            ),
          Text(
            DateFormatUtils.chatFormat(item.viewAt!, isHistory: true),
            style: TextStyle(
              fontSize: theme.textTheme.labelMedium!.fontSize,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> onPushHistory(
  HistoryItemModel item, {
  String? heroTag,
  BuildContext? context,
}) async {
  final business = item.history.business;
  if (business?.contains('article') == true) {
    ArticlePage.toArticlePage(
      id: (business == 'article-list' ? item.history.cid : item.history.oid)
          .toString(),
      type: .read,
    );
  } else if (business == 'live') {
    if (item.liveStatus == 1) {
      PageUtils.toLiveRoom(item.history.oid);
    } else {
      SmartDialog.showToast('直播未开播');
    }
  } else if (business == 'pgc') {
    PageUtils.viewPgc(
      epId: item.history.epid,
      progress: item.playbackProgress,
    );
  } else if (business == 'cheese') {
    if (item.uri?.isNotEmpty == true) {
      PageUtils.viewPgcFromUri(
        item.uri!,
        isPgc: false,
        aid: item.history.oid,
        progress: item.playbackProgress,
      );
    }
  } else {
    final useHero =
        heroTag != null &&
        context != null &&
        !isVideoPageTransitionActive(heroTag);
    if (useHero) {
      prepareVideoCardTransition(heroTag, context);
    }
    final aid = item.history.oid!;
    final bvid = item.history.bvid ?? IdUtils.av2bv(aid);
    int? cid = item.history.cid;
    Dimension? dimension;
    if (cid == null) {
      if (await SearchHttp.ab2cWithDimension(
            aid: aid,
            bvid: bvid,
            part: item.history.page,
          )
          case final res?) {
        cid = res.cid;
        dimension = res.dimension;
      }
    }
    if (cid != null) {
      // TODO: dimension
      PageUtils.toVideoPage(
        aid: aid,
        bvid: bvid,
        cid: cid,
        cover: item.cover,
        title: item.title,
        dimension: dimension,
        progress: item.playbackProgress,
        heroTag: useHero ? heroTag : null,
      );
    }
  }
}
