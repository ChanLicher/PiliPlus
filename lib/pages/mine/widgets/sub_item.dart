import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/sub/sub/list.dart';
import 'package:PiliPlus/pages/subscription/widgets/item.dart' show onPushSub;
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

class MineSubItem extends StatefulWidget {
  const MineSubItem({
    super.key,
    required this.item,
    required this.onPop,
  });

  final SubItemModel item;
  final VoidCallback onPop;

  @override
  State<MineSubItem> createState() => _MineSubItemState();
}

class _MineSubItemState extends State<MineSubItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroTag = Utils.makeHeroTag(item.id);
    final label = item.type2Label;
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
                  onTap: () =>
                      onPushSub(label, heroTag, item)?.whenComplete(widget.onPop),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Stack(
                        clipBehavior: .none,
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
                          PBadge(right: 6, top: 6, text: label),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(9, 7, 9, 6),
                          child: Text(
                            item.title ?? '',
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.38,
                              letterSpacing: 0.2,
                            ),
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
