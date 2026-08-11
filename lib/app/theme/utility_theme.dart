import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

class UtilityTheme extends StatelessWidget {
  const UtilityTheme({
    required this.utilityType,
    required this.child,
    super.key,
  });

  final UtilityType utilityType;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final visual = utilityType.visual;
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: visual.accent,
          onPrimary: AppColors.surface,
          primaryContainer: visual.container,
          onPrimaryContainer: visual.accent,
        ),
        progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
          color: visual.accent,
        ),
      ),
      child: child,
    );
  }
}
