import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/gestures.dart' show GestureBinding, PointerScrollEvent;

import 'package:PiliPlus/common/widgets/dialog/export_import.dart';
import 'package:PiliPlus/common/widgets/disabled_icon.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/sliver_wrap.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/search/search_rcmd/data.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/pages/search/widgets/hot_keyword.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/utils/em.dart' show Em;
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _tag = Utils.generateRandomString(6);
  late final SSearchController _searchController;
  late ThemeData theme;
  late bool isPortrait;
  late EdgeInsets padding;

  final ScrollController _scrollController = ScrollController();
  double? _wheelTarget;
  int _wheelLastMs = 0;

  @override
  void initState() {
    super.initState();
    _searchController = Get.put(SSearchController(_tag), tag: _tag);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) return;
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final now = DateTime.now().millisecondsSinceEpoch;
      final base = (_wheelTarget != null && now - _wheelLastMs < 260)
          ? _wheelTarget!
          : position.pixels;
      _wheelLastMs = now;
      final target = (base + dy * 1.15).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _wheelTarget = target;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    padding = MediaQuery.viewPaddingOf(context);
    isPortrait = MediaQuery.sizeOf(context).isPortrait;
  }

  @override
  Widget build(BuildContext context) {
    final trending = _searchController.enableTrending
        ? _buildHotSearch()
        : null;
    final rcmd = _searchController.enableSearchRcmd
        ? _buildHotSearch(isTrending: false)
        : null;

    final topBarHeight = padding.top + 68;
    return SimpleScaffold(
      body: Stack(
        children: [
          Padding(
            padding: .only(left: padding.left, right: padding.right),
            child: Listener(
              onPointerDown: (_) => _wheelTarget = null,
              onPointerSignal: _onPointerSignal,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topBarHeight)),
                  if (_searchController.searchSuggestion) _buildSearchSuggest(),
                  if (isPortrait) ...[
                    ?trending,
                    _buildHistory,
                    ?rcmd,
                  ] else if (trending != null || rcmd != null)
                    SliverCrossAxisGroup(
                      slivers: [
                        SliverMainAxisGroup(slivers: [?trending, ?rcmd]),
                        _buildHistory,
                      ],
                    )
                  else
                    _buildHistory,
                  SliverPadding(padding: .only(bottom: padding.bottom + 24)),
                ],
              ),
            ),
          ),
          // 顶部渐进柔化衬底：内容滑入毛玻璃搜索栏下方时平滑过渡，无硬分界线
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBarHeight + 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.92),
                      theme.colorScheme.surface.withValues(alpha: 0.65),
                      theme.colorScheme.surface.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // 顶部悬浮沉浸光感毛玻璃搜索栏
          Positioned(
            top: padding.top + 10,
            left: padding.left + 14,
            right: padding.right + 14,
            child: _buildFloatingGlassBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPill({
    required Widget child,
    double height = 48,
    double? width,
    Color? tintColor,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = tintColor ??
        (isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.62)
            : theme.colorScheme.surface.withValues(alpha: 0.72));
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.75);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingGlassBar() {
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        _buildGlassPill(
          width: 48,
          height: 48,
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              tooltip: '返回',
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: colorScheme.onSurface,
              ),
              onPressed: Get.back,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGlassPill(
            height: 48,
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      focusNode: _searchController.searchFocusNode,
                      controller: _searchController.controller,
                      textInputAction: TextInputAction.search,
                      onChanged: _searchController.onChange,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        hintText: _searchController.hintText ?? '搜索',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _searchController.submit(),
                    ),
                  ),
                  Obx(
                    () => _searchController.showUidBtn.value
                        ? IconButton(
                            tooltip: 'UID搜索用户',
                            icon: Icon(
                              Icons.person_outline,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            onPressed: () => Get.toNamed(
                              '/member?mid=${_searchController.controller.text}',
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  IconButton(
                    tooltip: '清空',
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _searchController.onClear,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildGlassPill(
          width: 48,
          height: 48,
          tintColor: colorScheme.primary.withValues(alpha: 0.85),
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              tooltip: '搜索',
              onPressed: _searchController.submit,
              icon: Icon(
                Icons.search_rounded,
                size: 22,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSuggest() {
    return Obx(() {
      final list = _searchController.searchSuggestList;
      return list.isNotEmpty &&
              list.first.term != null &&
              _searchController.controller.text != ''
          ? SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              sliver: SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh
                            .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: list
                              .map(
                                (item) => InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _searchController.onClickKeyword(
                                    item.term!,
                                    clearSuggest: false,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 11,
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        children: Em.regTitle(item.textRich)
                                            .map(
                                              (e) => TextSpan(
                                                text: e.text,
                                                style: e.isEm
                                                    ? TextStyle(
                                                        fontWeight: .bold,
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                      )
                                                    : null,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SliverToBoxAdapter();
    });
  }

  Widget _buildHotSearch({
    bool isTrending = true,
  }) {
    final text = Text(
      isTrending ? '大家都在搜' : '搜索发现',
      strutStyle: const StrutStyle(leading: 0, height: 1),
      style: theme.textTheme.titleMedium!.copyWith(
        height: 1,
        fontWeight: .bold,
      ),
    );
    final outline = theme.colorScheme.outline;
    final secondary = theme.colorScheme.secondary;
    final style = TextStyle(
      height: 1,
      fontSize: 13,
      color: outline,
    );
    return SliverPadding(
      padding: .fromLTRB(
        10,
        !isTrending && (isPortrait || _searchController.enableTrending)
            ? 4
            : 25,
        4,
        25,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const .fromLTRB(6, 0, 6, 6),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  isTrending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            text,
                            const SizedBox(width: 14),
                            TextButton(
                              style: const ButtonStyle(
                                visualDensity: .compact,
                                tapTargetSize: .shrinkWrap,
                                padding: WidgetStatePropertyAll(
                                  .symmetric(horizontal: 10),
                                ),
                              ),
                              onPressed: () => Get.toNamed('/searchTrending'),
                              child: Row(
                                children: [
                                  Text(
                                    '完整榜单',
                                    strutStyle: const StrutStyle(
                                      leading: 0,
                                      height: 1,
                                    ),
                                    style: style,
                                  ),
                                  Icon(
                                    size: 18,
                                    Icons.keyboard_arrow_right,
                                    color: outline,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : text,
                  TextButton.icon(
                    style: const ButtonStyle(
                      visualDensity: .compact,
                      tapTargetSize: .shrinkWrap,
                      padding: WidgetStatePropertyAll(
                        .symmetric(horizontal: 10),
                      ),
                    ),
                    onPressed: isTrending
                        ? _searchController.queryTrendingList
                        : _searchController.queryRecommendList,
                    icon: Icon(
                      Icons.refresh_outlined,
                      size: 18,
                      color: secondary,
                    ),
                    label: Text(
                      '刷新',
                      strutStyle: const StrutStyle(leading: 0, height: 1),
                      style: TextStyle(height: 1, color: secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => _buildHotKey(
              isTrending
                  ? _searchController.trendingState.value
                  : _searchController.recommendData.value,
              isTrending,
            ),
          ),
        ],
      ),
    );
  }

  late final mainAxisExtent = 16 + MediaQuery.textScalerOf(context).scale(14);
  Widget get _buildHistory {
    return Obx(
      () {
        final list = _searchController.historyList;
        if (list.isEmpty) {
          return const SliverToBoxAdapter();
        }
        final secondary = theme.colorScheme.secondary;
        return SliverPadding(
          padding: .fromLTRB(
            10,
            !isPortrait
                ? 25
                : _searchController.enableTrending
                ? 0
                : 6,
            6,
            25,
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const .fromLTRB(6, 0, 6, 6),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        '搜索历史',
                        strutStyle: const StrutStyle(leading: 0, height: 1),
                        style: theme.textTheme.titleMedium!.copyWith(
                          height: 1,
                          fontWeight: .bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _recordBtn,
                      _exportBtn,
                      const Spacer(),
                      TextButton.icon(
                        style: const ButtonStyle(
                          visualDensity: .compact,
                          tapTargetSize: .shrinkWrap,
                          padding: WidgetStatePropertyAll(
                            .symmetric(horizontal: 10),
                          ),
                        ),
                        onPressed: _searchController.onClearHistory,
                        icon: Icon(
                          Icons.clear_all_outlined,
                          size: 18,
                          color: secondary,
                        ),
                        label: Text(
                          '清空',
                          style: TextStyle(height: 1, color: secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFixedWrap(
                mainAxisExtent: mainAxisExtent,
                spacing: 8,
                runSpacing: 8,
                delegate: SliverChildBuilderDelegate(
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  childCount: list.length,
                  (context, index) => SearchText(
                    text: list[index],
                    onTap: _searchController.onClickKeyword,
                    onLongPress: _searchController.onLongSelect,
                    height: 1,
                    maxLines: 1,
                    fontSize: 14,
                    overflow: .ellipsis,
                    padding: const .fromLTRB(11, 8, 11, 0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget get _recordBtn => Obx(
    () {
      bool enable = _searchController.recordSearchHistory.value;
      return IconButton(
        iconSize: 22,
        tooltip: enable ? '记录搜索' : '无痕搜索',
        icon: DisabledIcon(
          disable: !enable,
          child: Icon(
            Icons.history,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        style: const ButtonStyle(
          visualDensity: .comfortable,
          tapTargetSize: .shrinkWrap,
          padding: WidgetStatePropertyAll(.zero),
        ),
        onPressed: () {
          enable = !enable;
          _searchController.recordSearchHistory.value = enable;
          GStorage.setting.put(
            SettingBoxKey.recordSearchHistory,
            enable,
          );
        },
      );
    },
  );

  Widget get _exportBtn => IconButton(
    iconSize: 22,
    tooltip: '导入/导出历史记录',
    icon: Icon(
      Icons.import_export_outlined,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
    ),
    style: const ButtonStyle(
      visualDensity: .comfortable,
      tapTargetSize: .shrinkWrap,
      padding: WidgetStatePropertyAll(.zero),
    ),
    onPressed: () => showImportExportDialog<List>(
      context,
      title: '历史记录',
      localFileName: () => 'search',
      onExport: () => jsonEncode(_searchController.historyList),
      onImport: (json) {
        final list = List<String>.from(json);
        _searchController.historyList.value = list;
        GStorage.historyWord.put('cacheList', list);
      },
    ),
  );

  Widget _buildHotKey(
    LoadingState<SearchRcmdData> loadingState,
    bool isTrending,
  ) {
    return switch (loadingState) {
      Success(:final response) when (response.list?.isNotEmpty ?? false) =>
        SliverHotKeyword(
          hotSearchList: response.list!,
          onClick: _searchController.onClickKeyword,
        ),
      Error(:final errMsg) => HttpError(
        safeArea: false,
        errMsg: errMsg,
        onReload: isTrending
            ? _searchController.queryTrendingList
            : _searchController.queryRecommendList,
      ),
      _ => const SliverToBoxAdapter(),
    };
  }
}
