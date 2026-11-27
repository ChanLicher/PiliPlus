import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

typedef PopupMenuItemSelected<T> = void Function(
  T value,
  VoidCallback setState,
);

List<PopupMenuEntry<T>> enumItemBuilder<T extends EnumWithLabel>(
  Iterable<T> items,
) => items.map((e) => PopupMenuItem(value: e, child: Text(e.label))).toList();

enum DescPosType { subtitle, title, trailing }

class PopupListTile<T> extends StatefulWidget {
  const PopupListTile({
    super.key,
    this.dense,
    this.safeArea = true,
    this.enabled = true,
    this.leading,
    required this.title,
    this.descPosType = .subtitle,
    required this.value,
    required this.itemBuilder,
    required this.onSelected,
    this.titleStyle,
    this.descStyle,
  });

  final bool? dense;
  final bool safeArea;
  final bool enabled;
  final Widget? leading;
  final Widget title;

  final DescPosType descPosType;
  final ValueGetter<(T, String)> value;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final TextStyle? titleStyle;
  final TextStyle? descStyle;

  @override
  State<PopupListTile<T>> createState() => _PopupListTileState<T>();
}

class _PopupListTileState<T> extends State<PopupListTile<T>> {
  final _key = PlatformUtils.isDesktop ? null : GlobalKey();

  void _showButtonMenu(TapUpDetails details, T value) {
    final thisOffset = details.globalPosition - details.localPosition;
    final double dx;
    if (PlatformUtils.isDesktop) {
      dx = details.globalPosition.dx + 1;
    } else {
      final thisBox = context.findRenderObject();
      final titleBox = _key!.currentContext!.findRenderObject() as RenderBox;
      final titleOffset = titleBox.localToGlobal(.zero, ancestor: thisBox);
      dx = thisOffset.dx + titleOffset.dx;
    }
    final rawItems = widget.itemBuilder(context);
    final items = rawItems.whereType<PopupMenuItem<T>>().toList();
    if (items.isEmpty) return;

    final OverlayState overlayState = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    bool removed = false;
    void removeEntry() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _PopupListTileGlassOverlay<T>(
        anchorOffset: Offset(dx, thisOffset.dy + 5),
        selectedValue: value,
        items: items,
        onSelected: (newValue) {
          if (!mounted) return;
          if (newValue == value) return;
          widget.onSelected(newValue, _refresh);
        },
        onRemoved: removeEntry,
      ),
    );
    overlayState.insert(entry);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (value, descStr) = widget.value();
    Widget title = KeyedSubtree(key: _key, child: widget.title);
    Widget? subtitle;
    Widget? trailing;
    final desc = Text(
      descStr,
      style: (widget.descStyle ?? theme.textTheme.labelMedium!).copyWith(
        color: widget.enabled
            ? theme.colorScheme.secondary
            : theme.disabledColor,
      ),
    );
    switch (widget.descPosType) {
      case DescPosType.subtitle:
        subtitle = desc;
      case DescPosType.title:
        title = Row(
          spacing: 12,
          mainAxisSize: .min,
          children: [title, desc],
        );
      case DescPosType.trailing:
        trailing = desc;
    }
    return ListTile(
      dense: widget.dense,
      safeArea: widget.safeArea,
      enabled: widget.enabled,
      onTapUp: (details) => _showButtonMenu(details, value),
      leading: widget.leading,
      title: title,
      titleTextStyle: widget.titleStyle ?? theme.textTheme.titleMedium,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

class _PopupListTileGlassOverlay<T> extends StatefulWidget {
  const _PopupListTileGlassOverlay({
    required this.anchorOffset,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.onRemoved,
  });

  final Offset anchorOffset;
  final T selectedValue;
  final List<PopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final VoidCallback onRemoved;

  @override
  State<_PopupListTileGlassOverlay<T>> createState() =>
      _PopupListTileGlassOverlayState<T>();
}

class _PopupListTileGlassOverlayState<T>
    extends State<_PopupListTileGlassOverlay<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0, 0, 1),
      reverseCurve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismissImmediately() {
    if (_closing) return;
    _closing = true;
    widget.onRemoved();
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    await _controller.reverse();
    widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
            onSecondaryTap: _dismiss,
            child: const SizedBox.expand(),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _PopupListTileDelegate(
            anchorOffset: widget.anchorOffset,
            safePadding: mediaQuery.padding,
          ),
          child: FadeTransition(
            opacity: _curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(_curved),
              alignment: Alignment.topLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.42 : 0.14,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1D1E22).withValues(alpha: 0.82)
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.94),
                          width: 0.9,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 152,
                          maxWidth: 260,
                          maxHeight: 360,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(6),
                          child: IntrinsicWidth(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.items.map((item) {
                                final isSelected =
                                    item.value == widget.selectedValue;
                                return Material(
                                  type: MaterialType.transparency,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    hoverColor:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.08),
                                    onTap: item.enabled
                                        ? () {
                                            _dismissImmediately();
                                            if (item.value != null) {
                                              widget.onSelected(
                                                item.value as T,
                                              );
                                            }
                                            item.onTap?.call();
                                          }
                                        : null,
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: isSelected
                                          ? BoxDecoration(
                                              color: primary.withValues(
                                                alpha: isDark ? 0.22 : 0.12,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    Radius.circular(10),
                                                  ),
                                            )
                                          : null,
                                      child: Opacity(
                                        opacity: item.enabled ? 1.0 : 0.4,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: DefaultTextStyle.merge(
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: isSelected
                                                      ? (isDark
                                                            ? Colors.white
                                                            : primary)
                                                      : theme
                                                            .colorScheme
                                                            .onSurface,
                                                ),
                                                child:
                                                    item.child ??
                                                    const SizedBox.shrink(),
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.check_rounded,
                                                size: 15,
                                                color: primary,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopupListTileDelegate extends SingleChildLayoutDelegate {
  _PopupListTileDelegate({
    required this.anchorOffset,
    required this.safePadding,
  });

  final Offset anchorOffset;
  final EdgeInsets safePadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth = (constraints.maxWidth - 20).clamp(152.0, 280.0);
    final maxHeight =
        (constraints.maxHeight - safePadding.top - safePadding.bottom - 24)
            .clamp(80.0, 380.0);
    return BoxConstraints.loose(Size(maxWidth, maxHeight));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double edgeMargin = 10.0;
    double x = anchorOffset.dx.clamp(
      safePadding.left + edgeMargin,
      (size.width - safePadding.right - childSize.width - edgeMargin).clamp(
        safePadding.left + edgeMargin,
        size.width,
      ),
    );
    double y = anchorOffset.dy;
    if (y + childSize.height > size.height - safePadding.bottom - edgeMargin) {
      y = anchorOffset.dy - childSize.height - 10;
    }
    y = y.clamp(
      safePadding.top + edgeMargin,
      (size.height - safePadding.bottom - childSize.height - edgeMargin).clamp(
        safePadding.top + edgeMargin,
        size.height,
      ),
    );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupListTileDelegate oldDelegate) {
    return anchorOffset != oldDelegate.anchorOffset ||
        safePadding != oldDelegate.safePadding;
  }
}
