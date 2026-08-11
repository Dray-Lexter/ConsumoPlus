abstract final class PortalTextParser {
  static const _months = <String, int>{
    'ENERO': 1,
    'FEBRERO': 2,
    'MARZO': 3,
    'ABRIL': 4,
    'MAYO': 5,
    'JUNIO': 6,
    'JULIO': 7,
    'AGOSTO': 8,
    'SETIEMBRE': 9,
    'SEPTIEMBRE': 9,
    'OCTUBRE': 10,
    'NOVIEMBRE': 11,
    'DICIEMBRE': 12,
  };

  static String normalize(String value) {
    return value
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String key(String value) {
    final upper = normalize(value).toUpperCase();
    final withoutAccents = upper
        .replaceAll(RegExp('[ÁÀÄÂ]'), 'A')
        .replaceAll(RegExp('[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp('[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp('[ÓÒÖÔ]'), 'O')
        .replaceAll(RegExp('[ÚÙÜÛ]'), 'U')
        .replaceAll('Ñ', 'N');
    return withoutAccents
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int month(String value) {
    final normalized = key(value);
    for (final entry in _months.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }

    final withYear = RegExp(
      r'(^|\D)(0?[1-9]|1[0-2])\D+(?:19|20)\d{2}($|\D)',
    ).firstMatch(normalized);
    if (withYear != null) return int.parse(withYear.group(2)!);

    final onlyMonth = RegExp(r'^(0?[1-9]|1[0-2])$').firstMatch(normalized);
    if (onlyMonth != null) return int.parse(onlyMonth.group(1)!);
    throw const FormatException('Mes no reconocido');
  }

  static int year(String value) {
    final match = RegExp(r'(?:19|20)\d{2}').firstMatch(normalize(value));
    if (match == null) throw const FormatException('Ano no reconocido');
    return int.parse(match.group(0)!);
  }

  static DateTime date(String value) {
    final normalized = normalize(value);
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(normalized);
    if (iso != null) {
      return _strictDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }

    final local = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
    ).firstMatch(normalized);
    if (local != null) {
      return _strictDate(
        int.parse(local.group(3)!),
        int.parse(local.group(2)!),
        int.parse(local.group(1)!),
      );
    }
    throw const FormatException('Fecha no reconocida');
  }

  static DateTime _strictDate(int year, int month, int day) {
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      throw const FormatException('Fecha imposible');
    }
    return value;
  }

  static int cents(String value) => (decimal(value) * 100).round();

  static int integer(String value) => decimal(value).round();

  static double decimal(String value) {
    var cleaned = normalize(value).replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (cleaned.isEmpty || cleaned == '-') {
      throw const FormatException('Numero no reconocido');
    }

    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');
    if (lastComma >= 0 && lastDot >= 0) {
      final decimalSeparator = lastComma > lastDot ? ',' : '.';
      final thousandsSeparator = decimalSeparator == ',' ? '.' : ',';
      cleaned = cleaned.replaceAll(thousandsSeparator, '');
      cleaned = cleaned.replaceAll(decimalSeparator, '.');
    } else if (lastComma >= 0) {
      cleaned = _normalizeSingleSeparator(cleaned, ',');
    } else if (lastDot >= 0) {
      cleaned = _normalizeSingleSeparator(cleaned, '.');
    }
    return double.parse(cleaned);
  }

  static String _normalizeSingleSeparator(String value, String separator) {
    final index = value.lastIndexOf(separator);
    final digitsAfter = value.length - index - 1;
    if (digitsAfter == 1 || digitsAfter == 2) {
      final integerPart = value.substring(0, index).replaceAll(separator, '');
      return '$integerPart.${value.substring(index + 1)}';
    }
    return value.replaceAll(separator, '');
  }
}
