import 'package:flutter/material.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const PulseCoachApp());
}
