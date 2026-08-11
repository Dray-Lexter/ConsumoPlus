abstract final class WaterFormatters {
  static const _months = <String>[
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static String money(int cents) {
    final sign = cents < 0 ? '-' : '';
    final absolute = cents.abs();
    return '${sign}S/ ${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }

  static String period(int year, int month) => '${_months[month - 1]} $year';

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String dateTime(DateTime value) {
    value = value.toLocal();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${date(value)} $hour:$minute';
  }
}
