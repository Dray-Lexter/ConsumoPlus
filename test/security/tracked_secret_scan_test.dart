import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prospective tracked source contains no common secret material', () {
    final result = Process.runSync('git', [
      '-c',
      'safe.directory=${Directory.current.path.replaceAll('\\', '/')}',
      'ls-files',
      '--cached',
      '--others',
      '--exclude-standard',
    ]);
    expect(result.exitCode, 0, reason: 'git ls-files must succeed');

    final candidates = (result.stdout as String)
        .split(RegExp(r'\r?\n'))
        .where((path) => path.isNotEmpty)
        .where((path) => !path.startsWith('.agents/'))
        .where((path) => !path.endsWith('pubspec.lock'))
        .where(_isTextSource);
    final patterns = <RegExp>[
      RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
      RegExp(r'AKIA[0-9A-Z]{16}'),
      RegExp(r'AIza[0-9A-Za-z_-]{35}'),
      RegExp(
        r'authorization\s*:\s*bearer\s+[a-z0-9._-]{16,}',
        caseSensitive: false,
      ),
      RegExp(r'https?://[^\s/:]+:[^\s/@]+@', caseSensitive: false),
    ];
    final findings = <String>[];

    for (final path in candidates) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (patterns.any((pattern) => pattern.hasMatch(lines[index]))) {
          findings.add('$path:${index + 1}');
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason: findings.isEmpty
          ? null
          : 'Possible secrets at ${findings.join(', ')}. Values are omitted.',
    );
  });
}

bool _isTextSource(String path) {
  return const {
    '.dart',
    '.md',
    '.yaml',
    '.yml',
    '.xml',
    '.kts',
    '.properties',
    '.pro',
    '.html',
  }.contains(
    File(path).uri.pathSegments.last.contains('.')
        ? '.${File(path).uri.pathSegments.last.split('.').last.toLowerCase()}'
        : '',
  );
}
