import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/shared/widgets/http_risk_authorization.dart';
import 'package:consumo_plus/shared/widgets/utility_message_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('message variants share icons and live-region behavior', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: UtilityMessageBanner(
              key: Key('statusMessage'),
              utilityType: UtilityType.electricity,
              kind: UtilityMessageKind.success,
              message: 'Datos actualizados.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const Key('statusMessage')))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: UtilityMessageBanner(
              utilityType: UtilityType.water,
              kind: UtilityMessageKind.error,
              message: 'No pudimos actualizar.',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('HTTP risk includes icon, explanation and authorization', (
    tester,
  ) async {
    bool? authorized;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: HttpRiskAuthorization(
            utilityType: UtilityType.water,
            checkboxKey: const Key('authorization'),
            title: 'Conexión no cifrada',
            body: 'Evita redes Wi-Fi públicas.',
            authorization: 'Comprendo el riesgo y autorizo esta consulta.',
            value: false,
            enabled: true,
            onChanged: (value) => authorized = value,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.text('Conexión no cifrada'), findsOneWidget);
    expect(find.text('Evita redes Wi-Fi públicas.'), findsOneWidget);
    expect(
      find.text('Comprendo el riesgo y autorizo esta consulta.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('authorization')));
    expect(authorized, isTrue);
  });
}
