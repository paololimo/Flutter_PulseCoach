import 'dart:async' show StreamSubscription, unawaited;

import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

abstract interface class WatchMessagingClient {
  Future<void> sendMessage(Map<String, dynamic> message);
}

class WatchConnectivityMessagingClient implements WatchMessagingClient {
  WatchConnectivityMessagingClient({WatchConnectivity? watch})
    : _watch = watch ?? WatchConnectivity();

  final WatchConnectivity _watch;

  @override
  Future<void> sendMessage(Map<String, dynamic> message) {
    return _watch.sendMessage(message);
  }
}

class WearBridgeService {
  WearBridgeService({WatchMessagingClient? client})
    : _client = client ?? WatchConnectivityMessagingClient();

  static const sessionPath = '/pulsecoach/session';
  static const endPath = '/pulsecoach/session/end';
  static const summaryPath = '/pulsecoach/session/summary';
  static const pathKey = '_path';

  final WatchMessagingClient _client;
  StreamSubscription<InSessionState>? _subscription;
  bool _ended = false;
  String? _sessionType;
  int _durationMinutes = 0;

  void start(
    Stream<InSessionState> stateStream, {
    String? sessionType,
    int durationMinutes = 0,
  }) {
    if (_subscription != null) return;
    _sessionType = sessionType;
    _durationMinutes = durationMinutes;
    _subscription = stateStream.listen(_handleState);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _sendEnd();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleState(InSessionState state) {
    if (_ended) return;
    if (state.isComplete || state.isAbandoned) {
      _ended = true;
      final sessionType = _sessionType;
      if (sessionType != null) {
        unawaited(
          _sendToWatch({
            pathKey: summaryPath,
            'sessionType': sessionType,
            'durationMinutes': _durationMinutes,
            'abandoned': state.isAbandoned,
          }),
        );
      } else {
        unawaited(_sendToWatch({pathKey: endPath, 'done': true}));
      }
      return;
    }

    final payload = <String, dynamic>{
      pathKey: sessionPath,
      'step': state.currentStep.title,
      'secs': state.secondsRemaining,
    };
    final liveHr = state.liveHr;
    if (liveHr != null) {
      payload['hr'] = liveHr;
    }

    unawaited(_sendToWatch(payload));
  }

  Future<void> _sendEnd() async {
    if (_ended) return;
    _ended = true;
    await _sendToWatch({pathKey: endPath, 'done': true});
  }

  static Future<void> sendEndMessage({WatchMessagingClient? client}) async {
    final messagingClient = client ?? WatchConnectivityMessagingClient();
    try {
      await messagingClient.sendMessage({pathKey: endPath, 'done': true});
    } catch (_) {
      // Silent degradation: the watch is optional and must not affect RPE UX.
    }
  }

  Future<void> _sendToWatch(Map<String, dynamic> payload) async {
    try {
      await _client.sendMessage(payload);
    } catch (_) {
      // Silent degradation: the watch is optional and must not affect session UX.
    }
  }
}
