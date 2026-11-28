import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/appbar/appbar.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/later/base_controller.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class LaterPage extends StatefulWidget {
  const LaterPage({super.key});

  @override
  State<LaterPage> createState() => _LaterPageState();
}

class _LaterPageState extends State<LaterPage>
    with SingleTickerProviderStateMixin {
  final LaterBaseController _baseCtr = Get.put(LaterBaseController());
  late final TabController _tabController;

  LaterController currCtr([int? index]) {
    final type = LaterViewType.values[index ?? _tabController.index];
    return Get.putOrFind(
      () => LaterController(type),
      tag: type.type.toString(),
    );
  }

  final _sortKey = GlobalKey();
  final _sortTriggerKey = GlobalKey();
  final _clearTriggerKey = GlobalKey();
  void listener() {
    (_sortKey.currentContext as Element?)?.markNeedsBuild();
  }

  void _showGlassDropdown({
    required BuildContext context,
    required GlobalKey anchorKey,
    required List<({String label, bool selected, VoidCallback onTap})> items,
  }) {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final media = MediaQuery.of(context);
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    const menuWidth = 148.0;
    final estHeight = items.length * 40.0 + 12.0;
    final left = (pos.dx + size.width - menuWidth).clamp(
      12.0,
      media.size.width - menuWidth - 12.0,
    );
    double top = pos.dy + size.height + 6;
    if (top + estHeight > media.size.height - media.padding.bottom - 12) {
      top = (pos.dy - estHeight - 6).clamp(
        media.padding.top + 12,
        media.size.height - estHeight - 12,
      );
    }

    late OverlayEntry entry;
    void dismiss() {
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final colorScheme = theme.colorScheme;
        const radius = BorderRadius.all(Radius.circular(16));
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
                onSecondaryTap: dismiss,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.42 : 0.14,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
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
                      child: Material(
                        type: MaterialType.transparency,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final item in items)
                                InkWell(
                                  onTap: () {
                                    dismiss();
                                    item.onTap();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: item.selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: item.selected
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (item.selected)
                                          Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                      ],
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
            ),
          ],
        );
      },
    );
    overlay.insert(entry);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LaterViewType.values.length,
      vsync: this,
    )..addListener(listener);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    Get.delete<LaterBaseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Obx(
      () {
        final enableMultiSelect = _baseCtr.enableMultiSelect.value;
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
          },
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final pageBg = isDark
                  ? const Color(0xFF0E0E10)
                  : const Color(0xFFF5F6F8);
              const fabRadius = BorderRadius.all(Radius.circular(20));
              return SimpleScaffold(
                appBar: _buildAppbar(enableMultiSelect),
                fabSideLocked: true,
                fab: Padding(
                  padding: .only(
                    right: kFloatingActionButtonMargin + padding.right,
                    bottom: kFloatingActionButtonMargin + padding.bottom,
                  ),
                  child: Obx(
                    () => currCtr().loadingState.value.isSuccess
                        ? AnimatedSlide(
                            offset: _baseCtr.isPlayAll.value
                                ? Offset.zero
                                : const Offset(0.75, 0),
                            duration: const Duration(milliseconds: 120),
                            child: GestureDetector(
                              onHorizontalDragDown: (details) =>
                                  _baseCtr.dx = details.localPosition.dx,
                              onHorizontalDragStart: (details) =>
                                  _baseCtr.setIsPlayAll(
                                    details.localPosition.dx < _baseCtr.dx,
                                  ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: fabRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.38 : 0.14,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: fabRadius,
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 20,
                                      sigmaY: 20,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xCC22242B)
                                            : Colors.white.withValues(
                                                alpha: 0.88,
                                              ),
                                        borderRadius: fabRadius,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.16,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.96,
                                                ),
                                          width: 0.9,
                                        ),
                                      ),
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          borderRadius: fabRadius,
                                          onTap: () {
                                            if (_baseCtr.isPlayAll.value) {
                                              currCtr().toViewPlayAll();
                                            } else {
                                              _baseCtr.setIsPlayAll(true);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              spacing: 6,
                                              children: [
                                                Icon(
                                                  Icons.playlist_play_rounded,
                                                  size: 21,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                Text(
                                                  '播放全部',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme
                                                        .colorScheme.onSurface,
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
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                body: ColoredBox(
                  color: pageBg,
                  child: ViewSafeArea(
                    child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.84),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.11)
                                    : Colors.white.withValues(alpha: 0.95),
                                width: 0.85,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                controller: _tabController,
                                dividerHeight: 0,
                                indicatorSize: TabBarIndicatorSize.tab,
                                splashBorderRadius: const BorderRadius.all(
                                  Radius.circular(13),
                                ),
                                indicator: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: isDark ? 0.22 : 0.12,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(13),
                                  ),
                                ),
                                labelColor: theme.colorScheme.primary,
                                unselectedLabelColor:
                                    theme.colorScheme.onSurfaceVariant,
                                labelStyle: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                tabs: LaterViewType.values.map((item) {
                                  final count = _baseCtr.counts[item.index];
                                  return Tab(
                                    height: 34,
                                    text:
                                        '${item.title}${count != -1 ? '($count)' : ''}',
                                  );
                                }).toList(),
                                onTap: (_) {
                                  if (!_tabController.indexIsChanging) {
                                    currCtr().scrollController.animToTop();
                                  } else if (enableMultiSelect) {
                                    currCtr(
                                      _tabController.previousIndex,
                                    ).handleSelect();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          physics: enableMultiSelect
                              ? const NeverScrollableScrollPhysics()
                              : tabBarScrollPhysics,
                          controller: _tabController,
                          horizontalDragGestureRecognizer:
                              CustomHorizontalDragGestureRecognizer.new,
                          children: LaterViewType.values
                              .map((item) => item.page)
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppbar(bool enableMultiSelect) {
    final theme = Theme.of(context);
    Color color = theme.colorScheme.secondary;
    final btnStyle = TextButton.styleFrom(visualDensity: .compact);
    final textStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    return MultiSelectAppBarWidget(
      visible: enableMultiSelect,
      ctr: currCtr(),
      actions: [
        TextButton(
          style: btnStyle,
          onPressed: () {
            final ctr = currCtr();
            RequestUtils.onCopyOrMove<LaterItemModel>(
              context: context,
              isCopy: true,
              ctr: ctr,
              mediaId: null,
              mid: ctr.mid,
            );
          },
          child: Text('复制', style: textStyle),
        ),
        TextButton(
          style: btnStyle,
          onPressed: () {
            final ctr = currCtr();
            RequestUtils.onCopyOrMove<LaterItemModel>(
              context: context,
              isCopy: false,
              ctr: ctr,
              mediaId: null,
              mid: ctr.mid,
            );
          },
          child: Text('移动', style: textStyle),
        ),
      ],
      child: AppBar(
        title: const Text('稍后再看'),
        actions: [
          IconButton(
            tooltip: '搜索',
            onPressed: () {
              final mid = Accounts.main.mid;
              Get.toNamed(
                '/laterSearch',
                arguments: {
                  'type': 0,
                  'mediaId': mid,
                  'mid': mid,
                  'title': '稍后再看',
                  'count': _baseCtr.counts[LaterViewType.all.index],
                },
              );
            },
            icon: const Icon(Icons.search),
          ),
          Builder(
            key: _sortKey,
            builder: (context) {
              final value = currCtr().asc.value;
              final isDark = theme.brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DecoratedBox(
                  key: _sortTriggerKey,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.84),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.95),
                      width: 0.8,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      onTap: () => _showGlassDropdown(
                        context: context,
                        anchorKey: _sortTriggerKey,
                        items: [
                          (
                            label: '最近添加',
                            selected: !value,
                            onTap: () => currCtr()
                              ..asc.value = false
                              ..onReload(),
                          ),
                          (
                            label: '最早添加',
                            selected: value,
                            onTap: () => currCtr()
                              ..asc.value = true
                              ..onReload(),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const .symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 2,
                          children: [
                            Text(
                              value ? '最早添加' : '最近添加',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1,
                                color: color,
                              ),
                            ),
                            Icon(
                              size: 14,
                              MdiIcons.unfoldMoreHorizontal,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              final isDark = theme.brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DecoratedBox(
                  key: _clearTriggerKey,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.84),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.95),
                      width: 0.8,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      onTap: () => _showGlassDropdown(
                        context: context,
                        anchorKey: _clearTriggerKey,
                        items: [
                          (
                            label: '清空失效',
                            selected: false,
                            onTap: () => currCtr().toViewClear(context, 1),
                          ),
                          (
                            label: '清空看完',
                            selected: false,
                            onTap: () => currCtr().toViewClear(context, 2),
                          ),
                          (
                            label: '清空全部',
                            selected: false,
                            onTap: () => currCtr().toViewClear(context),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const .symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 2,
                          children: [
                            Text(
                              '清空',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1,
                                color: color,
                              ),
                            ),
                            Icon(
                              size: 14,
                              MdiIcons.unfoldMoreHorizontal,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
