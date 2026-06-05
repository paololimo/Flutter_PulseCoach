import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsPageTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.settingsThemeSection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsThemeDark),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsThemeSystem),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selected) =>
                    context.read<ThemeCubit>().setTheme(selected.first),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.deviceSettingsNavSection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.deviceSettingsNavTile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRouter.deviceSettings),
              ),
            ],
          ),
        );
      },
    );
  }
}
