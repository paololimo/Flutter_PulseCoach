import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    test('10.0-LOG-001: debug() does not throw', () {
      expect(() => AppLogger.debug('test', name: 'TestSuite'), returnsNormally);
    });

    test('10.0-LOG-002: warning() does not throw', () {
      expect(
        () =>
            AppLogger.warning('warn', name: 'TestSuite', error: Exception('x')),
        returnsNormally,
      );
    });

    test('10.0-LOG-003: error() does not throw', () {
      expect(
        () => AppLogger.error(
          'err',
          name: 'TestSuite',
          error: Exception('x'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });
}
