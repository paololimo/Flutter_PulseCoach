import 'dart:async';

import 'package:watch_connectivity/watch_connectivity.dart';

abstract interface class PhoneMessagingClient {
  Stream<Map<String, dynamic>> get messageStream;
}

class WatchConnectivityPhoneMessagingClient implements PhoneMessagingClient {
  WatchConnectivityPhoneMessagingClient({WatchConnectivity? watch})
    : _watch = watch ?? WatchConnectivity();

  final WatchConnectivity _watch;

  @override
  Stream<Map<String, dynamic>> get messageStream => _watch.messageStream;
}

class SessionWearState {
  const SessionWearState({
    required this.stepName,
    required this.secondsRemaining,
    required this.isEnded,
    this.heartRate,
    this.isSummary = false,
    this.summarySessionType,
    this.summaryDurationMinutes = 0,
    this.summaryAbandoned = false,
  });

  const SessionWearState.active({
    required String stepName,
    required int secondsRemaining,
    int? heartRate,
  }) : this(
         stepName: stepName,
         secondsRemaining: secondsRemaining,
         heartRate: heartRate,
         isEnded: false,
       );

  const SessionWearState.ended()
    : this(stepName: '', secondsRemaining: 0, isEnded: true);

  const SessionWearState.summary({
    required String sessionType,
    required int durationMinutes,
    required bool abandoned,
  }) : this(
         stepName: '',
         secondsRemaining: 0,
         isEnded: false,
         isSummary: true,
         summarySessionType: sessionType,
         summaryDurationMinutes: durationMinutes,
         summaryAbandoned: abandoned,
       );

  final String stepName;
  final int secondsRemaining;
  final int? heartRate;
  final bool isEnded;
  final bool isSummary;
  final String? summarySessionType;
  final int summaryDurationMinutes;
  final bool summaryAbandoned;
}

class PhoneBridge {
  PhoneBridge({PhoneMessagingClient? client})
    : _client = client ?? WatchConnectivityPhoneMessagingClient() {
    _subscription = _client.messageStream.listen(_handleMessage);
  }

  static const sessionPath = '/pulsecoach/session';
  static const endPath = '/pulsecoach/session/end';
  static const summaryPath = '/pulsecoach/session/summary';
  static const pathKey = '_path';

  final PhoneMessagingClient _client;
  final StreamController<SessionWearState> _statesController =
      StreamController<SessionWearState>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  Stream<SessionWearState> get states => _statesController.stream;

  void _handleMessage(Map<String, dynamic> message) {
    final path = message[pathKey];
    if (path == sessionPath) {
      final state = _parseActiveState(message);
      if (state != null) _statesController.add(state);
      return;
    }
    if (path == endPath) {
      _statesController.add(const SessionWearState.ended());
      return;
    }
    if (path == summaryPath) {
      final state = _parseSummaryState(message);
      if (state != null) _statesController.add(state);
    }
  }

  SessionWearState? _parseActiveState(Map<String, dynamic> message) {
    final step = message['step'];
    final secs = message['secs'];
    final hr = message['hr'];
    if (step is! String || secs is! int) return null;
    if (hr != null && hr is! int) return null;

    return SessionWearState.active(
      stepName: step,
      secondsRemaining: secs,
      heartRate: hr,
    );
  }

  SessionWearState? _parseSummaryState(Map<String, dynamic> message) {
    final sessionType = message['sessionType'];
    final durationMinutes = message['durationMinutes'];
    final abandoned = message['abandoned'];
    if (sessionType is! String ||
        durationMinutes is! int ||
        abandoned is! bool) {
      return null;
    }

    return SessionWearState.summary(
      sessionType: sessionType,
      durationMinutes: durationMinutes,
      abandoned: abandoned,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _statesController.close();
  }
}
