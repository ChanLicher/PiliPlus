import 'dart:ui' show PointerDeviceKind;

import 'package:PiliPlus/utils/feed_back.dart';
import 'package:material_ui/material_ui.dart';

class ActionRowLineItem extends StatefulWidget {
  const ActionRowLineItem({
    super.key,
    required this.selectStatus,
    this.onTap,
    this.text,
    this.iconData,
    this.icon,
  });
  final bool selectStatus;
  final VoidCallback? onTap;
  final String? text;
  final IconData? iconData;
  final Widget? icon;

  @override
  State<ActionRowLineItem> createState() => _ActionRowLineItemState();
}

class _ActionRowLineItemState extends State<ActionRowLineItem> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selected = widget.selectStatus;
    const radius = BorderRadius.all(Radius.circular(30));

    return MouseRegion(
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
          final bg = selected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : colorScheme.primary.withValues(alpha: 0.12))
              : hovered
              ? (isDark ? Colors.white : Colors.black).withValues(
                  alpha: isDark ? 0.10 : 0.055,
                )
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03));
          return AnimatedScale(
            scale: hovered ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: const Cubic(0.2, 0, 0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.22)
                            : colorScheme.primary.withValues(alpha: 0.24))
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.07)),
                  width: 0.8,
                ),
              ),
              child: child,
            ),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            hoverColor: Colors.transparent,
            onTap: () => {
              feedBack(),
              widget.onTap?.call(),
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 5.5, 13, 4.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.iconData != null)
                    Icon(
                      widget.iconData,
                      size: 13,
                      color: selected
                          ? (isDark ? Colors.white : colorScheme.primary)
                          : colorScheme.outline,
                    )
                  else
                    ?widget.icon,
                  Text(
                    widget.text!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? (isDark ? Colors.white : colorScheme.primary)
                          : colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionIconItem extends StatefulWidget {
  const ActionIconItem({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.iconData,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData iconData;

  @override
  State<ActionIconItem> createState() => _ActionIconItemState();
}

class _ActionIconItemState extends State<ActionIconItem> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return MouseRegion(
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
            scale: hovered ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: const Cubic(0.2, 0, 0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: .circle,
                color: hovered
                    ? (isDark ? Colors.white : Colors.black).withValues(
                        alpha: isDark ? 0.12 : 0.06,
                      )
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.07),
                  width: 0.8,
                ),
              ),
              child: child,
            ),
          );
        },
        child: Material(
          type: .transparency,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            hoverColor: Colors.transparent,
            onTap: () => {
              feedBack(),
              widget.onTap(),
            },
            child: Padding(
              padding: const .all(5),
              child: Icon(
                widget.iconData,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
