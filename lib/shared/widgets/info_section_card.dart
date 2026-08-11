import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

class InfoRowData {
  const InfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({
    required this.rows,
    this.title,
    this.utilityType,
    super.key,
  });

  final String? title;
  final List<InfoRowData> rows;
  final UtilityType? utilityType;

  @override
  Widget build(BuildContext context) {
    final visual = utilityType?.visual;
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (visual != null) ...[
                    Icon(visual.icon, color: visual.accent),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
            ],
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              InfoRow(label: rows[index].label, value: rows[index].value),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 320 || textScale > 1.3;
        final labelWidget = Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
        );
        final valueWidget = Text(
          value,
          textAlign: stacked ? TextAlign.start : TextAlign.end,
          style: Theme.of(context).textTheme.titleSmall,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    labelWidget,
                    const SizedBox(height: AppSpacing.xxs),
                    valueWidget,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: labelWidget),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(flex: 2, child: valueWidget),
                  ],
                ),
        );
      },
    );
  }
}
