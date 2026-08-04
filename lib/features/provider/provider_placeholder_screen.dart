import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:flutter/material.dart';

class ProviderPlaceholderScreen extends StatelessWidget {
  const ProviderPlaceholderScreen({required this.identity, super.key});

  final ProviderIdentity identity;

  @override
  Widget build(BuildContext context) {
    final utilityName = AppCopy.utilityName(identity.utilityType);
    final visual = identity.utilityType.visual;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(utilityName)),
      body: ListView(
        key: const Key('providerContent'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: AppSpacing.xxl * 2,
              height: AppSpacing.xxl * 2,
              decoration: BoxDecoration(
                color: visual.container,
                borderRadius: BorderRadius.circular(visual.iconRadius),
              ),
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: visual.iconRotationRadians,
                  child: Icon(
                    visual.icon,
                    color: visual.accent,
                    size: AppSpacing.xxl,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(utilityName, style: textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(identity.displayName, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            identity.locality,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: visual.container,
                borderRadius: BorderRadius.circular(visual.iconRadius),
              ),
              child: Text(
                AppCopy.demoLabel,
                style: textTheme.labelLarge?.copyWith(color: visual.accent),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(identity.demoMessage, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppCopy.unavailableConnection,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
          ),
        ],
      ),
    );
  }
}
