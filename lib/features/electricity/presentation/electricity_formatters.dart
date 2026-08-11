abstract final class ElectricityFormatters {
  static const _months = [
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
    final value = cents.abs();
    return '${sign}S/ ${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';
  }

  static String period(int year, int month) => '${_months[month - 1]} $year';

  static String energy(int wattHours) {
    final kwh = wattHours / 1000;
    return '${kwh == kwh.roundToDouble() ? kwh.toStringAsFixed(0) : kwh.toStringAsFixed(1)} kWh';
  }

  static String date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String dateTime(DateTime value) {
    final local = value.toLocal();
    return '${date(local)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
