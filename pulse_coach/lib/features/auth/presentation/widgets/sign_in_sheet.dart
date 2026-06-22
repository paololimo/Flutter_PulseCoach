import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignInSheet extends StatefulWidget {
  const SignInSheet({super.key});

  @override
  State<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<SignInSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUpMode = false;
  bool _ageConfirmed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthUnconfirmed) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.signInSheetTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Chiudi',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state is AuthUnconfirmed) ...[
                    Text(
                      l10n.emailUnconfirmedMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // 1. Sign in with Apple (black button, HIG-compliant)
                    Semantics(
                      label: l10n.signInWithAppleLabel,
                      button: true,
                      child: SignInWithAppleButton(
                        onPressed: isLoading
                            ? () {}
                            : () => context.read<AuthBloc>().add(
                                const AuthEvent.signInWithAppleRequested(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 2. Sign in with Google
                    Semantics(
                      label: l10n.signInWithGoogleLabel,
                      button: true,
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => context.read<AuthBloc>().add(
                                const AuthEvent.signInWithGoogleRequested(),
                              ),
                        child: Text(l10n.signInWithGoogleLabel),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 3. Email / password section header
                    Text(
                      l10n.signInWithEmailLabel,
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Email / password form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            label: l10n.emailLabel,
                            textField: true,
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: l10n.emailLabel,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? l10n.emailLabel
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: l10n.passwordLabel,
                            textField: true,
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: l10n.passwordLabel,
                              ),
                              obscureText: true,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? l10n.passwordLabel
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // NFR37: age ≥ 16 confirmation, shown only in sign-up mode
                          if (_isSignUpMode)
                            Semantics(
                              label: l10n.ageConfirmationLabel,
                              checked: _ageConfirmed,
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.ageConfirmationLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                value: _ageConfirmed,
                                onChanged: (v) =>
                                    setState(() => _ageConfirmed = v ?? false),
                              ),
                            ),
                          TextButton(
                            onPressed: () => setState(() {
                              _isSignUpMode = !_isSignUpMode;
                              _ageConfirmed = false;
                            }),
                            child: Text(
                              _isSignUpMode
                                  ? l10n.signInAction
                                  : l10n.signUpPrompt,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: _isSignUpMode
                                ? l10n.signUpAction
                                : l10n.signInAction,
                            button: true,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isSignUpMode
                                          ? l10n.signUpAction
                                          : l10n.signInAction,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Inline error area
                  if (state is AuthError) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.signInErrorGeneric,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // NFR37: block sign-up if age confirmation not checked
    if (_isSignUpMode && !_ageConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.ageConfirmationRequired),
        ),
      );
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isSignUpMode) {
      context.read<AuthBloc>().add(
        AuthEvent.signUpWithEmailRequested(email: email, password: password),
      );
    } else {
      context.read<AuthBloc>().add(
        AuthEvent.signInWithEmailRequested(email: email, password: password),
      );
    }
  }
}
