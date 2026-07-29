// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/SplashViewModel.dart';

class SplashView extends GetWidget<SplashViewModel> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final isShort = size.height < 720;

            return SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    top: size.height * 0.36,
                    child: const CustomPaint(
                      painter: _SplashBackgroundPainter(),
                    ),
                  ),
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          SizedBox(height: isShort ? 38 : 72),
                          SvgPicture.asset(
                            'assets/icon/icon_logo.svg',
                            width: (size.width * 0.36).clamp(140.0, 170.0),
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Hệ thống Báo cáo và\nXử lý sự cố',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h2.copyWith(
                              color: const Color(0xFF29306F),
                              fontSize: size.width < 380 ? 25 : 28,
                              fontWeight: FontWeight.w800,
                              height: 1.22,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: size.height * 0.43,
                    child: _SplashIllustration(size: size),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplashIllustration extends StatefulWidget {
  const _SplashIllustration({required this.size});

  final Size size;

  @override
  State<_SplashIllustration> createState() => _SplashIllustrationState();
}

class _SplashIllustrationState extends State<_SplashIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final Animation<double> _orbitAnimation;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _orbitAnimation = _orbitController;

    _orbitController.repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artWidth = (widget.size.width * 0.64).clamp(245.0, 330.0);
    final ballSize = (widget.size.width * 0.105).clamp(38.0, 52.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final orbitCenter = Offset(
          widget.size.width * 0.50,
          widget.size.height * 0.36 +
              widget.size.height * 0.64 * 0.55 -
              widget.size.height * 0.43,
        );
        final orbitRadius = widget.size.width * 0.43;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: constraints.maxHeight * 0.23,
              child: Image.asset(
                'assets/image/image_splash.png',
                width: artWidth,
                fit: BoxFit.contain,
              ),
            ),
            _OrbitingBallIcons(
              animation: _orbitAnimation,
              center: orbitCenter,
              radius: orbitRadius,
              iconSize: ballSize,
            ),
          ],
        );
      },
    );
  }
}

class _OrbitingBallIcons extends StatelessWidget {
  const _OrbitingBallIcons({
    required this.animation,
    required this.center,
    required this.radius,
    required this.iconSize,
  });

  static const List<_OrbitBallConfig> _configs = [
    _OrbitBallConfig(
      asset: 'assets/icon/icon_ball_call.png',
      endAngle: -math.pi * 0.50,
      speed: 1.00,
    ),
    _OrbitBallConfig(
      asset: 'assets/icon/icon_ball_warning.png',
      endAngle: math.pi * 0.08,
      speed: 0.82,
    ),
    _OrbitBallConfig(
      asset: 'assets/icon/icon_ball_group.png',
      endAngle: math.pi * 0.78,
      speed: 1.18,
    ),
    _OrbitBallConfig(
      asset: 'assets/icon/icon_ball_hat.png',
      endAngle: math.pi * 1.28,
      speed: 0.92,
    ),
    _OrbitBallConfig(
      asset: 'assets/icon/icon_ball_fire.png',
      endAngle: math.pi * 1.70,
      speed: 1.08,
    ),
  ];

  final Animation<double> animation;
  final Offset center;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value * math.pi * 2;

        return Stack(
          children: [
            for (final config in _configs)
              _OrbitingBallIcon(
                asset: config.asset,
                center: center,
                radius: radius,
                iconSize: iconSize,
                angle: config.endAngle + progress * config.speed,
              ),
          ],
        );
      },
    );
  }
}

class _OrbitBallConfig {
  const _OrbitBallConfig({
    required this.asset,
    required this.endAngle,
    required this.speed,
  });

  final String asset;
  final double endAngle;
  final double speed;
}

class _OrbitingBallIcon extends StatelessWidget {
  const _OrbitingBallIcon({
    required this.asset,
    required this.center,
    required this.radius,
    required this.iconSize,
    required this.angle,
  });

  final String asset;
  final Offset center;
  final double radius;
  final double iconSize;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final offset = Offset(
      center.dx + math.cos(angle) * radius - iconSize / 2,
      center.dy + math.sin(angle) * radius - iconSize / 2,
    );

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: iconSize,
      height: iconSize,
      child: Transform.rotate(
        angle: math.sin(angle) * 0.08,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF56558E), Color(0xFF242D6C)],
      ).createShader(Offset.zero & size);

    final wavePath = Path()
      ..moveTo(0, size.height * 0.13)
      ..quadraticBezierTo(
        size.width * 0.50,
        -size.height * 0.05,
        size.width,
        size.height * 0.13,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(wavePath, backgroundPaint);

    final center = Offset(size.width * 0.50, size.height * 0.55);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.055);

    for (final radius in <double>[
      size.width * 0.34,
      size.width * 0.43,
      size.width * 0.52,
      size.width * 0.70,
    ]) {
      canvas.drawCircle(
        center,
        radius,
        ringPaint
          ..strokeWidth = radius == size.width * 0.43 ? 1.35 : 1.1
          ..color = Colors.white.withValues(
            alpha: radius == size.width * 0.43 ? 0.09 : 0.055,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) => false;
}
