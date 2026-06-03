import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

class RestDisplayPage extends StatelessWidget {
  const RestDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(shape == WearShape.round ? 40 : 24),
              child: Center(
                child: Text(
                  'REST',
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
