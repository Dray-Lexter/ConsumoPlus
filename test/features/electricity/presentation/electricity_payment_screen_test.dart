import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_payment_screen.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('electricity payments use shared cards newest first', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ElectricityPaymentScreen(records: [_payment(6), _payment(7)]),
      ),
    );

    final newest = find.byKey(const Key('electricityPayment-202607'));
    final oldest = find.byKey(const Key('electricityPayment-202606'));
    expect(find.byType(HistoryRecordCard), findsNWidgets(2));
    expect(
      tester.getTopLeft(newest).dy,
      lessThan(tester.getTopLeft(oldest).dy),
    );
    expect(find.text('CAJA FICTICIA'), findsNWidgets(2));
  });
}

ElectricityPaymentRecord _payment(int month) => ElectricityPaymentRecord(
  providerId: 'electrosur',
  contractNumber: 'CONTRATO-FICTICIO-001',
  billingYear: 2026,
  billingMonth: month,
  sourcePeriodCode: '2026${month.toString().padLeft(2, '0')}',
  paymentDate: DateTime(2026, month, 20),
  amountCents: 12300 + month,
  paymentCenter: 'CAJA FICTICIA',
  synchronizedAt: DateTime(2026, 8, 11),
);
