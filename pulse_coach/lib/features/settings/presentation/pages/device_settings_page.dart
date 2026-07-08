import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({super.key});

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DeviceSettingsCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceSettingsPageTitle)),
      body: BlocBuilder<DeviceSettingsCubit, DeviceSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const _DeviceSettingsSkeleton();
          }

          return RefreshIndicator(
            onRefresh: context.read<DeviceSettingsCubit>().load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(l10n.deviceSettingsHealthSection),
                _HealthRow(state: state),
                const SizedBox(height: 24),
                _SectionHeader(l10n.deviceSettingsWearSection),
                _WearRow(state: state),
                const SizedBox(height: 24),
                _SectionHeader(l10n.deviceSettingsSyncSection),
                _SyncRow(state: state),
                const SizedBox(height: 24),
                _SectionHeader(l10n.deviceSettingsCacheSection),
                _CacheRow(
                  label: l10n.deviceSettingsCacheWeather,
                  date: state.weatherCachedAt,
                ),
                _CacheRow(
                  label: l10n.deviceSettingsCacheExercise,
                  date: state.exerciseCachedAt,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeviceSettingsSkeleton extends StatelessWidget {
  const _DeviceSettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerPlaceholder(height: 24),
          SizedBox(height: 12),
          ShimmerPlaceholder(height: 72),
          SizedBox(height: 24),
          ShimmerPlaceholder(height: 24),
          SizedBox(height: 12),
          ShimmerPlaceholder(height: 72),
          SizedBox(height: 24),
          ShimmerPlaceholder(height: 24),
          SizedBox(height: 12),
          ShimmerPlaceholder(height: 96),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final granted = state.healthPermissionGranted;
    final colorScheme = Theme.of(context).colorScheme;
    final icon = granted == true
        ? Icons.check_circle_outline
        : granted == false
        ? Icons.cancel_outlined
        : Icons.help_outline;
    final color = granted == true
        ? colorScheme.primary
        : granted == false
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;
    final label = granted == true
        ? l10n.deviceSettingsHealthGranted
        : granted == false
        ? l10n.deviceSettingsHealthDenied
        : l10n.deviceSettingsHealthUnknown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(label),
        ),
        if (granted != true)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: context
                      .read<DeviceSettingsCubit>()
                      .requestHealthPermission,
                  child: Text(l10n.deviceSettingsHealthReRequest),
                ),
                OutlinedButton(
                  onPressed: context
                      .read<DeviceSettingsCubit>()
                      .openHealthConnectSettings,
                  child: Text(l10n.deviceSettingsHealthOpenSettings),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WearRow extends StatelessWidget {
  const _WearRow({required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connected = state.isWearConnected == true;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        connected ? Icons.watch : Icons.watch_off,
        color: connected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        connected
            ? l10n.deviceSettingsWearConnected
            : l10n.deviceSettingsWearDisconnected,
      ),
    );
  }
}

class _SyncRow extends StatelessWidget {
  const _SyncRow({required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pendingText = state.pendingSyncCount == 0
        ? l10n.deviceSettingsSyncNone
        : l10n.deviceSettingsSyncPending(state.pendingSyncCount);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(pendingText),
      trailing: state.pendingSyncCount > 0 && state.isOnline
          ? ElevatedButton(
              onPressed: context.read<DeviceSettingsCubit>().syncNow,
              child: Text(l10n.deviceSettingsSyncNow),
            )
          : null,
    );
  }
}

class _CacheRow extends StatelessWidget {
  const _CacheRow({required this.label, required this.date});

  final String label;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedDate = date == null
        ? l10n.deviceSettingsCacheNone
        : DateFormat('dd/MM/yyyy HH:mm').format(date!.toLocal());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(formattedDate),
    );
  }
}
