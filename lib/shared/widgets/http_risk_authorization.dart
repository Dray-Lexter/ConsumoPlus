import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/utility_message_banner.dart';
import 'package:flutter/material.dart';

class HttpRiskAuthorization extends StatelessWidget {
  const HttpRiskAuthorization({
    required this.utilityType,
    required this.checkboxKey,
    required this.title,
    required this.body,
    required this.authorization,
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final UtilityType utilityType;
  final Key checkboxKey;
  final String title;
  final String body;
  final String authorization;
  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        UtilityMessageBanner(
          utilityType: utilityType,
          kind: UtilityMessageKind.warning,
          title: title,
          message: body,
        ),
        const SizedBox(height: AppSpacing.xs),
        CheckboxListTile(
          key: checkboxKey,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: value,
          enabled: enabled,
          onChanged: onChanged,
          title: Text(authorization),
        ),
      ],
    );
  }
}
