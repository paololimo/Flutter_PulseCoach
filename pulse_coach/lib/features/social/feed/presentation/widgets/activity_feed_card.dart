import 'package:flutter/material.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class ActivityFeedCard extends StatefulWidget {
  final FeedEntry entry;
  final bool isOwn;
  final bool isReacting;
  final VoidCallback onReact;
  final VoidCallback? onRevoke;

  const ActivityFeedCard({
    super.key,
    required this.entry,
    required this.isOwn,
    required this.isReacting,
    required this.onReact,
    this.onRevoke,
  });

  @override
  State<ActivityFeedCard> createState() => _ActivityFeedCardState();
}

class _ActivityFeedCardState extends State<ActivityFeedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(_scaleController);
  }

  @override
  void didUpdateWidget(ActivityFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReacting && !oldWidget.isReacting) {
      _scaleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionIcon = _iconForSessionType(widget.entry.sessionType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(sessionIcon, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${widget.entry.ownerHandle}',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.visible, // UX-DR33: wraps, never truncates
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.entry.durationMinutes} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    _relativeTime(l10n, widget.entry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Reaction tap target — NO count shown (UX-DR27/31)
            if (!widget.isOwn)
              Semantics(
                label: l10n.feedReactionButtonLabel,
                button: true,
                child: GestureDetector(
                  onTap: widget.onReact,
                  child: SizedBox(
                    width: 48, // UX-DR33: ≥ 48dp touch target
                    height: 48,
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: const Icon(Icons.favorite_border, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            // Revoke button — only on own entries
            if (widget.isOwn)
              Semantics(
                label: l10n.feedRevokeButtonLabel,
                button: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: l10n.feedRevokeButtonLabel,
                    onPressed: widget.onRevoke,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForSessionType(String type) {
    return switch (type) {
      'mobility' => Icons.self_improvement,
      'cardio' => Icons.directions_run,
      'breathing' => Icons.air,
      _ => Icons.fitness_center,
    };
  }

  String _relativeTime(AppLocalizations l10n, DateTime createdAt) {
    var diff = DateTime.now().toUtc().difference(createdAt.toUtc());
    // Clamp clock-skew / future timestamps to 0 so we never render "-3 min fa".
    if (diff.isNegative) diff = Duration.zero;
    if (diff.inMinutes < 60) return l10n.feedRelativeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.feedRelativeHours(diff.inHours);
    return l10n.feedRelativeDays(diff.inDays);
  }
}
