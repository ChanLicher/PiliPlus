import 'dart:async';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/player_bar.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/mine_tab_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/mine/widgets/fav_item.dart';
import 'package:PiliPlus/pages/mine/widgets/history_item.dart';
import 'package:PiliPlus/pages/mine/widgets/later_item.dart';
import 'package:PiliPlus/pages/mine/widgets/sub_item.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key, this.showBackBtn = false});

  final bool showBackBtn;

  @override
  State<MinePage> createState() => _MediaPageState();
}

class _MediaPageState extends CommonPageState<MinePage>
    with AutomaticKeepAliveClientMixin {
  final MineController controller = Get.putOrFind(MineController.new);
  late final MainController _mainController = Get.find<MainController>();
  late ThemeData theme;

  @override
  bool get wantKeepAlive => true;

  bool get checkPage =>
      _mainController.navigationBars[0] != NavigationBarType.mine &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  BoxDecoration _glassDecoration({
    required bool isDark,
    double radius = 20,
    double? darkAlpha,
    double? lightAlpha,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: darkAlpha ?? 0.06)
          : Colors.white.withValues(alpha: lightAlpha ?? 0.86),
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.11)
            : Colors.white.withValues(alpha: 0.95),
        width: 0.85,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.045),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F6F8);
    final secondary = theme.colorScheme.secondary;
    return ColoredBox(
      color: pageBg,
      child: SafeArea( // 避让安全区
        child: Column(
          children: [
            Padding(
              padding: const .fromLTRB(0, 8, 0, 6),
              child: _buildHeaderActions,
            ),
            Expanded(
              child: Material(
                type: .transparency,
                child: refreshIndicator(
                  onRefresh: controller.onRefresh,
                  child: onBuild(
                    ListView(
                      padding: const .only(top: 4, bottom: 150),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _buildUserInfo(theme, secondary),
                        _buildActions(secondary),
                        for (final tab in controller.mineTabs)
                          switch (tab) {
                            .favorite => Obx(_buildFav),
                            .history => Obx(_buildHistory),
                            .later => Obx(_buildLater),
                            .sub => Obx(_buildSub),
                          },
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
  }

  Widget _buildActions(Color primary) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: _glassDecoration(isDark: isDark, radius: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            children: controller.list
                .map(
                  (e) => Expanded(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: e.onTap,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                          child: Column(
                            spacing: 7,
                            mainAxisSize: .min,
                            mainAxisAlignment: .center,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: primary.withValues(
                                    alpha: isDark ? 0.16 : 0.10,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 38,
                                  height: 38,
                                  child: Icon(
                                    e.icon,
                                    color: primary,
                                    size: 21,
                                  ),
                                ),
                              ),
                              Text(
                                e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget get _buildHeaderActions {
    final isDark = theme.brightness == Brightness.dark;
    const iconSize = 21.0;
    const padding = EdgeInsets.all(8);
    const style = ButtonStyle(
      tapTargetSize: .shrinkWrap,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
    return PlayerBar(
      left: widget.showBackBtn
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: DecoratedBox(
                decoration: _glassDecoration(isDark: isDark, radius: 18),
                child: const BackButton(),
              ),
            )
          : const SizedBox.shrink(),
      right: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: DecoratedBox(
          decoration: _glassDecoration(isDark: isDark, radius: 22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              spacing: 2,
              mainAxisSize: .min,
              children: [
                if (!_mainController.hasHome) ...[
                  IconButton(
                    iconSize: iconSize,
                    padding: padding,
                    style: style,
                    onPressed: () => Get.toNamed('/search'),
                    icon: const Icon(Icons.search),
                  ),
                  msgBadge(_mainController),
                ],
                if (GStorage.reply != null)
                  IconButton(
                    iconSize: iconSize,
                    padding: padding,
                    style: style,
                    onPressed: () => Get.toNamed('/myReply'),
                    icon: const Icon(Icons.message_outlined),
                  ),
                Obx(
                  () {
                    final anonymity = MineController.anonymity.value;
                    return IconButton(
                      iconSize: iconSize,
                      padding: padding,
                      style: style,
                      onPressed: MineController.onChangeAnonymity,
                      icon: anonymity
                          ? const Icon(MdiIcons.incognito)
                          : const Icon(MdiIcons.incognitoOff),
                    );
                  },
                ),
                IconButton(
                  iconSize: iconSize,
                  padding: padding,
                  style: style,
                  onPressed: () =>
                      LoginPageController.switchAccountDialog(context),
                  icon: const Icon(Icons.switch_account_outlined),
                ),
                Obx(
                  () => IconButton(
                    iconSize: iconSize,
                    padding: padding,
                    style: style,
                    onPressed: controller.onChangeTheme,
                    icon: controller.themeType.value.icon,
                  ),
                ),
                IconButton(
                  iconSize: iconSize,
                  padding: padding,
                  style: style,
                  onPressed: () =>
                      Get.toNamed('/setting', preventDuplicates: false),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(ThemeData theme, Color secondary) {
    final isDark = theme.brightness == Brightness.dark;
    final style = TextStyle(
      fontSize: theme.textTheme.titleMedium!.fontSize,
      fontWeight: FontWeight.bold,
    );
    final labelStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    final coinLabelStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: theme.colorScheme.outline,
    );
    final coinValStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.bold,
      color: secondary,
    );
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      final userStat = controller.userStat.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: DecoratedBox(
          decoration: _glassDecoration(isDark: isDark, radius: 22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: .opaque,
                  onTap: controller.onLogin,
                  onLongPress: () {
                    Feedback.forLongPress(context);
                    controller.onLogin(true);
                  },
                  onSecondaryTap: PlatformUtils.isMobile
                      ? null
                      : () => controller.onLogin(true),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      userInfo.face != null
                          ? Stack(
                              clipBehavior: .none,
                              children: [
                                NetworkImgLayer(
                                  src: userInfo.face,
                                  type: .avatar,
                                  width: 58,
                                  height: 58,
                                ),
                                if (isVip)
                                  Positioned(
                                    right: -1,
                                    bottom: -2,
                                    child: SvgPicture.asset(
                                      Assets.vipIcon,
                                      height: 19,
                                      semanticsLabel: "大会员",
                                    ),
                                  ),
                              ],
                            )
                          : ClipOval(
                              child: Image.asset(
                                width: 58,
                                height: 58,
                                cacheHeight: 58.cacheSize(context),
                                Assets.avatarPlaceHolder,
                                semanticLabel: "默认头像",
                              ),
                            ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: .min,
                          mainAxisAlignment: .center,
                          crossAxisAlignment: .start,
                          children: [
                            Row(
                              spacing: 6,
                              children: [
                                Flexible(
                                  child: Text(
                                    userInfo.uname ?? '点击登录',
                                    style: theme.textTheme.titleMedium!.copyWith(
                                      height: 1.1,
                                      fontWeight: FontWeight.w600,
                                      color: isVip && userInfo.vipType == 2
                                          ? theme.colorScheme.vipColor
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: .ellipsis,
                                  ),
                                ),
                                BiliUtils.levelPicture(
                                  levelInfo?.currentLevel ?? 0,
                                  isSeniorMember: userInfo.isSeniorMember == 1,
                                  height: 10,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '硬币 ',
                                    style: coinLabelStyle,
                                  ),
                                  TextSpan(
                                    text: userInfo.money?.toString() ?? '-',
                                    style: coinValStyle,
                                  ),
                                  TextSpan(
                                    text: "      经验 ",
                                    style: coinLabelStyle,
                                  ),
                                  TextSpan(
                                    text:
                                        levelInfo?.currentExp?.toString() ?? '-',
                                    style: coinValStyle,
                                  ),
                                  TextSpan(
                                    text: "/${levelInfo?.nextExp ?? '-'}",
                                    style: coinLabelStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: LinearProgressIndicator(
                                minHeight: 3.5,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                                value: hasLevel
                                    ? levelInfo.currentExp! / levelInfo.nextExp!
                                    : 0,
                                trackGap: hasLevel ? null : 0,
                                backgroundColor: theme.colorScheme.outline
                                    .withValues(alpha: 0.22),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  secondary,
                                ),
                                stopIndicatorColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Divider(
                    height: 1,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.06,
                    ),
                  ),
                ),
                Row(
                  spacing: 8,
                  children: [
                    _btn(
                      count: userStat.dynamicCount,
                      countStyle: style,
                      name: '动态',
                      labelStyle: labelStyle,
                      onTap: () => controller.push('memberDynamics'),
                    ),
                    _btn(
                      count: userStat.following,
                      countStyle: style,
                      name: '关注',
                      labelStyle: labelStyle,
                      onTap: () => controller.push('follow'),
                    ),
                    _btn(
                      count: userStat.follower,
                      countStyle: style,
                      name: '粉丝',
                      labelStyle: labelStyle,
                      onTap: () => controller.push('fan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _btn({
    required int? count,
    required TextStyle countStyle,
    required String name,
    required TextStyle? labelStyle,
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: isDark ? 0.035 : 0.025,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                spacing: 3,
                mainAxisSize: .min,
                mainAxisAlignment: .center,
                children: [
                  Text(
                    count?.toString() ?? '-',
                    style: countStyle,
                  ),
                  Text(
                    name,
                    style: labelStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _autoRefresh(MineRefreshMixin tabCtr) => Timer(
    const Duration(milliseconds: 150),
    () => tabCtr.onRefresh(isManual: false),
  );

  Widget _buildFav() {
    return _buildTab(
      .favorite,
      controller.favCtr!,
      itemBuilder: (element) => FavFolderItem(
        item: element,
        onPop: () => _autoRefresh(controller.favCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/fav',
      )?.whenComplete(() => _autoRefresh(controller.favCtr!)),
    );
  }

  Widget _buildHistory() {
    return _buildTab(
      .history,
      controller.historyCtr!,
      itemBuilder: (element) => MineHistoryItem(
        item: element,
        onPop: () => _autoRefresh(controller.historyCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/history',
      )?.whenComplete(() => _autoRefresh(controller.historyCtr!)),
    );
  }

  Widget _buildLater() {
    return _buildTab(
      .later,
      controller.laterCtr!,
      itemBuilder: (element) => MineLaterItem(
        item: element,
        onPop: () => _autoRefresh(controller.laterCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/later',
      )?.whenComplete(() => _autoRefresh(controller.laterCtr!)),
    );
  }

  Widget _buildSub() {
    return _buildTab(
      .sub,
      controller.subCtr!,
      itemBuilder: (element) => MineSubItem(
        item: element,
        onPop: () => _autoRefresh(controller.subCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/subscription',
      )?.whenComplete(() => _autoRefresh(controller.subCtr!)),
    );
  }

  Widget _buildTab<R, T>(
    MineTabType tab,
    MineRefreshMixin<R, T> tabCtr, {
    required Widget Function(T element) itemBuilder,
    required VoidCallback onPushDetail,
  }) {
    final Widget child;
    switch (tabCtr.loadingState.value) {
      case Loading():
        return const SizedBox.shrink();
      case Success(:final response):
        if (response == null || response.isEmpty) {
          return const SizedBox.shrink();
        }
        child = SizedBox(
          height: 192,
          child: ListView.separated(
            itemCount: response.length,
            controller: tabCtr.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const .fromLTRB(16, 6, 16, 12),
            itemBuilder: (context, index) {
              if (index == response.length - 1) {
                tabCtr.onLoadMore();
              }
              return SizedBox(width: 184, child: itemBuilder(response[index]));
            },
            scrollDirection: .horizontal,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
          ),
        );
      case Error(:final errMsg):
        if (errMsg == null) return const SizedBox.shrink();
        child = SizedBox(
          height: 160,
          child: Center(child: Text(errMsg, textAlign: .center)),
        );
    }
    final isDark = theme.brightness == Brightness.dark;
    final secondary = theme.colorScheme.secondary;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: DecoratedBox(
            decoration: _glassDecoration(isDark: isDark, radius: 16),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onPushDetail,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(
                    children: [
                      Text(
                        tab.label,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tabCtr.count != null) ...[
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: secondary.withValues(
                              alpha: isDark ? 0.18 : 0.11,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            child: Text(
                              '${tabCtr.count}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: secondary,
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onPressed: tabCtr.onRefresh,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 19,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
