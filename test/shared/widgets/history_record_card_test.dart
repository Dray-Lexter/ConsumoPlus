import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/history_record_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('record card stays readable at 320px and invokes its action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var taps = 0;

    await tester.pumpWidget(
      _app(
        textScale: 1.8,
        child: HistoryRecordCard(
          utilityType: UtilityType.water,
          title: 'Agosto 2026 con un título ficticio largo',
          amount: 'S/ 1,234.56',
          overline: 'RECIBO-FICTICIO-001',
          details: const ['16 m³', 'Mes S/ 45.00 · Deuda S/ 0.00'],
          icon: Icons.receipt_long_outlined,
          onTap: () => taps += 1,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.receipt_long_outlined)).color,
      AppColors.water,
    );
    await tester.tap(find.byType(HistoryRecordCard));
    expect(taps, 1);
  });

  testWidgets('record card reveals optional tertiary details', (tester) async {
    await tester.pumpWidget(
      _app(
        child: HistoryRecordCard(
          utilityType: UtilityType.electricity,
          title: 'S/ 123.45',
          amount: 'Jul 2026',
          details: const ['20/07/2026 · CAJA FICTICIA'],
          expandedDetails: const [
            Text('Tipo: PAGO FICTICIO'),
            Text('Detalle: OPERACIÓN FICTICIA'),
          ],
        ),
      ),
    );

    expect(find.text('Detalle: OPERACIÓN FICTICIA'), findsNothing);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.text('Detalle: OPERACIÓN FICTICIA'), findsOneWidget);
  });
}

Widget _app({required Widget child, double textScale = 1}) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, builtChild) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: builtChild!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
