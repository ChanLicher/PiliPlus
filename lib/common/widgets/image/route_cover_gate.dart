import 'package:flutter/widgets.dart';

/// 保留路由封面缓存：不再在页面被顶层路由覆盖时卸载封面并清空全局 ImageCache，
/// 避免从视频页返回主页时封面短暂闪灰消失或重新解码淡入。
/// 内存回收交由 Flutter 默认的 ImageCache LRU 上限自动管理。
class RouteCoverGate extends StatelessWidget {
  const RouteCoverGate({
    super.key,
    required this.child,
    required this.placeholder,
  });

  final Widget child;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) => child;
}
