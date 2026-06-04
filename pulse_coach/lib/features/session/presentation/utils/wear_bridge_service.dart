import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

abstract interface class WatchMessagingClient {
  Future<void> sendMessage(Map<String, dynamic> message);

  Future<void> updateApplicationContext(Map<String, dynamic> context);
}

abstract interface class WatchReachabilityClient {
  Future<bool> get isReachable;
}

class WatchConnectivityMessagingClient implements WatchMessagingClient {
  WatchConnectivityMessagingClient({WatchConnectivity? watch})
    : _watch = watch ?? WatchConnectivity();

  final WatchConnectivity _watch;

  @override
  Future<void> sendMessage(Map<String, dynamic> message) {
    return _watch.sendMessage(message);
  }

  @override
  Future<void> updateApplicationContext(Map<String, dynamic> context) {
    return _watch.updateApplicationContext(context);
  }
}

class WatchConnectivityReachabilityClient implements WatchReachabilityClient {
  WatchConnectivityReachabilityClient({WatchConnectivity? watch})
    : _watch = watch ?? WatchConnectivity();

  final WatchConnectivity _watch;

  @override
  Future<bool> get isReachable => _watch.isReachable;
}

class WearBridgeService {
  WearBridgeService({
    WatchMessagingClient? client,
    WatchReachabilityClient? reachabilityClient,
  }) : _client = client ?? WatchConnectivityMessagingClient(),
       _reachabilityClient =
           reachabilityClient ?? WatchConnectivityReachabilityClient();

  static const sessionPath = '/pulsecoach/session';
  static const endPath = '/pulsecoach/session/end';
  static const summaryPath = '/pulsecoach/session/summary';
  static const pathKey = '_path';

  // Set whenever an end message is sent (including via the static [sendEndMessage]
  // call from the RPE screen, which is decoupled from the live instance). The
  // reconnect poller checks this so it stops re-sending the summary once the
  // session has been formally ended — otherwise an orphaned poller would flip a
  // watch that already returned to idle back to the summary screen. Reset in
  // [start] when a new session begins.
  static bool _endMessageSent = false;

  final WatchMessagingClient _client;
  final WatchReachabilityClient _reachabilityClient;
  StreamSubscription<InSessionState>? _subscription;
  Timer? _reconnectPoller;
  Timer? _reconnectDeadlineTimer;
  Map<String, dynamic>? _terminalPayload;
  bool _ended = false;
  String? _sessionType;
  int _durationMinutes = 0;

  void start(
    Stream<InSessionState> stateStream, {
    String? sessionType,
    int durationMinutes = 0,
  }) {
    if (_subscription != null) return;
    _endMessageSent = false;
    _sessionType = sessionType;
    _durationMinutes = durationMinutes;
    _subscription = stateStream.listen(_handleState);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_ended && _terminalPayload != null) return;
    _cancelReconnectTimers();
    await _sendEnd();
  }

  Future<void> dispose() async {
    _cancelReconnectTimers();
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleState(InSessionState state) {
    if (_ended) return;
    if (state.isComplete || state.isAbandoned) {
      _ended = true;
      final sessionType = _sessionType;
      final Map<String, dynamic> payload;
      if (sessionType != null) {
        payload = {
          pathKey: summaryPath,
          'sessionType': sessionType,
          'durationMinutes': _durationMinutes,
          'abandoned': state.isAbandoned,
        };
      } else {
        payload = {pathKey: endPath, 'done': true};
      }
      unawaited(_sendTerminalToWatch(payload));
      _terminalPayload = payload;
      _startReconnectPoller();
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
    unawaited(_updateWatchContext(payload));
  }

  Future<void> _sendEnd() async {
    if (_ended) return;
    _ended = true;
    _endMessageSent = true;
    final payload = {pathKey: endPath, 'done': true};
    await _sendToWatch(payload);
    await _updateWatchContext(payload);
  }

  void _startReconnectPoller() {
    _cancelReconnectTimers();
    var active = true;
    _reconnectDeadlineTimer = Timer(const Duration(seconds: 60), () {
      active = false;
      _reconnectPoller?.cancel();
      _reconnectPoller = null;
      _reconnectDeadlineTimer = null;
    });
    _reconnectPoller = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!active) return;
      if (_endMessageSent) {
        active = false;
        _cancelReconnectTimers();
        return;
      }
      final reachable = await _isWatchReachable();
      if (!active) return;
      if (_endMessageSent) {
        active = false;
        _cancelReconnectTimers();
        return;
      }
      final payload = _terminalPayload;
      if (payload != null) unawaited(_sendTerminalToWatch(payload));
      if (reachable) {
        active = false;
        _cancelReconnectTimers();
      }
    });
  }

  Future<bool> _isWatchReachable() async {
    try {
      return await _reachabilityClient.isReachable;
    } catch (_) {
      return false;
    }
  }

  void _cancelReconnectTimers() {
    _reconnectPoller?.cancel();
    _reconnectPoller = null;
    _reconnectDeadlineTimer?.cancel();
    _reconnectDeadlineTimer = null;
  }

  static Future<void> sendEndMessage({WatchMessagingClient? client}) async {
    _endMessageSent = true;
    final messagingClient = client ?? WatchConnectivityMessagingClient();
    final payload = {pathKey: endPath, 'done': true};
    try {
      await messagingClient.sendMessage(payload);
      await messagingClient.updateApplicationContext(payload);
    } catch (_) {
      // Silent degradation: the watch is optional and must not affect RPE UX.
    }
  }

  Future<void> _sendTerminalToWatch(Map<String, dynamic> payload) async {
    await _sendToWatch(payload);
    await _updateWatchContext(payload);
  }

  Future<void> _sendToWatch(Map<String, dynamic> payload) async {
    try {
      await _client.sendMessage(payload);
    } catch (_) {
      // Silent degradation: the watch is optional and must not affect session UX.
    }
  }

  Future<void> _updateWatchContext(Map<String, dynamic> payload) async {
    try {
      await _client.updateApplicationContext(payload);
    } catch (_) {
      // Silent degradation: context sync is best-effort like live messages.
    }
  }
}
