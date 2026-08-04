import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTypography {
  static final textTheme = Typography.material2021().black
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
      .copyWith(
        headlineSmall: Typography.material2021().black.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: Typography.material2021().black.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: Typography.material2021().black.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      );
}
