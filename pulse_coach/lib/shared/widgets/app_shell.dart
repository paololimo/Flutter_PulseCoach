import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerButton(),
        title: const Text('PulseCoach'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(color: theme.surfaceContainer),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Text(
                    'PulseCoach',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(l10n.drawerProfile),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.drawerSettings),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(l10n.drawerPrivacy),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.privacy);
              },
            ),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: Text(l10n.drawerDebug),
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.fitness_center),
            label: l10n.navTabSessions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.today),
            label: l10n.navTabToday,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.navTabProgress,
          ),
        ],
      ),
    );
  }
}
