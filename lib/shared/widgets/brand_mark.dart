import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
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
        child: Icon(
          Icons.water_drop_rounded,
          size: size * 0.48,
          color: AppColors.water,
        ),
      ),
    );
  }
}
