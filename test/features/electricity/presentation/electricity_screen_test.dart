import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/features/electricity/application/electricity_view_model.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_metadata.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_result.dart';
import 'package:consumo_plus/features/electricity/domain/repositories/electricity_repository.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_account_status_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_consumption_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_copy.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_payment_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_supply_screen.dart';
import 'package:consumo_plus/shared/widgets/utility_consumption_chart.dart';
import 'package:consumo_plus/shared/widgets/utility_access_tile.dart';
import 'package:consumo_plus/shared/widgets/utility_greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 8, 11, 14);

ElectricitySnapshot snapshot({
  int currentConsumptionWh = 340000,
  int previousConsumptionWh = 280000,
  List<ElectricityConsumptionRecord>? consumptionRecords,
}) => ElectricitySnapshot(
  account: ElectricityAccount(
    providerId: 'electrosur',
    contractNumber: 'CONTRATO-FICTICIO-001',
    ownerName: 'PERSONA FICTICIA',
    serviceAddress: 'AVENIDA FICTICIA 100',
    tariffCode: 'BT5B-FICTICIA',
    meterNumber: 'MEDIDOR-FICTICIO-01',
    synchronizedAt: now,
  ),
  accountStatuses: [
    ElectricityAccountStatus(
      providerId: 'electrosur',
      contractNumber: 'CONTRATO-FICTICIO-001',
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodCode: '202607',
      currentBillingCents: 12345,
      previousDebtCents: 1000,
      totalDebtCents: 13345,
      amountPaidCents: 2000,
      totalBalanceCents: 11345,
      dueDate: DateTime(2026, 8, 25),
      synchronizedAt: now,
    ),
  ],
  consumptionRecords:
      consumptionRecords ??
      [
        ElectricityConsumptionRecord(
          providerId: 'electrosur',
          contractNumber: 'CONTRATO-FICTICIO-001',
          billingYear: 2026,
          billingMonth: 7,
          sourcePeriodCode: '202607',
          tariffCode: 'BT5B-FICTICIA',
          consumptionWh: currentConsumptionWh,
          monthlyChargeCents: 12345,
          synchronizedAt: now,
        ),
        ElectricityConsumptionRecord(
          providerId: 'electrosur',
          contractNumber: 'CONTRATO-FICTICIO-001',
          billingYear: 2026,
          billingMonth: 6,
          sourcePeriodCode: '202606',
          tariffCode: 'BT5B-FICTICIA',
          consumptionWh: previousConsumptionWh,
          monthlyChargeCents: 9810,
          synchronizedAt: now,
        ),
      ],
  paymentRecords: [
    ElectricityPaymentRecord(
      providerId: 'electrosur',
      contractNumber: 'CONTRATO-FICTICIO-001',
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodCode: '202607',
      paymentDate: DateTime(2026, 7, 20),
      amountCents: 12345,
      paymentCenter: 'CAJA FICTICIA',
      synchronizedAt: now,
    ),
  ],
  synchronization: ElectricitySynchronizationMetadata(
    providerId: 'electrosur',
    contractNumber: 'CONTRATO-FICTICIO-001',
    lastAttemptAt: now,
    lastSuccessfulSyncAt: now,
    status: ElectricitySynchronizationStatus.success,
    insertedConsumptionRecords: 2,
    updatedConsumptionRecords: 0,
    insertedPaymentRecords: 1,
    updatedPaymentRecords: 0,
    accountStatusUpdated: true,
    supplyDetailsUpdated: true,
  ),
);

class _Repository implements ElectricityRepository {
  _Repository(this.local);
  ElectricitySnapshot? local;
  String? receivedPassword;
  var deleteCalls = 0;

  @override
  Future<ElectricitySnapshot?> loadLocal() async => local;
  @override
  Future<String?> loadRememberedContract() async => 'CONTRATO-FICTICIO-001';
  @override
  Future<ElectricitySynchronizationResult> synchronize({
    required String contractNumber,
    required String password,
  }) async {
    receivedPassword = password;
    throw UnimplementedError('Solo se comprueba el ciclo efímero de la clave.');
  }

  @override
  Future<void> deleteElectricityData() async {
    deleteCalls += 1;
    local = null;
  }
}

Widget app(_Repository repository) => MaterialApp(
  theme: AppTheme.light(),
  home: ElectricityScreen(
    createViewModel: () async => ElectricityViewModel(repository: repository),
  ),
);

