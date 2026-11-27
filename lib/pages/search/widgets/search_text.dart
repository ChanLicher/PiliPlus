import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class SearchText extends StatelessWidget {
  final String text;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onLongPress;
  final double? fontSize;
  final Color? bgColor;
  final Color? textColor;
  final TextAlign? textAlign;
  final double? height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final int? maxLines;
  final TextOverflow? overflow;

  const SearchText({
    super.key,
    required this.text,
    this.onTap,
    this.onLongPress,
    this.fontSize,
    this.bgColor,
    this.textColor,
    this.textAlign,
    this.height,
    this.padding = const .symmetric(horizontal: 11, vertical: 5),
    this.borderRadius = const .all(.circular(16)),
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    late final colorScheme = ColorScheme.of(context);
    final hasLongPress = onLongPress != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    return Material(
      color: bgColor ?? defaultBg,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.6,
        ),
      ),
      child: InkWell(
        onTap: () => onTap?.call(text),
        onLongPress: hasLongPress ? () => onLongPress!(text) : null,
        onSecondaryTap: hasLongPress && !PlatformUtils.isMobile
            ? () => onLongPress!(text)
            : null,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Text(
            text,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: fontSize,
              height: height,
              color: textColor ?? colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
