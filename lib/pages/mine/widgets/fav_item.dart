import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavFolderItem extends StatefulWidget {
  const FavFolderItem({
    super.key,
    required this.item,
    required this.onPop,
  });

  final FavFolderInfo item;
  final VoidCallback onPop;

  @override
  State<FavFolderItem> createState() => _FavFolderItemState();
}

class _FavFolderItemState extends State<FavFolderItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final heroTag = Utils.makeHeroTag(item.id);
    const radius = BorderRadius.all(Radius.circular(14));
    return RepaintBoundary(
      child: MouseRegion(
        onHover: (e) {
          if (e.kind == PointerDeviceKind.mouse && !_hovered) {
            setState(() => _hovered = true);
          }
        },
        onExit: (_) {
          if (_hovered) setState(() => _hovered = false);
        },
        child: AnimatedScale(
          scale: _hovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: _hovered ? 0.09 : 0.06)
                  : Colors.white.withValues(alpha: _hovered ? 0.94 : 0.86),
              borderRadius: radius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: _hovered ? 0.18 : 0.11)
                    : Colors.white.withValues(alpha: 0.95),
                width: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark
                        ? (_hovered ? 0.30 : 0.20)
                        : (_hovered ? 0.09 : 0.045),
                  ),
                  blurRadius: _hovered ? 16 : 10,
                  offset: Offset(0, _hovered ? 6 : 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => Get.toNamed(
                    '/favDetail',
                    arguments: item,
                    parameters: {
                      'mediaId': item.id.toString(),
                      'heroTag': heroTag,
                    },
                  )?.whenComplete(widget.onPop),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: heroTag,
                        child: NetworkImgLayer(
                          src: item.cover,
                          width: 184,
                          height: 104,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(9, 7, 9, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: .ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              Text(
                                '共${item.mediaCount}条视频 · ${BiliUtils.isPublicFavText(item.attr)}',
                                maxLines: 1,
                                overflow: .ellipsis,
                                style: theme.textTheme.labelSmall!.copyWith(
                                  color: theme.colorScheme.outline,
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
    );
  }
}
