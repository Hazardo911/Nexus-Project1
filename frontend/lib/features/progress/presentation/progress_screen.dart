import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/latest_analysis_store.dart';
import '../../../core/route_names.dart';
import '../../../core/services/nexus_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic> _summary = <String, dynamic>{};
  bool _loading = true;
  String? _error;
  bool _didLoadArgs = false;
  String _userId = NexusApiService.defaultUserId;
  _MetricType _selectedMetric = _MetricType.safety;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    _didLoadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _summary = args.cast<String, dynamic>();
      _userId = _summary['user_id']?.toString() ?? NexusApiService.defaultUserId;
      _loading = false;
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await NexusApiService.getSummary(userId: _userId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
        _error = null;
      });
    } on NexusApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _openLatestResult() async {
    await AppHaptics.mediumImpact();
    final localLatest = LatestAnalysisStore.latestResult;
    if (localLatest != null && localLatest.isNotEmpty && mounted) {
      Navigator.pushNamed(context, AppRoutes.results, arguments: localLatest);
      return;
    }

    try {
      final latest = await NexusApiService.getLatestResult(userId: _userId);
      if (!mounted) return;
      if ((latest['message']?.toString().contains('No analysis') ?? false) || latest.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No latest analysis found yet. Upload a session first.')),
        );
        return;
      }
      LatestAnalysisStore.save(latest);
      if (latest['landmarks'] != null || latest['connections'] != null) {
        LatestAnalysisStore.saveVisual(latest);
      }
      Navigator.pushNamed(context, AppRoutes.results, arguments: latest);
    } on NexusApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklySummary = _extractMap(_summary['weekly_summary']);
    final monthlySummary = _extractMap(_summary['monthly_summary']);
    final totalSummary = _buildTopLevelSummary(_summary);
    final selectedExercise = _summary['selected_exercise']?.toString() ??
        _summary['exercise']?.toString() ??
        _summary['user_id']?.toString() ??
        'Recovery';
    final statusText = _summary['message']?.toString() ?? 'Tracking your movement quality';

    final chartPoints = _buildMetricPoints(
      metric: _selectedMetric,
      weekly: weeklySummary,
      monthly: monthlySummary,
      total: totalSummary,
    );
    final averageScore = chartPoints.isEmpty ? 0.0 : chartPoints.map((point) => point.value).reduce((a, b) => a + b) / chartPoints.length;
    final highlight = _metricHighlight(_selectedMetric, chartPoints);

    return AppShell(
      title: 'Progress',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 30),
        children: [
          Text(
            'Recovery Analytics',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 28,
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Track how your form, safety, symmetry, and stability are trending over time.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.68),
                ),
          ),
          const SizedBox(height: 22),
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(22),
            color: Colors.white.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.heroGradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.monitor_heart_rounded, color: AppColors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedExercise,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.white,
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.72),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _InfoCard(message: 'Loading recovery analytics...')
          else if (_error != null && _summary.isEmpty)
            _InfoCard(message: _error!)
          else ...[
            Text(
              'Interactive Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _MetricType.values
                  .map(
                    (metric) => _MetricChip(
                      label: metric.label,
                      tint: metric.tint,
                      selected: metric == _selectedMetric,
                      onTap: () => setState(() => _selectedMetric = metric),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            GlassCard(
              radius: 30,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              color: AppColors.white.withValues(alpha: 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedMetric.label} Trend',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap another metric to explore a different view.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.softCharcoal.withValues(alpha: 0.64),
                                ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _loadSummary,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (chartPoints.isEmpty)
                    Container(
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: AppColors.warmCream.withValues(alpha: 0.8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          'Run a few more sessions to unlock this graph view.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 220,
                      child: LineChart(_buildLineChartData(context, chartPoints, _selectedMetric.tint)),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _TrendValueCard(
                          label: 'Average',
                          value: '${averageScore.toStringAsFixed(1)}${_selectedMetric.suffix}',
                          tint: _selectedMetric.tint,
                        ),
                        _TrendValueCard(
                          label: 'Best Point',
                          value: highlight,
                          tint: AppColors.sageGreen,
                        ),
                        _TrendValueCard(
                          label: 'Data Points',
                          value: '${chartPoints.length}',
                          tint: AppColors.burntOrange,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Summary Panels',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: 14),
            _SummaryPanel(
              title: 'This Week',
              summary: weeklySummary,
              emptyLabel: 'Weekly summary is not available yet.',
            ),
            const SizedBox(height: 14),
            _SummaryPanel(
              title: 'This Month',
              summary: monthlySummary,
              emptyLabel: 'Monthly summary is not available yet.',
            ),
            const SizedBox(height: 14),
            _SummaryPanel(
              title: 'Overall Progress',
              summary: totalSummary,
              emptyLabel: 'Overall progress summary will appear after more sessions.',
            ),
            const SizedBox(height: 22),
            InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: _openLatestResult,
              child: GlassCard(
                radius: 26,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                color: Colors.white.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.dustyRose, AppColors.burntOrange]),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: AppColors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Open Latest Analysis Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 20, color: AppColors.white.withValues(alpha: 0.45)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Recovery Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: 172,
                  child: _ActionCard(
                    title: 'New Analysis',
                    subtitle: 'Upload or record again',
                    icon: Icons.cloud_upload_rounded,
                    tint: AppColors.terracotta,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.upload),
                  ),
                ),
                SizedBox(
                  width: 172,
                  child: _ActionCard(
                    title: 'Skeleton View',
                    subtitle: 'Check live tracking',
                    icon: Icons.accessibility_new_rounded,
                    tint: AppColors.sageGreen,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.skeleton),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(BuildContext context, List<_MetricPoint> points, Color tint) {
    return LineChartData(
      minY: 0,
      maxY: _selectedMetric.maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _selectedMetric.gridStep,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.softCharcoal.withValues(alpha: 0.08),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 14,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipColor: (_) => const Color(0xFF121821),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final index = spot.x.toInt();
              final label = index >= 0 && index < points.length ? points[index].label : 'Point';
              return LineTooltipItem(
                '$label\n${spot.y.toStringAsFixed(1)}${_selectedMetric.suffix}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.35),
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: _selectedMetric.gridStep,
            getTitlesWidget: (value, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.softCharcoal.withValues(alpha: 0.56),
                      ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  points[index].label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.softCharcoal.withValues(alpha: 0.72),
                      ),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: tint,
          barWidth: 4,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4.5,
              color: tint,
              strokeColor: Colors.white,
              strokeWidth: 2,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tint.withValues(alpha: 0.24),
                tint.withValues(alpha: 0.03),
              ],
            ),
          ),
          spots: List.generate(
            points.length,
            (index) => FlSpot(index.toDouble(), points[index].value),
          ),
        ),
      ],
    );
  }
}

enum _MetricType {
  safety('Safety', AppColors.sageGreen, '%', 100, 25),
  stability('Stability', AppColors.terracotta, '%', 100, 25),
  symmetry('Symmetry', AppColors.burntOrange, '%', 100, 25),
  kneeAngle('Knee Angle', AppColors.gold, 'deg', 180, 45);

  const _MetricType(this.label, this.tint, this.suffix, this.maxY, this.gridStep);

  final String label;
  final Color tint;
  final String suffix;
  final double maxY;
  final double gridStep;
}

class _MetricPoint {
  const _MetricPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? tint : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? tint : Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.white : Colors.white.withValues(alpha: 0.84),
              ),
        ),
      ),
    );
  }
}

