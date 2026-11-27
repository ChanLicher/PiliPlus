import 'dart:ui' show ImageFilter, PointerDeviceKind;

import 'package:material_ui/material_ui.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

typedef PopupMenuItemSelected<T> = bool Function(T value);

class PopupMenuText<T> extends StatefulWidget {
  final String title;
  final ValueGetter<T> value;
  final PopupMenuItemSelected<T> onSelected;
  final PopupMenuItemBuilder<T> itemBuilder;
  final String Function(T) getSelectTitle;

  const PopupMenuText({
    super.key,
    required this.title,
    required this.value,
    required this.onSelected,
    required this.itemBuilder,
    required this.getSelectTitle,
  });

  @override
  State<PopupMenuText<T>> createState() => _PopupMenuTextState<T>();
}

class _PopupMenuTextState<T> extends State<PopupMenuText<T>> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  void _openGlassMenu(BuildContext btnContext, T select) {
    final RenderBox? button = btnContext.findRenderObject() as RenderBox?;
    final OverlayState overlayState = Overlay.of(btnContext, rootOverlay: true);
    final RenderBox? overlay =
        overlayState.context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final Offset topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Rect anchorRect = topLeft & button.size;
    final rawEntries = widget.itemBuilder(btnContext);
    final items = rawEntries.whereType<PopupMenuItem<T>>().toList();
    if (items.isEmpty) return;

    late final OverlayEntry entry;
    bool removed = false;
    void removeEntry() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _PopupMenuTextGlassOverlay<T>(
        anchorRect: anchorRect,
        selectedValue: select,
        items: items,
        onSelected: (val) {
          if (val == select) return;
          if (!widget.onSelected(val) && mounted) {
            setState(() {});
          }
        },
        onRemoved: removeEntry,
      ),
    );
    overlayState.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final select = widget.value();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    const pillRadius = BorderRadius.all(Radius.circular(12));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.title}: ',
          style: TextStyle(
            fontSize: 13.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
        Builder(
          builder: (btnContext) => MouseRegion(
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
                return AnimatedScale(
                  scale: hovered ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: const Cubic(0.2, 0, 0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: hovered
                          ? primary.withValues(alpha: isDark ? 0.24 : 0.15)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.045)),
                      borderRadius: pillRadius,
                      border: Border.all(
                        color: hovered
                            ? primary.withValues(alpha: 0.35)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.08)),
                        width: 0.8,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: Material(
                type: MaterialType.transparency,
                borderRadius: pillRadius,
                child: InkWell(
                  borderRadius: pillRadius,
                  hoverColor: Colors.transparent,
                  onTap: () => _openGlassMenu(btnContext, select),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 3,
                      children: [
                        Text(
                          widget.getSelectTitle(select),
                          style: TextStyle(
                            height: 1.1,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : primary,
                          ),
                        ),
                        Icon(
                          size: 14,
                          MdiIcons.unfoldMoreHorizontal,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.78)
                              : primary,
                        ),
                      ],
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

class _PopupMenuTextGlassOverlay<T> extends StatefulWidget {
  const _PopupMenuTextGlassOverlay({
    required this.anchorRect,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.onRemoved,
  });

  final Rect anchorRect;
  final T selectedValue;
  final List<PopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final VoidCallback onRemoved;

  @override
  State<_PopupMenuTextGlassOverlay<T>> createState() =>
      _PopupMenuTextGlassOverlayState<T>();
}

class _PopupMenuTextGlassOverlayState<T>
    extends State<_PopupMenuTextGlassOverlay<T>>
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
          delegate: _PopupMenuTextDelegate(
            anchorRect: widget.anchorRect,
            safePadding: mediaQuery.padding,
          ),
          child: FadeTransition(
            opacity: _curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(_curved),
              alignment: Alignment.topCenter,
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
                          minWidth: 140,
                          maxWidth: 240,
                          maxHeight: 320,
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
                                      height: 36,
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
                                                  fontSize: 13,
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

class _PopupMenuTextDelegate extends SingleChildLayoutDelegate {
  _PopupMenuTextDelegate({
    required this.anchorRect,
    required this.safePadding,
  });

  final Rect anchorRect;
  final EdgeInsets safePadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth = (constraints.maxWidth - 20).clamp(140.0, 250.0);
    final maxHeight =
        (constraints.maxHeight - safePadding.top - safePadding.bottom - 24)
            .clamp(80.0, 340.0);
    return BoxConstraints.loose(Size(maxWidth, maxHeight));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double edgeMargin = 10.0;
    double x = anchorRect.left;
    x = x.clamp(
      safePadding.left + edgeMargin,
      (size.width - safePadding.right - childSize.width - edgeMargin).clamp(
        safePadding.left + edgeMargin,
        size.width,
      ),
    );
    double y = anchorRect.bottom + 6;
    if (y + childSize.height > size.height - safePadding.bottom - edgeMargin) {
      y = anchorRect.top - childSize.height - 6;
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
  bool shouldRelayout(_PopupMenuTextDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        safePadding != oldDelegate.safePadding;
  }
}
