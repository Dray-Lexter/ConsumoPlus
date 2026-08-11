import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

enum UtilityMessageKind { success, error, warning, information }

class UtilityMessageBanner extends StatelessWidget {
  const UtilityMessageBanner({
    required this.utilityType,
    required this.kind,
    required this.message,
    this.title,
    super.key,
  });

  final UtilityType utilityType;
  final UtilityMessageKind kind;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(utilityType, kind);
    final semanticLabel = [
      if (title != null && title!.isNotEmpty) title!,
      message,
    ].join(' ');
    return Semantics(
      container: true,
      liveRegion:
          kind == UtilityMessageKind.success ||
          kind == UtilityMessageKind.error,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: visual.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(color: visual.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(visual.icon, color: visual.foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null && title!.isNotEmpty) ...[
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: visual.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: visual.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _MessageVisual _visualFor(
    UtilityType utilityType,
    UtilityMessageKind kind,
  ) {
    final utility = utilityType.visual;
    return switch (kind) {
      UtilityMessageKind.success => _MessageVisual(
        icon: Icons.check_circle_outline_rounded,
        foreground: utility.accent,
        background: utility.container,
        border: utility.accent,
      ),
      UtilityMessageKind.error => const _MessageVisual(
        icon: Icons.error_outline_rounded,
        foreground: AppColors.error,
        background: AppColors.errorContainer,
        border: AppColors.error,
      ),
      UtilityMessageKind.warning => const _MessageVisual(
        icon: Icons.shield_outlined,
        foreground: AppColors.warningInk,
        background: AppColors.warningContainer,
        border: AppColors.warningOutline,
      ),
      UtilityMessageKind.information => const _MessageVisual(
        icon: Icons.info_outline_rounded,
        foreground: AppColors.mutedInk,
        background: AppColors.surface,
        border: AppColors.outline,
      ),
    };
  }
}

class _MessageVisual {
  const _MessageVisual({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
}
