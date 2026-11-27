import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';

class ComBtn extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double width;
  final double height;
  final String? tooltip;

  const ComBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.width = 34,
    this.height = 34,
    this.tooltip,
  });

  @override
  State<ComBtn> createState() => _ComBtnState();
}

class _ComBtnState extends State<ComBtn> {
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
    final isLarge = MediaQuery.sizeOf(context).shortestSide >= 600;
    final double scaleFactor = isLarge ? 1.22 : 1.0;
    return SizedBox(
      width: widget.width * scaleFactor,
      height: widget.height * scaleFactor,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) {
          if (event.kind == PointerDeviceKind.mouse && !_hovered.value) {
            _hovered.value = true;
          }
        },
        onExit: (_) {
          if (_hovered.value) _hovered.value = false;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onSecondaryTap,
          onTapDown: (_) => _pressed.value = true,
          onTapUp: (_) => _pressed.value = false,
          onTapCancel: () => _pressed.value = false,
          behavior: HitTestBehavior.opaque,
          child: ValueListenableBuilder<bool>(
            valueListenable: _hovered,
            builder: (context, hovered, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: _pressed,
                builder: (context, pressed, _) {
                  final scale = pressed ? 0.94 : (hovered ? 1.04 : 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 130),
                      curve: const Cubic(0.2, 0, 0, 1),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pressed
                              ? Colors.white.withValues(alpha: 0.24)
                              : hovered
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
              );
            },
            child: isLarge ? Transform.scale(scale: 1.15, child: widget.icon) : widget.icon,
          ),
        ),
      ),
    );
  }
}
