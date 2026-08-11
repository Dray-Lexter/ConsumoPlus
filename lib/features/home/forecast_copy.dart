import 'domain/forecast/forecast_models.dart';
import 'domain/forecast/service_forecast_calculator.dart';

abstract final class ForecastCopy {
  static const sectionTitle = 'Tu consumo estimado';
  static const consumptionEstimate = 'Consumo estimado';
  static const paymentEstimate = 'Pago estimado';
  static const insufficientStatus = 'Historial insuficiente';
  static const notEnoughTitle = 'Aún necesitamos más historial';
  static const notEnoughDetail =
      'ConsumoPlus necesita al menos 6 meses para realizar una estimación.';
  static const irregularHistory =
      'Historial insuficiente o irregular para estimar';
  static const preliminary = 'Estimación preliminar';
  static const orientative = 'Estimación orientativa';
  static const disclaimer =
      'Las estimaciones son orientativas y no garantizan el consumo ni el importe futuro.';
  static const variableHistory =
      'Tu historial presenta bastante variación, por lo que el rango '
      'estimado es más amplio.';

  static const _months = <String>[
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

  static String period(MonthPeriod value) =>
      'Estimación para ${_months[value.month - 1]} de ${value.year}';

  static String history(ForecastStatus status, int sampleCount) =>
      status == ForecastStatus.sufficient
      ? 'Basado en $sampleCount meses de historial'
      : preliminary;

  static String trend(TrendClassification value) => switch (value) {
    TrendClassification.favorable => '🙂 Tendencia favorable',
    TrendClassification.stable => '😐 Consumo estable',
    TrendClassification.rising => '🙁 Tendencia al alza',
  };

  static String semanticTrend(TrendClassification value) => switch (value) {
    TrendClassification.favorable => 'Tendencia favorable',
    TrendClassification.stable => 'Consumo estable',
    TrendClassification.rising => 'Tendencia al alza',
  };

  static String consumptionRange(SeriesForecast value, String unit) =>
      '${_decimal(value.lower)}–${_decimal(value.upper)} $unit';

  static String costRange(SeriesForecast value) =>
      'S/ ${_money(value.lower)}–${_money(value.upper)}';

  static String consumptionVariation(double? value) => _variation(
    value,
    more: 'más de consumo que el último mes',
    less: 'menos de consumo que el último mes',
    similar: 'Similar al último mes',
  );

  static String costVariation(double? value) => _variation(
    value,
    more: 'más de importe que el último periodo',
    less: 'menos de importe que el último periodo',
    similar: 'Importe similar al último periodo',
  );

  static String _variation(
    double? value, {
    required String more,
    required String less,
    required String similar,
  }) {
    if (value == null || !value.isFinite) return similar;
    final rounded = value.round();
    if (rounded == 0) return similar;
    return '≈ ${rounded.abs()} % ${rounded > 0 ? more : less}';
  }

  static String _decimal(double value) {
    final rounded = value.toStringAsFixed(1);
    final compact = rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
    return compact.replaceAll('.', ',');
  }

  static String _money(double cents) => (cents / 100).toStringAsFixed(2);
}
