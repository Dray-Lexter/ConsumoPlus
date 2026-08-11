import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/water/application/water_view_model.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_result.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:consumo_plus/features/water/domain/repositories/water_repository.dart';
import 'package:consumo_plus/features/water/presentation/billing_history_screen.dart';
import 'package:consumo_plus/features/water/presentation/payment_history_screen.dart';
import 'package:consumo_plus/features/water/presentation/supply_details_screen.dart';
import 'package:consumo_plus/features/water/presentation/water_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 8, 4, 12);

WaterSnapshot _snapshot() => WaterSnapshot(
  account: WaterAccount(
    providerId: 'eps-tacna',
    customerCode: 'USUARIO-DE-PRUEBA',
    ownerName: 'PERSONA DE PRUEBA',
    synchronizedAt: _now,
  ),
  billingRecords: [
    BillingRecord(
      providerId: 'eps-tacna',
      customerCode: 'USUARIO-DE-PRUEBA',
      billingYear: 2026,
      billingMonth: 8,
      sourcePeriodLabel: 'AGOSTO 2026',
      receiptNumber: 'REC-PRUEBA-002',
      consumptionCubicMeters: 14,
      averageReading: 13,
      monthlyChargeCents: 4250,
      overdueMonths: 1,
      outstandingDebtCents: 1250,
      totalAmountCents: 5500,
      synchronizedAt: _now,
    ),
    BillingRecord(
      providerId: 'eps-tacna',
      customerCode: 'USUARIO-DE-PRUEBA',
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodLabel: 'JULIO 2026',
      receiptNumber: 'REC-PRUEBA-001',
      consumptionCubicMeters: 12,
      averageReading: 11,
      monthlyChargeCents: 4000,
      overdueMonths: 0,
      outstandingDebtCents: 0,
      totalAmountCents: 4000,
      synchronizedAt: _now,
    ),
  ],
  paymentRecords: [
    PaymentRecord(
      providerId: 'eps-tacna',
      customerCode: 'USUARIO-DE-PRUEBA',
      paymentDate: DateTime(2026, 7, 15),
      paymentCenter: 'CAJA DE PRUEBA',
      paymentYear: 2026,
      paymentMonth: 7,
      documentType: 'RECIBO',
      receiptNumber: 'PAGO-PRUEBA-001',
      amountCents: 4000,
      detail: 'PAGO DE PRUEBA',
      synchronizedAt: _now,
    ),
  ],
  synchronization: SynchronizationMetadata(
    providerId: 'eps-tacna',
    customerCode: 'USUARIO-DE-PRUEBA',
    lastAttemptAt: _now,
    lastSuccessfulSyncAt: _now,
    status: SynchronizationStatus.success,
    insertedBillingRecords: 2,
    updatedBillingRecords: 0,
    insertedPaymentRecords: 1,
    updatedPaymentRecords: 0,
  ),
);

class _Repository implements WaterRepository {
  _Repository(this.snapshot);
  WaterSnapshot? snapshot;
  var deleteCalls = 0;
  String? receivedPassword;
  String? receivedUsername;

  @override
  Future<void> deleteWaterData() async {
    deleteCalls += 1;
    snapshot = null;
  }

  @override
  Future<WaterSnapshot?> loadLocal() async => snapshot;

  @override
  Future<String?> loadRememberedUsername() async => 'USUARIO-DE-PRUEBA';

  @override
  Future<SynchronizationResult> synchronize({
    required String username,
    required String password,
  }) async {
    receivedUsername = username;
    receivedPassword = password;
    return SynchronizationResult(
      snapshot: snapshot!,
      insertedBillingRecords: 0,
      updatedBillingRecords: 2,
      insertedPaymentRecords: 0,
      updatedPaymentRecords: 1,
    );
  }
}

Widget _app(_Repository repository) => MaterialApp(
  theme: AppTheme.light(),
  home: WaterScreen(
    createViewModel: () async => WaterViewModel(repository: repository),
  ),
);

void main() {
  testWidgets('local summary differentiates consumption, debt and total', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Repository(_snapshot())));
    await tester.pumpAndSettle();

    expect(find.text('14 m³'), findsOneWidget);
    expect(find.text('S/ 42.50'), findsOneWidget);
    expect(find.text('S/ 12.50'), findsOneWidget);
    expect(find.text('S/ 55.00'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Grafico de consumo')), findsOneWidget);
  });

  testWidgets('summary opens billing, payment and supply screens', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Repository(_snapshot())));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openBillingHistory')));
    await tester.pumpAndSettle();
    expect(find.byType(BillingHistoryScreen), findsOneWidget);
    expect(find.text('REC-PRUEBA-002'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openPaymentHistory')));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentHistoryScreen), findsOneWidget);
    expect(find.text('PAGO-PRUEBA-001'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openSupplyDetails')));
    await tester.pumpAndSettle();
    expect(find.byType(SupplyDetailsScreen), findsOneWidget);
    expect(find.text('No disponible en el portal'), findsNWidgets(5));
  });

  testWidgets('deleting water data requires confirmation', (tester) async {
    final repository = _Repository(_snapshot());
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteWaterData')));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar datos de Agua'), findsOneWidget);
    expect(repository.deleteCalls, 0);

    await tester.tap(find.byKey(const Key('confirmDeleteWaterData')));
    await tester.pumpAndSettle();
    expect(repository.deleteCalls, 1);
    expect(find.text('Aun no hay datos de Agua'), findsOneWidget);
  });

  testWidgets('manual update requires fresh password and HTTP authorization', (
    tester,
  ) async {
    final repository = _Repository(_snapshot());
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('updateWaterData')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('confirmWaterUpdate'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('updateWaterUsernameField')),
      'OTRO-USUARIO-DE-PRUEBA',
    );
    await tester.enterText(
      find.byKey(const Key('updateWaterPasswordField')),
      'OTRA-CLAVE-EFIMERA',
    );
    await tester.tap(find.byKey(const Key('updateWaterHttpAuthorization')));
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(repository.receivedPassword, 'OTRA-CLAVE-EFIMERA');
    expect(repository.receivedUsername, 'OTRO-USUARIO-DE-PRUEBA');
    expect(find.byKey(const Key('updateWaterPasswordField')), findsNothing);
    expect(find.text('2 actualizados, 1 pago actualizado.'), findsOneWidget);
  });
}
