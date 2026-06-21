import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/export_data_cubit.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSectionTitle)),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (_, current) => current is AuthUnauthenticated,
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                context.go(AppRouter.today);
              }
            },
          ),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (_, current) => current is AuthError,
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.failure.message)),
                );
              }
            },
          ),
          BlocListener<ExportDataCubit, ExportDataState>(
            listener: (context, state) {
              if (state is ExportDataSuccess) {
                Share.share(state.json, subject: l10n.exportDataShareSubject);
              } else if (state is ExportDataError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.failure.message)),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final email =
                state is AuthAuthenticated ? state.user.email : null;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (email != null)
                  Semantics(
                    label: 'Account: $email',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(email),
                      leading: const Icon(Icons.person),
                    ),
                  ),
                if (email != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    label: l10n.backupTileLabel,
                    button: true,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.backupTileLabel),
                      leading: const Icon(Icons.backup),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRouter.backup),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: l10n.exportDataTileLabel,
                    button: true,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.exportDataTileLabel),
                      leading: const Icon(Icons.download),
                      onTap: () =>
                          context.read<ExportDataCubit>().exportData(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: l10n.deleteAccountTileLabel,
                    button: true,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.deleteAccountTileLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      leading: Icon(
                        Icons.delete_forever,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onTap: () =>
                          _showDeleteConfirmationDialog(context, l10n),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Semantics(
                  label: l10n.signOutAction,
                  button: true,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.signOutAction),
                    leading: const Icon(Icons.logout),
                    onTap: () => context
                        .read<AuthBloc>()
                        .add(const AuthEvent.signOutRequested()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.deleteAccountCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<AuthBloc>()
                  .add(const AuthEvent.accountDeletionRequested());
            },
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );
  }
}
