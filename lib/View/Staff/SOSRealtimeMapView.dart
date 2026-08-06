// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Component/InteractiveTileMap.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSRealtimeMapViewModel.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSRealtimeMapView extends GetWidget<SOSRealtimeMapViewModel> {
  const SOSRealtimeMapView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _textColor = Color(0xFF222532);
  static const Color _mutedColor = Color(0xFF858996);
  static const Color _borderColor = Color(0xFFE2E4F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final item = controller.sos.value;
          final latitude = item?.latitude;
          final longitude = item?.longitude;
          final hasCoordinates = latitude != null && longitude != null;

          return Column(
            children: [
              _Header(isActive: controller.isActive.value),
              Expanded(
                child: controller.isLoading.value && item == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: hasCoordinates
                                ? InteractiveTileMap(
                                    latitude: latitude,
                                    longitude: longitude,
                                    height: MediaQuery.of(context).size.height,
                                    primaryColor: _primaryColor,
                                    dangerColor: _dangerColor,
                                    borderColor: _borderColor,
                                    initialZoom: 17,
                                    markerBuilder: (position) =>
                                        _PulseMarker(position: position),
                                    onDirections: () =>
                                        _openDirections(latitude, longitude),
                                  )
                                : Container(
                                    color: const Color(0xFFEFF2F6),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Chưa có tọa độ SOS để theo dõi.',
                                      style: AppTextStyles.bodyStrong.copyWith(
                                        color: _mutedColor,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 88,
                            child: _BottomInfoCard(controller: controller),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: SOSRealtimeMapView._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'Theo dõi vị trí SOS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: SOSRealtimeMapView._textColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isActive
                      ? SOSRealtimeMapView._dangerColor
                      : SOSRealtimeMapView._mutedColor)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isActive ? 'Đang theo dõi' : 'Đã dừng',
              style: AppTextStyles.caption.copyWith(
                color: isActive
                    ? SOSRealtimeMapView._dangerColor
                    : SOSRealtimeMapView._mutedColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  const _BottomInfoCard({required this.controller});

  final SOSRealtimeMapViewModel controller;

  @override
  Widget build(BuildContext context) {
    final item = controller.sos.value;
    final errorMessage = controller.errorMessage.value;
    final code = item?.code;
    final studentName = item?.student?.name;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SOSRealtimeMapView._dangerColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: SOSRealtimeMapView._dangerColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        code == null || code.trim().isEmpty
                            ? 'SOS #${item?.id ?? '--'}'
                            : code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: SOSRealtimeMapView._textColor,
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(isActive: controller.isActive.value),
                  ],
                ),
                if (studentName != null && studentName.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: SOSRealtimeMapView._textColor.withOpacity(0.82),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(
                    isActive: controller.isActive.value,
                    lastUpdatedAt: controller.lastUpdatedAt.value,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: errorMessage != null &&
                            errorMessage.trim().isNotEmpty
                        ? SOSRealtimeMapView._dangerColor
                        : SOSRealtimeMapView._mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RefreshButton(onPressed: controller.refresh),
        ],
      ),
    );
  }

  String _buildSubtitle({
    required bool isActive,
    required DateTime? lastUpdatedAt,
  }) {
    final timestamp = _formatDateTime(lastUpdatedAt);
    if (isActive) {
      return 'Cập nhật $timestamp';
    }
    return 'Đã dừng theo dõi · $timestamp';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Chưa có dữ liệu';
    }
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$hour:$minute:$second - $day/$month/${value.year}';
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F6FD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(11),
          child: Icon(
            Icons.refresh_rounded,
            size: 18,
            color: SOSRealtimeMapView._primaryColor,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? SOSRealtimeMapView._dangerColor
        : SOSRealtimeMapView._mutedColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Live' : 'Dừng',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: AppFontSizes.xs,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PulseMarker extends StatefulWidget {
  const _PulseMarker({required this.position});

  final Offset position;

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = Curves.easeOut.transform(_controller.value);
        final pulseScale = 0.8 + (t * 1.8);
        final pulseOpacity = (1 - t) * 0.22;

        return Positioned(
          left: widget.position.dx - 28,
          top: widget.position.dy - 28,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 24 * pulseScale,
                  height: 24 * pulseScale,
                  decoration: BoxDecoration(
                    color: SOSRealtimeMapView._dangerColor.withOpacity(
                      pulseOpacity,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: SOSRealtimeMapView._dangerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openDirections(double latitude, double longitude) async {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
    'travelmode': 'driving',
  });
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
