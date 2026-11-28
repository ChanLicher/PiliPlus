import 'dart:io' show Platform;

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart'
    show pushVideoH;
import 'package:PiliPlus/common/widgets/video_card/video_card_transition.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:material_ui/material_ui.dart';

const _kItemWidth = 140.0;
const _kItemHeight = _kItemWidth / Style.aspectRatio16x9;
const _kRadius = Radius.circular(10);
const _kBorderRadius = BorderRadius.all(_kRadius);

class SearchAllUserItem extends StatelessWidget {
  const SearchAllUserItem({
    super.key,
    required this.item,
  });

  final SearchUser item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final descStyle = TextStyle(color: colorScheme.outline, fontSize: 12.5);
    const cardRadius = BorderRadius.all(Radius.circular(18));

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.84),
          borderRadius: cardRadius,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.11)
                : Colors.white.withValues(alpha: 0.92),
            width: 0.85,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: cardRadius,
          child: Material(
            type: .transparency,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                InkWell(
                  onTap: () => Get.toNamed('/member?mid=${item.mid}'),
                  hoverColor: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
                  child: Padding(
                    padding: const .fromLTRB(12, 10, 12, 10),
                    child: Row(
                      spacing: 10,
                      children: [
                        PendantAvatar(
                          item.upic,
                          size: 50,
                          liveBottom: -3,
                          liveFontSize: 11,
                          officialType: item.officialVerify?.type,
                          roomId: item.isLive == 1 ? item.roomId : null,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: .min,
                            crossAxisAlignment: .start,
                            children: [
                              Row(
                                spacing: 6,
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.uname!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  BiliUtils.levelPicture(
                                    item.level!,
                                    isSeniorMember: item.isSeniorMember == 1,
                                    height: 11,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  text:
                                      '${NumUtils.numFormat(item.fans)}粉丝 · ${NumUtils.numFormat(item.videos)}个视频',
                                  children: item.officialVerify?.desc != null
                                      ? [
                                          TextSpan(
                                            text:
                                                '    ${item.officialVerify!.desc}',
                                          ),
                                        ]
                                      : null,
                                ),
                                maxLines: 1,
                                style: descStyle,
                                overflow: .ellipsis,
                              ),
                              if (item.usign case final sign?
                                  when sign.isNotEmpty)
                                Text(
                                  sign,
                                  maxLines: 1,
                                  style: descStyle,
                                  overflow: .ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (item.res case final list? when list.isNotEmpty)
                  Padding(
                    padding: const .only(top: 2, bottom: 12),
                    child: SizedBox(
                      height:
                          _kItemHeight +
                          MediaQuery.textScalerOf(context).scale(60),
                      child: ListView.builder(
                        itemCount: list.length,
                        scrollDirection: .horizontal,
                        itemExtent: _kItemWidth + 10,
                        padding: const .only(left: 12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final video = list[index];
                          return _SearchUserVideoItem(
                            colorScheme: colorScheme,
                            padding: index == list.length - 1
                                ? const .only(right: 12)
                                : const .only(right: 10),
                            video: video,
                          );
                        },
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
}

class _SearchUserVideoItem extends StatefulWidget {
  const _SearchUserVideoItem({
    required this.colorScheme,
    required this.padding,
    required this.video,
  });

  final ColorScheme colorScheme;
  final EdgeInsets padding;
  final SearchVideoItemModel video;

  @override
  State<_SearchUserVideoItem> createState() => _SearchUserVideoItemState();
}

class _SearchUserVideoItemState extends State<_SearchUserVideoItem> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);
  final GlobalKey _cardKey = GlobalKey();
  bool _pushing = false;

  String get _heroTag =>
      'search_user_av_${identityHashCode(this)}_${widget.video.bvid ?? widget.video.aid}';

  Future<void> _onTapVideo(BuildContext context) async {
    if (_pushing) return;
    _pushing = true;
    try {
      await pushVideoH(
        widget.video,
        heroTag: _heroTag,
        context: _cardKey.currentContext ?? context,
      );
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _pushing = false;
      });
    }
  }

  @override
  void dispose() {
    clearPendingVideoCardTransition(_heroTag);
    _hovered.dispose();
    super.dispose();
  }

  void _onLongPress() => imageSaveDialog(
    title: widget.video.title,
    cover: widget.video.cover,
    aid: widget.video.aid,
    bvid: widget.video.bvid,
  );

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark
        ? const Color(0xFF1A1B1F)
        : const Color(0xFFFFFFFF);
    return Padding(
      padding: widget.padding,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (e) {
          if (e.kind == PointerDeviceKind.mouse && !_hovered.value) {
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
              scale: hovered ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: const Cubic(0.2, 0, 0, 1),
              child: child,
            );
          },
          child: VideoCardHero(
            key: _cardKey,
            tag: _heroTag,
            surfaceColor: cardSurface,
            cornerRadius: 10,
            child: GestureDetector(
              behavior: .opaque,
              onTap: () => _onTapVideo(context),
            onLongPress: PlatformUtils.isMobile
                ? () {
                    Platform.isIOS
                        ? HapticFeedback.heavyImpact()
                        : HapticFeedback.vibrate();
                    _onLongPress();
                  }
                : null,
            onSecondaryTap: PlatformUtils.isDesktop ? _onLongPress : null,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Stack(
                  clipBehavior: .none,
                  children: [
                    NetworkImgLayer(
                      src: video.cover,
                      width: _kItemWidth,
                      height: _kItemHeight,
                      borderRadius: _kBorderRadius,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        alignment: .bottomLeft,
                        padding: const .fromLTRB(8, 6, 8, 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: .bottomCenter,
                            end: .topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                          borderRadius: .vertical(bottom: _kRadius),
                        ),
                        child: Row(
                          crossAxisAlignment: .end,
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            StatWidget(
                              type: .play,
                              value: video.stat.view,
                              color: Colors.white,
                            ),
                            Text(
                              DurationUtils.formatDuration(video.duration),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    video.title,
                    maxLines: 2,
                    overflow: .ellipsis,
                    style: const TextStyle(height: 1.4, fontSize: 12.5),
                  ),
                ),
                Text(
                  DateFormatUtils.dateFormat(video.pubdate),
                  style: TextStyle(
                    color: widget.colorScheme.outline,
                    fontSize: 12,
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
