import 'dart:io';

String fixture(String relativePath) {
  return File('test/fixtures/$relativePath').readAsStringSync();
}
