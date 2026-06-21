import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSectionTitle)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final email = state is AuthAuthenticated ? state.user.email : null;
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
    );
  }
}
