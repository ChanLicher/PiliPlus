import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/models/common/search/video_search_type.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/pages/search_panel/video/controller.dart';
import 'package:PiliPlus/pages/search_panel/view.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchVideoPanel extends CommonSearchPanel {
  const SearchVideoPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchVideoPanel> createState() => _SearchVideoPanelState();
}

class _SearchVideoPanelState
    extends
        CommonSearchPanelState<
          SearchVideoPanel,
          SearchVideoData,
          SearchVideoItemModel
        >
    with GridMixin, SearchVideoPanelMixin<SearchVideoPanel> {
  @override
  late final SearchVideoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchVideoController(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }
}

mixin SearchVideoPanelMixin<S extends SearchVideoPanel>
    on
        CommonSearchPanelState<S, SearchVideoData, SearchVideoItemModel>,
        GridMixin {
  @override
  SearchVideoController get controller;

  @override
  Widget buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverFloatingHeaderWidget(
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const .fromLTRB(12, 2, 12, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.78),
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.90),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 4,
                          children: [
                            for (final e in ArchiveFilterType.values)
                              Obx(() {
                                final selected =
                                    controller.selectedType.value == e;
                                return _GlassFilterChip(
                                  label: e.desc,
                                  selected: selected,
                                  isDark: isDark,
                                  primary: colorScheme.primary,
                                  onSurface: colorScheme.onSurface,
                                  onTap: () => controller
                                    ..order = e == .totalrank ? '' : e.name
                                    ..selectedType.value = e
                                    ..onSortSearch(getBack: false),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 0.8,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.12,
                      ),
                    ),
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        hoverColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                        onTap: () => controller.onShowFilterDialog(context),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.filter_list_outlined,
                            size: 17,
                            color: colorScheme.primary,
                          ),
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
    );
  }

  @override
  Widget buildList(List<SearchVideoItemModel> list) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return VideoCardH(
          videoItem: list[index],
          onRemove: () => controller.loadingState
            ..value.data!.removeAt(index)
            ..refresh(),
        );
      },
      itemCount: list.length,
    );
  }

  @override
  Widget get buildLoading => gridSkeleton;
}

class _GlassFilterChip extends StatefulWidget {
  const _GlassFilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;

  @override
  State<_GlassFilterChip> createState() => _GlassFilterChipState();
}

class _GlassFilterChipState extends State<_GlassFilterChip> {
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
        builder: (context, hovered, _) {
          final bgColor = widget.selected
              ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : widget.primary.withValues(alpha: 0.12))
              : hovered
              ? (widget.isDark ? Colors.white : Colors.black).withValues(
                  alpha: widget.isDark ? 0.09 : 0.05,
                )
              : Colors.transparent;
          return AnimatedScale(
            scale: hovered ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: const Cubic(0.2, 0, 0, 1),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                hoverColor: Colors.transparent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: const Cubic(0.2, 0, 0, 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.selected
                          ? (widget.isDark ? Colors.white : widget.primary)
                          : widget.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
