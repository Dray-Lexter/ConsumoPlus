import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

class UtilityUpdateButton extends StatelessWidget {
  const UtilityUpdateButton({
    required this.utilityType,
    required this.busy,
    required this.onPressed,
    required this.label,
    this.busyLabel = 'Actualizando...',
    super.key,
  });

  final UtilityType utilityType;
  final bool busy;
  final VoidCallback onPressed;
  final String label;
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    final visibleLabel = busy ? busyLabel : label;
    return Semantics(
      button: true,
      enabled: !busy,
      label: '${AppCopy.utilityName(utilityType)}: $visibleLabel',
      excludeSemantics: true,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: AppSpacing.md,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
        label: Text(visibleLabel),
      ),
    );
  }
}
