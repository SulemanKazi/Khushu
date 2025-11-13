import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedProgressRing extends StatefulWidget {
  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.size,
    this.assetPath = 'resources/timer_ring.png',
    this.animationDuration = const Duration(milliseconds: 450),
    this.desaturatedOpacity = 0.35,
    this.isActive = false,
    this.isCompleted = false,
  });

  final double progress; // 0.0 - 1.0
  final double size;
  final String assetPath;
  final Duration animationDuration;
  final double desaturatedOpacity;
  final bool isActive;
  final bool isCompleted;

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing> {
  double _previousProgress = 0;
  late ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    assert(
      widget.desaturatedOpacity >= 0 && widget.desaturatedOpacity <= 1,
      'desaturatedOpacity must be between 0 and 1.',
    );
    _imageProvider = AssetImage(widget.assetPath);
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
    }
    if (oldWidget.assetPath != widget.assetPath) {
      _imageProvider = AssetImage(widget.assetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previousProgress, end: clampedProgress),
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final progress = value.clamp(0.0, 1.0);
        final isCompleted = widget.isCompleted || progress >= 1.0;
  final isIdle = !widget.isActive && !isCompleted;

        if (progress >= 0.999) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: _buildRingImage(),
          );
        }
        if (isIdle && progress <= 0) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Opacity(
              opacity: widget.desaturatedOpacity,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_saturationMatrix(0)),
                child: _buildRingImage(),
              ),
            ),
          );
        }
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Base ring stays desaturated until the overlay paints color on top.
              Opacity(
                opacity: widget.desaturatedOpacity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(_saturationMatrix(0)),
                  child: _buildRingImage(),
                ),
              ),
              if (progress > 0)
                ClipPath(
                  clipper: _RingArcClipper(progress),
                  child: _buildRingImage(),
                ),
            ],
          ),
        );
      },
    );
  }

  List<double> _saturationMatrix(double saturation) {
    final invSat = 1 - saturation;
    const rLum = 0.2126;
    const gLum = 0.7152;
    const bLum = 0.0722;

    final r = invSat * rLum;
    final g = invSat * gLum;
    final b = invSat * bLum;

    return <double>[
      r + saturation,
      g,
      b,
      0,
      0,
      r,
      g + saturation,
      b,
      0,
      0,
      r,
      g,
      b + saturation,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  Widget _buildRingImage() {
    return Image(
      image: _imageProvider,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}

class _RingArcClipper extends CustomClipper<Path> {
  const _RingArcClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    if (progress <= 0) {
      return Path();
    }

    final rect = Offset.zero & size;
    final startAngle = -math.pi / 2;
    final sweepAngle = (math.pi * 2) * progress;

    final path = Path()
      ..moveTo(rect.center.dx, rect.center.dy)
      ..arcTo(rect, startAngle, sweepAngle, false)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _RingArcClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
