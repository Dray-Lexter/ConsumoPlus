import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_account_status_screen.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_supply_screen.dart';
import 'package:consumo_plus/shared/widgets/info_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('electricity account status groups economy and dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ElectricityAccountStatusScreen(status: _status)),
    );

    expect(find.byType(InfoSectionCard), findsNWidgets(2));
    expect(find.text('Resumen económico'), findsOneWidget);
    expect(find.text('Fechas'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets(
    'electricity supply masks contract and meter above safe actions',
    (tester) async {
      _useTallPhone(tester);
      await tester.pumpWidget(
        _app(
          ElectricitySupplyScreen(
            account: _account,
            onChangeSupply: () async {},
            onDeleteData: () async {},
          ),
        ),
      );

      expect(find.byType(InfoSectionCard), findsOneWidget);
      expect(find.text('CONTRATO-FICTICIO-0001'), findsNothing);
      expect(find.text('MEDIDOR-FICTICIO-0042'), findsNothing);
      expect(find.textContaining('0001'), findsOneWidget);
      expect(find.textContaining('0042'), findsOneWidget);
      expect(find.byKey(const Key('supplyBottomSafeArea')), findsOneWidget);
      expect(find.byKey(const Key('changeElectricitySupply')), findsOneWidget);
      expect(
        find.byKey(const Key('deleteElectricityDataFromSupply')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'electricity supply actions remain reachable at 320px and 1.8x text',
    (tester) async {
      _useSmallPhone(tester);
      await tester.pumpWidget(
        _app(
          ElectricitySupplyScreen(
            account: _account,
            onChangeSupply: () async {},
            onDeleteData: () async {},
          ),
          textScale: 1.8,
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final delete = find.byKey(const Key('deleteElectricityDataFromSupply'));
      expect(delete, findsOneWidget);
      expect(tester.getBottomRight(delete).dy, lessThanOrEqualTo(640));
    },
  );
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
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void _useSmallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 640);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

final _account = ElectricityAccount(
  providerId: 'electrosur',
  contractNumber: 'CONTRATO-FICTICIO-0001',
  ownerName: 'PERSONA FICTICIA',
  serviceAddress: 'AVENIDA FICTICIA 123',
  tariffCode: 'BT5B-FICTICIA',
  connectionType: 'CONEXIÓN FICTICIA',
  feederType: 'ALIMENTADOR FICTICIO',
  contractedPower: '3.00 kW',
  voltageLevel: '220 V',
  meterNumber: 'MEDIDOR-FICTICIO-0042',
  synchronizedAt: DateTime(2026, 8, 11),
);

final _status = ElectricityAccountStatus(
  providerId: 'electrosur',
  contractNumber: 'CONTRATO-FICTICIO-0001',
  billingYear: 2026,
  billingMonth: 8,
  sourcePeriodCode: '202608',
  currentBillingCents: 10000,
  previousDebtCents: 2000,
  totalDebtCents: 12000,
  amountPaidCents: 5000,
  totalBalanceCents: 7000,
  dueDate: DateTime(2026, 8, 25),
  issueDate: DateTime(2026, 8, 5),
  readingDate: DateTime(2026, 8, 1),
  previousReadingDate: DateTime(2026, 7, 1),
  synchronizedAt: DateTime(2026, 8, 11),
);
