// ignore_for_file: file_names

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    this.onDirections,
    this.onLocationChanged,
  });

  final double latitude;
  final double longitude;
  final Color primaryColor;
  final Color dangerColor;
  final Color borderColor;
  final double height;
  final double initialZoom;
  final VoidCallback? onDirections;
  final ValueChanged<LatLng>? onLocationChanged;

  @override
  State<InteractiveTileMap> createState() => _InteractiveTileMapState();
}

class _InteractiveTileMapState extends State<InteractiveTileMap> {
  static const _markerId = MarkerId('selected_location');

  GoogleMapController? _mapController;
  late LatLng _cameraTarget;
  bool _ignoreNextCameraIdle = false;

  @override
  void initState() {
    super.initState();
    _cameraTarget = _targetFromWidget();
  }

  @override
  void didUpdateWidget(covariant InteractiveTileMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude == widget.latitude &&
        oldWidget.longitude == widget.longitude) {
      return;
    }

    _cameraTarget = _targetFromWidget();
    _ignoreNextCameraIdle = true;
    _mapController?.animateCamera(CameraUpdate.newLatLng(_cameraTarget));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.onLocationChanged != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: widget.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _cameraTarget,
                  zoom: widget.initialZoom,
                ),
                markers: <Marker>{
                  Marker(
                    markerId: _markerId,
                    position: isEditable ? _cameraTarget : _targetFromWidget(),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                  ),
                },
                compassEnabled: true,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onMapCreated: (controller) => _mapController = controller,
                onCameraMove: isEditable
                    ? (position) => _cameraTarget = position.target
                    : null,
                onCameraIdle: isEditable ? _commitLocationChange : null,
              ),
            ),
            if (isEditable)
              Positioned(
                left: 10,
                top: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x1A29306F)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Text(
                      'Kéo bản đồ để chỉnh vị trí',
                      style: AppTextStyles.caption.copyWith(
                        color: widget.primaryColor,
                        fontSize: AppFontSizes.xs,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
  }

  LatLng _targetFromWidget() => LatLng(widget.latitude, widget.longitude);

  void _commitLocationChange() {
    if (_ignoreNextCameraIdle) {
      _ignoreNextCameraIdle = false;
      return;
    }
    widget.onLocationChanged?.call(_cameraTarget);
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
