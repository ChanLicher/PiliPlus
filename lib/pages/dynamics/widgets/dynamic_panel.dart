import 'package:PiliPlus/common/widgets/avatars.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_transition.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/widgets/action_panel.dart';
import 'package:PiliPlus/pages/dynamics/widgets/author_panel.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dyn_content.dart';
import 'package:PiliPlus/pages/dynamics/widgets/interaction.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class DynamicPanel extends StatefulWidget {
  final DynamicItemModel item;
  final bool isDetail;
  final ValueChanged<Object>? onRemove;
  final bool isSave;
  final void Function(bool isTop, Object dynId)? onSetTop;
  final VoidCallback? onBlock;
  final VoidCallback? onUnfold;
  final bool isDetailPortraitW;
  final Future<LoadingState> Function(bool isPrivate, Object dynId)?
  onSetPubSetting;
  final VoidCallback? onEdit;
  final ValueChanged<int>? onSetReplySubject;

  const DynamicPanel({
    super.key,
    required this.item,
    this.isDetail = false,
    this.onRemove,
    this.isSave = false,
    this.onSetTop,
    this.onBlock,
    this.onUnfold,
    this.isDetailPortraitW = true,
    this.onSetPubSetting,
    this.onEdit,
    this.onSetReplySubject,
  });

  @override
  State<DynamicPanel> createState() => _DynamicPanelState();
}

class _DynamicPanelState extends State<DynamicPanel> {
  final GlobalKey _cardKey = GlobalKey();
  bool _pushing = false;

  DynamicArchiveModel? get _avArchive => widget.item.type == 'DYNAMIC_TYPE_AV'
      ? widget.item.modules.moduleDynamic?.major?.archive
      : null;

  bool get _canVideoHero =>
      !widget.isSave &&
      _avArchive != null &&
      _avArchive!.bvid?.isNotEmpty == true;

  String get _heroTag =>
      'dyn_av_${identityHashCode(this)}_${_avArchive?.bvid ?? widget.item.idStr}';

  @override
  void dispose() {
    if (_canVideoHero) {
      clearPendingVideoCardTransition(_heroTag);
    }
    super.dispose();
  }

