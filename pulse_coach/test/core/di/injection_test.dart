import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

  // Regression: TodaySessionCubit takes a `DateTime Function()? now` param
  // annotated @ignoreParam so injectable's codegen skips the un-resolvable
  // raw-function dependency instead of failing to register the cubit at all.
  // If the annotation is dropped, this resolution throws.
  test('TodaySessionCubit resolves from the container', () async {
    await configureDependencies();
    expect(getIt<TodaySessionCubit>(), isA<TodaySessionCubit>());
  });

  // Regression: AuthBloc must be a lazySingleton, not a factory. As a factory,
  // every injected consumer (e.g. BackupBloc) got a fresh, always-
  // unauthenticated instance, so "Backup ora" failed with "Not authenticated"
  // even while signed in. As a singleton all consumers share one auth state.
  test('AuthBloc is registered as a singleton (same instance every resolve)',
      () async {
    await configureDependencies();
    final first = getIt<AuthBloc>();
    final second = getIt<AuthBloc>();
    expect(identical(first, second), isTrue);
  });
}
