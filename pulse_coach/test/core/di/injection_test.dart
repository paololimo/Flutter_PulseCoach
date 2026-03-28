import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock path_provider channel required by AppDatabase (driftDatabase uses path_provider)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '/tmp/test_pulse_coach',
    );
  });

  tearDown(() async {
    // Reset GetIt between test runs to avoid state leakage
    await getIt.reset();
  });

  test('configureDependencies completes without throwing', () async {
    await expectLater(configureDependencies(), completes);
  });

  test('getIt container is ready after configureDependencies', () async {
    await configureDependencies();
    // allReady() completes when all async singletons are initialized
    await expectLater(getIt.allReady(), completes);
  });
}
