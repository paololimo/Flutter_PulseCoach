// [P1] LocationService unit tests
// Tests: city-level rounding, permission denied, service disabled, generic error
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/utils/geolocator_wrapper.dart';
import 'package:pulse_coach/core/utils/location_service.dart';

import 'location_service_test.mocks.dart';

@GenerateMocks([GeolocatorWrapper])
void main() {
  late MockGeolocatorWrapper mockGeolocator;
  late LocationService sut;

  /// Helper: create a minimal Position object for test use.
  Position makePosition(double lat, double lon) => Position(
    longitude: lon,
    latitude: lat,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 100.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  setUp(() {
    mockGeolocator = MockGeolocatorWrapper();
    sut = LocationService(mockGeolocator);
  });

  group('LocationService.getCityLevelCoordinates', () {
    test(
      '4.3-UNIT-001: returns Left(LocationFailure) when location services are disabled',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);

        final result = await sut.getCityLevelCoordinates();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocationFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      '4.3-UNIT-002: returns Left(LocationFailure) when permission denied after request',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        final result = await sut.getCityLevelCoordinates();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocationFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      '4.3-UNIT-003: returns Left(LocationFailure) when permission permanently denied',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);

        final result = await sut.getCityLevelCoordinates();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocationFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(mockGeolocator.requestPermission());
      },
    );

    test(
      '4.3-UNIT-008: returns Right when checkPermission denied but requestPermission grants whileInUse (first-launch flow)',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => makePosition(45.46, 9.19));

        final result = await sut.getCityLevelCoordinates();

        expect(result.isRight(), isTrue);
        final (lat, lon) = result.getOrElse(() => throw Exception());
        expect(lat, equals(45.5));
        expect(lon, equals(9.2));
      },
    );

    test(
      '4.3-UNIT-004: returns Right with rounded coordinates when permission granted (AC1)',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => makePosition(48.856, 2.352));

        final result = await sut.getCityLevelCoordinates();

        expect(result.isRight(), isTrue);
        final (lat, lon) = result.getOrElse(() => throw Exception());
        expect(lat, equals(48.9)); // 48.856 rounded to 1 decimal
        expect(lon, equals(2.4)); // 2.352 rounded to 1 decimal
      },
    );

    test(
      '4.3-UNIT-005: rounding is applied to negative coordinates (southern/western hemisphere)',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.always);
        when(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => makePosition(-33.869, -70.673));

        final result = await sut.getCityLevelCoordinates();

        final (lat, lon) = result.getOrElse(() => throw Exception());
        expect(lat, equals(-33.9)); // -33.869 rounded to 1 decimal
        expect(lon, equals(-70.7)); // -70.673 rounded to 1 decimal
      },
    );

    test(
      '4.3-UNIT-006: returns Left(LocationFailure) on generic exception from getCurrentPosition',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(Exception('GPS timeout'));

        final result = await sut.getCityLevelCoordinates();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<LocationFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      '4.3-UNIT-007: uses LocationAccuracy.low — city-level sufficient, no high-precision GPS (NFR8)',
      () async {
        when(
          mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => makePosition(45.46, 9.19));

        await sut.getCityLevelCoordinates();

        final captured =
            verify(
                  mockGeolocator.getCurrentPosition(
                    locationSettings: captureAnyNamed('locationSettings'),
                  ),
                ).captured.single
                as LocationSettings;
        expect(captured.accuracy, equals(LocationAccuracy.low));
      },
    );
  });
}
