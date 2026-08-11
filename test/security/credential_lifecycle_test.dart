import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation is isolated from network, HTML and persistence APIs', () {
    final files = Directory('lib/features/water/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    const forbidden = <String>[
      "import 'dart:io'",
      'package:html',
      'sqflite',
      'flutter_secure_storage',
    ];

    final findings = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      if (forbidden.any(source.contains)) findings.add(file.path);
    }
    expect(findings, isEmpty);
  });

  test('password is absent from durable state and secure storage keys', () {
    final state = File(
      'lib/features/water/application/water_state.dart',
    ).readAsStringSync();
    final stores = Directory('lib/features/water/data/local')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(state.toLowerCase(), isNot(contains('password')));
    expect(stores, isNot(contains('remembered_password')));
    expect(stores, isNot(contains('eps_tacna_password')));
    expect(
      RegExp(
        r"storage\.write\([^\n]*password",
        caseSensitive: false,
      ).hasMatch(stores),
      isFalse,
    );
  });
}
