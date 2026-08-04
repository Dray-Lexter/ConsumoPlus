import 'dart:async';

import 'package:consumo_plus/app/app.dart';
import 'package:consumo_plus/app/config/app_metadata.dart';
import 'package:consumo_plus/app/theme/app_durations.dart';
import 'package:consumo_plus/core/startup/startup_service.dart';
import 'package:consumo_plus/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CompletingStartupService implements StartupService {
  int calls = 0;

  @override
  Future<void> initialize() async {
    calls += 1;
  }
}

class FailOnceStartupService implements StartupService {
  int calls = 0;

  @override
  Future<void> initialize() async {
    calls += 1;
    if (calls == 1) throw StateError('startup failed');
  }
}

class BlockingStartupService implements StartupService {
  int calls = 0;
  final completer = Completer<void>();

  @override
  Future<void> initialize() {
    calls += 1;
    return completer.future;
  }
}

void main() {
  testWidgets('Splash announces the product name once', (tester) async {
    final service = BlockingStartupService();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(ConsumoPlusApp(startupService: service));
      await tester.pump();
      await tester.pump(AppDurations.entrance);

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.bySemanticsLabel(AppMetadata.name), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('successful startup replaces Splash with Home', (tester) async {
    final service = CompletingStartupService();

    await tester.pumpWidget(ConsumoPlusApp(startupService: service));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    final homeContext = tester.element(find.byKey(const Key('homeScreen')));
    expect(Navigator.of(homeContext).canPop(), isFalse);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('failed startup offers a retry that reaches Home', (
    tester,
  ) async {
    final service = FailOnceStartupService();

    await tester.pumpWidget(ConsumoPlusApp(startupService: service));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startupError')), findsOneWidget);
    expect(find.byKey(const Key('retryStartupButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retryStartupButton')));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
  });

  testWidgets('disposing the app during startup is lifecycle safe', (
    tester,
  ) async {
    final service = BlockingStartupService();

    await tester.pumpWidget(ConsumoPlusApp(startupService: service));
    await tester.pump();
    expect(service.calls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    service.completer.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
