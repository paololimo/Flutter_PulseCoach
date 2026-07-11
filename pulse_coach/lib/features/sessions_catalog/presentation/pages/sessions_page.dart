import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/widgets/session_catalog_card.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/widgets/session_catalog_detail_sheet.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key, this.cubit});

  final SessionsCatalogCubit? cubit;

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  late final SessionsCatalogCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? getIt<SessionsCatalogCubit>();
    if (_cubit.state is SessionsCatalogInitial) {
      _cubit.loadCatalog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionsCatalogCubit>.value(
      value: _cubit,
      child: const _SessionsCatalogView(),
    );
  }
}

class _SessionsCatalogView extends StatelessWidget {
  const _SessionsCatalogView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionsCatalogCubit, SessionsCatalogState>(
      builder: (context, state) {
        return switch (state) {
          SessionsCatalogInitial() ||
          SessionsCatalogLoading() => const _SessionsCatalogSkeleton(),
          SessionsCatalogLoaded() => _LoadedCatalog(state: state),
          SessionsCatalogError() => const _CatalogError(),
        };
      },
    );
  }
}

/// Width (in logical pixels) at which the catalog switches from a single
/// scrolling column (phone / tablet portrait) to a master-detail split
/// (tablet landscape). Sits above the AppShell navigation-rail breakpoint
/// (600) so the split only engages when the content area has real room —
/// which makes it double as a rotation-adaptive layout on tablets.
const double _masterDetailBreakpoint = 720;

class _LoadedCatalog extends StatefulWidget {
  const _LoadedCatalog({required this.state});

  final SessionsCatalogLoaded state;

  @override
  State<_LoadedCatalog> createState() => _LoadedCatalogState();
}

class _LoadedCatalogState extends State<_LoadedCatalog> {
  Exercise? _selected;

  void _openModalDetail(BuildContext context, Exercise exercise) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SessionCatalogDetailSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _masterDetailBreakpoint) {
          return _CatalogList(
            state: widget.state,
            onExerciseTap: (exercise) => _openModalDetail(context, exercise),
          );
        }

        return _MasterDetailCatalog(
          state: widget.state,
          selected: _selected,
          onExerciseTap: (exercise) => setState(() => _selected = exercise),
        );
      },
    );
  }
}

/// Tablet master-detail layout: the browsable list on the left, the detail of
/// the currently selected session (or an empty-state) persistently on the right.
class _MasterDetailCatalog extends StatelessWidget {
  const _MasterDetailCatalog({
    required this.state,
    required this.selected,
    required this.onExerciseTap,
  });

  final SessionsCatalogLoaded state;
  final Exercise? selected;
  final ValueChanged<Exercise> onExerciseTap;

  @override
  Widget build(BuildContext context) {
    final selectedExercise = selected;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: _CatalogList(
            state: state,
            onExerciseTap: onExerciseTap,
            selectedId: selectedExercise?.id,
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: selectedExercise == null
              ? const SessionCatalogDetailPlaceholder()
              : SessionCatalogDetailBody(
                  key: ValueKey(selectedExercise.id),
                  exercise: selectedExercise,
                ),
        ),
      ],
    );
  }
}

/// The scrollable catalog itself (header + filters + category sections). Shared
/// by the phone single-column layout and the tablet master pane.
class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.state,
    required this.onExerciseTap,
    this.selectedId,
  });

  final SessionsCatalogLoaded state;
  final ValueChanged<Exercise> onExerciseTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;
    final categories = state.selectedCategory == SessionsCatalogCategory.all
        ? sessionsCatalogDisplayCategories
        : <SessionsCatalogCategory>[state.selectedCategory];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.sessionsPageTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: pulseTheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _CategoryFilters(
                  selectedCategory: state.selectedCategory,
                  onSelected: context
                      .read<SessionsCatalogCubit>()
                      .selectCategory,
                ),
              ],
            ),
          ),
        ),
        for (final category in categories)
          _CategorySection(
            category: category,
            exercises: state.groupedExercises[category] ?? const [],
            degraded: state.degradedCategories.containsKey(category),
            onExerciseTap: onExerciseTap,
            selectedId: selectedId,
          ),
      ],
    );
  }
}

class _CategoryFilters extends StatefulWidget {
  const _CategoryFilters({
    required this.selectedCategory,
    required this.onSelected,
  });

  final SessionsCatalogCategory selectedCategory;
  final ValueChanged<SessionsCatalogCategory> onSelected;

  @override
  State<_CategoryFilters> createState() => _CategoryFiltersState();
}

class _CategoryFiltersState extends State<_CategoryFilters> {
  late final Map<SessionsCatalogCategory, GlobalKey> _chipKeys = {
    for (final category in SessionsCatalogCategory.values)
      category: GlobalKey(),
  };

  @override
  void didUpdateWidget(covariant _CategoryFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _ensureSelectedChipVisible();
    }
  }

  void _ensureSelectedChipVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chipContext = _chipKeys[widget.selectedCategory]?.currentContext;
      if (chipContext == null) return;

      Scrollable.ensureVisible(
        chipContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in SessionsCatalogCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: _chipKeys[category],
                label: Text(
                  category.localizedLabel(AppLocalizations.of(context)!),
                ),
                selected: widget.selectedCategory == category,
                onSelected: (_) => widget.onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.exercises,
    required this.degraded,
    required this.onExerciseTap,
    this.selectedId,
  });

  final SessionsCatalogCategory category;
  final List<Exercise> exercises;
  final bool degraded;
  final ValueChanged<Exercise> onExerciseTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final categoryName = category.localizedLabel(l10n);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            categoryName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: pulseTheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                degraded
                    ? l10n.catalogUnavailable(categoryName)
                    : l10n.catalogEmpty(categoryName.toLowerCase()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final exercise in exercises)
              SessionCatalogCard(
                key: ValueKey(exercise.id),
                exercise: exercise,
                selected: exercise.id == selectedId,
                onTap: () => onExerciseTap(exercise),
              ),
        ]),
      ),
    );
  }
}

class _SessionsCatalogSkeleton extends StatelessWidget {
  const _SessionsCatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;

    return Shimmer.fromColors(
      baseColor: pulseTheme.surfaceContainer,
      highlightColor: pulseTheme.surfaceContainerHigh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          const _SkeletonBlock(width: 128, height: 32),
          const SizedBox(height: 20),
          const Row(
            children: [
              _SkeletonBlock(width: 64, height: 36),
              SizedBox(width: 8),
              _SkeletonBlock(width: 92, height: 36),
              SizedBox(width: 8),
              _SkeletonBlock(width: 76, height: 36),
            ],
          ),
          const SizedBox(height: 28),
          for (var section = 0; section < 3; section++) ...[
            const _SkeletonBlock(width: 112, height: 24),
            const SizedBox(height: 12),
            const _SkeletonBlock(width: double.infinity, height: 104),
            const SizedBox(height: 12),
            const _SkeletonBlock(width: double.infinity, height: 104),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: pulseTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Sessions are unavailable right now.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: pulseTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
