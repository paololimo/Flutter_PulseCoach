import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/missed_sessions/missed_sessions_calculator.dart';

void main() {
  const calc = MissedSessionsCalculator();

  test('7.1b-CALC-001: empty list returns 0', () {
    expect(calc.calculate([]), equals(0));
  });

  test('7.1b-CALC-002: 3 plans 1 completed -> 2 missed', () {
    expect(calc.calculate([true, false, false]), equals(2));
  });

  test('7.1b-CALC-003: 7 plans all uncompleted -> 7', () {
    expect(calc.calculate(List.filled(7, false)), equals(7));
  });

  test('7.1b-CALC-004: all completed -> 0 missed', () {
    expect(
      calc.calculate([true, true, true, true, true, true, true]),
      equals(0),
    );
  });

  test('7.1b-CALC-005: today completed, 3 prior misses -> 3 missed', () {
    expect(calc.calculate([false, false, false, true]), equals(3));
  });

  test('7.1b-CALC-006: exactly 1 missed', () {
    expect(calc.calculate([true, true, false]), equals(1));
  });

  test('7.1b-CALC-007: exactly 2 missed (threshold for atRisk rule)', () {
    expect(calc.calculate([false, false, true, true, true]), equals(2));
  });

  test('7.1b-CALC-008: idempotent - same flags produce same result', () {
    final flags = [false, false, true];
    expect(calc.calculate(flags), equals(calc.calculate(flags)));
  });
}
