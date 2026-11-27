import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class SearchPgcItem extends StatefulWidget {
  const SearchPgcItem({
    super.key,
    required this.item,
  });

  final SearchPgcItemModel item;

  @override
  State<SearchPgcItem> createState() => _SearchPgcItemState();
}

class _SearchPgcItemState extends State<SearchPgcItem> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    _pressed.dispose();
    super.dispose();
  }

  void onLongPress() => showPgcCover(
    title: widget.item.title.map((item) => item.text).join(),
    cover: widget.item.cover,
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;
    final TextStyle style = TextStyle(
      fontSize: 12.5,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
    );
    const radius = BorderRadius.all(Radius.circular(16));

    return RepaintBoundary(
      child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Style.safeSpace - 2,
        vertical: 4,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _hovered.value = true,
        onExit: (_) => _hovered.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, hovered, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: _pressed,
              builder: (context, pressed, _) {
                final double scale = pressed ? 0.98 : (hovered ? 1.012 : 1.0);
                return AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 160),
                  curve: const Cubic(0.2, 0, 0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(
                              alpha: hovered ? 0.085 : 0.055,
                            )
                          : Colors.white.withValues(
                              alpha: hovered ? 0.96 : 0.82,
                            ),
                      borderRadius: radius,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(
                                alpha: hovered ? 0.16 : 0.09,
                              )
                            : Colors.white.withValues(
                                alpha: hovered ? 0.98 : 0.88,
                              ),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark
                                ? (hovered ? 0.28 : 0.16)
                                : (hovered ? 0.085 : 0.04),
                          ),
                          blurRadius: hovered ? 16 : 10,
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
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          NetworkImgLayer(
                            width: 111,
                            height: 148,
                            src: item.cover,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          PBadge(
                            text: item.seasonTypeName,
                            top: 6.0,
                            right: 6.0,
                            bottom: null,
                            left: null,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              TextSpan(
                                children: item.title
                                    .map(
                                      (e) => TextSpan(
                                        text: e.text,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: e.isEm
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '评分:${item.mediaScore?['score']}',
                              style: style,
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                              TextSpan(
                                children: [
                                  if (item.areas?.isNotEmpty == true)
                                    TextSpan(text: '${item.areas!}  ·  '),
                                  TextSpan(
                                    text: DateFormatUtils.dateFormat(
                                      item.pubtime,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                              TextSpan(
                                children: [
                                  if (item.styles?.isNotEmpty == true)
                                    TextSpan(text: '${item.styles!}  ·  '),
                                  if (item.indexShow?.isNotEmpty == true)
                                    TextSpan(text: item.indexShow!),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}
