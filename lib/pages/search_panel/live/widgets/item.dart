import 'package:PiliPlus/common/widgets/video_card/card_enter_motion.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class LiveItem extends StatefulWidget {
  final SearchLiveItemModel liveItem;

  const LiveItem({super.key, required this.liveItem});

  @override
  State<LiveItem> createState() => _LiveItemState();
}

class _LiveItemState extends State<LiveItem> {
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
    final liveItem = widget.liveItem;
    const radius = BorderRadius.all(Radius.circular(14));

    void onLongPress() => imageSaveDialog(
      title: liveItem.title.map((item) => item.text).join(),
      cover: liveItem.cover,
    );

    return CardEnterMotion(
      itemKey: liveItem.roomid,
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
              final double scale = pressed ? 0.975 : (hovered ? 1.018 : 1.0);
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
                            alpha: hovered ? 0.96 : 0.84,
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
                              ? (hovered ? 0.30 : 0.18)
                              : (hovered ? 0.09 : 0.045),
                        ),
                        blurRadius: hovered ? 18 : 12,
                        offset: Offset(0, hovered ? 6 : 4),
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
              onTap: () => PageUtils.toLiveRoom(liveItem.roomid),
              onLongPress: onLongPress,
              onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
              child: Column(
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
                              src: liveItem.cover,
                              width: maxWidth,
                              height: maxHeight,
                              borderRadius: BorderRadius.zero,
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: liveStat(
                                liveItem.online,
                                liveItem.cateName,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  liveContent(theme),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget liveContent(ThemeData theme) => Expanded(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            TextSpan(
              children: widget.liveItem.title
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
          Text(
            widget.liveItem.uname!,
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

  Widget liveStat(int? online, String? cateName) {
    return Container(
      height: 45,
      padding: const EdgeInsets.only(top: 22, left: 8, right: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            Colors.black54,
          ],
          tileMode: TileMode.mirror,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            cateName!,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          Text(
            '${NumUtils.numFormat(online)}围观',
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
