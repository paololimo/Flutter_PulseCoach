import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/backup_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class BackupSettingsWidget extends StatelessWidget {
  const BackupSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<BackupBloc, BackupState>(
      listener: (context, state) {
        if (state is BackupRestoreSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupRestoreSuccess)),
          );
        }
      },
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OptInToggle(state: state, l10n: l10n),
            if (state is BackupAwaitingPhraseAck) ...[
              const SizedBox(height: 16),
              _RecoveryPhraseCard(phrase: state.phrase, l10n: l10n),
            ],
            if (state is BackupEnabled || state is BackupComplete) ...[
              const SizedBox(height: 16),
              _BackupNowButton(state: state, l10n: l10n),
            ],
            if (state is BackupComplete) ...[
              const SizedBox(height: 8),
              Text(
                l10n.backupLastBackupLabel(
                  state.lastBackup.toLocal().toString().split('.').first,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (state is BackupQueued) ...[
              const SizedBox(height: 16),
              Semantics(
                label: l10n.backupQueuedMessage,
                child: Text(
                  l10n.backupQueuedMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _RestoreSection(l10n: l10n, isLoading: state is BackupLoading),
            if (state is BackupError) ...[
              const SizedBox(height: 16),
              Semantics(
                label: _errorMessage(state.failure, l10n),
                child: Text(
                  _errorMessage(state.failure, l10n),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _errorMessage(BackupFailure failure, AppLocalizations l10n) {
    if (failure is BackupDecryptionFailure) return l10n.backupErrorWrongPhrase;
    return l10n.backupErrorGeneric;
  }
}

class _OptInToggle extends StatelessWidget {
  const _OptInToggle({required this.state, required this.l10n});
  final BackupState state;
  final AppLocalizations l10n;

  bool get _isEnabled =>
      state is BackupEnabled ||
      state is BackupComplete ||
      state is BackupQueued ||
      state is BackupAwaitingPhraseAck;

  @override
  Widget build(BuildContext context) {
    final isLoading = state is BackupLoading;
    return Semantics(
      label: l10n.backupToggleLabel,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.backupToggleLabel),
        subtitle: Text(l10n.backupToggleDescription),
        value: _isEnabled,
        onChanged: isLoading
            ? null
            : (value) {
                final bloc = context.read<BackupBloc>();
                if (value) {
                  bloc.add(const BackupEvent.toggled());
                } else {
                  bloc.add(const BackupEvent.disabled());
                }
              },
      ),
    );
  }
}

class _RecoveryPhraseCard extends StatelessWidget {
  const _RecoveryPhraseCard({required this.phrase, required this.l10n});
  final String phrase;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupRecoveryPhraseTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.backupRecoveryPhraseInstruction),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    phrase,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Copia frase di recupero',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: phrase)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              label: l10n.backupPhraseAcknowledgeButton,
              button: true,
              child: FilledButton(
                onPressed: () => context
                    .read<BackupBloc>()
                    .add(const BackupEvent.phraseAcknowledged()),
                child: Text(l10n.backupPhraseAcknowledgeButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupNowButton extends StatelessWidget {
  const _BackupNowButton({required this.state, required this.l10n});
  final BackupState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isLoading = state is BackupLoading;
    return Semantics(
      label: l10n.backupNowButton,
      button: true,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () => context
                  .read<BackupBloc>()
                  .add(const BackupEvent.backupNowRequested()),
        child: Text(l10n.backupNowButton),
      ),
    );
  }
}

class _RestoreSection extends StatefulWidget {
  const _RestoreSection({required this.l10n, required this.isLoading});
  final AppLocalizations l10n;
  final bool isLoading;

  @override
  State<_RestoreSection> createState() => _RestoreSectionState();
}

class _RestoreSectionState extends State<_RestoreSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.l10n.backupRestoreTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.l10n.backupRestorePhraseHint,
          child: TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.l10n.backupRestorePhraseHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.l10n.backupRestoreButton,
          button: true,
          child: ElevatedButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    final phrase = _controller.text.trim();
                    if (phrase.isNotEmpty) {
                      context.read<BackupBloc>().add(
                        BackupEvent.restoreRequested(phrase: phrase),
                      );
                    }
                  },
            child: Text(widget.l10n.backupRestoreButton),
          ),
        ),
      ],
    );
  }
}
