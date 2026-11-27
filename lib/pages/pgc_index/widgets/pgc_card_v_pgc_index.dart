import 'dart:ui' show PointerDeviceKind;

import 'package:PiliPlus/common/widgets/video_card/card_enter_motion.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/pgc/pgc_index_result/list.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 垂直布局
class PgcCardVPgcIndex extends StatefulWidget {
  const PgcCardVPgcIndex({
    super.key,
    required this.item,
  });

  final PgcIndexItem item;

  @override
  State<PgcCardVPgcIndex> createState() => _PgcCardVPgcIndexState();
}

class _PgcCardVPgcIndexState extends State<PgcCardVPgcIndex> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    _pressed.dispose();
    super.dispose();
  }

  void onLongPress() =>
      showPgcCover(title: widget.item.title, cover: widget.item.cover);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;
    const radius = BorderRadius.all(Radius.circular(14));

    return CardEnterMotion(
      itemKey: item.seasonId,
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
            return ValueListenableBuilder<bool>(
              valueListenable: _pressed,
              builder: (context, pressed, _) {
                final double scale = pressed ? 0.975 : (hovered ? 1.018 : 1.0);
                return AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 150),
                  curve: const Cubic(0.2, 0, 0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(
                              alpha: hovered ? 0.085 : 0.055,
                            )
                          : Colors.white.withValues(
                              alpha: hovered ? 0.96 : 0.84,
                            ),
                      borderRadius: radius,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(
                                alpha: hovered ? 0.16 : 0.09,
                              )
                            : Colors.white.withValues(
                                alpha: hovered ? 0.98 : 0.90,
                              ),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark
                                ? (hovered ? 0.28 : 0.16)
                                : (hovered ? 0.085 : 0.045),
                          ),
                          blurRadius: hovered ? 14 : 9,
                          offset: Offset(0, hovered ? 5 : 3),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                hoverColor: Colors.transparent,
                onHighlightChanged: (v) => _pressed.value = v,
                onTap: () => PageUtils.viewPgc(seasonId: item.seasonId),
                onLongPress: onLongPress,
                onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: Style.aspectRatio3x4,
                      child: LayoutBuilder(
                        builder: (context, boxConstraints) {
                          final double maxWidth = boxConstraints.maxWidth;
                          final double maxHeight = boxConstraints.maxHeight;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              NetworkImgLayer(
                                src: item.cover,
                                width: maxWidth,
                                height: maxHeight,
                                borderRadius: BorderRadius.zero,
                              ),
                              PBadge(
                                text: item.badge,
                                top: 6,
                                right: 6,
                                bottom: null,
                                left: null,
                              ),
                              PBadge(
                                text: item.order,
                                top: null,
                                right: null,
                                bottom: 6,
                                left: 6,
                                type: PBadgeType.gray,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    content(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title!,
              textAlign: TextAlign.start,
              style: const TextStyle(
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            if (item.indexShow != null)
              Text(
                item.indexShow!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: theme.textTheme.labelMedium!.fontSize,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
