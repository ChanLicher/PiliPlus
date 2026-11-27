import 'package:material_ui/material_ui.dart';

/// 轻量卡片入场过渡动画（鸿蒙重减速曲线淡入 + 微缩放弹出），
/// 配合 RepaintBoundary 隔离绘制层，供全站各类视频/直播/番剧/专栏卡片复用。
class CardEnterMotion extends StatefulWidget {
  const CardEnterMotion({
    super.key,
    required this.child,
    this.itemKey,
    this.beginScale = 0.96,
    this.duration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final Object? itemKey;
  final double beginScale;
  final Duration duration;

  @override
  State<CardEnterMotion> createState() => _CardEnterMotionState();
}

class _CardEnterMotionState extends State<CardEnterMotion>
    with SingleTickerProviderStateMixin {
  static const Cubic _enterCurve = Cubic(0.2, 0, 0, 1);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: _enterCurve,
    );
    _fade = curved;
    _scale = Tween<double>(begin: widget.beginScale, end: 1.0).animate(curved);
    _controller.forward();
  }

  @override
  void didUpdateWidget(CardEnterMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemKey != null && widget.itemKey != oldWidget.itemKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
