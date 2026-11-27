import 'dart:ui' show PointerDeviceKind;

import 'package:PiliPlus/common/widgets/custom_arc.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class ActionItem extends StatefulWidget {
  const ActionItem({
    super.key,
    required this.icon,
    this.selectIcon,
    this.onTap,
    this.onLongPress,
    this.text,
    this.selectStatus = false,
    required this.semanticsLabel,
    this.expand = true,
    this.animation,
    this.onStartTriple,
    this.onCancelTriple,
  }) : assert(!selectStatus || selectIcon != null),
       _isThumbsUp = onStartTriple != null;

  final Icon icon;
  final Icon? selectIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? text;
  final bool selectStatus;
  final String semanticsLabel;
  final bool expand;
  final Animation<double>? animation;
  final VoidCallback? onStartTriple;
  final void Function([bool])? onCancelTriple;
  final bool _isThumbsUp;

  @override
  State<ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<ActionItem> {
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
    late final primary = !widget.expand && colorScheme.isLight
        ? colorScheme.inversePrimary
        : colorScheme.primary;
    Widget child = Icon(
      widget.selectStatus ? widget.selectIcon!.icon! : widget.icon.icon,
      size: 18,
      color: widget.selectStatus
          ? primary
          : widget.icon.color ?? colorScheme.outline,
      semanticLabel: widget.semanticsLabel,
    );

    if (widget.animation != null) {
      child = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: widget.animation!,
            builder: (context, child) => Arc(
              size: 28,
              color: primary,
              progress: -widget.animation!.value,
            ),
          ),
          child,
        ],
      );
    } else {
      child = SizedBox.square(dimension: 28, child: child);
    }

    child = MouseRegion(
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
        builder: (context, hovered, inner) {
          return AnimatedScale(
            scale: hovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: const Cubic(0.2, 0, 0, 1),
            child: inner,
          );
        },
        child: Material(
          type: .transparency,
          child: InkWell(
            borderRadius: const .all(.circular(10)),
            hoverColor: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.06,
            ),
            onTap: widget._isThumbsUp ? null : widget.onTap,
            onLongPress: widget._isThumbsUp ? null : widget.onLongPress,
            onSecondaryTap: PlatformUtils.isMobile || widget._isThumbsUp
                ? null
                : widget.onLongPress,
            onTapDown: widget._isThumbsUp
                ? (_) => widget.onStartTriple!()
                : null,
            onTapUp: widget._isThumbsUp
                ? (_) => widget.onCancelTriple!(true)
                : null,
            onTapCancel: widget._isThumbsUp ? widget.onCancelTriple : null,
            child: widget.expand
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [child, _buildText(theme)],
                  )
                : child,
          ),
        ),
      ),
    );
    return widget.expand ? Expanded(child: child) : child;
  }

  Widget _buildText(ThemeData theme) {
    final hasText = widget.text != null;
    final child = Text(
      hasText ? widget.text! : '-',
      key: hasText ? ValueKey(widget.text!) : null,
      style: TextStyle(
        color: widget.selectStatus
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
        fontSize: theme.textTheme.labelSmall!.fontSize,
      ),
    );
    if (hasText) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: child,
      );
    }
    return child;
  }
}
