import 'dart:ui' show ImageFilter;

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

Widget _buildGlassDialog({
  required BuildContext context,
  required Widget child,
  EdgeInsets insetPadding = const EdgeInsets.symmetric(
    horizontal: 28,
    vertical: 24,
  ),
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  const radius = BorderRadius.all(Radius.circular(22));
  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: insetPadding,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xCC1E1F24)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: radius,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.95),
                  width: 0.9,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required Widget title,
  Widget? content,
  // @Deprecated('use `bool result = await showConfirmDialog()` instead')
  VoidCallback? onConfirm,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;
          return _buildGlassDialog(
            context: context,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    child: title,
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: DefaultTextStyle.merge(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          child: content,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                        onPressed: Get.back,
                        child: Text(
                          '取消',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                        ),
                        onPressed: () {
                          Get.back(result: true);
                          onConfirm?.call();
                        },
                        child: Text(
                          '确认',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ) ??
      false;
}

Widget _statusItem({
  required BuildContext context,
  required bool enabled,
  required String text,
  required VoidCallback onTap,
}) {
  final colorScheme = ColorScheme.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final selected = !enabled;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: enabled ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.11)
                : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '标记为 $text',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void showPgcFollowDialog({
  required BuildContext context,
  required String type,
  required int followStatus,
  required ValueChanged<int> onUpdateStatus,
}) {
  showDialog(
    context: context,
    builder: (context) {
      final colorScheme = ColorScheme.of(context);
      return _buildGlassDialog(
        context: context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...const [
                (followStatus: 3, title: '看过'),
                (followStatus: 2, title: '在看'),
                (followStatus: 1, title: '想看'),
              ].map(
                (item) => _statusItem(
                  context: context,
                  enabled: followStatus != item.followStatus,
                  text: item.title,
                  onTap: () {
                    Get.back();
                    onUpdateStatus(item.followStatus);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    onTap: () {
                      Get.back();
                      onUpdateStatus(-1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '取消$type',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
