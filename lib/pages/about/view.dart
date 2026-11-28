import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/dialog/export_import.dart';
import 'package:PiliPlus/common/widgets/dialog/simple_dialog_option.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/services/logger.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/android/bindings.g.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/cache_manager.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/update.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:os_type/os_type.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final currentVersion =
      '${BuildConfig.versionName}+${BuildConfig.versionCode}';
  final versionTag = '${BuildConfig.versionTag}+${BuildConfig.versionCode}';
  RxString cacheSize = ''.obs;

  late int _pressCount = 0;

  @override
  void initState() {
    super.initState();
    getCacheSize();
  }

  @override
  void dispose() {
    cacheSize.close();
    super.dispose();
  }

  void getCacheSize() {
    CacheManager.loadApplicationCache().then((res) {
      if (mounted) {
        cacheSize.value = res.formatSize;
      }
    });
  }

  Widget _buildGlassDialog(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(22));
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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

  Widget _buildGlassSection({
    required bool isDark,
    required List<Widget> children,
  }) {
    const radius = BorderRadius.all(Radius.circular(20));
    final dividerColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.06,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.86),
          borderRadius: radius,
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
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 52,
                      endIndent: 16,
                      color: dividerColor,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDialog() => showDialog(
    context: context,
    builder: (context) => _buildGlassDialog(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入链接或 Scheme 跳转',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (value) {
            Get.back();
            if (value.isNotEmpty) {
              PiliScheme.routePushFromUrl(value);
            }
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F6F8);
    const style = TextStyle(fontSize: 15);
    final outline = theme.colorScheme.outline;
    final subTitleStyle = TextStyle(fontSize: 13, color: outline);
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    return SimpleScaffold(
      appBar: showAppBar ? AppBar(title: const Text('关于')) : null,
      body: ColoredBox(
        color: pageBg,
        child: ListView(
          padding: EdgeInsets.only(
            left: showAppBar ? padding.left : 0,
            right: showAppBar ? padding.right : 0,
            top: 12,
            bottom: padding.bottom + 100,
          ),
          children: [
            _buildGlassSection(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (++_pressCount == 5) {
                            _pressCount = 0;
                            _showDialog();
                          }
                        },
                        onSecondaryTap: PlatformUtils.isDesktop
                            ? _showDialog
                            : null,
                        child: Image.asset(
                          width: 120,
                          height: 120,
                          excludeFromSemantics: true,
                          cacheWidth: 120.cacheSize(context),
                          Assets.logo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${Constants.appName}${OS.isHarmony ? '(鸿蒙版)' : ''}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '使用Flutter开发的B站第三方客户端',
                            style: TextStyle(color: outline, fontSize: 13),
                            semanticsLabel: '与你一起，发现不一样的世界',
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.accessibility_new,
                            semanticLabel: "无障碍适配",
                            size: 16,
                            color: outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  onTap: () => Update.checkUpdate(false),
                  onLongPress: () => Utils.copyText(versionTag),
                  onSecondaryTap: PlatformUtils.isMobile
                      ? null
                      : () => Utils.copyText(versionTag),
                  title: const Text('当前版本'),
                  leading: const Icon(Icons.commit_outlined),
                  trailing: Text(
                    versionTag,
                    style: subTitleStyle,
                  ),
                ),
                ListTile(
                  title: Text(
                    'Build Time: ${DateFormatUtils.format(BuildConfig.buildTime, format: DateFormatUtils.longFormatDs)}\nCommit Hash: ${BuildConfig.commitHash}',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  leading: const Icon(Icons.info_outline),
                  onTap: () => PageUtils.launchURL(
                    '${Constants.sourceCodeUrl}/commit/${BuildConfig.commitHash == 'N/A' ? 'HEAD' : BuildConfig.commitHash}',
                  ),
                  onLongPress: () => Utils.copyText(BuildConfig.commitHash),
                  onSecondaryTap: PlatformUtils.isMobile
                      ? null
                      : () => Utils.copyText(BuildConfig.commitHash),
                ),
              ],
            ),
            _buildGlassSection(
              isDark: isDark,
              children: [
                ListTile(
                  onTap: () =>
                      PageUtils.launchURL(Constants.upstreamSourceCodeUrl),
                  leading: const Icon(Icons.code),
                  title: const Text('上游Source Code'),
                  subtitle: Text(
                    Constants.upstreamSourceCodeUrl,
                    style: subTitleStyle,
                  ),
                ),
                ListTile(
                  onTap: () => PageUtils.launchURL(Constants.sourceCodeUrl),
                  leading: const Icon(Icons.code),
                  title: const Text('Source Code'),
                  subtitle: Text(Constants.sourceCodeUrl, style: subTitleStyle),
                ),
                if (Platform.isAndroid)
                  ListTile(
                    onTap: AndroidHelper.openLinkVerifySettings,
                    leading: const Icon(MdiIcons.linkBoxOutline),
                    title: const Text('打开受支持的链接'),
                    trailing: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: outline,
                    ),
                  ),
                ListTile(
                  onTap: () =>
                      PageUtils.launchURL('${Constants.sourceCodeUrl}/issues'),
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('问题反馈'),
                  trailing: Icon(Icons.arrow_forward, size: 16, color: outline),
                ),
                ListTile(
                  onTap: () => Get.toNamed('/logs'),
                  onLongPress: LoggerUtils.clearLogs,
                  onSecondaryTap: PlatformUtils.isMobile
                      ? null
                      : LoggerUtils.clearLogs,
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('错误日志'),
                  subtitle: Text('长按清除日志', style: subTitleStyle),
                  trailing: Icon(Icons.arrow_forward, size: 16, color: outline),
                ),
              ],
            ),
            _buildGlassSection(
              isDark: isDark,
              children: [
                ListTile(
                  onTap: () {
                    if (cacheSize.value.isNotEmpty) {
                      showConfirmDialog(
                        context: context,
                        title: const Text('提示'),
                        content: const Text('该操作将清除图片及网络请求缓存数据，确认清除？'),
                        onConfirm: () async {
                          SmartDialog.showLoading(msg: '正在清除...');
                          try {
                            await CacheManager.clearLibraryCache();
                            SmartDialog.showToast('清除成功');
                          } catch (err) {
                            SmartDialog.showToast(err.toString());
                          } finally {
                            SmartDialog.dismiss();
                          }
                          getCacheSize();
                        },
                      );
                    }
                  },
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('清除缓存'),
                  subtitle: Obx(
                    () => Text(
                      '图片及网络缓存 ${cacheSize.value}',
                      style: subTitleStyle,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('导入/导出登录信息'),
                  leading: const Icon(Icons.import_export_outlined),
                  onTap: () => showImportExportDialog<Map<String, dynamic>>(
                    context,
                    title: '登录信息',
                    localFileName: () => 'account',
                    onExport: () =>
                        Utils.jsonEncoder.convert(Accounts.account.toMap()),
                    onImport: Accounts.importJsonAccount,
                  ),
                ),
                ListTile(
                  title: const Text('导入/导出设置'),
                  dense: false,
                  leading: const Icon(Icons.import_export_outlined),
                  onTap: () => showImportExportDialog<Map<String, dynamic>>(
                    context,
                    title: '设置',
                    localFileName: () => 'setting_${DeviceUtils.platformName}',
                    onExport: GStorage.exportAllSettings,
                    onImport: GStorage.importAllJsonSettings,
                  ),
                ),
                ListTile(
                  title: const Text('导入/导出所有数据'),
                  dense: false,
                  leading: const Icon(Icons.archive_outlined),
                  onTap: () => showDataImportExportDialog(context),
                ),
                ListTile(
                  title: const Text('重置所有设置'),
                  leading: const Icon(Icons.settings_backup_restore_outlined),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) {
                      return _buildGlassDialog(
                        context,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 18, 10, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  10,
                                ),
                                child: Text(
                                  '是否重置所有设置？',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DialogOption(
                                onPressed: () async {
                                  Get.back();
                                  await Future.wait([
                                    GStorage.setting.clear(),
                                    GStorage.video.clear(),
                                  ]);
                                  SmartDialog.showToast('重置成功');
                                },
                                child: const Text('重置可导出的设置', style: style),
                              ),
                              DialogOption(
                                onPressed: () async {
                                  Get.back();
                                  await GStorage.clear();
                                  SmartDialog.showToast('重置成功');
                                },
                                child: const Text(
                                  '重置所有数据（含登录信息）',
                                  style: style,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }}
