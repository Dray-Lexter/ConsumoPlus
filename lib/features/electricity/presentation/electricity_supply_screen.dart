import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/shared/presentation/masked_identifier.dart';
import 'package:consumo_plus/shared/widgets/info_section_card.dart';
import 'package:consumo_plus/shared/widgets/utility_sensitive_actions.dart';
import 'package:flutter/material.dart';

class ElectricitySupplyScreen extends StatelessWidget {
  const ElectricitySupplyScreen({
    required this.account,
    required this.onChangeSupply,
    required this.onDeleteData,
    super.key,
  });
  static const unavailable = 'No disponible en el portal';
  final ElectricityAccount account;
  final Future<void> Function() onChangeSupply;
  final Future<void> Function() onDeleteData;

  @override
  Widget build(BuildContext context) => UtilityTheme(
    utilityType: UtilityType.electricity,
    child: Scaffold(
      appBar: AppBar(title: const Text('Datos del suministro')),
      body: SafeArea(
        key: const Key('supplyBottomSafeArea'),
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            InfoSectionCard(
              title: 'Información del suministro',
              utilityType: UtilityType.electricity,
              rows: [
                InfoRowData(
                  label: 'Suministro',
                  value: maskUtilityIdentifier(account.contractNumber),
                ),
                InfoRowData(label: 'Titular', value: account.ownerName),
                InfoRowData(label: 'Dirección', value: account.serviceAddress),
                InfoRowData(label: 'Tarifa', value: account.tariffCode),
                InfoRowData(
                  label: 'Conexión',
                  value: _value(account.connectionType),
                ),
                InfoRowData(
                  label: 'Alimentador',
                  value: _value(account.feederType),
                ),
                InfoRowData(
                  label: 'Potencia contratada',
                  value: _value(account.contractedPower),
                ),
                InfoRowData(
                  label: 'Nivel de tensión',
                  value: _value(account.voltageLevel),
                ),
                InfoRowData(
                  label: 'Medidor',
                  value: account.meterNumber == null
                      ? unavailable
                      : maskUtilityIdentifier(account.meterNumber!),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            UtilitySensitiveActions(
              utilityType: UtilityType.electricity,
              serviceName: 'Electricidad',
              otherServiceName: 'Agua',
              onChangeSupply: onChangeSupply,
              onDeleteData: onDeleteData,
              changeButtonKey: const Key('changeElectricitySupply'),
              deleteButtonKey: const Key('deleteElectricityDataFromSupply'),
            ),
          ],
        ),
      ),
    ),
  );

  static String _value(String? value) =>
      value == null || value.trim().isEmpty ? unavailable : value;
}
