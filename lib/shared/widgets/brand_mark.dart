import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = AppSpacing.xxl + AppSpacing.xl});

  final double size;

  @override
  Widget build(BuildContext context) {
    final waterVisual = UtilityType.water.visual;
    final electricityVisual = UtilityType.electricity.visual;

    return Semantics(
      label: AppMetadata.name,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  waterVisual.icon,
                  size: AppSpacing.lg,
                  color: waterVisual.accent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  electricityVisual.icon,
                  size: AppSpacing.lg,
                  color: electricityVisual.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
