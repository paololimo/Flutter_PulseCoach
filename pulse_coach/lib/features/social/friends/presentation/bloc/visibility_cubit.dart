import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

/// UI-only cubit holding the currently selected visibility tier
/// before (or immediately after) a PATCH is sent via SocialProfileBloc.
@injectable
class VisibilityCubit extends Cubit<VisibilityTier> {
  VisibilityCubit() : super(VisibilityTier.private);

  void select(VisibilityTier tier) => emit(tier);
}
