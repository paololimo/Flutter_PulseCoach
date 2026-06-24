import 'package:flutter/material.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

enum FriendRowVariant { searchResult, receivedRequest, sentRequest, friend }

class FriendRow extends StatelessWidget {
  final String displayHandle;
  final FriendRowVariant variant;
  final bool requestSent;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const FriendRow({
    super.key,
    required this.displayHandle,
    required this.variant,
    this.requestSent = false,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      title: Text(
        '@$displayHandle',
        maxLines: 2,
        overflow: TextOverflow.visible,
      ),
      trailing: _buildTrailing(context),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (variant) {
      case FriendRowVariant.searchResult:
        if (requestSent) {
          return Text(
            l10n.friendsRequestSent,
            style: const TextStyle(color: Colors.grey),
          );
        }
        return SizedBox(
          height: 48,
          child: TextButton(
            onPressed: onPrimaryAction,
            child: Text(l10n.friendsAddButton),
          ),
        );
      case FriendRowVariant.receivedRequest:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onPrimaryAction,
                child: Text(l10n.friendsAcceptButton),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: onSecondaryAction,
                child: Text(l10n.friendsDeclineButton),
              ),
            ),
          ],
        );
      case FriendRowVariant.sentRequest:
        return SizedBox(
          height: 48,
          child: Center(
            child: Text(
              l10n.friendsPendingWaiting,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      case FriendRowVariant.friend:
        return SizedBox(
          height: 48,
          child: TextButton(
            onPressed: onPrimaryAction,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.friendsRemoveButton),
          ),
        );
    }
  }
}
