import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/backup_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/widgets/backup_settings.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupSectionTitle)),
      body: BlocProvider<BackupBloc>(
        create: (_) => getIt<BackupBloc>()..add(const BackupEvent.started()),
        child: const BackupSettingsWidget(),
      ),
    );
  }
}
