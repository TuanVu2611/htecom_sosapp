// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Repository/UserLocationRepository.dart';

class UserLocationUpdateService {
  UserLocationUpdateService._({UserLocationRepository? locationRepository})
    : _locationRepository = locationRepository ?? UserLocationRepository();

  static final UserLocationUpdateService instance =
      UserLocationUpdateService._();

  static const Duration updateInterval = Duration(minutes: 5);

  final UserLocationRepository _locationRepository;

  Timer? _timer;
  bool _isSending = false;
  int _generation = 0;

  bool get isRunning => _timer != null;

  void startForUser(AuthUserEntity user) {
    if (user.role != AuthUserRole.staff && user.role != AuthUserRole.student) {
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
        'Could not update user location.',
        name: 'UserLocationUpdateService',
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
