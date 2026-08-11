import 'dart:math' as math;

import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/presentation/electricity_formatters.dart';
import 'package:flutter/material.dart';

class ElectricityConsumptionChart extends StatelessWidget {
  const ElectricityConsumptionChart({required this.records, super.key});

  final List<ElectricityConsumptionRecord> records;

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
              '${ElectricityFormatters.period(record.billingYear, record.billingMonth)}: '
              '${ElectricityFormatters.energy(record.consumptionWh)}',
        )
        .join('; ');

    if (visible.isEmpty) {
      return const Text('No hay consumos guardados para mostrar.');
    }

    return Semantics(
      key: const Key('electricityConsumptionChart'),
      label: 'Gráfico de consumo eléctrico. $description',
      image: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Center(
                  child: RotatedBox(quarterTurns: 3, child: Text('kWh')),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: SizedBox(
                    height: 176,
                    child: CustomPaint(
                      painter: _ElectricityConsumptionChartPainter(visible),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final record in visible)
                  Text(
                    ElectricityFormatters.period(
                      record.billingYear,
                      record.billingMonth,
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ElectricityConsumptionChartPainter extends CustomPainter {
  const _ElectricityConsumptionChartPainter(this.records);

  final List<ElectricityConsumptionRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    final line = Paint()
      ..color = AppColors.electricity
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final point = Paint()
      ..color = AppColors.electricity
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
      1,
      records.map((record) => record.consumptionWh).reduce(math.max),
    );
    final path = Path();
    for (var index = 0; index < records.length; index++) {
      final x = records.length == 1
          ? size.width / 2
          : inset + chartWidth * index / (records.length - 1);
      final y =
          size.height -
          inset -
          chartHeight * records[index].consumptionWh / maximum;
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
  bool shouldRepaint(
    covariant _ElectricityConsumptionChartPainter oldDelegate,
  ) => oldDelegate.records != records;
}
