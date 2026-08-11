import 'package:html/dom.dart';

import 'electrosur_text_parser.dart';

class ElectrosurTableReader {
  ElectrosurTableReader._(this._table, this.headers, this.rows);

  factory ElectrosurTableReader.find(
    Document document,
    Iterable<String> requiredHeaders,
  ) {
    final required = requiredHeaders.map(ElectrosurTextParser.key).toSet();
    for (final table in document.querySelectorAll('table')) {
      final allRows = table.querySelectorAll('tr');
      if (allRows.isEmpty) continue;
      final headerRow = allRows.firstWhere(
        (row) => row.querySelectorAll('th').isNotEmpty,
        orElse: () => allRows.first,
      );
      final headers = headerRow.children
          .map((cell) => ElectrosurTextParser.key(cell.text))
          .toList(growable: false);
      if (!required.every(headers.contains)) continue;
      final rows = allRows
          .where((row) => !identical(row, headerRow))
          .toList(growable: false);
      return ElectrosurTableReader._(table, headers, rows);
    }
    throw const FormatException('Tabla requerida ausente');
  }

  final Element _table;
  final List<String> headers;
  final List<Element> rows;

  String cell(Element row, String header) {
    final index = headers.indexOf(ElectrosurTextParser.key(header));
    if (index < 0 || index >= row.children.length) {
      throw const FormatException('Columna requerida ausente');
    }
    return ElectrosurTextParser.normalize(row.children[index].text);
  }

  @override
  String toString() => 'ElectrosurTableReader(${_table.localName}, $headers)';
}
