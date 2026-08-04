import 'dart:async';

import 'package:consumo_plus/core/startup/startup_controller.dart';
import 'package:consumo_plus/core/startup/startup_service.dart';
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

class FailThenBlockStartupService implements StartupService {
  int calls = 0;
  final completer = Completer<void>();

  @override
  Future<void> initialize() {
    calls += 1;
    if (calls == 1) return Future<void>.error(StateError('startup failed'));
    return completer.future;
  }
}

void main() {
  test('initialize reaches success', () async {
    final service = CompletingStartupService();
    final controller = StartupController(service);

    final future = controller.initialize();
    expect(controller.status, StartupStatus.initializing);
    await future;

    expect(controller.status, StartupStatus.success);
    expect(service.calls, 1);
  });

  test('failure is exposed and retry performs a real second call', () async {
    final service = FailOnceStartupService();
    final controller = StartupController(service);

    await controller.initialize();
    expect(controller.status, StartupStatus.failure);
    expect(controller.error, isA<StateError>());

    await controller.retry();
    expect(controller.status, StartupStatus.success);
    expect(service.calls, 2);
  });

  test('concurrent initialize calls share one service execution', () async {
    final service = BlockingStartupService();
    final controller = StartupController(service);

    final first = controller.initialize();
    final second = controller.initialize();
    expect(service.calls, 1);

    service.completer.complete();
    await Future.wait([first, second]);
    expect(controller.status, StartupStatus.success);
  });

  test('initialization completes after controller is disposed', () async {
    final service = BlockingStartupService();
    final controller = StartupController(service);

    final future = controller.initialize();
    controller.dispose();
    service.completer.complete();

    await future;
  });

  test(
    'retry clears the previous error while initialization is pending',
    () async {
      final service = FailThenBlockStartupService();
      final controller = StartupController(service);

      await controller.initialize();
      expect(controller.status, StartupStatus.failure);
      expect(controller.error, isA<StateError>());

      final retry = controller.retry();
      expect(controller.status, StartupStatus.initializing);
      expect(controller.error, isNull);

      service.completer.complete();
      await retry;
      expect(controller.status, StartupStatus.success);
    },
  );
}