  Future<void> _onTapPanel(BuildContext context) async {
    if (_canVideoHero) {
      if (_pushing) return;
      _pushing = true;
      try {
        final archive = _avArchive!;
        final bvid = archive.bvid!;
        final useHero = !isVideoPageTransitionActive(_heroTag);
        if (useHero) {
          prepareVideoCardTransition(_heroTag, _cardKey.currentContext ?? context);
        }
        int? cid;
        Dimension? dimension;
        if (await SearchHttp.ab2cWithDimension(bvid: bvid) case final res?) {
          cid = res.cid;
          dimension = res.dimension;
        }
        if (cid != null) {
          PageUtils.toVideoPage(
            bvid: bvid,
            cid: cid,
            cover: archive.cover,
            title: archive.title,
            dimension: dimension,
            heroTag: useHero ? _heroTag : null,
          );
          return;
        }
      } finally {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _pushing = false;
        });
      }
    }
    PageUtils.pushDynDetail(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDetail = widget.isDetail;
    final isSave = widget.isSave;
    final isDetailPortraitW = widget.isDetailPortraitW;
    if (item.visible == false) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const cardRadius = BorderRadius.all(Radius.circular(16));
    final cardSurface = isDark
        ? const Color(0xFF1A1B1F)
        : const Color(0xFFFFFFFF);
    final authorWidget = AuthorPanel(
      item: item,
      isDetail: isDetail,
      onRemove: widget.onRemove,
      isSave: isSave,
      onSetTop: widget.onSetTop,
      onBlock: widget.onBlock,
      onSetPubSetting: widget.onSetPubSetting,
      onEdit: widget.onEdit,
      onSetReplySubject: widget.onSetReplySubject,
    );

    void showMore() => _imageSaveDialog(context, authorWidget.morePanel);

    final child = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: isSave ? null : cardRadius,
        onTap:
            isDetail &&
                !const {
                  'DYNAMIC_TYPE_AV',
                  'DYNAMIC_TYPE_UGC_SEASON',
                  'DYNAMIC_TYPE_PGC_UNION',
                  'DYNAMIC_TYPE_PGC',
                  'DYNAMIC_TYPE_LIVE',
                  'DYNAMIC_TYPE_LIVE_RCMD',
                  'DYNAMIC_TYPE_MEDIALIST',
                  'DYNAMIC_TYPE_COURSES_SEASON',
                }.contains(item.type)
            ? null
            : () => _onTapPanel(context),
        onLongPress: showMore,
        onSecondaryTap: PlatformUtils.isMobile ? null : showMore,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: authorWidget,
            ),
            if (item.modules.moduleDispute case final moduleDispute?)
              _buildDispute(theme, moduleDispute),
            ...dynContent(
              context,
              theme: theme,
              isSave: isSave,
              isDetail: isDetail,
              item: item,
              floor: 1,
            ),
            const SizedBox(height: 2),
            if (!isDetail) ...[
              if (item.modules.moduleInteraction case ModuleInteraction(
                :final items,
              ))
                if (items != null && items.isNotEmpty)
                  dynInteraction(
                    theme: theme,
                    items: items,
                  ),
              ActionPanel(item: item),
              if (item.modules.moduleFold case final moduleFold?) ...[
                Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                _buildFoldItem(theme, moduleFold),
              ],
            ] else if (!isSave)
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (isSave || (isDetail && !isDetailPortraitW)) {
      if (_canVideoHero) {
        return VideoCardHero(
          key: _cardKey,
          tag: _heroTag,
          surfaceColor: cardSurface,
          cornerRadius: 16,
          child: child,
        );
      }
      return child;
    }
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: cardRadius,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.95),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.045),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: child,
      ),
    );
    if (_canVideoHero) {
      card = VideoCardHero(
        key: _cardKey,
        tag: _heroTag,
        surfaceColor: cardSurface,
        cornerRadius: 16,
        child: card,
      );
    }
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: card,
      ),
    );
  }

  void _imageSaveDialog(
    BuildContext context,
    Function(BuildContext) morePanel,
  ) {
    String? title;
    String? cover;
    String? bvid;
    final item = widget.item;
    late final major = item.modules.moduleDynamic?.major;
    switch (item.type) {
      case 'DYNAMIC_TYPE_AV':
        if (major?.archive case final archive?) {
          title = archive.title;
          cover = archive.cover;
          bvid = archive.bvid;
        }
        break;
      case 'DYNAMIC_TYPE_UGC_SEASON':
        if (major?.ugcSeason case final ugcSeason?) {
          title = ugcSeason.title;
          cover = ugcSeason.cover;
          bvid = ugcSeason.bvid;
        }
        break;
      case 'DYNAMIC_TYPE_PGC' || 'DYNAMIC_TYPE_PGC_UNION':
        if (major?.pgc case final pgc?) {
          title = pgc.title;
          cover = pgc.cover;
        }
        break;
      case 'DYNAMIC_TYPE_LIVE_RCMD':
        if (major?.liveRcmd case final liveRcmd?) {
          title = liveRcmd.title;
          cover = liveRcmd.cover;
        }
        break;
      case 'DYNAMIC_TYPE_LIVE':
        if (major?.live case final live?) {
          title = live.title;
          cover = live.cover;
        }
        break;
      case 'DYNAMIC_TYPE_COURSES_SEASON':
        if (major?.courses case final courses?) {
          title = courses.title;
          cover = courses.cover;
        }
        break;
      case 'DYNAMIC_TYPE_SUBSCRIPTION_NEW':
        if (major?.subscriptionNew?.liveRcmd?.content?.livePlayInfo
            case final livePlayInfo?) {
          title = livePlayInfo.title;
          cover = livePlayInfo.cover;
        }
        break;
      default:
        morePanel(context);
        return;
    }
    imageSaveDialog(
      title: title,
      cover: cover,
      bvid: bvid,
    );
  }

  Widget _buildFoldItem(ThemeData theme, ModuleFold moduleFold) {
    Widget child = Text.rich(
      textAlign: TextAlign.center,
      style: TextStyle(
        height: 1,
        fontSize: 13,
        color: theme.colorScheme.outline,
      ),
      strutStyle: const StrutStyle(
        height: 1,
        leading: 0,
        fontSize: 13,
      ),
      TextSpan(
        children: [
          TextSpan(text: moduleFold.statement ?? '展开'),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              size: 19,
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
    final users = moduleFold.users;
    if (users != null && users.isNotEmpty) {
      child = Row(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          avatars(colorScheme: theme.colorScheme, users: users),
          child,
        ],
      );
    }
    return InkWell(
      onTap: widget.onUnfold,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: child,
      ),
    );
  }

  Widget _buildDispute(ThemeData theme, ModuleDispute moduleDispute) {
    final child = Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(
          alpha: theme.isLight ? 0.5 : 0.7,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Text.rich(
        style: TextStyle(
          height: 1,
          fontSize: 13,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        strutStyle: const StrutStyle(
          leading: 0,
          height: 1,
          fontSize: 13,
        ),
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  size: 15,
                  Icons.warning_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            TextSpan(text: moduleDispute.title),
          ],
        ),
      ),
    );
    if (moduleDispute.jumpUrl?.isNotEmpty == true) {
      return GestureDetector(
        onTap: () => PageUtils.handleWebview(moduleDispute.jumpUrl!),
        child: child,
      );
    }
    return child;
  }
}