void main() {
  testWidgets('empty form requires HTTP authorization and clears password', (
    tester,
  ) async {
    final repository = _Repository(null);
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('No tengo una clave'), findsOneWidget);
    expect(find.text(ElectricityCopy.httpRiskBody), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('No tengo una clave'),
        matching: find.byType(ButtonStyleButton),
      ),
      findsNothing,
    );
    final connect = find.byKey(const Key('electricityConnectButton'));
    expect(
      Theme.of(tester.element(connect)).colorScheme.primary,
      AppColors.electricity,
    );
    expect(tester.widget<FilledButton>(connect).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('electricityPasswordField')),
      'CLAVE-EFIMERA-FICTICIA',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('electricityHttpAuthorization')));
    await tester.pump();
    expect(tester.widget<FilledButton>(connect).onPressed, isNotNull);
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(connect);
    await tester.pumpAndSettle();

    expect(repository.receivedPassword, 'CLAVE-EFIMERA-FICTICIA');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('electricityPasswordField')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('summary shows electricity metrics without address or meter', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(_Repository(snapshot())));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('Resumen de Electricidad')),
      findsOneWidget,
    );
    expect(find.text('340 kWh'), findsOneWidget);
    expect(find.text('S/ 123.45'), findsOneWidget);
    expect(find.text('S/ 10.00'), findsOneWidget);
    expect(find.text('S/ 133.45'), findsOneWidget);
    expect(find.text('S/ 113.45'), findsOneWidget);
    expect(find.textContaining('Última actualización:'), findsOneWidget);
    expect(find.byType(UtilityGreeting), findsOneWidget);
    expect(find.byType(UtilityAccessTile), findsNWidgets(4));
    expect(find.text('AVENIDA FICTICIA 100'), findsNothing);
    expect(find.text('MEDIDOR-FICTICIO-01'), findsNothing);

    final update = find.byKey(const Key('updateElectricityData'));
    expect(
      tester.getTopLeft(update).dy,
      lessThan(tester.getTopLeft(find.text('340 kWh')).dy),
    );
    expect(
      Theme.of(tester.element(update)).colorScheme.primary,
      AppColors.electricity,
    );
    semantics.dispose();
  });

  testWidgets('electricity summary charts only the latest six periods', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        _Repository(
          snapshot(consumptionRecords: _sevenElectricityConsumptions()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is UtilityConsumptionChartPainter,
      ),
    );
    final painter = paint.painter! as UtilityConsumptionChartPainter;
    expect(painter.points, hasLength(6));
    expect(painter.points.first.periodLabel, 'Mar 2026');
    expect(painter.points.last.periodLabel, 'Ago 2026');
  });

  testWidgets('update repeats the complete HTTP risk and authorization', (
    tester,
  ) async {
    await tester.pumpWidget(app(_Repository(snapshot())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('updateElectricityData')));
    await tester.pumpAndSettle();

    expect(find.text(ElectricityCopy.httpRiskTitle), findsOneWidget);
    expect(find.text(ElectricityCopy.httpRiskBody), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(
      find.byKey(const Key('updateElectricityHttpAuthorization')),
      findsOneWidget,
    );
  });

  testWidgets('summary describes a positive consumption variation', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        _Repository(
          snapshot(currentConsumptionWh: 340000, previousConsumptionWh: 334000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,8 % más que el mes anterior'), findsOneWidget);
  });

  testWidgets('summary describes a negative consumption variation', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        _Repository(
          snapshot(currentConsumptionWh: 320000, previousConsumptionWh: 334000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4,2 % menos que el mes anterior'), findsOneWidget);
  });

  testWidgets('summary omits variation when the prior consumption is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        _Repository(
          snapshot(currentConsumptionWh: 340000, previousConsumptionWh: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('que el mes anterior'), findsNothing);
  });

  testWidgets('summary opens all four electricity detail screens', (
    tester,
  ) async {
    await tester.pumpWidget(app(_Repository(snapshot())));
    await tester.pumpAndSettle();

    for (final entry in <Key, Type>{
      const Key('openElectricityStatus'): ElectricityAccountStatusScreen,
      const Key('openElectricityConsumptions'): ElectricityConsumptionScreen,
      const Key('openElectricityPayments'): ElectricityPaymentScreen,
      const Key('openElectricitySupply'): ElectricitySupplyScreen,
    }.entries) {
      await tester.dragUntilVisible(
        find.byKey(entry.key),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(entry.key));
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('supply can change Electricity after explicit confirmation', (
    tester,
  ) async {
    final repository = _Repository(snapshot());
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openElectricitySupply')));
    await tester.pumpAndSettle();

    expect(find.byType(ElectricitySupplyScreen), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('changeElectricitySupply')), findsOneWidget);
    expect(
      find.byKey(const Key('deleteElectricityDataFromSupply')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('changeElectricitySupply')));
    await tester.pumpAndSettle();
    expect(repository.deleteCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 1);
    expect(find.text('Aún no hay datos de Electricidad'), findsOneWidget);
    expect(find.byType(ElectricitySupplyScreen), findsNothing);
  });

  testWidgets('empty electricity remains usable at 320px with enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: app(_Repository(null)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('electricityConnectButton')),
      240,
    );
    expect(tester.takeException(), isNull);
  });
}

List<ElectricityConsumptionRecord> _sevenElectricityConsumptions() =>
    List.generate(7, (index) {
      final period = DateTime(2026, 2 + index);
      return ElectricityConsumptionRecord(
        providerId: 'electrosur',
        contractNumber: 'CONTRATO-FICTICIO-001',
        billingYear: period.year,
        billingMonth: period.month,
        sourcePeriodCode:
            '${period.year}${period.month.toString().padLeft(2, '0')}',
        tariffCode: 'BT5B-FICTICIA',
        consumptionWh: (300 + index * 10) * 1000,
        monthlyChargeCents: 20000 + index * 100,
        synchronizedAt: now,
      );
    }).reversed.toList();
