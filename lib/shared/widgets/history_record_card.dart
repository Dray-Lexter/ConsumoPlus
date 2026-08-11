import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard({
    required this.utilityType,
    required this.title,
    required this.amount,
    required this.details,
    this.overline,
    this.icon,
    this.onTap,
    this.expandedDetails = const [],
    super.key,
  });

  final UtilityType utilityType;
  final String title;
  final String amount;
  final List<String> details;
  final String? overline;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Widget> expandedDetails;

  @override
  Widget build(BuildContext context) {
    final visual = utilityType.visual;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      side: const BorderSide(color: AppColors.outline),
    );
    final body = _RecordBody(
      title: title,
      amount: amount,
      details: details,
      overline: overline,
    );

    if (expandedDetails.isNotEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: icon == null ? null : Icon(icon, color: visual.accent),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          iconColor: visual.accent,
          collapsedIconColor: AppColors.mutedInk,
          title: body,
          children: [
            const Divider(),
            for (final detail in expandedDetails)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: detail,
              ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: visual.accent),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: body),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded, color: visual.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordBody extends StatelessWidget {
  const _RecordBody({
    required this.title,
    required this.amount,
    required this.details,
    required this.overline,
  });

  final String title;
  final String amount;
  final List<String> details;
  final String? overline;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 280 || textScale > 1.3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (overline != null) ...[
              Text(
                overline!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.mutedInk),
              ),
              const SizedBox(height: AppSpacing.xxs),
            ],
            if (stackHeader) ...[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(amount, style: Theme.of(context).textTheme.titleMedium),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      amount,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            for (final detail in details) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                detail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              ),
            ],
          ],
        );
      },
    );
  }
}
