import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/presentation/billing_detail_screen.dart';
import 'package:consumo_plus/features/water/presentation/billing_history_screen.dart';
import 'package:consumo_plus/features/water/presentation/payment_history_screen.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('water bills use cards newest first and keep detail navigation', (
    tester,
  ) async {
    _useTallPhone(tester);
    await tester.pumpWidget(
      _app(BillingHistoryScreen(records: [_bill(6), _bill(7)])),
    );

    final newest = find.byKey(const Key('waterBill-REC-FICTICIO-07'));
    final oldest = find.byKey(const Key('waterBill-REC-FICTICIO-06'));
    expect(find.byType(HistoryRecordCard), findsNWidgets(2));
    expect(
      tester.getTopLeft(newest).dy,
      lessThan(tester.getTopLeft(oldest).dy),
    );

    await tester.tap(newest);
    await tester.pumpAndSettle();
    expect(find.byType(BillingDetailScreen), findsOneWidget);
    expect(find.text('REC-FICTICIO-07'), findsOneWidget);
  });

  testWidgets('water payments use newest-first expandable record cards', (
    tester,
  ) async {
    _useTallPhone(tester);
    await tester.pumpWidget(
      _app(PaymentHistoryScreen(records: [_payment(6), _payment(7)])),
    );

    final newest = find.byKey(const Key('waterPayment-PAGO-FICTICIO-07'));
    final oldest = find.byKey(const Key('waterPayment-PAGO-FICTICIO-06'));
    expect(find.byType(HistoryRecordCard), findsNWidgets(2));
    expect(
      tester.getTopLeft(newest).dy,
      lessThan(tester.getTopLeft(oldest).dy),
    );
    expect(find.text('Detalle: OPERACIÓN FICTICIA 07'), findsNothing);

    await tester.tap(
      find.descendant(of: newest, matching: find.byType(ExpansionTile)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detalle: OPERACIÓN FICTICIA 07'), findsOneWidget);
  });
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light(), home: home);

void _useTallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

BillingRecord _bill(int month) => BillingRecord(
  providerId: 'eps-tacna',
  customerCode: 'CLIENTE-FICTICIO-001',
  billingYear: 2026,
  billingMonth: month,
  sourcePeriodLabel: 'PERIODO FICTICIO $month',
  receiptNumber: 'REC-FICTICIO-${month.toString().padLeft(2, '0')}',
  consumptionCubicMeters: 10 + month.toDouble(),
  averageReading: 10,
  monthlyChargeCents: 4000 + month,
  overdueMonths: 0,
  outstandingDebtCents: 0,
  totalAmountCents: 4000 + month,
  synchronizedAt: DateTime(2026, 8, 11),
);

PaymentRecord _payment(int month) => PaymentRecord(
  providerId: 'eps-tacna',
  customerCode: 'CLIENTE-FICTICIO-001',
  paymentDate: DateTime(2026, month, 15),
  paymentCenter: 'CAJA FICTICIA',
  paymentYear: 2026,
  paymentMonth: month,
  documentType: 'RECIBO FICTICIO',
  receiptNumber: 'PAGO-FICTICIO-${month.toString().padLeft(2, '0')}',
  amountCents: 4000 + month,
  detail: 'OPERACIÓN FICTICIA ${month.toString().padLeft(2, '0')}',
  synchronizedAt: DateTime(2026, 8, 11),
);
