import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SocialProfileBloc>(
      create: (_) => getIt<SocialProfileBloc>()..add(const SocialProfileLoaded()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.qrScreenTitle),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: BlocBuilder<SocialProfileBloc, SocialProfileState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context)!;
            return state.maybeWhen(
              loaded: (profile) {
                final handle = profile.displayHandle;
                if (handle == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.qrScreenNoHandle),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.push(AppRouter.account),
                          child: Text(l10n.qrGoToAccountLink),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: '@$handle',
                        version: QrVersions.auto,
                        size: 240,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '@$handle',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.qrScreenHelper,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const Center(
                child: SizedBox.square(
                  dimension: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
