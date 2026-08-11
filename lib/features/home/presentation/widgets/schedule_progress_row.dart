import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_models.dart';
import 'package:flutter/material.dart';

class ScheduleProgressRow extends StatelessWidget {
  const ScheduleProgressRow({
    required this.utilityType,
    required this.indicator,
    super.key,
  });

  final UtilityType utilityType;
  final ScheduleIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = utilityType.visual.accent;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: indicator.semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(indicator.label, style: textTheme.labelLarge),
              ),
              if (indicator.shortDateText != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  indicator.shortDateText!,
                  style: textTheme.labelLarge?.copyWith(color: accent),
                ),
              ],
            ],
          ),
          if (indicator.distanceText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              indicator.distanceText,
              style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
            ),
          ],
          if (indicator.secondaryText != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              indicator.secondaryText!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
            ),
          ],
          if (indicator.progress != null) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: indicator.progress!.clamp(0.0, 1.0),
              minHeight: AppSpacing.xxs,
              color: accent,
              backgroundColor: utilityType.visual.container,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
          ],
        ],
      ),
    );
  }
}
