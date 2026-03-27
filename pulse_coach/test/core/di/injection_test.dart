import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';

void main() {
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
