// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';

class InteractiveTileMap extends StatefulWidget {
  const InteractiveTileMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.primaryColor,
    required this.dangerColor,
    required this.borderColor,
    this.height = 164,
    this.initialZoom = 16,
    this.minZoom = 12,
    this.maxZoom = 19,
    this.onDirections,
    this.markerBuilder,
  });

  final double latitude;
  final double longitude;
  final Color primaryColor;
  final Color dangerColor;
  final Color borderColor;
  final double height;
  final int initialZoom;
  final int minZoom;
  final int maxZoom;
  final VoidCallback? onDirections;
  final Widget Function(Offset position)? markerBuilder;

  @override
  State<InteractiveTileMap> createState() => _InteractiveTileMapState();
}

class _InteractiveTileMapState extends State<InteractiveTileMap> {
  static const double _tileSize = 256;

  late int _zoom;
  late Offset _centerPixel;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom.clamp(widget.minZoom, widget.maxZoom);
    _centerPixel = _latLngToWorldPixel(
      widget.latitude,
      widget.longitude,
      _zoom,
    );
  }

  @override
  void didUpdateWidget(covariant InteractiveTileMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.initialZoom != widget.initialZoom) {
      _zoom = widget.initialZoom.clamp(widget.minZoom, widget.maxZoom);
      _centerPixel = _latLngToWorldPixel(
        widget.latitude,
        widget.longitude,
        _zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _centerPixel -= details.delta;
                _centerPixel = _clampCenter(_centerPixel, _zoom);
              });
            },
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                border: Border.all(color: widget.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: constraints.maxWidth,
                    height: widget.height,
                    child: _buildTileGrid(width: constraints.maxWidth),
                  ),
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  widget.markerBuilder?.call(
                        _markerPosition(
                          width: constraints.maxWidth,
                          height: widget.height,
                        ),
                      ) ??
                      _Marker(
                        position: _markerPosition(
                          width: constraints.maxWidth,
                          height: widget.height,
                        ),
                        color: widget.dangerColor,
                      ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _ZoomControls(
                      primaryColor: widget.primaryColor,
                      canZoomIn: _zoom < widget.maxZoom,
                      canZoomOut: _zoom > widget.minZoom,
                      onZoomIn: () => _changeZoom(_zoom + 1),
                      onZoomOut: () => _changeZoom(_zoom - 1),
                    ),
                  ),
                  if (widget.onDirections != null)
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: FilledButton.icon(
                        onPressed: widget.onDirections,
                        icon: const Icon(Icons.near_me_outlined, size: 18),
                        label: const Text('Chỉ đường'),
                        style: _directionsButtonStyle(widget.primaryColor),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTileGrid({required double width}) {
    final centerTileX = (_centerPixel.dx / _tileSize).floor();
    final centerTileY = (_centerPixel.dy / _tileSize).floor();
    final offsetInTile = Offset(
      _centerPixel.dx - centerTileX * _tileSize,
      _centerPixel.dy - centerTileY * _tileSize,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var dx = -2; dx <= 2; dx++)
          for (var dy = -2; dy <= 2; dy++)
            Positioned(
              left: width / 2 + dx * _tileSize - offsetInTile.dx,
              top: widget.height / 2 + dy * _tileSize - offsetInTile.dy,
              width: _tileSize,
              height: _tileSize,
              child: Image.network(
                _tileUrlFor(centerTileX + dx, centerTileY + dy),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    Container(color: const Color(0xFFEFF2F6)),
              ),
            ),
      ],
    );
  }

  Offset _markerPosition({required double width, required double height}) {
    final markerPixel = _latLngToWorldPixel(
      widget.latitude,
      widget.longitude,
      _zoom,
    );
    final delta = markerPixel - _centerPixel;
    return Offset(width / 2 + delta.dx, height / 2 + delta.dy);
  }

  void _changeZoom(int nextZoom) {
    final clampedZoom = nextZoom.clamp(widget.minZoom, widget.maxZoom);
    if (clampedZoom == _zoom) {
      return;
    }
    final scale = math.pow(2.0, clampedZoom - _zoom).toDouble();
    setState(() {
      _centerPixel *= scale;
      _zoom = clampedZoom;
      _centerPixel = _clampCenter(_centerPixel, _zoom);
    });
  }

  String _tileUrlFor(int tileX, int tileY) {
    final n = math.pow(2.0, _zoom).toInt();
    final wrappedX = tileX.remainder(n);
    final normalizedX = wrappedX < 0 ? wrappedX + n : wrappedX;
    final normalizedY = tileY.clamp(0, n - 1);
    return 'https://tile.openstreetmap.org/$_zoom/$normalizedX/$normalizedY.png';
  }

  Offset _clampCenter(Offset pixel, int zoom) {
    final scale = _tileSize * math.pow(2.0, zoom);
    return Offset(
      pixel.dx.clamp(0.0, scale.toDouble()),
      pixel.dy.clamp(0.0, scale.toDouble()),
    );
  }

  Offset _latLngToWorldPixel(double latitude, double longitude, int zoom) {
    final sinLat = math.sin(latitude * math.pi / 180).clamp(-0.9999, 0.9999);
    final scale = _tileSize * math.pow(2.0, zoom);
    final x = (longitude + 180.0) / 360.0 * scale;
    final y =
        (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return Offset(x, y);
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.position, required this.color});

  final Offset position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 22,
      top: position.dy - 42,
      child: Icon(
        Icons.location_on_rounded,
        color: color,
        size: 44,
        shadows: const [
          Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.primaryColor,
    required this.canZoomIn,
    required this.canZoomOut,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final Color primaryColor;
  final bool canZoomIn;
  final bool canZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add_rounded,
            enabled: canZoomIn,
            primaryColor: primaryColor,
            onTap: onZoomIn,
          ),
          const SizedBox(width: 34, child: Divider(height: 1)),
          _ZoomButton(
            icon: Icons.remove_rounded,
            enabled: canZoomOut,
            primaryColor: primaryColor,
            onTap: onZoomOut,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.enabled,
    required this.primaryColor,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 36,
        height: 34,
        child: Icon(
          icon,
          color: enabled ? primaryColor : const Color(0xFFBDC1CE),
          size: 22,
        ),
      ),
    );
  }
}

ButtonStyle _directionsButtonStyle(Color primaryColor) {
  return FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 5,
    shadowColor: primaryColor.withValues(alpha: 0.24),
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    textStyle: AppTextStyles.bodyStrong.copyWith(
      fontSize: AppFontSizes.base,
      fontWeight: FontWeight.w900,
    ),
  );
}
