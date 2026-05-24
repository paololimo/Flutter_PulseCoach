import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';

typedef RpeSemanticLabelBuilder = String Function(int value);

class RPEInputWidget extends StatelessWidget {
  final int? selectedRpe;
  final ValueChanged<int> onRpeSelected;
  final RpeSemanticLabelBuilder? semanticLabelBuilder;

  const RPEInputWidget({
    required this.onRpeSelected,
    this.selectedRpe,
    this.semanticLabelBuilder,
    super.key,
  });

  // Spec UX-DR9: 44dp visible diameter inside a ≥48dp effective hit area.
  static const double _minVisibleDiameter = 44;
  static const double _minHitDiameter = 48;
  static const double _maxHitDiameter = 56;
  static const double _interButtonGap = 4;
  static const int _buttonCount = 10;

  // Width a single row of 10 hit cells + 9 gaps would need at the 48dp floor.
  // Real phones are ~360dp wide (minus page padding), well below this — so the
  // single-row spec layout only fits on wider surfaces (tablets / landscape).
  static const double _singleRowWidth =
      _minHitDiameter * _buttonCount + _interButtonGap * (_buttonCount - 1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _singleRowWidth;
        // UX-DR9 asks for a single row of 10, but 10×48dp + gaps (516dp) cannot
        // fit a typical phone without either clipping targets off-screen or
        // shrinking them below the 48dp accessibility floor. When the surface
        // is too narrow we degrade to two rows of five: every target keeps its
        // ≥48dp hit area (NFR24) and all ten stay on-screen.
        final fitsSingleRow = available >= _singleRowWidth;
        final perRow = fitsSingleRow ? _buttonCount : _buttonCount ~/ 2;
        final totalGap = _interButtonGap * (perRow - 1);
        final perButton = ((available - totalGap) / perRow).clamp(
          _minHitDiameter,
          _maxHitDiameter,
        );
        // Visible circle shrinks proportionally if the hit area is squeezed
        // below its 48dp ideal, but never below the 44dp spec minimum.
        final visibleDiameter = (perButton - 4).clamp(
          _minVisibleDiameter,
          _maxHitDiameter,
        );

        if (fitsSingleRow) {
          return _buildRow(1, _buttonCount, perButton, visibleDiameter);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow(1, perRow, perButton, visibleDiameter),
            const SizedBox(height: _interButtonGap * 2),
            _buildRow(perRow + 1, _buttonCount, perButton, visibleDiameter),
          ],
        );
      },
    );
  }

  Widget _buildRow(
    int start,
    int end,
    double hitDiameter,
    double visibleDiameter,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        for (var value = start; value <= end; value++) ...[
          if (value > start) const SizedBox(width: _interButtonGap),
          _RpeButton(
            value: value,
            selected: selectedRpe == value,
            disabled: selectedRpe != null,
            hitDiameter: hitDiameter,
            visibleDiameter: visibleDiameter,
            semanticLabel: semanticLabelBuilder?.call(value) ?? 'RPE $value',
            onTap: () => onRpeSelected(value),
          ),
        ],
      ],
    );
  }
}

class _RpeButton extends StatelessWidget {
  final int value;
  final bool selected;
  final bool disabled;
  final double hitDiameter;
  final double visibleDiameter;
  final String semanticLabel;
  final VoidCallback onTap;

  const _RpeButton({
    required this.value,
    required this.selected,
    required this.disabled,
    required this.hitDiameter,
    required this.visibleDiameter,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 150);
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final background = selected
        ? theme.colorScheme.primary
        : Colors.transparent;
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      label: semanticLabel,
      child: SizedBox(
        width: hitDiameter,
        height: hitDiameter,
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: disabled ? null : onTap,
            child: AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: duration,
              curve: Curves.easeOut,
              child: AnimatedContainer(
                width: visibleDiameter,
                height: visibleDiameter,
                duration: duration,
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: AppTextStyles.rpeNumbers.copyWith(color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
