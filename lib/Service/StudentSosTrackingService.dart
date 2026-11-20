// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Repository/SosTrackingRepository.dart';
import 'package:hcmu_sos/Service/AppLocationRequirementService.dart';

class StudentSosTrackingService with WidgetsBindingObserver {
  StudentSosTrackingService._({SosTrackingRepository? repository})
    : _repository = repository ?? SosTrackingRepository();

  static final StudentSosTrackingService instance =
      StudentSosTrackingService._();

  static const Duration _minimumUploadInterval = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 10);
  static const int _distanceFilterInMeters = 15;

  final SosTrackingRepository _repository;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  bool _observerAttached = false;
  bool _isSending = false;
  int _generation = 0;
  int? _activeSosId;
  Position? _latestPosition;
  Position? _lastSentPosition;
  DateTime? _lastSentAt;

  bool get isTracking => _activeSosId != null;
  int? get currentSosId => _activeSosId;

  Future<void> startIfStudent(AuthUserEntity user) async {
    if (user.role != AuthUserRole.student) {
      stop();
      return;
    }

    _attachObserverIfNeeded();
    await resumeTrackingIfNeeded();
  }

  Future<void> resumeTrackingIfNeeded() async {
    final generation = _generation;
    try {
      final status = await _repository.getCurrentSosStatus();
      if (generation != _generation) return;
      if (status == null || !status.canTrack) {
        stop();
        return;
      }

      await startTracking(status.sosId, syncImmediately: true);
    } catch (error, stackTrace) {
      developer.log(
        'Could not restore SOS tracking state.',
        name: 'StudentSosTrackingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> startTracking(
    int sosId, {
    bool syncImmediately = false,
    bool userInitiated = false,
  }) async {
    if (sosId <= 0) {
      return;
    }

    _attachObserverIfNeeded();

    final shouldRecreate =
        _activeSosId != sosId || _positionSubscription == null;
    _activeSosId = sosId;

    try {
      if (shouldRecreate) {
        await _restartTrackingStream(userInitiated: userInitiated);
      }

      if (syncImmediately) {
        unawaited(_sendLatestPosition(force: true));
      }
    } catch (error, stackTrace) {
      // A tracking/permission failure must not turn a successfully created SOS
      // into a creation failure or cause the user to submit it again.
      developer.log(
        'Could not start SOS tracking.',
        name: 'StudentSosTrackingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void stop() {
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    _positionSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _positionSubscription = null;
    _heartbeatTimer = null;
    _latestPosition = null;
    _lastSentPosition = null;
    _lastSentAt = null;
    _activeSosId = null;
    _isSending = false;
    _generation++;
  }

  Future<void> _restartTrackingStream({required bool userInitiated}) async {
    final generation = ++_generation;
    _positionSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _positionSubscription = null;
    _heartbeatTimer = null;
    _latestPosition = null;
    _lastSentPosition = null;
    _lastSentAt = null;

    final permissionGranted = await _ensureLocationPermission(
      userInitiated: userInitiated,
    );
    if (!permissionGranted || generation != _generation) {
      return;
    }

    final settings = _buildLocationSettings();

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) {
            if (generation != _generation) {
              return;
            }
            _latestPosition = position;
            if (_shouldUpload(position)) {
              unawaited(_sendLatestPosition());
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            developer.log(
              'SOS location stream failed.',
              name: 'StudentSosTrackingService',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (generation != _generation) {
        return;
      }
      unawaited(_sendLatestPosition(force: true));
    });
  }

  Future<void> _sendLatestPosition({bool force = false}) async {
    final sosId = _activeSosId;
    final position = _latestPosition;
    if (sosId == null ||
        position == null ||
        _isSending ||
        !AppLocationRequirementService.instance.hasConsent(
          use: LocationUse.sosTracking,
        )) {
      return;
    }

    if (!force && !_shouldUpload(position)) {
      return;
    }

    _isSending = true;
    final generation = _generation;
    try {
      final result = await _repository.updateSosLocation(
        sosId: sosId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (generation != _generation) {
        return;
      }

      _lastSentAt = DateTime.now();
      _lastSentPosition = position;

      if (result != null && !result.isActive) {
        stop();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Could not upload SOS location.',
        name: 'StudentSosTrackingService',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (generation == _generation) {
        _isSending = false;
      }
    }
  }

  bool _shouldUpload(Position position) {
    final now = DateTime.now();
    final lastSentAt = _lastSentAt;
    if (lastSentAt == null) {
      return true;
    }

    final elapsed = now.difference(lastSentAt);
    if (elapsed >= _heartbeatInterval) {
      return true;
    }

    if (elapsed < _minimumUploadInterval) {
      return false;
    }

    final lastSentPosition = _lastSentPosition;
    if (lastSentPosition == null) {
      return true;
    }

    final distance = Geolocator.distanceBetween(
      lastSentPosition.latitude,
      lastSentPosition.longitude,
      position.latitude,
      position.longitude,
    );
    return distance >= _distanceFilterInMeters;
  }

  Future<bool> _ensureLocationPermission({required bool userInitiated}) async {
    return AppLocationRequirementService.instance.checkLocationStatus(
      use: LocationUse.sosTracking,
      userInitiated: userInitiated,
    );
  }

  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: _distanceFilterInMeters,
        intervalDuration: _minimumUploadInterval,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'staff.sosRealtime.notificationTitle'.tr,
          notificationText: 'staff.sosRealtime.notificationBody'.tr,
          enableWakeLock: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: _distanceFilterInMeters,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        activityType: ActivityType.automotiveNavigation,
      );
    }

    if (Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _distanceFilterInMeters,
      );
    }

    return const LocationSettings(accuracy: LocationAccuracy.best);
  }

  void _attachObserverIfNeeded() {
    if (_observerAttached) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(resumeTrackingIfNeeded());
    }
  }
}
