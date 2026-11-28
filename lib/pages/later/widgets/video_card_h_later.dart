import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/select_mask.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_transition.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 水平布局
class VideoCardHLater extends StatefulWidget {
  const VideoCardHLater({
    super.key,
    required this.ctr,
    required this.index,
    required this.videoItem,
    required this.onViewLater,
  });
  final int index;
  final BaseLaterController ctr;
  final LaterItemModel videoItem;
  final ValueChanged<int> onViewLater;

  @override
  State<VideoCardHLater> createState() => _VideoCardHLaterState();
}

class _VideoCardHLaterState extends State<VideoCardHLater> {
  bool _hovered = false;
  final GlobalKey _cardKey = GlobalKey();
  bool _pushing = false;

  bool get _isNormalVideo =>
      !(widget.videoItem.isPugv ?? false) && !(widget.videoItem.isPgc ?? false);

  String get _heroTag =>
      'later_h_${identityHashCode(this)}_${widget.videoItem.bvid ?? widget.videoItem.aid}';

  @override
  void dispose() {
    clearPendingVideoCardTransition(_heroTag);
    super.dispose();
  }

  Future<void> _onTapLater(BuildContext context) async {
    final videoItem = widget.videoItem;
    if (_isNormalVideo && widget.ctr is LaterController) {
      if (_pushing) return;
      _pushing = true;
      try {
        final useHero = !isVideoPageTransitionActive(_heroTag);
        if (useHero) {
          prepareVideoCardTransition(
            _heroTag,
            _cardKey.currentContext ?? context,
          );
        }
        final cid =
            videoItem.cid ??
            await SearchHttp.ab2c(
              aid: videoItem.aid,
              bvid: videoItem.bvid,
            );
        if (cid != null) {
          (widget.ctr as LaterController).openVideoWithHero(
            videoItem,
            cid,
            widget.index,
            heroTag: useHero ? _heroTag : null,
          );
        }
      } catch (err) {
        SmartDialog.showToast(err.toString());
      } finally {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _pushing = false;
        });
      }
      return;
    }
    await onPushLater(
      videoItem,
      onViewLater: widget.onViewLater,
      heroTag: _isNormalVideo ? _heroTag : null,
      context: _isNormalVideo ? (_cardKey.currentContext ?? context) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctr = widget.ctr;
    final videoItem = widget.videoItem;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enableMultiSelect = ctr.enableMultiSelect.value;
    const radius = BorderRadius.all(Radius.circular(14));
    final cardSurface = isDark
        ? const Color(0xFF1A1B1F)
        : const Color(0xFFFFFFFF);

    final onLongPress = enableMultiSelect
        ? null
        : () => ctr
            ..enableMultiSelect.value = true
            ..onSelect(videoItem);

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
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            onTap: enableMultiSelect
                ? () => ctr.onSelect(videoItem)
                : () => _onTapLater(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AspectRatio(
                          aspectRatio: Style.aspectRatio,
                          child: LayoutBuilder(
                            builder: (context, boxConstraints) {
                              final double maxWidth = boxConstraints.maxWidth;
                              final double maxHeight = boxConstraints.maxHeight;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  NetworkImgLayer(
                                    src: videoItem.pic,
                                    width: maxWidth,
                                    height: maxHeight,
                                    cacheWidth: videoItem.dimension?.cacheWidth,
                                  ),
                                  ?videoItem.label,
                                  ...videoItem.progressIndicator(
                                    theme.colorScheme,
                                  ),
                                  Positioned.fill(
                                    child: selectMask(
                                      theme.colorScheme,
                                      videoItem.checked,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        content(context, theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

    if (_isNormalVideo && !enableMultiSelect) {
      card = VideoCardHero(
        key: _cardKey,
        tag: _heroTag,
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

  Widget content(BuildContext context, ThemeData theme) {
    final videoItem = widget.videoItem;
    final isPgc = videoItem.isPgc == true && videoItem.bangumi != null;
    Widget stat = StatWidget(
      type: StatType.play,
      value: videoItem.stat?.view,
    );
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isPgc
                ? [
                    Text(
                      videoItem.bangumi!.season!.title!,
                      style: TextStyle(
                        fontSize: theme.textTheme.bodyMedium!.fontSize,
                        height: 1.42,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      videoItem.subtitle!,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    stat,
                  ]
                : [
                    Expanded(
                      child: Text(
                        videoItem.title!,
                        style: TextStyle(
                          fontSize: theme.textTheme.bodyMedium!.fontSize,
                          height: 1.42,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      videoItem.owner!.name!,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1,
                        color: theme.colorScheme.outline,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      spacing: 8,
                      children: [
                        stat,
                        StatWidget(
                          type: StatType.danmaku,
                          value: videoItem.stat?.danmaku,
                        ),
                      ],
                    ),
                  ],
          ),
          Positioned(
            right: 0,
            bottom: -6,
            child: iconButton(
              onPressed: () =>
                  widget.ctr.toViewDel(context, widget.index, videoItem.aid!),
              icon: const Icon(Icons.clear),
              iconColor: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> onPushLater(
  LaterItemModel item, {
  ValueChanged<int>? onViewLater,
  String? heroTag,
  BuildContext? context,
}) async {
  if (item.isPugv ?? false) {
    PageUtils.viewPugv(seasonId: item.aid);
    return;
  }
  if (item.isPgc ?? false) {
    if (item.bangumi?.epId != null) {
      PageUtils.viewPgc(epId: item.bangumi!.epId, viewLater: true);
    } else if (item.redirectUrl?.isNotEmpty == true) {
      PageUtils.viewPgcFromUri(item.redirectUrl!, viewLater: true);
    }
    return;
  }
  final useHero =
      onViewLater == null &&
      heroTag != null &&
      context != null &&
      !isVideoPageTransitionActive(heroTag);
  if (useHero) {
    prepareVideoCardTransition(heroTag, context);
  }
  try {
    final cid =
        item.cid ??
        await SearchHttp.ab2c(
          aid: item.aid,
          bvid: item.bvid,
        );
    if (cid != null) {
      if (onViewLater != null) {
        onViewLater(cid);
      } else {
        await PageUtils.toVideoPage(
          bvid: item.bvid,
          cid: cid,
          cover: item.pic,
          title: item.title,
          dimension: item.dimension,
          heroTag: useHero ? heroTag : null,
          extraArguments: const {'viewLater': true},
        );
      }
    }
  } catch (err) {
    SmartDialog.showToast(err.toString());
  }
}
