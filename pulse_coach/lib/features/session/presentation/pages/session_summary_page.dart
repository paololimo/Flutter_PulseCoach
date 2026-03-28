import 'package:flutter/material.dart';

class SessionSummaryPage extends StatelessWidget {
  const SessionSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: const Center(child: Text('Summary — Story 9.x')),
    );
  }
}
