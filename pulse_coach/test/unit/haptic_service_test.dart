import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/session/presentation/utils/haptic_service.dart';

void main() {
  group('HapticService', () {
    test(
      '8.3-SERVICE-001: VibrationHapticService.stepTransition is a no-op before init',
      () {
        final service = VibrationHapticService();

        expect(() => service.stepTransition(), returnsNormally);
      },
    );

    test(
      '8.3-SERVICE-002: VibrationHapticService.stepTransition is a no-op after init when hasVibrator=false',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final service = VibrationHapticService();

        // Headless test binding has no vibration plugin, so init() will
        // resolve with _supported=false. This exercises the post-init branch
        // that 8.3-SERVICE-001 cannot reach.
        await service.init();

        expect(() => service.stepTransition(), returnsNormally);
        expect(() => service.stepTransition(), returnsNormally);
      },
    );
  });
}
