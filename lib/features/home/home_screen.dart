import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:consumo_plus/shared/widgets/brand_mark.dart';
import 'package:consumo_plus/shared/widgets/utility_service_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.providers,
    required this.onProviderSelected,
    required this.onSettingsSelected,
    super.key,
  });

  final List<ProviderIdentity> providers;
  final ValueChanged<ProviderIdentity> onProviderSelected;
  final VoidCallback onSettingsSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      key: const Key('homeScreen'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                const ExcludeSemantics(child: BrandMark(size: AppSpacing.xxl)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(AppMetadata.name, style: textTheme.titleMedium),
                ),
                IconButton(
                  key: const Key('openSettingsButton'),
                  onPressed: onSettingsSelected,
                  tooltip: AppCopy.settingsTooltip,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppCopy.welcomeTitle,
              style: textTheme.titleMedium?.copyWith(color: AppColors.mutedInk),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(AppCopy.homeTitle, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.mutedInk,
                    size: AppSpacing.lg,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppCopy.demoNotice,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  ),
                ),
              ],
            ),
            for (final provider in providers) ...[
              const SizedBox(height: AppSpacing.md),
              UtilityServiceCard(
                identity: provider,
                onTap: () => onProviderSelected(provider),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
