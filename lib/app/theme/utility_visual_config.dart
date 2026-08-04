import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

class UtilityVisualConfig {
  const UtilityVisualConfig({
    required this.icon,
    required this.accent,
    required this.container,
    required this.iconRadius,
    required this.iconRotationRadians,
  });

  final IconData icon;
  final Color accent;
  final Color container;
  final double iconRadius;
  final double iconRotationRadians;
}

extension UtilityTypeVisual on UtilityType {
  UtilityVisualConfig get visual => switch (this) {
    UtilityType.water => const UtilityVisualConfig(
      icon: Icons.water_drop_rounded,
      accent: AppColors.water,
      container: AppColors.waterContainer,
      iconRadius: AppRadii.full,
      iconRotationRadians: 0,
    ),
    UtilityType.electricity => const UtilityVisualConfig(
      icon: Icons.bolt_rounded,
      accent: AppColors.electricity,
      container: AppColors.electricityContainer,
      iconRadius: AppRadii.sm,
      iconRotationRadians: -0.08,
    ),
  };
}
