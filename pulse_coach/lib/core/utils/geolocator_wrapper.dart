import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

/// Abstract wrapper for Geolocator static methods — enables unit testing.
/// Wraps the three static calls used by LocationService.
abstract class GeolocatorWrapper {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition({LocationSettings? locationSettings});
}

@Injectable(as: GeolocatorWrapper)
class GeolocatorWrapperImpl implements GeolocatorWrapper {
  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      Geolocator.getCurrentPosition(locationSettings: locationSettings);
}
