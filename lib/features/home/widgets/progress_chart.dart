import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../training/models/training_session.dart';
import '../../training/providers/session_repository.dart';

class ProgressChart extends ConsumerWidget {
  const ProgressChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(trainingHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('データを読み込めませんでした')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const _EmptyChart();
        }
        // 最新7件を古い順に並べ直してグラフ用データを作成
        final chartSessions = sessions.reversed.take(7).toList();
        return _buildChart(context, chartSessions);
      },
    );
  }

  Widget _buildChart(BuildContext context, List<TrainingSession> sessions) {
    final spots = sessions.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.bestHoldSeconds);
    }).toList();

    final maxY = sessions
        .map((s) => s.bestHoldSeconds)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '最長ホールド推移',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '過去${sessions.length}回',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 5 ? maxY / 3 : 5,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: maxY > 5 ? maxY / 3 : 5,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}s',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= sessions.length)
                        return const SizedBox.shrink();
                      final date = sessions[idx].date;
                      return Text(
                        '${date.month}/${date.day}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (sessions.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.3,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 5,
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.3),
                        AppTheme.primaryColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 直近ベスト表示
        _buildSummaryRow(sessions),
      ],
    );
  }

  Widget _buildSummaryRow(List<TrainingSession> sessions) {
    final best = sessions
        .map((s) => s.bestHoldMs)
        .reduce((a, b) => a > b ? a : b);
    final totalCount = sessions.fold<int>(0, (sum, s) => sum + s.holdCount);
    return Row(
      children: [
        _buildSummaryItem('🏆 自己ベスト', '${(best / 1000).toStringAsFixed(1)}秒'),
        const SizedBox(width: 24),
        _buildSummaryItem('🔥 総ホールド数', '$totalCount回'),
        const SizedBox(width: 24),
        _buildSummaryItem('📅 セッション数', '${sessions.length}回'),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'AI解析を使ってトレーニングすると',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Text(
            'ここにグラフが表示されます',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
