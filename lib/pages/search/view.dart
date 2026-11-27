import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/dialog/export_import.dart';
import 'package:PiliPlus/common/widgets/disabled_icon.dart';
import 'package:PiliPlus/pages/common/common_controller.dart'
    show SmoothWheelScrollController;
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

  final ScrollController _scrollController = SmoothWheelScrollController();

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

    final isDark = theme.brightness == Brightness.dark;
    // 纯净中性底色：去掉 Material You 色偏，与透明毛玻璃胶囊质感保持一致
    final pageBg = isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F6F8);
    final topBarHeight = padding.top + 68;
    return SimpleScaffold(
      body: ColoredBox(
        color: pageBg,
        child: Stack(
        children: [
          Padding(
            padding: .only(left: padding.left, right: padding.right),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topBarHeight + 8)),
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
                      pageBg.withValues(alpha: 0.94),
                      pageBg.withValues(alpha: 0.65),
                      pageBg.withValues(alpha: 0.0),
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
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    double borderRadius = 22,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.85);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPill({
    required Widget child,
    double height = 48,
    double? width,
  }) {
    return _buildGlassContainer(
      width: width,
      height: height,
      borderRadius: height / 2,
      child: child,
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
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              onPressed: _searchController.submit,
              icon: Icon(
                Icons.search_rounded,
                size: 22,
                color: colorScheme.primary,
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
                child: _buildGlassContainer(
                  borderRadius: 20,
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
      padding: EdgeInsets.fromLTRB(
        14,
        !isTrending && (isPortrait || _searchController.enableTrending)
            ? 6
            : 12,
        isPortrait ? 14 : 7,
        12,
      ),
      sliver: SliverToBoxAdapter(
        child: _buildGlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  isTrending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            text,
                            const SizedBox(width: 10),
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
              const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  Widget get _buildHistory {
    return Obx(
      () {
        final list = _searchController.historyList;
        if (list.isEmpty) {
          return const SliverToBoxAdapter();
        }
        final secondary = theme.colorScheme.secondary;
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isPortrait ? 14 : 7,
            !isPortrait
                ? 12
                : _searchController.enableTrending
                ? 6
                : 12,
            14,
            12,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildGlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: list
                        .map(
                          (word) => SearchText(
                            text: word,
                            onTap: _searchController.onClickKeyword,
                            onLongPress: _searchController.onLongSelect,
                            height: 1.15,
                            maxLines: 1,
                            fontSize: 14,
                            overflow: .ellipsis,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
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
        HotKeywordView(
          hotSearchList: response.list!,
          onClick: _searchController.onClickKeyword,
        ),
      Error(:final errMsg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton.icon(
            onPressed: isTrending
                ? _searchController.queryTrendingList
                : _searchController.queryRecommendList,
            icon: const Icon(Icons.refresh_outlined, size: 18),
            label: Text(errMsg ?? '加载失败，点击重试'),
          ),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
