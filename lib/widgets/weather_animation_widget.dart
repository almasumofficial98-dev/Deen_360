import 'dart:math';
import 'package:flutter/material.dart';

class WeatherAnimationWidget extends StatefulWidget {
  final int weatherCode;
  final Color tintColor;
  final Widget child;

  const WeatherAnimationWidget({
    super.key,
    required this.weatherCode,
    required this.tintColor,
    required this.child,
  });

  @override
  State<WeatherAnimationWidget> createState() => _WeatherAnimationWidgetState();
}

class _WeatherAnimationWidgetState extends State<WeatherAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _driftController;
  late AnimationController _rainController;

  @override
  void initState() {
    super.initState();
    // Soft sun glow pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // Slow, subtle cloud drift
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();

    // Gentle rain / snow fall rate
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _driftController.dispose();
    _rainController.dispose();
    super.dispose();
  }

  bool get _isSunny => widget.weatherCode == 0;
  bool get _isCloudy => widget.weatherCode >= 1 && widget.weatherCode <= 3;
  bool get _isFog => widget.weatherCode >= 45 && widget.weatherCode <= 48;
  bool get _isRain =>
      (widget.weatherCode >= 51 && widget.weatherCode <= 67) ||
      (widget.weatherCode >= 80 && widget.weatherCode <= 82);
  bool get _isSnow =>
      (widget.weatherCode >= 71 && widget.weatherCode <= 77) ||
      (widget.weatherCode >= 85 && widget.weatherCode <= 86);
  bool get _isThunder => widget.weatherCode >= 95;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          // 1. Main Base Content (Gradient Card & Text)
          widget.child,

          // 2. Minimal Weather Overlay Layer
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  // Subtle Ambient Sun Glow
                  if (_isSunny || _isCloudy)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.08);
                        final opacity = 0.08 + (_pulseController.value * 0.07);
                        return Positioned(
                          top: -20,
                          right: -15,
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.amber.withValues(alpha: opacity),
                                    Colors.orangeAccent.withValues(alpha: opacity * 0.3),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.2, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Minimal Moving Clouds Effect
                  if (_isCloudy || _isSunny || _isThunder || _isRain || _isFog)
                    AnimatedBuilder(
                      animation: _driftController,
                      builder: (context, child) {
                        final progress = _driftController.value;
                        return Stack(
                          children: [
                            // Cloud 1 - Slow Top Drift
                            Positioned(
                              top: 15,
                              left: -80 + (progress * 440),
                              child: Opacity(
                                opacity: 0.10,
                                child: Icon(
                                  Icons.cloud_rounded,
                                  size: 70,
                                  color: widget.tintColor,
                                ),
                              ),
                            ),
                            // Cloud 2 - Very Soft Secondary Drift
                            Positioned(
                              top: 40,
                              left: 260 - (progress * 380),
                              child: Opacity(
                                opacity: 0.07,
                                child: Icon(
                                  Icons.cloud_queue_rounded,
                                  size: 55,
                                  color: widget.tintColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // Minimal Falling Rain Effect
                  if (_isRain || _isThunder)
                    AnimatedBuilder(
                      animation: _rainController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: _RainPainter(
                            progress: _rainController.value,
                            color: widget.tintColor.withValues(alpha: 0.18),
                          ),
                        );
                      },
                    ),

                  // Minimal Falling Snow Effect
                  if (_isSnow)
                    AnimatedBuilder(
                      animation: _rainController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: _SnowPainter(
                            progress: _rainController.value,
                            color: widget.tintColor.withValues(alpha: 0.20),
                          ),
                        );
                      },
                    ),

                  // Subtle Lightning Flash Effect
                  if (_isThunder)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final isLightning = (_pulseController.value > 0.92);
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: isLightning ? 0.12 : 0.0,
                          child: Container(
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;
  final Color color;
  static final List<Point<double>> _drops = List.generate(
    14,
    (i) => Point(
      Random(i).nextDouble(),
      Random(i + 50).nextDouble(),
    ),
  );

  _RainPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _drops.length; i++) {
      final drop = _drops[i];
      final startX = drop.x * size.width;
      final startY = ((drop.y + progress) % 1.0) * size.height;
      final endX = startX - 2;
      final endY = startY + 10;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SnowPainter extends CustomPainter {
  final double progress;
  final Color color;
  static final List<Point<double>> _flakes = List.generate(
    12,
    (i) => Point(
      Random(i).nextDouble(),
      Random(i + 20).nextDouble(),
    ),
  );

  _SnowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (int i = 0; i < _flakes.length; i++) {
      final flake = _flakes[i];
      final sway = sin((progress + flake.x) * 2 * pi) * 4;
      final startX = (flake.x * size.width) + sway;
      final startY = ((flake.y + progress) % 1.0) * size.height;
      final radius = 1.2 + (i % 2);

      canvas.drawCircle(Offset(startX, startY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
