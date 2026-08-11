import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/shared/widgets/settings_info_row.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppCopy.settingsTitle)),
      body: SafeArea(
        child: ListView(
          key: const Key('settingsContent'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SettingsInfoRow(
              icon: Icons.privacy_tip_outlined,
              title: AppCopy.privacyStorageTitle,
              description: AppCopy.privacyStorageDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            const SettingsInfoRow(
              icon: Icons.password_outlined,
              title: AppCopy.privacyCredentialsTitle,
              description: AppCopy.privacyCredentialsDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            const SettingsInfoRow(
              icon: Icons.http_outlined,
              title: AppCopy.privacyConnectionsTitle,
              description: AppCopy.privacyConnectionsDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            const SettingsInfoRow(
              icon: Icons.delete_outline,
              title: AppCopy.privacyControlTitle,
              description: AppCopy.privacyControlDescription,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '${AppCopy.versionLabel} ${AppMetadata.displayVersion}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}
