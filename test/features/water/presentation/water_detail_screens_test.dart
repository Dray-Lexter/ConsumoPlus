import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/presentation/billing_detail_screen.dart';
import 'package:consumo_plus/features/water/presentation/supply_details_screen.dart';
import 'package:consumo_plus/shared/widgets/info_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('water bill detail groups compact summary and billing sections', (
    tester,
  ) async {
    await tester.pumpWidget(_app(BillingDetailScreen(record: _bill)));

    expect(find.byType(InfoSectionCard), findsNWidgets(2));
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Facturación'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('water supply masks identifiers and keeps bottom actions safe', (
    tester,
  ) async {
    _useTallPhone(tester);
    await tester.pumpWidget(
      _app(
        SupplyDetailsScreen(
          account: _waterAccount,
          onChangeSupply: () async {},
          onDeleteData: () async {},
        ),
      ),
    );

    expect(find.byType(InfoSectionCard), findsOneWidget);
    expect(find.text('CLIENTE-FICTICIO-1234'), findsNothing);
    expect(find.text('MEDIDOR-FICTICIO-5678'), findsNothing);
    expect(find.textContaining('1234'), findsOneWidget);
    expect(find.textContaining('5678'), findsOneWidget);
    expect(find.byKey(const Key('supplyBottomSafeArea')), findsOneWidget);
    expect(find.byKey(const Key('changeWaterSupply')), findsOneWidget);
    expect(find.byKey(const Key('deleteWaterDataFromSupply')), findsOneWidget);
  });

  testWidgets('water supply actions remain reachable at 320px and 1.8x text', (
    tester,
  ) async {
    _useSmallPhone(tester);
    await tester.pumpWidget(
      _app(
        SupplyDetailsScreen(
          account: _waterAccount,
          onChangeSupply: () async {},
          onDeleteData: () async {},
        ),
        textScale: 1.8,
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final delete = find.byKey(const Key('deleteWaterDataFromSupply'));
    expect(delete, findsOneWidget);
    expect(tester.getBottomRight(delete).dy, lessThanOrEqualTo(640));
  });
}

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

void _useTallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void _useSmallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 640);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

final _bill = BillingRecord(
  providerId: 'eps-tacna',
  customerCode: 'CLIENTE-FICTICIO-1234',
  billingYear: 2026,
  billingMonth: 8,
  sourcePeriodLabel: 'AGOSTO FICTICIO 2026',
  receiptNumber: 'RECIBO-FICTICIO-001',
  consumptionCubicMeters: 16,
  averageReading: 15,
  monthlyChargeCents: 4500,
  overdueMonths: 0,
  outstandingDebtCents: 0,
  totalAmountCents: 4500,
  synchronizedAt: DateTime(2026, 8, 11),
);

final _waterAccount = WaterAccount(
  providerId: 'eps-tacna',
  customerCode: 'CLIENTE-FICTICIO-1234',
  ownerName: 'PERSONA FICTICIA',
  serviceAddress: 'AVENIDA FICTICIA 123',
  serviceStatus: 'ACTIVO FICTICIO',
  tariffName: 'TARIFA FICTICIA',
  meterNumber: 'MEDIDOR-FICTICIO-5678',
  connectionType: 'CONEXIÓN FICTICIA',
  synchronizedAt: DateTime(2026, 8, 11),
);
