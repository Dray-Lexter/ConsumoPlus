import 'dart:math' as math;

import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/presentation/water_formatters.dart';
import 'package:flutter/material.dart';

class ConsumptionChart extends StatelessWidget {
  const ConsumptionChart({required this.records, super.key});

  final List<BillingRecord> records;

  @override
  Widget build(BuildContext context) {
    final ordered = [...records]
      ..sort((a, b) {
        final year = a.billingYear.compareTo(b.billingYear);
        return year != 0 ? year : a.billingMonth.compareTo(b.billingMonth);
      });
    final visible = ordered.length > 12
        ? ordered.sublist(ordered.length - 12)
        : ordered;
    final description = visible
        .map(
          (record) =>
              '${WaterFormatters.period(record.billingYear, record.billingMonth)}: '
              '${_number(record.consumptionCubicMeters)} metros cubicos',
        )
        .join('; ');

    if (visible.isEmpty) {
      return const Text('No hay consumos guardados para mostrar.');
    }

    return Semantics(
      label: 'Grafico de consumo. $description',
      image: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 176,
              child: CustomPaint(painter: _ConsumptionChartPainter(visible)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final record in visible)
                  Text(
                    '${WaterFormatters.period(record.billingYear, record.billingMonth)} '
                    '${_number(record.consumptionCubicMeters)} m³',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _ConsumptionChartPainter extends CustomPainter {
  const _ConsumptionChartPainter(this.records);

  final List<BillingRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    final line = Paint()
      ..color = AppColors.water
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final point = Paint()
      ..color = AppColors.water
      ..style = PaintingStyle.fill;
    const inset = 12.0;
    final chartHeight = size.height - inset * 2;
    final chartWidth = size.width - inset * 2;
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      axis,
    );
    final maximum = math.max(
      1.0,
      records.map((record) => record.consumptionCubicMeters).reduce(math.max),
    );
    final path = Path();
    for (var index = 0; index < records.length; index++) {
      final x = records.length == 1
          ? size.width / 2
          : inset + chartWidth * index / (records.length - 1);
      final y =
          size.height -
          inset -
          chartHeight * records[index].consumptionCubicMeters / maximum;
      final offset = Offset(x, y);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(offset, 4, point);
    }
    if (records.length > 1) canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _ConsumptionChartPainter oldDelegate) {
    return oldDelegate.records != records;
  }
}
