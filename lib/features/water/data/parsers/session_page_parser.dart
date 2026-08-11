import 'package:html/parser.dart' as html_parser;

abstract final class SessionPageParser {
  static bool hasLoginForm(String source) {
    final document = html_parser.parse(source);
    return document.querySelector('input[name="usu"]') != null &&
        document.querySelector('input[name="pas"]') != null;
  }

  static bool isAuthenticated(String source) {
    final document = html_parser.parse(source);
    final hasLogout = document.querySelector('a[href*="salir.php"]') != null;
    final hasBilling =
        document.querySelector('a[onclick*="ctacte.php"]') != null;
    final hasPayments =
        document.querySelector('a[onclick*="historialpagos.php"]') != null;
    return !hasLoginForm(source) && hasLogout && hasBilling && hasPayments;
  }
}
