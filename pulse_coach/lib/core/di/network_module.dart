import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@module
abstract class NetworkModule {
  @singleton
  Connectivity get connectivity => Connectivity();

  /// Shared Dio instance — singleton to reuse connection pools.
  /// Configured with reasonable timeouts for Open-Meteo (free API, no SLA guarantee).
  @singleton
  Dio get dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );
}
