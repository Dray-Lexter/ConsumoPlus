import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:flutter/material.dart';

class UtilityServiceCard extends StatelessWidget {
  const UtilityServiceCard({
    required this.identity,
    required this.onTap,
    super.key,
  });

  final ProviderIdentity identity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = identity.utilityType.visual;
    final utilityName = AppCopy.utilityName(identity.utilityType);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: 'Abrir $utilityName de ${identity.displayName}',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('providerCard-${identity.id}'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: visual.iconRotationRadians,
                    child: Container(
                      width: AppSpacing.xxl,
                      height: AppSpacing.xxl,
                      decoration: BoxDecoration(
                        color: visual.container,
                        borderRadius: BorderRadius.circular(visual.iconRadius),
                      ),
                      child: Icon(
                        visual.icon,
                        color: visual.accent,
                        size: AppSpacing.lg,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          utilityName,
                          style: textTheme.labelLarge?.copyWith(
                            color: visual.accent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          identity.displayName,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          identity.cardDescription,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.mutedInk,
                      size: AppSpacing.md,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
