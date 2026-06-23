import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class HandleSetupSection extends StatefulWidget {
  const HandleSetupSection({super.key});

  @override
  State<HandleSetupSection> createState() => _HandleSetupSectionState();
}

class _HandleSetupSectionState extends State<HandleSetupSection> {
  static final _handlePattern = RegExp(r'^[a-z0-9_]{3,20}$');

  final _controller = TextEditingController();
  String? _inlineError;
  // True only while a handle submission dispatched from this widget is in
  // flight — guards the success snackbar so it fires for an actual save, not
  // for an initial load or a visibility-tier change on the shared bloc.
  bool _submitting = false;
  // True once the user taps "Skip for now" — collapses the section for the
  // rest of the session (no bloc event, matching the spec).
  bool _skipped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SocialProfileBloc, SocialProfileState>(
      listener: (context, state) {
        state.whenOrNull(
          error: (failure) {
            _submitting = false;
            if (failure is SocialHandleTakenFailure) {
              setState(() => _inlineError = l10n.handleDuplicateError);
            } else {
              setState(() => _inlineError = null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.socialGenericError)),
              );
            }
          },
          loaded: (_) {
            setState(() => _inlineError = null);
            if (_submitting) {
              _submitting = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.handleUpdateSuccess)),
              );
            }
          },
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => _formOrEmpty(context, l10n),
          loading: () => _buildShimmer(),
          loaded: (profile) {
            if (profile.displayHandle != null) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alternate_email),
                title: Text('@${profile.displayHandle}'),
              );
            }
            return _formOrEmpty(context, l10n);
          },
          error: (_) => _formOrEmpty(context, l10n),
        );
      },
    );
  }

  Widget _formOrEmpty(BuildContext context, AppLocalizations l10n) {
    if (_skipped) return const SizedBox.shrink();
    return _buildForm(context, l10n);
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.handleSetupTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.handleSetupPlaceholder,
            errorText: _inlineError,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _onSave(context, l10n),
              child: Text(l10n.handleSetupSave),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => setState(() => _skipped = true),
              child: Text(l10n.handleSetupSkip),
            ),
          ],
        ),
      ],
    );
  }

  void _onSave(BuildContext context, AppLocalizations l10n) {
    final handle = _controller.text.trim().toLowerCase();
    if (!_handlePattern.hasMatch(handle)) {
      setState(() => _inlineError = l10n.handleInvalidError);
      return;
    }
    setState(() {
      _inlineError = null;
      _submitting = true;
    });
    context.read<SocialProfileBloc>().add(HandleUpdateRequested(handle));
  }
}
