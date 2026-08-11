abstract final class UpcomingDatesCopy {
  static const sectionTitle = 'Próximas fechas';
  static const waterService = 'Agua';
  static const waterProvider = 'EPS Tacna';
  static const electricityService = 'Electricidad';
  static const electricityProvider = 'Electrosur';
  static const estimatedIssue = 'Próximo recibo estimado';
  static const estimatedDue = 'Próximo vencimiento estimado';
  static const officialDue = 'Vence tu recibo';
  static const pendingDue = 'Vencimiento pendiente de actualización';
  static const pendingDueDetail =
      'Actualiza Electrosur para consultar la fecha del nuevo recibo.';
  static const expectedToday = 'Esperado hoy';
  static const dueToday = 'Vence hoy';

  static const shortMonths = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const fullMonths = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String futureDistance(int days) =>
      days == 1 ? 'Falta 1 día' : 'Faltan $days días';

  static String pastDueDistance(int days) =>
      days == 1 ? 'Venció hace 1 día' : 'Venció hace $days días';

  static String shortDate(DateTime value) =>
      '${value.day} ${shortMonths[value.month - 1]}';

  static String fullDate(DateTime value) =>
      '${value.day} de ${fullMonths[value.month - 1]} de ${value.year}';
}
