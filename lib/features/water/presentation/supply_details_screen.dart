import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:flutter/material.dart';

class SupplyDetailsScreen extends StatelessWidget {
  const SupplyDetailsScreen({
    required this.account,
    required this.onChangeSupply,
    required this.onDeleteData,
    super.key,
  });

  static const unavailable = 'No disponible en el portal';
  final WaterAccount account;
  final Future<void> Function() onChangeSupply;
  final Future<void> Function() onDeleteData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos del suministro')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Field('Titular', account.ownerName),
          _Field('Codigo de cliente', _masked(account.customerCode)),
          _Field('Direccion', account.serviceAddress),
          _Field('Estado', account.serviceStatus),
          _Field('Tarifa', account.tariffName),
          _Field(
            'Medidor',
            account.meterNumber == null ? null : _masked(account.meterNumber!),
          ),
          _Field('Tipo de conexion', account.connectionType),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            key: const Key('changeWaterSupply'),
            onPressed: () => _confirm(
              context,
              title: 'Cambiar de suministro',
              message:
                  'Se eliminaran los datos actuales antes de conectar otro suministro.',
              action: 'Cambiar',
              callback: onChangeSupply,
            ),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Cambiar de suministro'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            key: const Key('deleteWaterDataFromSupply'),
            onPressed: () => _confirm(
              context,
              title: 'Eliminar datos de Agua',
              message:
                  'Se borrarán la cuenta, recibos, pagos y usuario recordado de Agua. Electricidad permanecerá intacta.',
              action: 'Eliminar',
              callback: onDeleteData,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar datos de Agua'),
          ),
        ],
      ),
    );
  }

  static String _masked(String value) {
    if (value.length <= 4) return '••••';
    final hidden = List.filled(value.length - 4, '•').join();
    return '$hidden${value.substring(value.length - 4)}';
  }

  static Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    required Future<void> Function() callback,
  }) async {
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await callback();
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(
      value == null || value!.trim().isEmpty
          ? SupplyDetailsScreen.unavailable
          : value!,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}
