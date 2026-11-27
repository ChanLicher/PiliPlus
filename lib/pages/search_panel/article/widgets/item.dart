import 'package:PiliPlus/common/widgets/video_card/card_enter_motion.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/pages/article/view.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class SearchArticleItem extends StatefulWidget {
  const SearchArticleItem({super.key, required this.item});

  final SearchArticleItemModel item;

  @override
  State<SearchArticleItem> createState() => _SearchArticleItemState();
}

class _SearchArticleItemState extends State<SearchArticleItem> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    _pressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;
    final textStyle = TextStyle(
      fontSize: theme.textTheme.labelSmall!.fontSize,
      color: theme.colorScheme.outline,
    );
    const radius = BorderRadius.all(Radius.circular(14));

    void onLongPress() => imageSaveDialog(
      title: item.title.map((item) => item.text).join(),
      cover: item.imageUrls?.firstOrNull,
    );

    return CardEnterMotion(
      itemKey: item.id,
      child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Style.safeSpace - 2,
        vertical: 3,
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
                onTap: () => ArticlePage.toArticlePage(
                  id: item.id.toString(),
                  type: .read,
                ),
                onLongPress: onLongPress,
                onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (item.imageUrls?.isNotEmpty == true)
                        AspectRatio(
                          aspectRatio: Style.aspectRatio,
                          child: LayoutBuilder(
                            builder: (context, boxConstraints) {
                              double maxWidth = boxConstraints.maxWidth;
                              double maxHeight = boxConstraints.maxHeight;
                              return NetworkImgLayer(
                                width: maxWidth,
                                height: maxHeight,
                                src: item.imageUrls?.firstOrNull,
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                          color: e.isEm
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormatUtils.dateFormat(item.pubTime),
                              style: textStyle,
                            ),
                            Row(
                              children: [
                                Text('${item.view}浏览', style: textStyle),
                                Text(' • ', style: textStyle),
                                Text('${item.reply}评论', style: textStyle),
                              ],
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
