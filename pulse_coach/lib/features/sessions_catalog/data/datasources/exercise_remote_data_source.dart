import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/constants/api_constants.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/sessions_catalog/data/models/exercise_model.dart';

@injectable
class ExerciseRemoteDataSource {
  ExerciseRemoteDataSource(this._dio);

  final Dio _dio;

  /// Fetch the full ExerciseDB catalog and map every record that can be
  /// safely converted into a PulseCoach exercise. ExerciseDB does not expose
  /// a per-category filter, so the catalog is fetched once and consumers
  /// filter by session type downstream.
  Future<List<ExerciseModel>> fetchAll() async {
    try {
      final response = await _dio.get(ApiConstants.exerciseDbExercisesUrl);
      final data = response.data;
      if (data is! List) {
        throw const ServerException('ExerciseDB returned a non-list payload');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(ExerciseModel.fromExerciseDbJson)
          .whereType<ExerciseModel>()
          .toList(growable: false);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException('ExerciseDB request failed: ${e.message}');
    } catch (e, st) {
      throw ServerException('Unexpected error fetching exercises: $e\n$st');
    }
  }

  /// Thin convenience wrapper around [fetchAll] that filters by session type.
  /// Prefer [fetchAll] when caching the entire catalog in a single round-trip.
  Future<List<ExerciseModel>> fetchExercisesByType(String sessionType) async {
    final all = await fetchAll();
    return all
        .where((exercise) => exercise.sessionType == sessionType)
        .toList(growable: false);
  }
}
