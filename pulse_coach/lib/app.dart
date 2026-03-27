import 'package:flutter/material.dart';

class PulseCoachApp extends StatelessWidget {
  const PulseCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseCoach',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('PulseCoach')),
      ),
    );
  }
}
