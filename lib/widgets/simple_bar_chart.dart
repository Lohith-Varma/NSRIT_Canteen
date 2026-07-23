import 'package:flutter/material.dart';

class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({required this.label, required this.value});
}

class SimpleBarChart extends StatelessWidget {
  final String title;
  final List<ChartPoint> points;
  final Color color;

  const SimpleBarChart({
    super.key,
    required this.title,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold(0.0, (max, point) {
      return point.value > max ? point.value : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: points.isEmpty
                  ? const Center(child: Text('No data available'))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: points.map((point) {
                        final heightFactor = maxValue == 0
                            ? 0.04
                            : (point.value / maxValue).clamp(0.04, 1.0);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      heightFactor: heightFactor,
                                      child: Tooltip(
                                        message:
                                            '${point.label}: ${point.value.toStringAsFixed(2)}',
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.82,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const SizedBox.expand(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  point.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
