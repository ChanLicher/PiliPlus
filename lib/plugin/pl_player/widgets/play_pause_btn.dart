import 'dart:ui' show PointerDeviceKind;

import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:material_ui/material_ui.dart';

class PlayOrPauseButton extends StatefulWidget {
  final PlPlayerController plPlayerController;

  const PlayOrPauseButton({
    super.key,
    required this.plPlayerController,
  });

  @override
  PlayOrPauseButtonState createState() => PlayOrPauseButtonState();
}

class PlayOrPauseButtonState extends State<PlayOrPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      value: widget.plPlayerController.playerStatus.isPlaying ? 1 : 0,
      duration: const Duration(milliseconds: 200),
    );
    // 不要缓存 Player 实例：HDR / SDR 之间切换画质会整体重建播放器，缓存下来
    // 的 Player 连同它的 stream 一起失效，按钮就永久停在切换前的状态。
    // playerStatus 由 _startListeners 重新绑定到新播放器，因此这里改为订阅
    // controller 自己的状态回调（用回调而非 Obx：forward/reverse 是副作用，
    // 不应该写在 build 闭包里）。
    widget.plPlayerController.addStatusLister(_onStatusChanged);
  }

  void _onStatusChanged(PlayerStatus status) {
    if (status.isPlaying) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  void dispose() {
    widget.plPlayerController.removeStatusLister(_onStatusChanged);
    controller.dispose();
    _hovered.dispose();
    _pressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = MediaQuery.sizeOf(context).shortestSide >= 600;
    return SizedBox(
      width: isLarge ? 50 : 42,
      height: isLarge ? 42 : 34,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) {
          if (event.kind == PointerDeviceKind.mouse && !_hovered.value) {
            _hovered.value = true;
          }
        },
        onExit: (_) {
          if (_hovered.value) _hovered.value = false;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.plPlayerController.onDoubleTapCenter,
          onTapDown: (_) => _pressed.value = true,
          onTapUp: (_) => _pressed.value = false,
          onTapCancel: () => _pressed.value = false,
          child: ValueListenableBuilder<bool>(
            valueListenable: _hovered,
            builder: (context, hovered, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: _pressed,
                builder: (context, pressed, _) {
                  final scale = pressed ? 0.94 : (hovered ? 1.08 : 1.0);
                  return AnimatedScale(
                    scale: scale,
                    duration: const Duration(milliseconds: 130),
                    curve: const Cubic(0.2, 0, 0, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pressed
                            ? Colors.white.withValues(alpha: 0.24)
                            : hovered
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
              );
            },
            child: Center(
              child: AnimatedIcon(
                semanticLabel: widget.plPlayerController.playerStatus.isPlaying
                    ? '暂停'
                    : '播放',
                progress: controller,
                icon: AnimatedIcons.play_pause,
                color: Colors.white,
                size: isLarge ? 24 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
