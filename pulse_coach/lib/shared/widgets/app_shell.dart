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
    AppRouter.social,
  ];

  int _currentIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _TabletScaffold(
            currentIndex: currentIndex,
            onTabSelected: (index) => context.go(_tabs[index]),
            child: child,
          );
        }

        return _PhoneScaffold(
          currentIndex: currentIndex,
          onTabSelected: (index) => context.go(_tabs[index]),
          child: child,
        );
      },
    );
  }
}

class _PhoneScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget child;

  const _PhoneScaffold({
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const _AppDrawer(),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.onSurfaceVariant,
        onTap: onTabSelected,
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
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: l10n.navTabSocial,
          ),
        ],
      ),
    );
  }
}

class _TabletScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget child;

  const _TabletScaffold({
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const _AppDrawer(),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTabSelected,
            labelType: NavigationRailLabelType.all,
            minWidth: 80,
            selectedIconTheme: IconThemeData(color: theme.primaryColor),
            unselectedIconTheme: IconThemeData(color: theme.onSurfaceVariant),
            selectedLabelTextStyle: TextStyle(color: theme.primaryColor),
            unselectedLabelTextStyle: TextStyle(color: theme.onSurfaceVariant),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.fitness_center),
                label: Text(l10n.navTabSessions),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.today),
                label: Text(l10n.navTabToday),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart),
                label: Text(l10n.navTabProgress),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people),
                label: Text(l10n.navTabSocial),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

PreferredSizeWidget _buildAppBar() {
  return AppBar(leading: const DrawerButton(), title: const Text('PulseCoach'));
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
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
              context.push(AppRouter.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.drawerSettings),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.drawerPrivacy),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.privacy);
            },
          ),
          if (kDebugMode) ...[
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: Text(l10n.drawerDebug),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: Text(l10n.aiDecisionLogDrawerTile),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.aiDecisionLog);
              },
            ),
          ],
        ],
      ),
    );
  }
}
