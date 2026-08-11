import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/material.dart';

class DestructiveActionButton extends StatelessWidget {
  const DestructiveActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.errorContainer,
        foregroundColor: AppColors.error,
      ),
      icon: const Icon(Icons.delete_outline_rounded),
      label: Text(label),
    );
  }
}

class UtilitySensitiveActions extends StatelessWidget {
  const UtilitySensitiveActions({
    required this.utilityType,
    required this.serviceName,
    required this.otherServiceName,
    required this.onChangeSupply,
    required this.onDeleteData,
    this.changeButtonKey,
    this.deleteButtonKey,
    super.key,
  });

  final UtilityType utilityType;
  final String serviceName;
  final String otherServiceName;
  final Future<void> Function() onChangeSupply;
  final Future<void> Function() onDeleteData;
  final Key? changeButtonKey;
  final Key? deleteButtonKey;

  @override
  Widget build(BuildContext context) {
    return UtilityTheme(
      utilityType: utilityType,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: changeButtonKey,
            onPressed: () => _change(context),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Cambiar de suministro'),
          ),
          const SizedBox(height: AppSpacing.sm),
          DestructiveActionButton(
            key: deleteButtonKey,
            onPressed: () => _delete(context),
            label: 'Eliminar datos de $serviceName',
          ),
        ],
      ),
    );
  }

  Future<void> _change(BuildContext context) async {
    final confirmed = await showUtilityActionConfirmation(
      context,
      title: 'Cambiar suministro de $serviceName',
      message:
          'Se eliminarán los datos actuales de $serviceName antes de conectar otro suministro. Los datos de $otherServiceName no se modificarán.',
      actionLabel: 'Cambiar',
    );
    if (!confirmed || !context.mounted) return;
    await onChangeSupply();
    _closeSupplyScreen(context);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showUtilityActionConfirmation(
      context,
      title: 'Eliminar datos de $serviceName',
      message:
          'Se borrarán los datos locales y el identificador recordado de $serviceName. Los datos de $otherServiceName no se modificarán.',
      actionLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await onDeleteData();
    _closeSupplyScreen(context);
  }

  static void _closeSupplyScreen(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

Future<bool> showUtilityActionConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  bool destructive = false,
  Key? confirmKey,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: confirmKey,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.errorContainer,
                      foregroundColor: AppColors.error,
                    )
                  : null,
              child: Text(actionLabel),
            ),
          ],
        ),
      ) ??
      false;
}
