// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Repository/StaffLocationRepository.dart';

class StaffLocationUpdateService {
  StaffLocationUpdateService._({
    StaffLocationRepository? locationRepository,
  }) : _locationRepository =
           locationRepository ?? StaffLocationRepository();

  static final StaffLocationUpdateService instance =
      StaffLocationUpdateService._();

  static const Duration updateInterval = Duration(minutes: 5);

  final StaffLocationRepository _locationRepository;

  Timer? _timer;
  bool _isSending = false;
  int _generation = 0;

  bool get isRunning => _timer != null;

  void startIfStaff(AuthUserEntity user) {
    if (user.role != AuthUserRole.staff) {
      stop();
      return;
    }

    if (_timer != null) {
      return;
    }

    final generation = _generation;
    unawaited(_sendCurrentLocation(generation));
    _timer = Timer.periodic(updateInterval, (_) {
      unawaited(_sendCurrentLocation(generation));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isSending = false;
    _generation++;
  }

  Future<void> _sendCurrentLocation(int generation) async {
    if (_isSending || generation != _generation) {
      return;
    }

    _isSending = true;
    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        return;
      }
      if (generation != _generation) {
        return;
      }

      await _locationRepository.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Could not update staff location.',
        name: 'StaffLocationUpdateService',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (generation == _generation) {
        _isSending = false;
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }
}
