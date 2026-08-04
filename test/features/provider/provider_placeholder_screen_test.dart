import 'package:consumo_plus/app/config/app_copy.dart';
import 'package:consumo_plus/app/theme/app_theme.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/provider_identity.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/provider/provider_placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the supplied provider identity without body controls', (
    tester,
  ) async {
    const identity = ProviderIdentity(
      id: 'custom-electricity',
      displayName: 'Proveedor de prueba',
      locality: 'Ciudad de prueba',
      utilityType: UtilityType.electricity,
      cardDescription: 'Descripción de tarjeta',
      demoMessage: 'Mensaje específico del proveedor.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ProviderPlaceholderScreen(identity: identity),
      ),
    );

    final content = find.byKey(const Key('providerContent'));
    expect(content, findsOneWidget);
    expect(
      find.descendant(of: content, matching: find.text('Electricidad')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: content, matching: find.text('Proveedor de prueba')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: content, matching: find.text('Ciudad de prueba')),
      findsOneWidget,
    );
    expect(AppCopy.demoLabel, 'Versión demostrativa');
    expect(
      find.descendant(of: content, matching: find.text(AppCopy.demoLabel)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: content, matching: find.text(identity.demoMessage)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: content,
        matching: find.text(AppCopy.unavailableConnection),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: content, matching: find.byIcon(Icons.bolt_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: content, matching: find.byType(TextField)),
      findsNothing,
    );
    expect(
      find.descendant(of: content, matching: find.byType(TextFormField)),
      findsNothing,
    );
    expect(
      find.descendant(of: content, matching: find.byType(ButtonStyleButton)),
      findsNothing,
    );
    expect(
      find.descendant(of: content, matching: find.byType(IconButton)),
      findsNothing,
    );
    expect(
      find.descendant(of: content, matching: find.byType(Switch)),
      findsNothing,
    );
  });

  testWidgets('rotates only the electricity icon from its visual identity', (
    tester,
  ) async {
    const identity = ProviderIdentity(
      id: 'custom-electricity',
      displayName: 'Proveedor de prueba',
      locality: 'Ciudad de prueba',
      utilityType: UtilityType.electricity,
      cardDescription: 'Descripción de tarjeta',
      demoMessage: 'Mensaje específico del proveedor.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ProviderPlaceholderScreen(identity: identity),
      ),
    );

    final content = find.byKey(const Key('providerContent'));
    final iconTransform = find.descendant(
      of: content,
      matching: find.byWidgetPredicate(
        (widget) => widget is Transform && widget.child is Icon,
      ),
    );
    final containerTransform = find.descendant(
      of: content,
      matching: find.byWidgetPredicate(
        (widget) => widget is Transform && widget.child is Container,
      ),
    );

    expect(iconTransform, findsOneWidget);
    expect(containerTransform, findsNothing);
    expect(
      tester.widget<Transform>(iconTransform).transform.storage,
      orderedEquals(
        Matrix4.rotationZ(
          identity.utilityType.visual.iconRotationRadians,
        ).storage,
      ),
    );
  });

  testWidgets('remains scrollable on a narrow screen with large text', (
    tester,
  ) async {
    const identity = ProviderIdentity(
      id: 'custom-water',
      displayName: 'Proveedor de agua con un nombre extenso',
      locality: 'Localidad de prueba con un nombre extenso',
      utilityType: UtilityType.water,
      cardDescription: 'Descripción de tarjeta',
      demoMessage: 'Mensaje específico del proveedor que ocupa varias líneas.',
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: const ProviderPlaceholderScreen(identity: identity),
      ),
    );
    final content = find.byKey(const Key('providerContent'));
    await tester.scrollUntilVisible(
      find.text(AppCopy.unavailableConnection),
      100,
      scrollable: find.descendant(
        of: content,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();

    expect(content, findsOneWidget);
    expect(tester.widget(content), isA<ListView>());
    expect(find.text(AppCopy.unavailableConnection), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
