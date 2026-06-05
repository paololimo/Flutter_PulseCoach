import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pulse_coach/features/settings/data/models/ai_decision_record.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class AiDecisionLogPage extends StatelessWidget {
  const AiDecisionLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiDecisionLogTitle)),
      body: BlocBuilder<AiDecisionLogCubit, AiDecisionLogState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.decisions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.aiDecisionLogEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.decisions.length,
            itemBuilder: (context, index) =>
                _DecisionTile(record: state.decisions[index]),
          );
        },
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({required this.record});

  final AiDecisionRecord record;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy HH:mm').format(record.decidedAt);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(dateText),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_humanizedArmKey(record.armKey)),
          const Text('StateVector non disponibile'),
        ],
      ),
      trailing: Chip(label: Text('RPE ${record.rpeValue}')),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _DecisionDetails(record: record),
        ),
      ],
    );
  }
}

class _DecisionDetails extends StatelessWidget {
  const _DecisionDetails({required this.record});

  final AiDecisionRecord record;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('decidedAt', record.decidedAt.toIso8601String()),
      MapEntry('armKey', record.armKey),
      MapEntry('rpeValue', record.rpeValue.toString()),
      const MapEntry('stateVector', 'StateVector non disponibile'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows
          .map((row) => _DetailRow(label: row.key, value: row.value))
          .toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _humanizedArmKey(String armKey) => switch (armKey) {
  'mobility_low' => 'Mobilità / Bassa',
  'mobility_medium' => 'Mobilità / Media',
  'mobility_high' => 'Mobilità / Alta',
  'cardio_low' => 'Cardio / Bassa',
  'cardio_medium' => 'Cardio / Media',
  'cardio_high' => 'Cardio / Alta',
  'breathing_low' => 'Respirazione / Bassa',
  'breathing_medium' => 'Respirazione / Media',
  'breathing_high' => 'Respirazione / Alta',
  _ => 'Dati non disponibili',
};
