import 'package:flutter/material.dart';
import 'package:walleta/theme/app_colors.dart';

class VoiceListeningIndicator extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const VoiceListeningIndicator({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<VoiceListeningIndicator> createState() =>
      _VoiceListeningIndicatorState();
}

class _VoiceListeningIndicatorState extends State<VoiceListeningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isListening) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant VoiceListeningIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const double micSize = 80;

    return SizedBox(
      width: micSize * 2,
      height: micSize * 2,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              AnimatedBuilder(
                animation: _controller,
                child: const SizedBox(),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: micSize,
                        height: micSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.primary, width: 2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: micSize,
                height: micSize,
                decoration: BoxDecoration(
                  gradient: AppColors.tealGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: colors.solidBlack,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
