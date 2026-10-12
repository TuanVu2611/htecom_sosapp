// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Repository/UserLocationRepository.dart';
import 'package:hcmu_sos/Service/AppLocationRequirementService.dart';

class UserLocationUpdateService with WidgetsBindingObserver {
  UserLocationUpdateService._({UserLocationRepository? locationRepository})
    : _locationRepository = locationRepository ?? UserLocationRepository(),
      _now = DateTime.now;

  @visibleForTesting
  UserLocationUpdateService.forTesting({
    required UserLocationRepository locationRepository,
    required DateTime Function() now,
  }) : _locationRepository = locationRepository,
       _now = now;

  static final UserLocationUpdateService instance =
      UserLocationUpdateService._();

  static const Duration updateInterval = Duration(minutes: 5);

  final UserLocationRepository _locationRepository;
  final DateTime Function() _now;

  Timer? _timer;
  AuthUserRole? _role;
  String? _userId;
  DateTime? _lastStudentRequest;
  bool _isForeground = true;
  bool _pendingResume = false;
  bool _isSending = false;
  int _generation = 0;

  bool get isRunning => _role != null;

  void startForUser(AuthUserEntity user) {
    if (user.role != AuthUserRole.staff && user.role != AuthUserRole.student) {
      stop();
      return;
    }

    if (_role == user.role && _userId == user.id) {
      return;
    }

    stop();
    _role = user.role;
    _userId = user.id;
    _isForeground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    final generation = _generation;
    unawaited(_sendCurrentLocation(generation));
    if (_role == AuthUserRole.staff) {
      _timer = Timer.periodic(updateInterval, (_) {
        unawaited(_sendCurrentLocation(generation));
      });
    }
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    _isSending = false;
    _role = null;
    _userId = null;
    _lastStudentRequest = null;
    _pendingResume = false;
    _generation++;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isForeground;
    _isForeground = state == AppLifecycleState.resumed;
    if (_role != AuthUserRole.student || !_isForeground || wasForeground) {
      return;
    }
    if (_isSending) {
      _pendingResume = true;
    } else {
      unawaited(_sendCurrentLocation(_generation));
    }
  }

  bool get _canSend {
    if (_role == AuthUserRole.staff) return true;
    if (_role != AuthUserRole.student || !_isForeground) return false;
    final lastRequest = _lastStudentRequest;
    return lastRequest == null ||
        _now().difference(lastRequest) >= updateInterval;
  }

  Future<void> _sendCurrentLocation(int generation) async {
    if (_isSending || generation != _generation || !_canSend) {
      return;
    }

    _isSending = true;
    try {
      final allowed = await AppLocationRequirementService.instance
          .checkLocationStatus(showDialog: false);
      if (!allowed || generation != _generation || !_canSend) return;
      final position = await _getCurrentPosition(generation);
      if (position == null) {
        return;
      }
      if (generation != _generation || !_canSend) {
        return;
      }

      if (_role == AuthUserRole.student) _lastStudentRequest = _now();
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
        if (_pendingResume) {
          _pendingResume = false;
          unawaited(_sendCurrentLocation(generation));
        }
      }
    }
  }

  Future<Position?> _getCurrentPosition(int generation) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled || generation != _generation || !_canSend) {
      return null;
    }

    final permission = await Geolocator.checkPermission();
    if (generation != _generation || !_canSend) return null;
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
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