class _TrendValueCard extends StatelessWidget {
  const _TrendValueCard({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.softCharcoal.withValues(alpha: 0.68),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.softCharcoal,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.title,
    required this.summary,
    required this.emptyLabel,
  });

  final String title;
  final Map<String, dynamic> summary;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
          const SizedBox(height: 14),
          if (summary.isEmpty)
            Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...summary.entries
                .where((entry) => entry.value != null && entry.key != 'message')
                .take(5)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SummaryValueRow(
                      label: _pretty(entry.key),
                      value: _formatValue(entry.value),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SummaryValueRow extends StatelessWidget {
  const _SummaryValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softCharcoal.withValues(alpha: 0.68),
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.softCharcoal,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        color: Colors.white.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.68)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

List<_MetricPoint> _buildMetricPoints({
  required _MetricType metric,
  required Map<String, dynamic> weekly,
  required Map<String, dynamic> monthly,
  required Map<String, dynamic> total,
}) {
  double? weeklyValue;
  double? monthlyValue;
  double? totalValue;

  switch (metric) {
    case _MetricType.safety:
      weeklyValue = _percentish(weekly['safe_session_rate']);
      monthlyValue = _percentish(monthly['safe_session_rate']);
      totalValue = _percentish(total['safe_session_rate']);
      break;
    case _MetricType.stability:
      weeklyValue = _percentish(weekly['avg_stability']);
      monthlyValue = _percentish(monthly['avg_stability']);
      totalValue = _percentish(total['stability_trend'] ?? weekly['avg_stability'] ?? monthly['avg_stability']);
      break;
    case _MetricType.symmetry:
      weeklyValue = _percentish(weekly['avg_symmetry']);
      monthlyValue = _percentish(monthly['avg_symmetry']);
      totalValue = _percentish(total['symmetry_trend'] ?? weekly['avg_symmetry'] ?? monthly['avg_symmetry']);
      break;
    case _MetricType.kneeAngle:
      weeklyValue = _toDouble(weekly['avg_knee_angle']);
      monthlyValue = _toDouble(monthly['avg_knee_angle']);
      totalValue = _toDouble(total['avg_knee_angle'] ?? total['best_knee_angle'] ?? monthly['avg_knee_angle']);
      break;
  }

  final points = <_MetricPoint>[
    if (weeklyValue != null) _MetricPoint(label: 'Week', value: weeklyValue),
    if (monthlyValue != null) _MetricPoint(label: 'Month', value: monthlyValue),
    if (totalValue != null) _MetricPoint(label: 'Overall', value: totalValue),
  ];
  return points;
}

String _metricHighlight(_MetricType metric, List<_MetricPoint> points) {
  if (points.isEmpty) return 'N/A';
  final best = points.reduce((a, b) => a.value >= b.value ? a : b);
  return '${best.label} ${best.value.toStringAsFixed(1)}${metric.suffix}';
}

Map<String, dynamic> _extractMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, dynamic val) => MapEntry(key.toString(), val));
  return <String, dynamic>{};
}

Map<String, dynamic> _buildTopLevelSummary(Map<String, dynamic> summary) {
  const keys = [
    'total_sessions',
    'avg_knee_angle',
    'best_knee_angle',
    'rom_improvement',
    'symmetry_trend',
    'stability_trend',
    'speed_trend',
    'coordination_trend',
    'safe_session_rate',
  ];
  final extracted = <String, dynamic>{};
  for (final key in keys) {
    if (summary.containsKey(key) && summary[key] != null) {
      extracted[key] = summary[key];
    }
  }
  return extracted;
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double? _percentish(Object? value) {
  final numeric = _toDouble(value);
  if (numeric == null) return null;
  return numeric <= 1 ? numeric * 100 : numeric;
}

String _pretty(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatValue(Object? value) {
  if (value is num) {
    return value is int ? value.toString() : value.toStringAsFixed(2);
  }
  if (value is List) {
    return value.join(', ');
  }
  if (value is Map) {
    return '${value.length} items';
  }
  return value?.toString() ?? 'N/A';
}
