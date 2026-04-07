import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/utils/geolocator_wrapper.dart';

/// Returns city-level coordinates (rounded to 1 decimal place, ~11km precision).
/// Returns [LocationFailure] if permission is denied or location unavailable.
/// Never returns precise GPS coordinates — privacy constraint NFR8.
@injectable
class LocationService {
  LocationService(this._geolocator);

  final GeolocatorWrapper _geolocator;

  Future<Either<Failure, (double lat, double lon)>> getCityLevelCoordinates() async {
    try {
      final serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Left(LocationFailure('Location services are disabled'));
      }

      LocationPermission permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Left(LocationFailure('Location permission denied'));
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return Left(LocationFailure('Location permission permanently denied'));
      }

      final position = await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // city-level sufficient
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Round to 1 decimal place — ~11km precision, city-level (NFR8, FR35)
      final lat = _roundCityLevel(position.latitude);
      final lon = _roundCityLevel(position.longitude);
      return Right((lat, lon));
    } on LocationServiceDisabledException {
      return Left(LocationFailure('Location services are disabled'));
    } catch (e) {
      return Left(LocationFailure('Location unavailable: $e'));
    }
  }

  double _roundCityLevel(double coord) => (coord * 10).round() / 10;
}
