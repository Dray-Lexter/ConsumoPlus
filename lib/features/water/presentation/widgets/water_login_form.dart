import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/water/presentation/water_copy.dart';
import 'package:consumo_plus/shared/widgets/http_risk_authorization.dart';
import 'package:flutter/material.dart';

class WaterLoginForm extends StatelessWidget {
  const WaterLoginForm({
    required this.usernameController,
    required this.passwordController,
    required this.authorized,
    required this.obscurePassword,
    required this.busy,
    required this.onAuthorizationChanged,
    required this.onTogglePassword,
    required this.onChanged,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool authorized;
  final bool obscurePassword;
  final bool busy;
  final ValueChanged<bool?> onAuthorizationChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HttpRiskAuthorization(
          utilityType: UtilityType.water,
          checkboxKey: const Key('waterHttpAuthorization'),
          title: WaterCopy.httpRiskTitle,
          body: WaterCopy.httpRiskBody,
          authorization: WaterCopy.httpAuthorization,
          value: authorized,
          enabled: !busy,
          onChanged: onAuthorizationChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(WaterCopy.credentialsHelp),
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(WaterCopy.credentialsHelpBody),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('waterUsernameField'),
          controller: usernameController,
          enabled: !busy,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: WaterCopy.usernameLabel,
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('waterPasswordField'),
          controller: passwordController,
          enabled: !busy,
          obscureText: obscurePassword,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmit?.call(),
          decoration: InputDecoration(
            labelText: WaterCopy.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: busy ? null : onTogglePassword,
              tooltip: obscurePassword
                  ? WaterCopy.showPassword
                  : WaterCopy.hidePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const Key('waterConnectButton'),
          onPressed: onSubmit,
          icon: busy
              ? const SizedBox.square(
                  dimension: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_open_rounded),
          label: Text(busy ? WaterCopy.connecting : WaterCopy.connect),
        ),
      ],
    );
  }
}
