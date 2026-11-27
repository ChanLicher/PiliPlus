import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/radio_widget.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

typedef ReasonCheck = bool Function(int? reasonType);

bool _kReportCheck(int? reasonType) => reasonType == 0;

typedef OnReport = Future<LoadingState> Function(
  int reasonType,
  String? reasonDesc,
  bool banUid,
);

Future<void> autoWrapReportDialog(
  BuildContext context,
  Map<String, Map<int, String>> options,
  OnReport onReport, {
  ValueGetter<int>? mid,
  VoidCallback? onRemove,
  String? reportUrl,
  ReasonCheck withContent = _kReportCheck,
  ReasonCheck contentRequired = _kReportCheck,
}) {
  int? reasonType;
  String? reasonDesc;
  bool banUid = false;
  late final key = GlobalKey<FormFieldState<String>>();

  bool isWithContent = withContent(reasonType);
  bool isContentRequired = contentRequired(reasonType);

  void updateReasonType(int? value) {
    reasonType = value;
    isWithContent = withContent(reasonType);
    isContentRequired = contentRequired(reasonType);
    if (isWithContent) {
      key.currentState?.validate();
    }
  }

  Widget title = const Text('举报');
  if (reportUrl != null) {
    title = Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        title,
        iconButton(
          iconSize: 21,
          tooltip: '网页举报',
          onPressed: () =>
              Get.toNamed('/webview', parameters: {'url': reportUrl}),
          icon: const Icon(MdiIcons.web, size: 22),
        ),
      ],
    );
  }

  return showDialog(
    context: context,
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
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 16, 8),
                        child: DefaultTextStyle.merge(
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          child: title,
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: Builder(
                              builder: (context) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: .only(
                                      left: 22,
                                      right: 22,
                                      bottom: 5,
                                    ),
                                    child: Text('请选择举报的理由：'),
                                  ),
                                  RadioGroup(
                                    onChanged: (value) {
                                      updateReasonType(value);
                                      (context as Element).markNeedsBuild();
                                    },
                                    groupValue: reasonType,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: options.entries.map((entry) {
                                        return WrapRadioOptionsGroup<int>(
                                          groupTitle: entry.key,
                                          options: entry.value,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  if (isWithContent)
                                    Padding(
                                      padding: const .only(
                                        left: 22,
                                        top: 6,
                                        right: 22,
                                        bottom: 4,
                                      ),
                                      child: TextFormField(
                                        key: key,
                                        minLines: 2,
                                        maxLines: 4,
                                        initialValue: reasonDesc,
                                        autofocus: isContentRequired,
                                        decoration: InputDecoration(
                                          labelText:
                                              '为帮助审核人员更快处理，请补充问题类型和出现位置等详细信息',
                                          filled: true,
                                          fillColor: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.03,
                                                ),
                                          border: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          contentPadding: const .all(10),
                                          labelStyle: const TextStyle(
                                            fontSize: 14,
                                          ),
                                          floatingLabelStyle: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        onChanged: (value) =>
                                            reasonDesc = value,
                                        validator: (value) =>
                                            isContentRequired &&
                                                value.isNullOrEmpty
                                            ? '理由不能为空'
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (mid != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 6),
                          child: CheckBoxText(
                            text: '拉黑该用户',
                            onChanged: (value) => banUid = value,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 8,
                          children: [
                            if (mid != null)
                              TextButton(
                                style: subtleBtnStyle,
                                onPressed: () {
                                  Get.back();
                                  Pref.setBlackMid(mid());
                                  onRemove?.call();
                                },
                                child: const Text('本地屏蔽'),
                              ),
                            TextButton(
                              style: subtleBtnStyle,
                              onPressed: Get.back,
                              child: Text(
                                '取消',
                                style: TextStyle(color: colorScheme.outline),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                backgroundColor: colorScheme.primary.withValues(
                                  alpha: isDark ? 0.22 : 0.12,
                                ),
                              ),
                              onPressed: () async {
                                if (reasonType == null ||
                                    (isContentRequired &&
                                        key.currentState?.validate() != true)) {
                                  return;
                                }
                                SmartDialog.showLoading();
                                try {
                                  final res = await onReport(
                                    reasonType!,
                                    isWithContent ? reasonDesc : null,
                                    banUid,
                                  );
                                  SmartDialog.dismiss();
                                  if (res.isSuccess) {
                                    Get.back();
                                    SmartDialog.showToast('举报成功');
                                  } else {
                                    res.toast();
                                  }
                                } catch (e, s) {
                                  SmartDialog.dismiss();
                                  SmartDialog.showToast('提交失败：$e');
                                  Utils.reportError(e, s);
                                }
                              },
                              child: Text(
                                '确定',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
    },
  );
}

class CheckBoxText extends StatefulWidget {
  final String text;
  final ValueChanged<bool> onChanged;
  final bool selected;

  const CheckBoxText({
    super.key,
    required this.text,
    required this.onChanged,
    this.selected = false,
  });

  @override
  State<CheckBoxText> createState() => _CheckBoxTextState();
}

class _CheckBoxTextState extends State<CheckBoxText> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      onTap: () {
        setState(() {
          _selected = !_selected;
          widget.onChanged(_selected);
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              size: 22,
              _selected
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              color: _selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            Text(
              ' ${widget.text}',
              style: TextStyle(color: _selected ? colorScheme.primary : null),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class ReportOptions {
  // from https://s1.hdslb.com/bfs/seed/jinkela/comment-h5/static/js/605.chunks.js
  static Map<String, Map<int, String>> get commentReport => const {
    '违反法律法规': {9: '违法违规', 2: '色情', 10: '低俗', 12: '赌博诈骗', 23: '违法信息外链'},
    '谣言类不实信息': {19: '涉政谣言', 22: '虚假不实信息*', 20: '涉社会事件谣言'},
    '侵犯个人权益': {7: '人身攻击', 15: '侵犯隐私'},
    '有害社区环境': {
      1: '垃圾广告',
      4: '引战',
      5: '剧透',
      3: '刷屏',
      8: '视频不相关',
      18: '违规抽奖',
      17: '青少年不良信息',
    },
    '其他': {0: '其他*'},
  };
  static bool withContentReply(int? reasonType) => reasonType != null;
  static bool contentRequiredReply(int? reasonType) =>
      reasonType == 0 || reasonType == 22;

  static Map<String, Map<int, String>> get dynamicReport => const {
    '': {
      4: '垃圾广告',
      8: '引战',
      1: '色情',
      5: '人身攻击',
      3: '违法信息',
      9: '涉政谣言',
      10: '涉社会事件谣言',
      12: '虚假不实信息',
      13: '违法信息外链',
      0: '其他*',
    },
  };

  static Map<String, Map<int, String>> get danmakuReport => const {
    '': {
      1: '违法违禁',
      2: '色情低俗',
      3: '赌博诈骗',
      4: '人身攻击',
      5: '侵犯隐私',
      6: '垃圾广告',
      7: '引战',
      8: '剧透',
      9: '恶意刷屏',
      10: '视频无关',
      12: '青少年不良信息',
      13: '违法信息外链',
      11: '其它*',
    },
  };
  static bool danmakuReportCheck(int? reasonType) => reasonType == 11;

  static Map<String, Map<int, String>> get liveDanmakuReport => const {
    '': {
      1: '违法违规',
      2: '低俗色情',
      3: '垃圾广告',
      4: '辱骂引战',
      5: '政治敏感',
      6: '青少年不良信息',
      0: '其他',
    },
  };
  static bool liveDanmakuReportCheck(int? _) => false;

  static Map<String, Map<int, String>> get imMsgReport => const {
    '': {
      1: '色情低俗',
      2: '政治敏感',
      3: '违法有害',
      4: '广告骚扰',
      5: '人身攻击',
      6: '诈骗',
      0: '其他问题*',
    },
  };
}
