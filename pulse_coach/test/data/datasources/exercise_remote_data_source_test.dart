import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/constants/api_constants.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart';

import 'exercise_remote_data_source_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late ExerciseRemoteDataSource sut;

  setUp(() {
    mockDio = MockDio();
    sut = ExerciseRemoteDataSource(mockDio);
  });

  test(
    '6.1-UNIT-004: successful payload parses safe cardio exercises',
    () async {
      when(mockDio.get(ApiConstants.exerciseDbExercisesUrl)).thenAnswer(
        (_) async => Response(
          data: [
            {
              'exerciseId': 'cardio-1',
              'name': 'High Knees',
              'bodyParts': ['waist'],
              'targetMuscles': ['abs'],
              'equipments': ['body weight'],
              'instructions': ['Drive your knees upward', 'Keep a quick tempo'],
            },
            {
              'exerciseId': 'mobility-1',
              'name': 'Hip Stretch',
              'bodyParts': ['hips'],
              'targetMuscles': ['glutes'],
              'equipments': ['body weight'],
              'instructions': ['Move gently'],
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(
            path: ApiConstants.exerciseDbExercisesUrl,
          ),
        ),
      );

      final result = await sut.fetchExercisesByType('cardio');

      expect(result, hasLength(1));
      expect(result.first.sessionType, 'cardio');
      expect(result.first.durationMinutes, inInclusiveRange(2, 10));
      expect(result.first.indoorCompatible, isTrue);
    },
  );

  test('6.1-UNIT-005: DioException maps to ServerException', () async {
    when(mockDio.get(ApiConstants.exerciseDbExercisesUrl)).thenThrow(
      DioException(
        requestOptions: RequestOptions(
          path: ApiConstants.exerciseDbExercisesUrl,
        ),
        message: 'timeout',
      ),
    );

    expect(
      () => sut.fetchExercisesByType('cardio'),
      throwsA(isA<ServerException>()),
    );
  });

  test(
    '6.1-UNIT-006: malformed or unmappable records are filtered predictably',
    () async {
      when(mockDio.get(ApiConstants.exerciseDbExercisesUrl)).thenAnswer(
        (_) async => Response(
          data: [
            {
              'exerciseId': 'bad-1',
              'name': 'Unknown Machine',
              'bodyParts': ['arms'],
              'targetMuscles': ['biceps'],
              'equipments': ['machine'],
              'instructions': ['Do the movement'],
            },
            {
              'exerciseId': 'good-1',
              'name': 'Cat Cow Stretch',
              'bodyParts': ['back'],
              'targetMuscles': ['spine'],
              'equipments': ['body weight'],
              'instructions': ['Arch the back', 'Round the spine'],
            },
            {'exerciseId': 'bad-2', 'name': 'No Steps', 'instructions': []},
          ],
          statusCode: 200,
          requestOptions: RequestOptions(
            path: ApiConstants.exerciseDbExercisesUrl,
          ),
        ),
      );

      final result = await sut.fetchExercisesByType('mobility');

      expect(result, hasLength(1));
      expect(result.first.id, 'good-1');
    },
  );
}
