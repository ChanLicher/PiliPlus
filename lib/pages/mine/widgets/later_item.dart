import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_transition.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/later/widgets/video_card_h_later.dart'
    show onPushLater;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

class MineLaterItem extends StatefulWidget {
  const MineLaterItem({
    super.key,
    required this.item,
    required this.onPop,
  });

  final LaterItemModel item;
  final VoidCallback onPop;

  @override
  State<MineLaterItem> createState() => _MineLaterItemState();
}

class _MineLaterItemState extends State<MineLaterItem> {
  bool _hovered = false;
  final GlobalKey _cardKey = GlobalKey();

  bool get _isNormalVideo =>
      !(widget.item.isPugv ?? false) && !(widget.item.isPgc ?? false);

  String get _heroTag =>
      'mine_later_${identityHashCode(this)}_${widget.item.bvid ?? widget.item.aid}';

  @override
  void dispose() {
    clearPendingVideoCardTransition(_heroTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(14));
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
            onTap: () => onPushLater(
              item,
              heroTag: _isNormalVideo ? _heroTag : null,
              context: _isNormalVideo
                  ? (_cardKey.currentContext ?? context)
                  : null,
            ).whenComplete(widget.onPop),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Stack(
                  clipBehavior: .none,
                  children: [
                    NetworkImgLayer(
                      src: item.pic,
                      width: 184,
                      height: 104,
                      borderRadius: BorderRadius.zero,
                    ),
                    ?item.label,
                    ...item.progressIndicator(ColorScheme.of(context)),
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
        key: _cardKey,
        tag: _heroTag,
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
