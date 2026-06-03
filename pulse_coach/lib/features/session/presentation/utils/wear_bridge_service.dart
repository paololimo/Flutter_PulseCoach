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
  static const pathKey = '_path';

  final WatchMessagingClient _client;
  StreamSubscription<InSessionState>? _subscription;
  bool _ended = false;

  void start(Stream<InSessionState> stateStream) {
    if (_subscription != null) return;
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
    if (state.isComplete || state.isAbandoned) {
      unawaited(stop());
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

  Future<void> _sendToWatch(Map<String, dynamic> payload) async {
    try {
      await _client.sendMessage(payload);
    } catch (_) {
      // Silent degradation: the watch is optional and must not affect session UX.
    }
  }
}
