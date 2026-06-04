import 'dart:async' show StreamSubscription, unawaited;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/sync_queue_dao.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';

typedef SyncEventHandler =
    Future<Either<Failure, Unit>> Function(String payload);

@singleton
class SyncManager {
  SyncManager(this._dao, this._connectivity);

  /// After this many failed attempts an entry is dropped (dead-lettered)
  /// instead of being retried forever.
  static const int _maxRetries = 10;

  final SyncQueueDao _dao;
  final Connectivity _connectivity;
  final Map<String, SyncEventHandler> _handlers = {};

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _processing = false;

  void registerHandler(String eventType, SyncEventHandler handler) {
    _handlers[eventType] = handler;
  }

  Future<int> enqueue(String eventType, String payload) async {
    final id = await _dao.insertEntry(
      SyncQueueCompanion.insert(
        eventType: eventType,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    // Drain opportunistically: if we are already online there may be no
    // future connectivity change to trigger processing.
    try {
      if (_isOnline(await _connectivity.checkConnectivity())) {
        unawaited(processQueue());
      }
    } catch (e, st) {
      AppLogger.warning(
        'SyncManager: connectivity probe failed during enqueue',
        name: 'SyncManager',
        error: e,
        stackTrace: st,
      );
    }

    return id;
  }

  Future<void> processQueue() async {
    // Re-entrancy guard: startup and the connectivity stream can both invoke
    // processQueue concurrently. Without this, the same entry could be handled
    // (and its retryCount incremented) twice from overlapping passes.
    if (_processing) return;
    _processing = true;
    try {
      final entries = await _dao.getPendingEntries();
      final now = DateTime.now().toUtc();
      final dueEntries = entries.where(
        (entry) =>
            entry.nextRetryAt == null ||
            !entry.nextRetryAt!.toUtc().isAfter(now),
      );

      for (final entry in dueEntries) {
        final handler = _handlers[entry.eventType];
        if (handler == null) {
          AppLogger.warning(
            'SyncManager: no handler for ${entry.eventType}',
            name: 'SyncManager',
          );
          continue;
        }

        Either<Failure, Unit> result;
        try {
          result = await handler(entry.payload);
        } catch (e, st) {
          // A handler that throws (instead of returning Left) must not abort
          // the whole pass nor surface as an unhandled async error. Treat it
          // as a transient failure and schedule a retry.
          AppLogger.warning(
            'SyncManager: handler for ${entry.eventType} threw',
            name: 'SyncManager',
            error: e,
            stackTrace: st,
          );
          result = const Left(ServerFailure('handler threw'));
        }

        await result.fold(
          (_) => _handleFailure(entry),
          (_) => _dao.deleteEntry(entry.id),
        );
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> start() async {
    await stop();

    try {
      if (_isOnline(await _connectivity.checkConnectivity())) {
        await processQueue();
      }
    } catch (e, st) {
      // A failed initial probe must not prevent the subscription below from
      // being established, otherwise auto-sync is dead for the whole session.
      AppLogger.warning(
        'SyncManager: initial connectivity probe failed',
        name: 'SyncManager',
        error: e,
        stackTrace: st,
      );
    }

    _sub = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (_isOnline(results)) {
          unawaited(processQueue());
        }
      },
      onError: (Object e, StackTrace st) {
        AppLogger.warning(
          'SyncManager: connectivity stream error',
          name: 'SyncManager',
          error: e,
          stackTrace: st,
        );
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Drops an entry after [_maxRetries] failures, otherwise schedules the next
  /// exponential-backoff retry.
  Future<void> _handleFailure(SyncQueueEntry entry) async {
    final nextAttempt = entry.retryCount + 1;
    if (nextAttempt >= _maxRetries) {
      AppLogger.error(
        'SyncManager: dropping ${entry.eventType} after '
        '$nextAttempt failed attempts',
        name: 'SyncManager',
      );
      await _dao.deleteEntry(entry.id);
      return;
    }
    await _scheduleRetry(entry);
  }

  Future<void> _scheduleRetry(SyncQueueEntry entry) async {
    // Clamp the exponent before shifting: 1 << 6 already reaches the 60-min
    // cap, and an unclamped large/negative retryCount would overflow the
    // 64-bit shift (collapsing the delay back to the 1-min floor) or throw.
    final minutes = (1 << entry.retryCount.clamp(0, 6)).clamp(1, 60);
    final nextRetryAt = DateTime.now().toUtc().add(Duration(minutes: minutes));
    AppLogger.warning(
      'SyncManager: ${entry.eventType} failed, retry in ${minutes}m '
      '(attempt ${entry.retryCount + 1})',
      name: 'SyncManager',
    );

    await _dao.updateEntry(
      entry.copyWith(
        retryCount: entry.retryCount + 1,
        nextRetryAt: Value(nextRetryAt),
      ),
    );
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
