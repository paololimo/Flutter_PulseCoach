import 'dart:async';
import 'dart:collection' show Queue;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/features/session/presentation/utils/wear_bridge_service.dart';

void main() {
  const steps = [
    ExerciseStep(
      title: 'Warm-up',
      instruction: 'Move gently',
      durationSeconds: 60,
    ),
    ExerciseStep(
      title: 'Squat',
      instruction: 'Controlled reps',
      durationSeconds: 45,
    ),
  ];

  test('sends active session updates with step, seconds, and HR', () async {
    final client = _RecordingWatchMessagingClient();
    final controller = StreamController<InSessionState>();
    final service = WearBridgeService(client: client);

    service.start(controller.stream);
    controller.add(
      const InSessionState(
        steps: steps,
        currentStepIndex: 1,
        secondsRemaining: 42,
        liveHr: 128,
      ),
    );

    await pumpEventQueue();

    expect(client.messages, [
      {
        '_path': WearBridgeService.sessionPath,
        'step': 'Squat',
        'secs': 42,
        'hr': 128,
      },
    ]);

    await controller.close();
    await service.dispose();
  });

  test('omits HR key when live HR is unavailable', () async {
    final client = _RecordingWatchMessagingClient();
    final controller = StreamController<InSessionState>();
    final service = WearBridgeService(client: client);

    service.start(controller.stream);
    controller.add(
      const InSessionState(
        steps: steps,
        currentStepIndex: 0,
        secondsRemaining: 30,
      ),
    );

    await pumpEventQueue();

    expect(client.messages.single, {
      '_path': WearBridgeService.sessionPath,
      'step': 'Warm-up',
      'secs': 30,
    });

    await controller.close();
    await service.dispose();
  });

  test('sends end message when complete or stopped', () async {
    final client = _RecordingWatchMessagingClient();
    final controller = StreamController<InSessionState>();
    final service = WearBridgeService(client: client);

    service.start(
      controller.stream,
      sessionType: 'mobility',
      durationMinutes: 20,
    );
    controller.add(
      const InSessionState(
        steps: steps,
        currentStepIndex: 0,
        secondsRemaining: 0,
        isComplete: true,
      ),
    );

    await pumpEventQueue();

    expect(client.messages, [
      {
        '_path': WearBridgeService.summaryPath,
        'sessionType': 'mobility',
        'durationMinutes': 20,
        'abandoned': false,
      },
    ]);

    await controller.close();
    await service.dispose();
  });

  test('sends summary with abandoned=true when session is abandoned', () async {
    final client = _RecordingWatchMessagingClient();
    final controller = StreamController<InSessionState>();
    final service = WearBridgeService(client: client);

    service.start(
      controller.stream,
      sessionType: 'cardio',
      durationMinutes: 15,
    );
    controller.add(
      const InSessionState(
        steps: steps,
        currentStepIndex: 0,
        secondsRemaining: 0,
        isAbandoned: true,
      ),
    );

    await pumpEventQueue();

    expect(client.messages, [
      {
        '_path': WearBridgeService.summaryPath,
        'sessionType': 'cardio',
        'durationMinutes': 15,
        'abandoned': true,
      },
    ]);

    await controller.close();
    await service.dispose();
  });

  test('sends end fallback when no session type is provided', () async {
    final client = _RecordingWatchMessagingClient();
    final controller = StreamController<InSessionState>();
    final service = WearBridgeService(client: client);

    service.start(controller.stream);
    controller.add(
      const InSessionState(
        steps: steps,
        currentStepIndex: 0,
        secondsRemaining: 0,
        isComplete: true,
      ),
    );

    await pumpEventQueue();

    expect(client.messages, [
      {'_path': WearBridgeService.endPath, 'done': true},
    ]);

    await controller.close();
    await service.dispose();
  });

  test('sendEndMessage sends end payload without crashing', () async {
    final client = _RecordingWatchMessagingClient();

    await WearBridgeService.sendEndMessage(client: client);

    expect(client.messages, [
      {'_path': WearBridgeService.endPath, 'done': true},
    ]);
  });

  test('swallows messaging exceptions for silent degradation', () async {
    final client = _ThrowingWatchMessagingClient();
    final controller = StreamController<InSessionState>();
    final service = WearBridgeService(client: client);

    service.start(controller.stream);
    controller.add(
      const InSessionState(
        steps: steps,
        currentStepIndex: 0,
        secondsRemaining: 20,
      ),
    );

    await pumpEventQueue();

    await controller.close();
    await service.dispose();
  });

  test(
    'reconnect poller re-sends terminal payload when watch becomes reachable',
    () {
      fakeAsync((async) {
        final client = _RecordingWatchMessagingClient();
        final reachabilityClient = _FakeReachabilityClient([false, true]);
        final controller = StreamController<InSessionState>();
        final service = WearBridgeService(
          client: client,
          reachabilityClient: reachabilityClient,
        );

        service.start(
          controller.stream,
          sessionType: 'mobility',
          durationMinutes: 20,
        );
        controller.add(
          const InSessionState(
            steps: steps,
            currentStepIndex: 0,
            secondsRemaining: 0,
            isComplete: true,
          ),
        );
        async.flushMicrotasks();

        expect(client.messages.length, 1);

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(client.messages.length, 2);

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(client.messages, [
          {
            '_path': WearBridgeService.summaryPath,
            'sessionType': 'mobility',
            'durationMinutes': 20,
            'abandoned': false,
          },
          {
            '_path': WearBridgeService.summaryPath,
            'sessionType': 'mobility',
            'durationMinutes': 20,
            'abandoned': false,
          },
          {
            '_path': WearBridgeService.summaryPath,
            'sessionType': 'mobility',
            'durationMinutes': 20,
            'abandoned': false,
          },
        ]);

        controller.close();
        service.dispose();
        async.flushMicrotasks();
      });
    },
  );

  test('reconnect poller stops after re-send and does not keep re-sending', () {
    fakeAsync((async) {
      final client = _RecordingWatchMessagingClient();
      final reachabilityClient = _FakeReachabilityClient([true, true, true]);
      final controller = StreamController<InSessionState>();
      final service = WearBridgeService(
        client: client,
        reachabilityClient: reachabilityClient,
      );

      service.start(
        controller.stream,
        sessionType: 'cardio',
        durationMinutes: 15,
      );
      controller.add(
        const InSessionState(
          steps: steps,
          currentStepIndex: 0,
          secondsRemaining: 0,
          isComplete: true,
        ),
      );
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 15));
      async.flushMicrotasks();

      expect(client.messages.length, 2);
      expect(reachabilityClient.callCount, 1);

      controller.close();
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test(
    'reconnect poller is cancelled on dispose with no re-send after dispose',
    () {
      fakeAsync((async) {
        final client = _RecordingWatchMessagingClient();
        final reachabilityClient = _FakeReachabilityClient([true]);
        final controller = StreamController<InSessionState>();
        final service = WearBridgeService(
          client: client,
          reachabilityClient: reachabilityClient,
        );

        service.start(
          controller.stream,
          sessionType: 'strength',
          durationMinutes: 10,
        );
        controller.add(
          const InSessionState(
            steps: steps,
            currentStepIndex: 0,
            secondsRemaining: 0,
            isComplete: true,
          ),
        );
        async.flushMicrotasks();

        service.dispose();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(client.messages.length, 1);
        expect(reachabilityClient.callCount, 0);

        controller.close();
        async.flushMicrotasks();
      });
    },
  );

  test('stop after terminal state preserves poller for reconnect summary', () {
    fakeAsync((async) {
      final client = _RecordingWatchMessagingClient();
      final reachabilityClient = _FakeReachabilityClient([true]);
      final controller = StreamController<InSessionState>();
      final service = WearBridgeService(
        client: client,
        reachabilityClient: reachabilityClient,
      );

      service.start(
        controller.stream,
        sessionType: 'mobility',
        durationMinutes: 20,
      );
      controller.add(
        const InSessionState(
          steps: steps,
          currentStepIndex: 0,
          secondsRemaining: 0,
          isAbandoned: true,
        ),
      );
      async.flushMicrotasks();

      service.stop();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();

      expect(client.messages, [
        {
          '_path': WearBridgeService.summaryPath,
          'sessionType': 'mobility',
          'durationMinutes': 20,
          'abandoned': true,
        },
        {
          '_path': WearBridgeService.summaryPath,
          'sessionType': 'mobility',
          'durationMinutes': 20,
          'abandoned': true,
        },
      ]);

      controller.close();
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('reconnect poller auto-cancels after 60 seconds without reachable', () {
    fakeAsync((async) {
      final client = _RecordingWatchMessagingClient();
      final reachabilityClient = _FakeReachabilityClient([false]);
      final controller = StreamController<InSessionState>();
      final service = WearBridgeService(
        client: client,
        reachabilityClient: reachabilityClient,
      );

      service.start(
        controller.stream,
        sessionType: 'mobility',
        durationMinutes: 20,
      );
      controller.add(
        const InSessionState(
          steps: steps,
          currentStepIndex: 0,
          secondsRemaining: 0,
          isComplete: true,
        ),
      );
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 65));
      async.flushMicrotasks();
      final callsAfterCancelWindow = reachabilityClient.callCount;
      final messagesAfterCancelWindow = client.messages.length;
      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();

      expect(messagesAfterCancelWindow, greaterThan(1));
      expect(client.messages.length, messagesAfterCancelWindow);
      expect(callsAfterCancelWindow, greaterThan(0));
      expect(reachabilityClient.callCount, callsAfterCancelWindow);

      controller.close();
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test(
    'mirrors every outbound payload into application context for reconnect '
    'recovery',
    () async {
      final client = _RecordingWatchMessagingClient();
      final controller = StreamController<InSessionState>();
      final service = WearBridgeService(client: client);

      service.start(
        controller.stream,
        sessionType: 'mobility',
        durationMinutes: 20,
      );
      controller.add(
        const InSessionState(
          steps: steps,
          currentStepIndex: 1,
          secondsRemaining: 42,
          liveHr: 128,
        ),
      );
      await pumpEventQueue();

      // Each active tick is persisted as application context so a relaunched
      // watch can hydrate the latest state on reconnect (Story 12.4 AC2/AC3).
      expect(client.contexts, [
        {
          '_path': WearBridgeService.sessionPath,
          'step': 'Squat',
          'secs': 42,
          'hr': 128,
        },
      ]);

      controller.add(
        const InSessionState(
          steps: steps,
          currentStepIndex: 1,
          secondsRemaining: 0,
          isComplete: true,
        ),
      );
      await pumpEventQueue();

      // The terminal summary is also persisted as the latest application
      // context — the mechanism that makes reconnect-after-end recovery work.
      expect(client.contexts.length, 2);
      expect(client.contexts.last, {
        '_path': WearBridgeService.summaryPath,
        'sessionType': 'mobility',
        'durationMinutes': 20,
        'abandoned': false,
      });

      await controller.close();
      await service.dispose();
    },
  );

  test('reconnect poller stops re-sending once an end message has been sent', () {
    fakeAsync((async) {
      final client = _RecordingWatchMessagingClient();
      // Never reachable: the poller keeps re-sending the summary until an end
      // is sent (or the 60s deadline) — exercises the end-gate, not reachability.
      final reachabilityClient = _FakeReachabilityClient([false]);
      final controller = StreamController<InSessionState>();
      final service = WearBridgeService(
        client: client,
        reachabilityClient: reachabilityClient,
      );

      service.start(
        controller.stream,
        sessionType: 'mobility',
        durationMinutes: 20,
      );
      controller.add(
        const InSessionState(
          steps: steps,
          currentStepIndex: 0,
          secondsRemaining: 0,
          isComplete: true,
        ),
      );
      async.flushMicrotasks();
      expect(client.messages.length, 1); // summary on completion

      // One poll re-sends the summary (RPE not yet submitted).
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(client.messages.length, greaterThan(1));

      // RPE submitted on the phone → end sent via the decoupled static path.
      WearBridgeService.sendEndMessage(client: client);
      async.flushMicrotasks();
      final afterEnd = client.messages.length;

      // The orphaned poller must stop re-sending the summary now that the
      // session has formally ended (Story 12.4 review D2).
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
      expect(client.messages.length, afterEnd);

      controller.close();
      service.dispose();
      async.flushMicrotasks();
    });
  });
}

class _RecordingWatchMessagingClient implements WatchMessagingClient {
  final messages = <Map<String, dynamic>>[];
  final contexts = <Map<String, dynamic>>[];

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    messages.add(Map<String, dynamic>.from(message));
  }

  @override
  Future<void> updateApplicationContext(Map<String, dynamic> context) async {
    contexts.add(Map<String, dynamic>.from(context));
  }
}

class _ThrowingWatchMessagingClient implements WatchMessagingClient {
  @override
  Future<void> sendMessage(Map<String, dynamic> message) {
    throw Exception('watch disconnected');
  }

  @override
  Future<void> updateApplicationContext(Map<String, dynamic> context) {
    throw Exception('watch disconnected');
  }
}

class _FakeReachabilityClient implements WatchReachabilityClient {
  _FakeReachabilityClient(List<bool> values) : _values = Queue.of(values);

  final Queue<bool> _values;
  int callCount = 0;

  @override
  Future<bool> get isReachable async {
    callCount += 1;
    if (_values.isEmpty) return true;
    if (_values.length == 1) return _values.first;
    return _values.removeFirst();
  }
}
