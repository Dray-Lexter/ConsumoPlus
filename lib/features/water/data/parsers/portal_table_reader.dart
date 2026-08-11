import 'package:consumo_plus/features/water/data/parsers/portal_text_parser.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:html/dom.dart';

class PortalTableReader {
  PortalTableReader(Document document) : _table = _findTable(document) {
    final headerRow = _table.querySelector('thead tr');
    if (headerRow == null) throw const UnexpectedPortalStructureException();
    headers = headerRow.children
        .map((cell) => PortalTextParser.key(cell.text))
        .toList(growable: false);
  }

  final Element _table;
  late final List<String> headers;

  List<Element> get rows => _table.querySelectorAll('tbody tr');

  int requireIndex(bool Function(String header) matches) {
    final index = headers.indexWhere(matches);
    if (index < 0) throw const UnexpectedPortalStructureException();
    return index;
  }

  String cell(Element row, int index) {
    final cells = row.children;
    if (index >= cells.length) throw const UnexpectedPortalStructureException();
    return PortalTextParser.normalize(cells[index].text);
  }

  static Element _findTable(Document document) {
    return document.querySelector('table#example1') ??
        document.querySelector('table') ??
        (throw const UnexpectedPortalStructureException());
  }
}
