import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/select_mask.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_transition.dart';
import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pbenum.dart'
    show PlaylistSource;
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/media.dart';
import 'package:PiliPlus/pages/audio/view.dart';
import 'package:PiliPlus/pages/fav_detail/controller.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

// 收藏视频卡片 - 水平布局
class FavVideoCardH extends StatefulWidget {
  final FavDetailItemModel item;
  final int? index;
  final BaseFavController? ctr;

  const FavVideoCardH({
    super.key,
    required this.item,
    this.index,
    this.ctr,
  }) : assert(ctr == null || index != null);

  @override
  State<FavVideoCardH> createState() => _FavVideoCardHState();
}

class _FavVideoCardHState extends State<FavVideoCardH> {
  bool _hovered = false;
  final GlobalKey _cardKey = GlobalKey();

  bool get isSort => widget.ctr == null;

  bool get _isNormalVideo =>
      !isSort &&
      !const [1, 9].contains(widget.item.attr) &&
      widget.item.type != 12 &&
      widget.item.type != 24;

  String get _heroTag =>
      'fav_video_${identityHashCode(this)}_${widget.item.bvid ?? widget.item.id}';

  @override
  void dispose() {
    clearPendingVideoCardTransition(_heroTag);
    super.dispose();
  }

  void _onTap(BuildContext context) {
    final item = widget.item;
    // 0/4/16/...: 正常；9: up自己删除；1: 其他原因删除
    if (const [1, 9].contains(item.attr)) {
      Get.toNamed('/member?mid=${item.upper?.mid}');
      return;
    }

    switch (item.type) {
      case 12:
        AudioPage.toAudioPage(
          oid: item.id!,
          itemType: 3,
          from: PlaylistSource.AUDIO_CARD,
        );
        break;
      case 24:
        PageUtils.viewPgc(
          seasonId: item.ogv!.seasonId,
          epId: item.id,
        );
        break;
      default:
        widget.ctr!.onViewFavWithHero(
          item,
          widget.index,
          heroTag: _heroTag,
          context: _cardKey.currentContext ?? context,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ctr = widget.ctr;
    final isOwner = !isSort && ctr!.isOwner;
    late final enableMultiSelect = ctr?.enableMultiSelect.value ?? false;
    final colorScheme = ColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(14));
    final cardSurface = isDark
        ? const Color(0xFF1A1B1F)
        : const Color(0xFFFFFFFF);

    final onLongPress = isSort || enableMultiSelect
        ? null
        : isOwner && !enableMultiSelect
        ? () {
            ctr!
              ..enableMultiSelect.value = true
              ..onSelect(item);
          }
        : () => imageSaveDialog(
            title: item.title,
            cover: item.cover,
            bvid: item.bvid,
          );

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
          child: (_isNormalVideo && !enableMultiSelect)
              ? VideoCardHero(
                  key: _cardKey,
                  tag: _heroTag,
                  surfaceColor: cardSurface,
                  cornerRadius: 14,
                  child: _buildCardBody(
                    context,
                    colorScheme,
                    isDark,
                    radius,
                    isOwner,
                    enableMultiSelect,
                    onLongPress,
                  ),
                )
              : _buildCardBody(
                  context,
                  colorScheme,
                  isDark,
                  radius,
                  isOwner,
                  enableMultiSelect,
                  onLongPress,
                ),
        ),
      ),
    );
  }

  Widget _buildCardBody(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    BorderRadius radius,
    bool isOwner,
    bool enableMultiSelect,
    VoidCallback? onLongPress,
  ) {
    final item = widget.item;
    final ctr = widget.ctr;
    return DecoratedBox(
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
            onTap: isSort
                ? null
                : enableMultiSelect
                ? () => ctr!.onSelect(item)
                : () => _onTap(context),
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            child: Padding(
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
                              src: item.cover,
                              width: maxWidth,
                              height: maxHeight,
                            ),
                            PBadge(
                              text: DurationUtils.formatDuration(
                                item.duration,
                              ),
                              right: 6.0,
                              bottom: 6.0,
                              type: PBadgeType.gray,
                            ),
                            if (item.type == 12)
                              const PBadge(
                                text: '音频',
                                top: 6.0,
                                right: 6.0,
                                type: PBadgeType.gray,
                              )
                            else
                              PBadge(
                                text: item.ogv?.typeName,
                                top: 6.0,
                                right: 6.0,
                                bottom: null,
                                left: null,
                              ),
                            if (!isSort)
                              Positioned.fill(
                                child: selectMask(
                                  colorScheme,
                                  item.checked,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  content(context, colorScheme, isOwner),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget content(BuildContext context, ColorScheme colorScheme, bool isOwner) {
    final item = widget.item;
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            spacing: 3,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title!,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.type == 24 && item.intro?.isNotEmpty == true)
                Text(
                  item.intro!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.outline,
                  ),
                ),
              const Spacer(),
              Text(
                '${DateFormatUtils.dateFormat(item.favTime)} ${item.upper?.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  height: 1,
                  fontSize: 12,
                  color: colorScheme.outline,
                ),
              ),
              if (item.type != 24)
                Row(
                  spacing: 8,
                  children: [
                    StatWidget(
                      type: StatType.play,
                      value: item.cntInfo?.play,
                    ),
                    StatWidget(
                      type: StatType.danmaku,
                      value: item.cntInfo?.danmaku,
                    ),
                  ],
                ),
            ],
          ),
          if (isOwner)
            Positioned(
              right: 0,
              bottom: -6,
              child: iconButton(
                icon: const Icon(Icons.clear),
                iconColor: colorScheme.outline,
                onPressed: () => showConfirmDialog(
                  context: context,
                  title: const Text('提示'),
                  content: const Text('要取消收藏吗？'),
                  onConfirm: () =>
                      widget.ctr!.onCancelFav(widget.index!, item.id!, item.type!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
