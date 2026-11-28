import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

abstract final class Update {
  // 检查更新
  static Future<void> checkUpdate([bool isAuto = true]) async {
    // if (kDebugMode) return;
    // 获取到默认值，没有构建时间信息
    if (BuildConfig.buildTime == 0) {
      SmartDialog.showToast('未知Build Time，可前往源码仓库检查更新');
      return;
    }
    SmartDialog.dismiss();
    try {
      final reqOptions = Options(
        headers: {'user-agent': BrowserUa.mob},
        extra: {'account': const NoAccount()},
      );
      final res = await Request().get(
        Constants.latestReleaseApi,
        options: reqOptions,
      );
      if (res.data is Map || res.data.isEmpty) {
        if (!isAuto) {
          SmartDialog.showToast('检查更新失败，GitHub接口未返回数据，请检查网络');
        }
        return;
      }
      final data = res.data[0];
      final int latest =
          DateTime.parse(data['created_at']).millisecondsSinceEpoch ~/ 1000;
      final latestTag = data['tag_name'];
      String? latestHash;
      try {
        final refRes = await Request().get(
          '${Constants.tagRefApiPrefix}$latestTag',
          options: reqOptions,
        );
        if (refRes.data is Map) {
          latestHash = refRes.data['object']?['sha']?.toString();
        }
      } catch (_) {}
      if (BuildConfig.buildTime >= latest ||
          (latestHash != null && BuildConfig.commitHash == latestHash)) {
        if (!isAuto) {
          SmartDialog.showToast('已是最新版本');
        }
      } else {
        SmartDialog.show(
          animationType: SmartAnimationType.centerFade_otherSlide,
          builder: (context) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;
            const radius = BorderRadius.all(Radius.circular(22));
            final subtleBtnStyle = TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            );
            final primaryBtnStyle = TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              backgroundColor: colorScheme.primary.withValues(
                alpha: isDark ? 0.22 : 0.12,
              ),
            );
            Widget downloadBtn(String text, {String? ext}) => TextButton(
              style: primaryBtnStyle,
              onPressed: () => onDownload(data, ext: ext),
              child: Text(
                text,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.42 : 0.14,
                        ),
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
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎉 发现新版本',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 260,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${data['tag_name']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('${data['body']}'),
                                      const SizedBox(height: 6),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                          ),
                                        ),
                                        onPressed: () => PageUtils.launchURL(
                                          '${Constants.sourceCodeUrl}/commits/ohos', // 鸿蒙版ohos分支
                                        ),
                                        child: Text(
                                          "点此查看完整更新(即commit)内容",
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                spacing: 8,
                                children: [
                                  if (isAuto)
                                    TextButton(
                                      style: subtleBtnStyle,
                                      onPressed: () {
                                        SmartDialog.dismiss();
                                        GStorage.setting.put(
                                          SettingBoxKey.autoUpdate,
                                          false,
                                        );
                                      },
                                      child: Text(
                                        '不再提醒',
                                        style: TextStyle(
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                    ),
                                  TextButton(
                                    style: subtleBtnStyle,
                                    onPressed: SmartDialog.dismiss,
                                    child: Text(
                                      '取消',
                                      style: TextStyle(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                  if (Platform.isWindows) ...[
                                    downloadBtn('zip', ext: 'zip'),
                                    downloadBtn('exe', ext: 'exe'),
                                  ] else if (Platform.isLinux) ...[
                                    downloadBtn('rpm', ext: 'rpm'),
                                    downloadBtn('deb', ext: 'deb'),
                                    downloadBtn('targz', ext: 'tar.gz'),
                                  ] else
                                    downloadBtn('Github'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('failed to check update: $e');
    }
  }

  // 下载适用于当前系统的安装包
  static Future<void> onDownload(Map data, {String? ext}) async {
    SmartDialog.dismiss();
    try {
      void download(String plat) {
        if (data['assets'].isNotEmpty) {
          for (Map<String, dynamic> i in data['assets']) {
            final String name = i['name'];
            if (name.contains(plat) &&
                (ext == null || ext.isEmpty ? true : name.endsWith(ext))) {
              PageUtils.launchURL(i['browser_download_url']);
              return;
            }
          }
          throw UnsupportedError('platform not found: $plat');
        }
      }

      if (Platform.isAndroid) {
        // 获取设备信息
        AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
        // [arm64-v8a]
        download(androidInfo.supportedAbis.first);
      } else {
        download(Platform.operatingSystem);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('download error: $e');
      PageUtils.launchURL('${Constants.sourceCodeUrl}/releases/latest');
    }
  }
}
