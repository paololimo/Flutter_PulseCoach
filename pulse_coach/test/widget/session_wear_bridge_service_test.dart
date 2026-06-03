import 'dart:async';

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
}

class _RecordingWatchMessagingClient implements WatchMessagingClient {
  final messages = <Map<String, dynamic>>[];

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    messages.add(Map<String, dynamic>.from(message));
  }
}

class _ThrowingWatchMessagingClient implements WatchMessagingClient {
  @override
  Future<void> sendMessage(Map<String, dynamic> message) {
    throw Exception('watch disconnected');
  }
}
