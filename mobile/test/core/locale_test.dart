import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/core/providers/core_providers.dart';

void main() {
  test('uses English on English devices and German otherwise', () {
    expect(deviceLanguage(const Locale('en', 'GB')), 'en');
    expect(deviceLanguage(const Locale('de', 'DE')), 'de');
    expect(deviceLanguage(const Locale('fr')), 'de');
  });
}
