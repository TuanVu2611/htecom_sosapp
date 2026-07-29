// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hcmu_sos/Entity/PendingTicketEntity.dart';
import 'package:hcmu_sos/Repository/PendingTicketRepository.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class PendingTicketSyncState {
  const PendingTicketSyncState({
    this.pendingCount = 0,
    this.isSyncing = false,
  });

  final int pendingCount;
  final bool isSyncing;
}

class PendingTicketSyncService with WidgetsBindingObserver {
  PendingTicketSyncService._();

  static final PendingTicketSyncService instance = PendingTicketSyncService._();
  static const Duration _retryInterval = Duration(seconds: 20);

  final PendingTicketRepository _pendingRepository = PendingTicketRepository();
  final SupportRequestRepository _requestRepository = SupportRequestRepository();
  final Connectivity _connectivity = Connectivity();
  final StreamController<PendingTicketSyncState> _stateController =
      StreamController<PendingTicketSyncState>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _runningSync;
  Timer? _retryTimer;
  PendingTicketSyncState _state = const PendingTicketSyncState();

  Stream<PendingTicketSyncState> get stateStream => _stateController.stream;

  PendingTicketSyncState get currentState => _state;

  Future<void> start() async {
    await _pendingRepository.markPendingAfterInterruptedSync();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (_hasNetwork(results)) {
        syncPendingTickets();
      }
    });
    _retryTimer ??= Timer.periodic(_retryInterval, (_) {
      syncPendingTickets();
    });
    await refreshState();
    if (await hasNetwork()) {
      unawaited(syncPendingTickets());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncPendingTickets());
    }
  }

  Future<bool> hasNetwork() async {
    return _hasNetwork(await _connectivity.checkConnectivity());
  }

  Future<int> pendingCount() {
    return _pendingRepository.pendingCount();
  }

  Future<void> refreshState({bool? isSyncing}) async {
    _emitState(
      PendingTicketSyncState(
        pendingCount: await pendingCount(),
        isSyncing: isSyncing ?? _state.isSyncing,
      ),
    );
  }

  Future<void> syncPendingTickets() {
    final runningSync = _runningSync;
    if (runningSync != null) {
      return runningSync;
    }

    final syncFuture = _syncPendingTickets().whenComplete(() {
      _runningSync = null;
    });
    _runningSync = syncFuture;
    return syncFuture;
  }

  Future<void> _syncPendingTickets() async {
    await refreshState(isSyncing: true);
    try {
      if (!await hasNetwork()) return;

      final tickets = await _pendingRepository.list();
      for (final ticket in tickets) {
        if (ticket.status == PendingTicketStatus.failed) continue;

        await _syncTicket(ticket);
        await refreshState(isSyncing: true);
        if (!await hasNetwork()) return;
      }
    } finally {
      await refreshState(isSyncing: false);
    }
  }

  Future<void> _syncTicket(PendingTicketEntity ticket) async {
    await _pendingRepository.update(
      ticket.copyWith(status: PendingTicketStatus.syncing, lastError: null),
    );

    try {
      final imageFileIds = <int>[];
      for (final attachment in ticket.attachments) {
        final bytes = await File(attachment.filePath).readAsBytes();
        imageFileIds.add(
          await Utils.uploadFile(
            bytes: bytes,
            fileName: attachment.fileName,
            mimeType: attachment.mimeType,
            purpose: 'report_image',
          ),
        );
      }

      await _requestRepository.createRequest(
        incidentTypeId: ticket.incidentTypeId,
        title: ticket.title,
        description: ticket.description,
        priority: ticket.priority,
        locationText: ticket.locationText,
        latitude: ticket.latitude,
        longitude: ticket.longitude,
        imageFileIds: imageFileIds,
      );

      await _pendingRepository.remove(ticket);
      await refreshState(isSyncing: true);
    } on ApiException catch (error) {
      await _pendingRepository.update(
        ticket.copyWith(
          status: _shouldRetry(error)
              ? PendingTicketStatus.pending
              : PendingTicketStatus.failed,
          retryCount: ticket.retryCount + 1,
          lastError: error.message,
        ),
      );
    } catch (error) {
      await _pendingRepository.update(
        ticket.copyWith(
          status: PendingTicketStatus.pending,
          retryCount: ticket.retryCount + 1,
          lastError: error.toString(),
        ),
      );
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  bool _shouldRetry(ApiException error) {
    final statusCode = error.statusCode;
    if (statusCode == null) return true;
    if (statusCode == 401 || statusCode == 403) return true;
    return statusCode >= 500 || statusCode == 408 || statusCode == 429;
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _connectivitySubscription = null;
    _retryTimer = null;
    await _stateController.close();
  }

  void _emitState(PendingTicketSyncState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
