import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class UtilityGreeting extends StatelessWidget {
  const UtilityGreeting({required this.ownerName, super.key});

  final String ownerName;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Hola, $ownerName',
    header: true,
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hola,', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(ownerName, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    ),
  );
}
