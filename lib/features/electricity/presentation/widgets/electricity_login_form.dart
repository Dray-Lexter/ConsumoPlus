import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_copy.dart';
import 'package:consumo_plus/shared/widgets/http_risk_authorization.dart';
import 'package:flutter/material.dart';

class ElectricityLoginForm extends StatelessWidget {
  const ElectricityLoginForm({
    required this.contractController,
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

  final TextEditingController contractController;
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
          utilityType: UtilityType.electricity,
          checkboxKey: const Key('electricityHttpAuthorization'),
          title: ElectricityCopy.httpRiskTitle,
          body: ElectricityCopy.httpRiskBody,
          authorization: ElectricityCopy.authorization,
          value: authorized,
          enabled: !busy,
          onChanged: onAuthorizationChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('electricityContractField'),
          controller: contractController,
          enabled: !busy,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: ElectricityCopy.contractLabel,
            prefixIcon: Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('electricityPasswordField'),
          controller: passwordController,
          enabled: !busy,
          obscureText: obscurePassword,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmit?.call(),
          decoration: InputDecoration(
            labelText: ElectricityCopy.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: busy ? null : onTogglePassword,
              tooltip: obscurePassword ? 'Mostrar clave' : 'Ocultar clave',
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          ElectricityCopy.noPassword,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text(ElectricityCopy.noPasswordHelp),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const Key('electricityConnectButton'),
          onPressed: onSubmit,
          icon: busy
              ? const SizedBox.square(
                  dimension: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bolt_rounded),
          label: Text(
            busy ? ElectricityCopy.connecting : ElectricityCopy.connect,
          ),
        ),
      ],
    );
  }
}
