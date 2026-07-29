// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateSOSViewModel.dart';

class CreateSOSView extends GetWidget<CreateSOSViewModel> {
  const CreateSOSView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF8202D);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.state.value == CreateSOSState.sent) {
        return _SentSOSView(controller: controller);
      }

      return _CreateSOSContent(controller: controller);
    });
  }
}

class _CreateSOSContent extends StatelessWidget {
  const _CreateSOSContent({required this.controller});

  final CreateSOSViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CreateSOSView._primaryColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF29306F), Color(0xFF222963), Color(0xFF1C2358)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'sos.title'.tr,
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontSize: AppFontSizes.xl,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(flex: 2),
                Center(
                  child: Obx(
                    () => _HoldSOSButton(
                      progress: controller.holdProgress.value,
                      isHolding:
                          controller.state.value == CreateSOSState.holding,
                      isSubmitting: controller.isSubmitting.value,
                      onPointerDown: controller.startHolding,
                      onPointerUp: controller.cancelHolding,
                    ),
                  ),
                ),
                const SizedBox(height: 42),
                Center(
                  child: Obx(() {
                    final isHolding =
                        controller.state.value == CreateSOSState.holding;

                    return Column(
                      children: [
                        Text(
                          isHolding
                              ? 'sos.holdingTitle'.tr
                              : 'sos.holdTitle'.tr,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: Colors.white,
                            fontSize: AppFontSizes.base,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'sos.holdDescription'.trParams({
                            'seconds': controller.remainingSeconds.value
                                .toString(),
                          }),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: AppFontSizes.sm,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const Spacer(flex: 2),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      'sos.warning'.tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: AppFontSizes.sm,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldSOSButton extends StatefulWidget {
  const _HoldSOSButton({
    required this.progress,
    required this.isHolding,
    required this.isSubmitting,
    required this.onPointerDown,
    required this.onPointerUp,
  });

  final double progress;
  final bool isHolding;
  final bool isSubmitting;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;

  @override
  State<_HoldSOSButton> createState() => _HoldSOSButtonState();
}

class _HoldSOSButtonState extends State<_HoldSOSButton>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _holdWaveController;

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _holdWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didUpdateWidget(covariant _HoldSOSButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isHolding && !oldWidget.isHolding) {
      _holdWaveController.repeat();
    }

    if (!widget.isHolding && oldWidget.isHolding) {
      _holdWaveController.stop();
      _holdWaveController.reset();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _holdWaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.onPointerDown(),
      onPointerUp: (_) => widget.onPointerUp(),
      onPointerCancel: (_) => widget.onPointerUp(),
      child: AnimatedScale(
        scale: widget.isHolding ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 280,
          height: 280,
          child: AnimatedBuilder(
            animation: Listenable.merge([_idleController, _holdWaveController]),
            builder: (context, child) {
              final idle = _idleController.value;
              final delayedIdle = (idle + 0.5) % 1.0;

              final wave = _holdWaveController.value;
              final delayedWave = (wave + 0.46) % 1.0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  if (!widget.isHolding) ...[
                    _SoftWaveRing(
                      size: 154 + delayedIdle * 76,
                      color: Colors.white,
                      opacity: 0.18 * (1 - delayedIdle),
                      strokeWidth: 1.3,
                    ),
                  ],
                  if (widget.isHolding) ...[
                    _SoftWaveRing(
                      size: 154 + wave * 142,
                      color: CreateSOSView._dangerColor,
                      opacity: 0.36 * (1 - wave),
                      strokeWidth: 2.2,
                    ),
                    _SoftWaveRing(
                      size: 154 + delayedWave * 142,
                      color: CreateSOSView._dangerColor,
                      opacity: 0.24 * (1 - delayedWave),
                      strokeWidth: 1.8,
                    ),
                  ],
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: widget.progress),
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, _) {
                      return SizedBox(
                        width: 154,
                        height: 154,
                        child: CustomPaint(
                          painter: _SOSProgressPainter(
                            progress: animatedProgress,
                            showProgress:
                                widget.isHolding || animatedProgress > 0,
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: widget.isHolding ? 112 : 104,
                    height: widget.isHolding ? 112 : 104,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFF4652),
                          Color(0xFFF8202D),
                          Color(0xFFD91422),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CreateSOSView._dangerColor.withValues(
                            alpha: widget.isHolding ? 0.48 : 0.32,
                          ),
                          blurRadius: widget.isHolding ? 36 : 26,
                          spreadRadius: widget.isHolding ? 2 : 0,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: widget.isSubmitting
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            'SOS',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SoftWaveRing extends StatelessWidget {
  const _SoftWaveRing({
    required this.size,
    required this.color,
    required this.opacity,
    required this.strokeWidth,
  });

  final double size;
  final Color color;
  final double opacity;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          width: strokeWidth,
        ),
      ),
    );
  }
}

class _SOSProgressPainter extends CustomPainter {
  const _SOSProgressPainter({
    required this.progress,
    required this.showProgress,
  });

  final double progress;
  final bool showProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = Colors.white.withValues(alpha: showProgress ? 0.12 : 0.28);

    canvas.drawArc(rect, 0, math.pi * 2, false, basePaint);

    if (!showProgress) return;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = CreateSOSView._dangerColor.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6A73), Color(0xFFFF3A46), Color(0xFFF8202D)],
      ).createShader(rect);

    final sweep = math.pi * 2 * progress;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _SOSProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showProgress != showProgress;
  }
}

class _SentSOSView extends StatelessWidget {
  const _SentSOSView({required this.controller});

  final CreateSOSViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 106),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                const Center(child: _SentIcon()),
                const SizedBox(height: 44),
                Text(
                  'sos.sentTitle'.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    color: CreateSOSView._dangerColor,
                    fontSize: AppFontSizes.h3,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      'sos.sentDescription'.tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: const Color(0xFF8D93A3),
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w700,
                        height: 1.34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 66),
                Center(
                  child: SizedBox(
                    width: 174,
                    height: 46,
                    child: Obx(
                      () => OutlinedButton(
                        onPressed: controller.isCancelling.value
                            ? null
                            : controller.cancelSentSOS,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CreateSOSView._primaryColor,
                          side: const BorderSide(
                            color: CreateSOSView._primaryColor,
                            width: 1.15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: AppTextStyles.bodyStrong.copyWith(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: controller.isCancelling.value
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.1,
                                ),
                              )
                            : Text('sos.cancel'.tr),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SentIcon extends StatelessWidget {
  const _SentIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final item in const <({double size, double opacity})>[
            (size: 254, opacity: 0.045),
            (size: 216, opacity: 0.065),
            (size: 176, opacity: 0.095),
            (size: 136, opacity: 0.12),
          ])
            Container(
              width: item.size,
              height: item.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CreateSOSView._primaryColor.withValues(
                    alpha: item.opacity,
                  ),
                  width: 1.1,
                ),
              ),
            ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF6F6), Color(0xFFFFECEE)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CreateSOSView._dangerColor.withValues(alpha: 0.16),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/image/icon_sos_done.png',
            width: 92,
            height: 92,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
