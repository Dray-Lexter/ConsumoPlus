import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:flutter/material.dart';

class ElectricitySupplyScreen extends StatelessWidget {
  const ElectricitySupplyScreen({required this.account, super.key});
  final ElectricityAccount account;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Datos del suministro')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Field('Suministro', account.contractNumber),
        _Field('Titular', account.ownerName),
        _Field('Dirección', account.serviceAddress),
        _Field('Tarifa', account.tariffCode),
        _Field('Conexión', account.connectionType),
        _Field('Alimentador', account.feederType),
        _Field('Potencia contratada', account.contractedPower),
        _Field('Nivel de tensión', account.voltageLevel),
        _Field('Medidor', account.meterNumber),
      ],
    ),
  );
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
          ? 'No disponible en el portal'
          : value!,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}
