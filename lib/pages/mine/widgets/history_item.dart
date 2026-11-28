import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_transition.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/pages/history/widgets/item.dart' show onPushHistory;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

class MineHistoryItem extends StatefulWidget {
  const MineHistoryItem({
    super.key,
    required this.item,
    required this.onPop,
  });

  final HistoryItemModel item;
  final VoidCallback onPop;

  @override
  State<MineHistoryItem> createState() => _MineHistoryItemState();
}

class _MineHistoryItemState extends State<MineHistoryItem> {
  bool _hovered = false;

  bool get _isNormalVideo {
    final b = widget.item.history.business;
    return b?.contains('article') != true &&
        b != 'live' &&
        b != 'pgc' &&
        b != 'cheese';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasDuration = item.hasDuration;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(14));
    final heroTag = 'mine_history_${item.history.oid}_${item.viewAt}';
    final cardSurface = isDark
        ? const Color(0xFF1A1B1F)
        : const Color(0xFFFFFFFF);

    Widget card = DecoratedBox(
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
            onTap: () => onPushHistory(
              item,
              heroTag: _isNormalVideo ? heroTag : null,
              context: _isNormalVideo ? context : null,
            ).whenComplete(widget.onPop),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Stack(
                  clipBehavior: .none,
                  children: [
                    NetworkImgLayer(
                      src: item.cover,
                      width: 184,
                      height: 104,
                      borderRadius: BorderRadius.zero,
                    ),
                    if (hasDuration)
                      ...item.progressIndicator(ColorScheme.of(context)),
                    ?item.label,
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
    );

    if (_isNormalVideo) {
      card = VideoCardHero(
        tag: heroTag,
        surfaceColor: cardSurface,
        cornerRadius: 14,
        child: card,
      );
    }

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
          child: card,
        ),
      ),
    );
  }
}
