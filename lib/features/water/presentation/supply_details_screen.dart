import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/shared/presentation/masked_identifier.dart';
import 'package:consumo_plus/shared/widgets/info_section_card.dart';
import 'package:consumo_plus/shared/widgets/utility_sensitive_actions.dart';
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
  Widget build(BuildContext context) => UtilityTheme(
    utilityType: UtilityType.water,
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
              utilityType: UtilityType.water,
              rows: [
                InfoRowData(label: 'Titular', value: account.ownerName),
                InfoRowData(
                  label: 'Código de cliente',
                  value: maskUtilityIdentifier(account.customerCode),
                ),
                InfoRowData(
                  label: 'Dirección',
                  value: _value(account.serviceAddress),
                ),
                InfoRowData(
                  label: 'Estado',
                  value: _value(account.serviceStatus),
                ),
                InfoRowData(label: 'Tarifa', value: _value(account.tariffName)),
                InfoRowData(
                  label: 'Medidor',
                  value: account.meterNumber == null
                      ? unavailable
                      : maskUtilityIdentifier(account.meterNumber!),
                ),
                InfoRowData(
                  label: 'Tipo de conexión',
                  value: _value(account.connectionType),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            UtilitySensitiveActions(
              utilityType: UtilityType.water,
              serviceName: 'Agua',
              otherServiceName: 'Electricidad',
              onChangeSupply: onChangeSupply,
              onDeleteData: onDeleteData,
              changeButtonKey: const Key('changeWaterSupply'),
              deleteButtonKey: const Key('deleteWaterDataFromSupply'),
            ),
          ],
        ),
      ),
    ),
  );

  static String _value(String? value) =>
      value == null || value.trim().isEmpty ? unavailable : value;
}
