import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

void main() {
  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            return MaterialApp(
              title: 'PulseCoach Wear',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF00C896),
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              home: PulseCoachWearHome(
                isAmbient: mode == WearMode.ambient,
                shape: shape,
              ),
            );
          },
        );
      },
    );
  }
}

class PulseCoachWearHome extends StatelessWidget {
  const PulseCoachWearHome({
    required this.isAmbient,
    required this.shape,
    super.key,
  });

  final bool isAmbient;
  final WearShape shape;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(shape == WearShape.round ? 32 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PulseCoach Wear',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isAmbient
                    ? null
                    : () => debugPrint('PulseCoach Wear button tapped'),
                child: const Text('Tap me'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
