import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/pages/search_panel/all/view.dart';
import 'package:PiliPlus/pages/search_panel/article/view.dart';
import 'package:PiliPlus/pages/search_panel/live/view.dart';
import 'package:PiliPlus/pages/search_panel/pgc/view.dart';
import 'package:PiliPlus/pages/search_panel/user/view.dart';
import 'package:PiliPlus/pages/search_panel/video/view.dart';
import 'package:PiliPlus/pages/search_result/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late SearchResultController _searchResultController;
  late TabController _tabController;
  final String _tag = DateTime.now().millisecondsSinceEpoch.toString();
  final bool _isFromSearch = Get.arguments?['fromSearch'] ?? false;
  SSearchController? sSearchController;

  @override
  void initState() {
    super.initState();
    _searchResultController = Get.put(
      SearchResultController(),
      tag: _tag,
    );

    _tabController = TabController(
      vsync: this,
      initialIndex: Get.arguments?['initIndex'] ?? 0,
      length: SearchType.actives.length,
    );

    if (_isFromSearch) {
      try {
        sSearchController = Get.find<SSearchController>(
          tag: Get.parameters['tag'],
        );
        _tabController.addListener(listener);
      } catch (_) {}
    }
  }

  void listener() {
    sSearchController?.initIndex = _tabController.index;
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    super.dispose();
  }

  void _onTapSearchBar() {
    if (_isFromSearch) {
      Get.back(result: true);
    } else {
      Get.offNamed(
        '/search',
        parameters: {'text': _searchResultController.keyword},
      );
    }
  }

  Widget _buildGlassBox({
    required bool isDark,
    required double radius,
    required Widget child,
    double? width,
    double? height,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.all(Radius.circular(radius)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.13)
                    : Colors.white.withValues(alpha: 0.90),
                width: 0.85,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F6F8);
    final topPadding = MediaQuery.paddingOf(context).top;

    return SimpleScaffold(
      body: ColoredBox(
        color: pageBg,
        child: ViewSafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12, topPadding + 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _HoverScaleWrap(
                          scale: 1.05,
                          child: _buildGlassBox(
                            isDark: isDark,
                            radius: 20,
                            width: 40,
                            height: 40,
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                onTap: Get.back,
                                customBorder: const CircleBorder(),
                                hoverColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.08),
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 17,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildGlassBox(
                            isDark: isDark,
                            radius: 20,
                            height: 40,
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                onTap: _onTapSearchBar,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                                hoverColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.05),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _searchResultController.keyword,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildGlassBox(
                      isDark: isDark,
                      radius: 21,
                      height: 42,
                      child: TabBar(
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        splashFactory: NoSplash.splashFactory,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        controller: _tabController,
                        tabs: SearchType.actives
                            .map(
                              (item) => Obx(
                                () {
                                  int count =
                                      _searchResultController.count[item.index];
                                  final label =
                                      '${item.label}${count != -1 ? ' ${count > 99 ? '99+' : count}' : ''}';
                                  return _HoverGlassTab(
                                    label: label,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            )
                            .toList(),
                        isScrollable: true,
                        indicatorWeight: 0,
                        indicatorPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        indicator: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(18),
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.16,
                                  ),
                            width: 0.6,
                          ),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: isDark
                            ? Colors.white
                            : theme.colorScheme.primary,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        dividerColor: Colors.transparent,
                        dividerHeight: 0,
                        unselectedLabelColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.64),
                        tabAlignment: TabAlignment.start,
                        onTap: (index) {
                          if (!_tabController.indexIsChanging) {
                            if (_searchResultController.toTopIndex.value ==
                                index) {
                              _searchResultController.toTopIndex.refresh();
                            } else {
                              _searchResultController.toTopIndex.value = index;
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tabBarView(
                  controller: _tabController,
                  children: SearchType.actives
                      .map(
                        (item) => switch (item) {
                          .all => SearchAllPanel(
                            tag: _tag,
                            searchType: item,
                            keyword: _searchResultController.keyword,
                          ),
                          .video => SearchVideoPanel(
                            tag: _tag,
                            searchType: item,
                            keyword: _searchResultController.keyword,
                          ),
                          .media_bangumi || .media_ft => SearchPgcPanel(
                            tag: _tag,
                            searchType: item,
                            keyword: _searchResultController.keyword,
                          ),
                          .live_room => SearchLivePanel(
                            tag: _tag,
                            searchType: item,
                            keyword: _searchResultController.keyword,
                          ),
                          .bili_user => SearchUserPanel(
                            tag: _tag,
                            searchType: item,
                            keyword: _searchResultController.keyword,
                          ),
                          .article => SearchArticlePanel(
                            tag: _tag,
                            searchType: item,
                            keyword: _searchResultController.keyword,
                          ),
                        },
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverScaleWrap extends StatefulWidget {
  const _HoverScaleWrap({
    required this.child,
    this.scale = 1.04,
  });

  final Widget child;
  final double scale;

  @override
  State<_HoverScaleWrap> createState() => _HoverScaleWrapState();
}

class _HoverScaleWrapState extends State<_HoverScaleWrap> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _hovered,
        builder: (context, hovered, child) {
          return AnimatedScale(
            scale: hovered ? widget.scale : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: const Cubic(0.2, 0, 0, 1),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _HoverGlassTab extends StatefulWidget {
  const _HoverGlassTab({
    required this.label,
    required this.isDark,
  });

  final String label;
  final bool isDark;

  @override
  State<_HoverGlassTab> createState() => _HoverGlassTabState();
}

class _HoverGlassTabState extends State<_HoverGlassTab> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 34,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _hovered.value = true,
        onExit: (_) => _hovered.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, hovered, child) {
            return AnimatedScale(
              scale: hovered ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: const Cubic(0.2, 0, 0, 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: const Cubic(0.2, 0, 0, 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: hovered
                      ? (widget.isDark ? Colors.white : Colors.black)
                            .withValues(alpha: widget.isDark ? 0.10 : 0.055)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: child,
              ),
            );
          },
          child: Text(widget.label),
        ),
      ),
    );
  }
}
