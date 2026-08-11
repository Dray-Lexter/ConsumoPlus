import 'package:html/parser.dart' as html_parser;

abstract final class ElectrosurSessionParser {
  static bool hasLoginForm(String html) {
    final document = html_parser.parse(html);
    final names = document
        .querySelectorAll('input')
        .map((input) => input.attributes['name']?.toLowerCase())
        .whereType<String>()
        .toSet();
    return names.contains('gstrnumerocontrato') && names.contains('gstrclave');
  }
}
