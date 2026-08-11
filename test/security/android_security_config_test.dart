import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleartext is limited to the exact EPS Tacna and Electrosur hosts', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(manifest, contains('@xml/network_security_config'));
    expect(config, contains('cleartextTrafficPermitted="false"'));
    expect(config, contains('cleartextTrafficPermitted="true"'));
    expect(config, contains('oficinavirtual.epstacna.com.pe'));
    expect(config, contains('www.electrosur.com.pe'));
    expect(config, isNot(contains('<domain>electrosur.com.pe</domain>')));
    expect(config, isNot(contains('includeSubdomains="true"')));
  });

  test('Android backups are disabled for local utility data', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('@xml/backup_rules'));
    expect(manifest, contains('@xml/data_extraction_rules'));
  });

  test('release rules preserve SQLCipher integration', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(rules, contains('net.zetetic.database.sqlcipher'));
    expect(gradle, contains('proguard-rules.pro'));
  });
}
