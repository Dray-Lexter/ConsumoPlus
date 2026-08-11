import 'package:html/dom.dart';

import 'electrosur_text_parser.dart';

class ElectrosurFieldReader {
  ElectrosurFieldReader(Document document) {
    for (final label in document.querySelectorAll('label')) {
      final key = ElectrosurTextParser.key(label.text);
      final input = _inputFor(document, label);
      if (key.isNotEmpty && input != null) {
        _values[key] = ElectrosurTextParser.normalize(
          input.attributes['value'] ?? input.text,
        );
      }
    }
    for (final row in document.querySelectorAll('tr')) {
      final cells = row.children;
      if (cells.length < 2) continue;
      final key = ElectrosurTextParser.key(cells.first.text);
      final input = cells[1].querySelector('input');
      final value = input?.attributes['value'] ?? cells[1].text;
      if (key.isNotEmpty) _values[key] = ElectrosurTextParser.normalize(value);
    }
  }

  final Map<String, String> _values = {};

  String? optional(Iterable<String> labels) {
    for (final label in labels) {
      final value = _values[ElectrosurTextParser.key(label)];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String require(Iterable<String> labels) {
    return optional(labels) ??
        (throw const FormatException('Campo requerido ausente'));
  }

  bool hasAny(Iterable<String> labels) {
    final keys = labels.map(ElectrosurTextParser.key).toSet();
    return _values.keys.any(keys.contains);
  }

  static Element? _inputFor(Document document, Element label) {
    final id = label.attributes['for'];
    if (id != null && id.isNotEmpty) {
      final byId = document.getElementById(id);
      if (byId != null && byId.localName == 'input') return byId;
      for (final input in document.querySelectorAll('input')) {
        if (input.attributes['name'] == id) return input;
      }
    }
    final nested = label.querySelector('input');
    if (nested != null) return nested;
    var next = label.nextElementSibling;
    while (next != null) {
      if (next.localName == 'input') return next;
      final contained = next.querySelector('input');
      if (contained != null) return contained;
      if (next.localName == 'label') return null;
      next = next.nextElementSibling;
    }
    return null;
  }
}
