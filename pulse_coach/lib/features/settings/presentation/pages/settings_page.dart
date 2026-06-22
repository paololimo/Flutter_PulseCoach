import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/widgets/sign_in_sheet.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_state.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
                // Account section — added by Story 16.2
                Text(
                  l10n.accountSectionTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    return authState.maybeWhen(
                      authenticated: (user) => ListTile(
                        contentPadding: const EdgeInsets.all(0),
                        title: Text(user.email ?? l10n.accountSectionTitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRouter.account),
                      ),
                      orElse: () => ListTile(
                        contentPadding: const EdgeInsets.all(0),
                        title: Text(l10n.signInTileLabel),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => BlocProvider.value(
                            value: context.read<AuthBloc>(),
                            child: const SignInSheet(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Abbonamento',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                BlocBuilder<SubscriptionBloc, SubscriptionState>(
                  builder: (context, subState) {
                    final isPro = subState.maybeWhen(
                      loaded: (tier) => tier == SubscriptionTier.pro,
                      orElse: () => false,
                    );
                    if (isPro) {
                      return ListTile(
                        contentPadding: const EdgeInsets.all(0),
                        title: const Text('Gestisci abbonamento'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchSubscriptionManagement(context),
                      );
                    }
                    return ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      title: const Text('Scopri Pro'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRouter.paywall),
                    );
                  },
                ),
                const SizedBox(height: 24),
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
                  contentPadding: const EdgeInsets.all(0),
                  title: Text(l10n.deviceSettingsNavTile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRouter.deviceSettings),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.dataExportNavSection,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  title: Text(l10n.dataExportTile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExportSheet(context),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _launchSubscriptionManagement(BuildContext context) async {
  final url = Platform.isAndroid
      ? Uri.parse('https://play.google.com/store/account/subscriptions')
      : Uri.parse('https://apps.apple.com/account/subscriptions');
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched =
        await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire la gestione abbonamento.'),
        ),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Impossibile aprire la gestione abbonamento.'),
      ),
    );
  }
}

void _showExportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<DataExportCubit>(),
      child: const _ExportBottomSheet(),
    ),
  );
}

class _ExportBottomSheet extends StatelessWidget {
  const _ExportBottomSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<DataExportCubit, DataExportState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.dataExportError)),
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.dataExportSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (state.isExporting)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  OutlinedButton(
                    onPressed: () =>
                        context.read<DataExportCubit>().exportJson(),
                    child: Text(l10n.dataExportJson),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<DataExportCubit>().exportCsv(),
                    child: Text(l10n.dataExportCsv),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
