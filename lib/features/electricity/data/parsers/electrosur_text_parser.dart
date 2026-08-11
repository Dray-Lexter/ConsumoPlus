abstract final class ElectrosurTextParser {
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

  static String normalize(String value) =>
      value.replaceAll('\u00a0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String key(String value) {
    final upper = normalize(value).toUpperCase();
    return upper
        .replaceAll(RegExp('[ÁÀÄÂ]'), 'A')
        .replaceAll(RegExp('[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp('[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp('[ÓÒÖÔ]'), 'O')
        .replaceAll(RegExp('[ÚÙÜÛ]'), 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static ({int year, int month, String code}) period(String value) {
    final normalized = key(value);
    final compact = RegExp(
      r'(^|\D)((?:19|20)\d{2})(0[1-9]|1[0-2])($|\D)',
    ).firstMatch(normalized);
    if (compact != null) {
      final year = int.parse(compact.group(2)!);
      final month = int.parse(compact.group(3)!);
      return (
        year: year,
        month: month,
        code: '$year${month.toString().padLeft(2, '0')}',
      );
    }

    final separated = RegExp(
      r'(^|\D)(0?[1-9]|1[0-2])\D+((?:19|20)\d{2})($|\D)',
    ).firstMatch(normalized);
    if (separated != null) {
      final month = int.parse(separated.group(2)!);
      final year = int.parse(separated.group(3)!);
      return (
        year: year,
        month: month,
        code: '$year${month.toString().padLeft(2, '0')}',
      );
    }

    final yearMatch = RegExp(r'(?:19|20)\d{2}').firstMatch(normalized);
    if (yearMatch != null) {
      for (final entry in _months.entries) {
        if (normalized.contains(entry.key)) {
          final year = int.parse(yearMatch.group(0)!);
          final month = entry.value;
          return (
            year: year,
            month: month,
            code: '$year${month.toString().padLeft(2, '0')}',
          );
        }
      }
    }
    throw const FormatException('Periodo no reconocido');
  }

  static DateTime date(String value) {
    final normalized = normalize(value);
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
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(normalized);
    if (iso != null) {
      return _strictDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
    throw const FormatException('Fecha no reconocida');
  }

  static DateTime _strictDate(int year, int month, int day) {
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException('Fecha imposible');
    }
    return parsed;
  }

  static int cents(String value) {
    final amount = RegExp(r'-?\d+(?:[.,]\d+)*').firstMatch(normalize(value));
    if (amount == null) {
      throw const FormatException('Importe no reconocido');
    }
    var cleaned = amount.group(0)!;
    final negative = cleaned.startsWith('-');
    cleaned = cleaned.replaceAll('-', '');
    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');
    String integerPart;
    String decimals;

    if (lastComma >= 0 && lastDot >= 0) {
      final decimalIndex = lastComma > lastDot ? lastComma : lastDot;
      integerPart = cleaned
          .substring(0, decimalIndex)
          .replaceAll(RegExp(r'[,.]'), '');
      decimals = cleaned.substring(decimalIndex + 1);
    } else if (lastComma >= 0 || lastDot >= 0) {
      final decimalIndex = lastComma >= 0 ? lastComma : lastDot;
      integerPart = cleaned
          .substring(0, decimalIndex)
          .replaceAll(RegExp(r'[,.]'), '');
      decimals = cleaned.substring(decimalIndex + 1);
    } else {
      integerPart = cleaned;
      decimals = '';
    }

    if (integerPart.isEmpty ||
        decimals.length > 2 &&
            decimals.substring(2).split('').any((digit) => digit != '0')) {
      throw const FormatException('Importe con fracción no soportada');
    }
    final centsDigits = decimals.padRight(2, '0').substring(0, 2);
    final result = int.parse(integerPart) * 100 + int.parse(centsDigits);
    return negative ? -result : result;
  }

  static int wattHours(String value) {
    final cleaned = normalize(value).replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (cleaned.isEmpty) throw const FormatException('Consumo no reconocido');
    final separator = cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')
        ? ','
        : '.';
    final normalized = separator == ','
        ? cleaned.replaceAll('.', '').replaceAll(',', '.')
        : cleaned.replaceAll(',', '');
    final wh = double.parse(normalized) * 1000;
    if ((wh - wh.round()).abs() > 0.000001) {
      throw const FormatException('Consumo no representable en Wh');
    }
    return wh.round();
  }
}
