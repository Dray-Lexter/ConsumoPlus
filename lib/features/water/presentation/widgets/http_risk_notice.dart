import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/water/presentation/water_copy.dart';
import 'package:flutter/material.dart';

class HttpRiskNotice extends StatelessWidget {
  const HttpRiskNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${WaterCopy.httpRiskTitle} ${WaterCopy.httpRiskBody}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.warningOutline),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.shield_outlined, color: AppColors.warningInk),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    WaterCopy.httpRiskTitle,
                    style: TextStyle(
                      color: AppColors.warningInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    WaterCopy.httpRiskBody,
                    style: TextStyle(color: AppColors.warningInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
