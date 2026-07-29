// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/StaffPerformanceEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';

class StaffPerformanceView extends StatelessWidget {
  const StaffPerformanceView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _successColor = Color(0xFF21B85C);
  static const Color _warningColor = Color(0xFFFFA31A);
  static const Color _infoColor = Color(0xFF4E8BFF);
  static const Color _textColor = Color(0xFF242733);
  static const Color _mutedColor = Color(0xFF858996);
  static const Color _pageColor = Color(0xFFF8F9FD);
  static const Color _borderColor = Color(0xFFE2E4F0);

  @override
  Widget build(BuildContext context) {
    final performance = _readPerformance();
    final now = DateTime.now();
    final monthLabel = '${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hiệu suất tháng',
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: _textColor,
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _MonthChip(monthLabel: monthLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _OverviewCard(performance: performance),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: _MetricTile(
                              value: performance.completed.toString(),
                              label: 'Sự cố đã hoàn thành',
                              icon: Icons.check_circle_outline_rounded,
                              color: _successColor,
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: _MetricTile(
                              value: _processingCount(performance).toString(),
                              label: 'Đang xử lý',
                              icon: Icons.timelapse_rounded,
                              color: const Color(0xFF9A63FF),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: _MetricTile(
                              value: _formatHours(
                                performance.avgProcessingTimeHours,
                              ),
                              label: 'TB thời gian xử lý',
                              icon: Icons.schedule_rounded,
                              color: _infoColor,
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: _MetricTile(
                              value: _formatRating(performance.ratingAvg),
                              label: 'Đánh giá trung bình',
                              icon: Icons.star_border_rounded,
                              color: _warningColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  StaffPerformanceEntity _readPerformance() {
    final args = Get.arguments;
    if (args is StaffPerformanceEntity) {
      return args;
    }
    if (args is Map) {
      return StaffPerformanceEntity.fromJson(args);
    }
    return StaffPerformanceEntity.empty;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(6, 8, 18, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: StaffPerformanceView._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'Thống kê hiệu suất',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: StaffPerformanceView._textColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: StaffPerformanceView._borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: StaffPerformanceView._primaryColor,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            monthLabel,
            style: AppTextStyles.caption.copyWith(
              color: StaffPerformanceView._primaryColor,
              fontSize: AppFontSizes.sm,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.performance});

  final StaffPerformanceEntity performance;

  @override
  Widget build(BuildContext context) {
    final rate = performance.completionRate.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StaffPerformanceView._borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Center(child: _RateRing(rate: rate)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OverviewLine(
                  icon: Icons.verified_outlined,
                  title: 'Sự cố đã hoàn thành',
                  value: '${performance.completed}/${performance.totalAssigned}',
                  color: StaffPerformanceView._primaryColor,
                ),
                const SizedBox(height: 16),
                _OverviewLine(
                  icon: Icons.schedule_rounded,
                  title: 'Thời gian xử lý TB',
                  value: _formatHours(performance.avgProcessingTimeHours),
                  color: StaffPerformanceView._infoColor,
                ),
                const SizedBox(height: 16),
                _OverviewLine(
                  icon: Icons.star_border_rounded,
                  title: 'Đánh giá',
                  value: _formatRating(performance.ratingAvg),
                  color: StaffPerformanceView._warningColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateRing extends StatelessWidget {
  const _RateRing({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: CustomPaint(
        painter: _RateRingPainter(rate: rate),
        child: Center(
          child: Text(
            '${rate.round()}%',
            style: AppTextStyles.h3.copyWith(
              color: StaffPerformanceView._textColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _RateRingPainter extends CustomPainter {
  const _RateRingPainter({required this.rate});

  final double rate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE7F6ED);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..color = StaffPerformanceView._successColor;

    canvas.drawCircle(center, radius, basePaint);
    if (rate > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * (rate / 100),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RateRingPainter oldDelegate) {
    return oldDelegate.rate != rate;
  }
}

class _OverviewLine extends StatelessWidget {
  const _OverviewLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.24)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: StaffPerformanceView._mutedColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: StaffPerformanceView._textColor,
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StaffPerformanceView._borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    color: StaffPerformanceView._textColor,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: StaffPerformanceView._mutedColor,
              fontSize: AppFontSizes.xs,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

int _processingCount(StaffPerformanceEntity performance) {
  final processing = performance.totalAssigned - performance.completed;
  return processing < 0 ? 0 : processing;
}

String _formatHours(double hours) {
  if (hours <= 0) {
    return '0 phút';
  }
  if (hours < 1) {
    return '${(hours * 60).round()} phút';
  }
  final rounded = hours.round();
  return '$rounded giờ';
}

String _formatRating(double rating) {
  if (rating == rating.roundToDouble()) {
    return rating.toStringAsFixed(0);
  }
  return rating.toStringAsFixed(1);
}
