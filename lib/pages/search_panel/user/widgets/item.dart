import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:material_ui/material_ui.dart';

class SearchUserItem extends StatefulWidget {
  const SearchUserItem({
    super.key,
    required this.item,
  });

  final SearchUserItemModel item;

  @override
  State<SearchUserItem> createState() => _SearchUserItemState();
}

class _SearchUserItemState extends State<SearchUserItem> {
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
    final style = TextStyle(
      fontSize: theme.textTheme.labelSmall!.fontSize,
      color: theme.colorScheme.outline,
    );
    const radius = BorderRadius.all(Radius.circular(14));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: const Cubic(0.2, 0, 0, 1),
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
                                ? (hovered ? 0.26 : 0.14)
                                : (hovered ? 0.08 : 0.038),
                          ),
                          blurRadius: hovered ? 14 : 9,
                          offset: Offset(0, hovered ? 4 : 2),
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
                onTap: () => Get.toNamed('/member?mid=${item.mid}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      PendantAvatar(
                        item.upic,
                        size: 42,
                        officialType: item.officialVerify?.type,
                        liveBottom: -5,
                        liveFontSize: 11,
                        roomId: item.isLive == 1 ? item.roomId : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.uname!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                BiliUtils.levelPicture(
                                  item.level!,
                                  isSeniorMember: item.isSeniorMember == 1,
                                  height: 11,
                                ),
                              ],
                            ),
                            Text(
                              '粉丝：${NumUtils.numFormat(item.fans)}  视频：${NumUtils.numFormat(item.videos)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                            if (item.officialVerify?.desc?.isNotEmpty == true)
                              Text(
                                item.officialVerify!.desc!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style,
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
    );
  }
}
