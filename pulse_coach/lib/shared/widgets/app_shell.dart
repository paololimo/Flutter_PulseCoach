import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    AppRouter.sessions,
    AppRouter.today,
    AppRouter.progress,
  ];

  int _currentIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerButton(),
        title: const Text('PulseCoach'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.surfaceContainer),
              child: const Text('PulseCoach'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.privacy);
              },
            ),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Debug'),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(location),
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.onSurfaceVariant,
        onTap: (index) => context.go(_tabs[index]),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Sessions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
