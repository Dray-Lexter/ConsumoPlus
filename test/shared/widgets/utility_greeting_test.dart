import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/shared/widgets/utility_greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('greeting preserves a long fictitious name at large text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const owner = 'PERSONA FICTICIA CON NOMBRE COMPLETO MUY EXTENSO';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(child: UtilityGreeting(ownerName: owner)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hola,'), findsOneWidget);
    expect(find.text(owner), findsOneWidget);
  });
}
