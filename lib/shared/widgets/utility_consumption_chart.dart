import 'dart:math' as math;

import 'package:consumo_plus/app/theme/app_colors.dart';
import 'package:consumo_plus/app/theme/app_radii.dart';
import 'package:consumo_plus/app/theme/app_spacing.dart';
import 'package:consumo_plus/app/theme/utility_visual_config.dart';
import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UtilityConsumptionPoint {
  const UtilityConsumptionPoint({
    required this.year,
    required this.month,
    required this.value,
    required this.periodLabel,
    required this.displayValue,
    required this.semanticValue,
    this.contextualValue,
  });

  final int year;
  final int month;
  final double value;
  final String periodLabel;
  final String displayValue;
  final String semanticValue;
  final String? contextualValue;
}

List<UtilityConsumptionPoint> visibleUtilityConsumptionPoints(
  List<UtilityConsumptionPoint> points, {
  required int maxPeriods,
}) {
  assert(maxPeriods > 0);
  final ordered = [...points]
    ..sort((left, right) {
      final year = left.year.compareTo(right.year);
      return year != 0 ? year : left.month.compareTo(right.month);
    });
  return ordered.length > maxPeriods
      ? ordered.sublist(ordered.length - maxPeriods)
      : ordered;
}

class UtilityConsumptionChart extends StatefulWidget {
  const UtilityConsumptionChart({
    required this.utilityType,
    required this.unit,
    required this.semanticTitle,
    required this.points,
    this.maxPeriods = 12,
    this.onPointSelected,
    super.key,
  }) : assert(maxPeriods > 0);

  final UtilityType utilityType;
  final String unit;
  final String semanticTitle;
  final List<UtilityConsumptionPoint> points;
  final int maxPeriods;
  final ValueChanged<UtilityConsumptionPoint>? onPointSelected;

  @override
  State<UtilityConsumptionChart> createState() =>
      _UtilityConsumptionChartState();
}

