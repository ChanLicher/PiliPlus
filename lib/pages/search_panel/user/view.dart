import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/pages/search_panel/user/controller.dart';
import 'package:PiliPlus/pages/search_panel/user/widgets/item.dart';
import 'package:PiliPlus/pages/search_panel/view.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class SearchUserPanel extends CommonSearchPanel {
  const SearchUserPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchUserPanel> createState() => _SearchUserPanelState();
}

class _SearchUserPanelState
    extends
        CommonSearchPanelState<
          SearchUserPanel,
          SearchUserData,
          SearchUserItemModel
        > {
  @override
  late final SearchUserController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchUserController(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  @override
  Widget buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverFloatingHeaderWidget(
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const .fromLTRB(12, 2, 12, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: RepaintBoundary(
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.06),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.92),
                          Colors.white.withValues(alpha: 0.78),
                        ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.13)
                      : Colors.white.withValues(alpha: 0.94),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => Text(
                      '排序: ${controller.userOrderType!.value.label}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.8,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  ),
                  Obx(
                    () => Text(
                      '用户类型: ${controller.userType!.value.label}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.8,
                    height: 14,
                    margin: const EdgeInsets.only(left: 10, right: 4),
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
    );
  }

  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: Grid.smallCardWidth * 2,
    mainAxisExtent: 78,
  );

  @override
  Widget buildList(List<SearchUserItemModel> list) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (BuildContext context, int index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return SearchUserItem(
          item: list[index],
        );
      },
      itemCount: list.length,
    );
  }

  @override
  Widget get buildLoading => SliverGrid(
    gridDelegate: gridDelegate,
    delegate: const SliverSingleChildDelegate(
      count: 10,
      child: MsgFeedTopSkeleton(),
    ),
  );
}