class _UtilityConsumptionChartState extends State<UtilityConsumptionChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant UtilityConsumptionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.points, widget.points) ||
        oldWidget.maxPeriods != widget.maxPeriods) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleUtilityConsumptionPoints(
      widget.points,
      maxPeriods: widget.maxPeriods,
    );
    if (visible.isEmpty) {
      return const Text('No hay consumos guardados para mostrar.');
    }

    final scale = _ChartScale.fromPoints(visible);
    final description = visible
        .map((point) => '${point.periodLabel}: ${point.semanticValue}')
        .join('; ');
    final accent = widget.utilityType.visual.accent;
    final selected = _selectedIndex == null ? null : visible[_selectedIndex!];

    return Semantics(
      label: '${widget.semanticTitle}. $description',
      image: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 176,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.unit,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (
                              var index = scale.yTicks.length - 1;
                              index >= 0;
                              index--
                            )
                              Text(
                                _formatAxisValue(scale.yTicks[index]),
                                key: Key(
                                  'chartYAxis-${scale.yTicks.length - 1 - index}',
                                ),
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.mutedInk),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 176,
                        child: LayoutBuilder(
                          builder: (context, constraints) => GestureDetector(
                            key: const Key('utilityChartPlot'),
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final index = _nearestPointIndex(
                                details.localPosition.dx,
                                constraints.maxWidth,
                                visible.length,
                              );
                              setState(() => _selectedIndex = index);
                              widget.onPointSelected?.call(visible[index]);
                            },
                            child: CustomPaint(
                              painter: UtilityConsumptionChartPainter(
                                points: visible,
                                color: accent,
                                minimumY: scale.minimum,
                                maximumY: scale.maximum,
                                yTicks: scale.yTicks,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _XAxis(points: visible),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              liveRegion: true,
              label: _selectionLabel(selected),
              child: ExcludeSemantics(
                child: Container(
                  key: const Key('utilityChartTooltip'),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: widget.utilityType.visual.container,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: accent),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runAlignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        selected.periodLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        selected.displayValue,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (selected.contextualValue != null)
                        Text(
                          selected.contextualValue!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static int _nearestPointIndex(double dx, double width, int count) {
    if (count <= 1 || width <= 0) return 0;
    final normalized = (dx / width).clamp(0.0, 1.0);
    return (normalized * (count - 1)).round();
  }

  static String _selectionLabel(UtilityConsumptionPoint point) {
    final context = point.contextualValue;
    return context == null
        ? '${point.periodLabel}: ${point.semanticValue}'
        : '${point.periodLabel}: ${point.semanticValue}, $context';
  }
}

class _XAxis extends StatelessWidget {
  const _XAxis({required this.points});

  final List<UtilityConsumptionPoint> points;

  @override
  Widget build(BuildContext context) {
    final multipleYears = points.map((point) => point.year).toSet().length > 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < points.length; index++)
          Expanded(
            child: _showLabel(index)
                ? Column(
                    key: index == points.length - 1
                        ? const Key('chartLatestPoint')
                        : null,
                    children: [
                      SizedBox(
                        key: Key(
                          'chartXAxis-${_month(points[index].month)}-${points[index].year}',
                        ),
                        child: Text(
                          _month(points[index].month),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: index == points.length - 1
                                    ? Theme.of(context).colorScheme.primary
                                    : AppColors.mutedInk,
                                fontWeight: index == points.length - 1
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                      if (_showYear(index, multipleYears))
                        Text(
                          '${points[index].year}',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.mutedInk),
                        ),
                      if (index == points.length - 1)
                        Text(
                          'Actual',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  bool _showLabel(int index) =>
      points.length <= 6 || index.isEven || index == points.length - 1;

  bool _showYear(int index, bool multipleYears) {
    if (!multipleYears) return false;
    return index == 0 ||
        index == points.length - 1 ||
        points[index - 1].year != points[index].year;
  }
}

class UtilityConsumptionChartPainter extends CustomPainter {
  const UtilityConsumptionChartPainter({
    required this.points,
    required this.color,
    required this.minimumY,
    required this.maximumY,
    required this.yTicks,
  });

  final List<UtilityConsumptionPoint> points;
  final Color color;
  final double minimumY;
  final double maximumY;
  final List<double> yTicks;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.75)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final latestHalo = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    const horizontalInset = 6.0;
    const verticalInset = 7.0;
    final chartHeight = size.height - verticalInset * 2;
    final chartWidth = size.width - horizontalInset * 2;
    for (final tick in yTicks) {
      final y = _yFor(tick, chartHeight, verticalInset);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }

    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : horizontalInset + chartWidth * index / (points.length - 1);
      final y = _yFor(points[index].value, chartHeight, verticalInset);
      final offset = Offset(x, y);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      if (index == points.length - 1) {
        canvas.drawCircle(offset, 9, latestHalo);
        canvas.drawCircle(offset, 5.5, pointPaint);
      } else {
        canvas.drawCircle(offset, 4, pointPaint);
      }
    }
    if (points.length > 1) canvas.drawPath(path, line);
  }

  double _yFor(double value, double height, double inset) {
    final normalized = (value - minimumY) / (maximumY - minimumY);
    return inset + height * (1 - normalized.clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(covariant UtilityConsumptionChartPainter oldDelegate) {
    return !listEquals(oldDelegate.points, points) ||
        oldDelegate.color != color ||
        oldDelegate.minimumY != minimumY ||
        oldDelegate.maximumY != maximumY ||
        !listEquals(oldDelegate.yTicks, yTicks);
  }
}

class _ChartScale {
  const _ChartScale({
    required this.minimum,
    required this.maximum,
    required this.yTicks,
  });

  factory _ChartScale.fromPoints(List<UtilityConsumptionPoint> points) {
    final minimumValue = points.map((point) => point.value).reduce(math.min);
    final maximumValue = points.map((point) => point.value).reduce(math.max);
    final rawRange = maximumValue - minimumValue;
    final minimumSpan = math.max(maximumValue.abs() * 0.20, 1.0);
    final span = math.max(rawRange * 1.35, minimumSpan);
    final padding = (span - rawRange) / 2;
    final minimum = math.max(0.0, minimumValue - padding);
    final maximum = math.max(maximumValue + padding, minimum + 1);
    final ticks = List<double>.generate(
      4,
      (index) => minimum + (maximum - minimum) * index / 3,
    );
    return _ChartScale(minimum: minimum, maximum: maximum, yTicks: ticks);
  }

  final double minimum;
  final double maximum;
  final List<double> yTicks;
}

String _formatAxisValue(double value) {
  if (value.abs() >= 10 || value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _month(int month) => const [
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
][month - 1];
