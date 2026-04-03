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

  @override
  Widget build(BuildContext context) {
    final weeklySummary = _extractMap(_summary['weekly_summary']);
    final monthlySummary = _extractMap(_summary['monthly_summary']);
    final totalSummary = _buildTopLevelSummary(_summary);
    final selectedExercise = _summary['selected_exercise']?.toString() ?? _summary['exercise']?.toString() ?? _summary['user_id']?.toString() ?? 'Recovery';
    final score = _toDouble(_summary['safe_session_rate'] ?? _summary['score'] ?? _summary['accuracy']) ?? 0;
    final formStatus = _summary['message']?.toString() ?? 'No session yet';
    final weeklyValues = _buildWeeklySeries(weeklySummary);
    final hasWeeklyChartData = weeklyValues.isNotEmpty;
    final hasLatestAnalysis = LatestAnalysisStore.hasResult;

    return AppShell(
      title: 'Progress',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 30),
        children: [
          Text('Recovery Analytics', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28, color: AppColors.white)),
          const SizedBox(height: 10),
          Text(
            'Track rehab recovery, weekly summaries, monthly trends, and session quality from the updated backend.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.68)),
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
                      Text(selectedExercise, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 20)),
                      const SizedBox(height: 6),
                      Text('Form status: $formStatus', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
                    ],
                  ),
                ),
                Text('${score.round()}%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _InfoCard(message: 'Loading backend summary...')
          else if (_error != null && _summary.isEmpty)
            _InfoCard(message: _error!)
          else ...[
            GlassCard(
              radius: 30,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              color: AppColors.white.withValues(alpha: 0.88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Weekly Rehab Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                      TextButton.icon(onPressed: _loadSummary, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (hasWeeklyChartData)
                    SizedBox(height: 190, child: BarChart(_weeklyBarData(context, weeklyValues)))
                  else
                    Container(
                      height: 190,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: AppColors.warmCream.withValues(alpha: 0.6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          'Not enough weekly rehab data yet. Upload a few more rehab sessions to unlock the chart.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: AppColors.warmCream.withValues(alpha: 0.82)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.trending_up_rounded, color: AppColors.white)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weekly Average', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 6),
                              Text(hasWeeklyChartData ? '${_average(weeklyValues).toStringAsFixed(1)}%' : 'N/A', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Weekly Entries', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 6),
                              Text('${weeklySummary['total_sessions'] ?? 0}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.terracotta, fontSize: 20)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _SummaryPanel(title: 'Monthly Rehab Summary', summary: monthlySummary, emptyLabel: 'Monthly summary is not available yet.')),
                const SizedBox(width: 14),
                Expanded(child: _SummaryPanel(title: 'Total Progress Summary', summary: totalSummary, emptyLabel: 'Total recovery analytics will appear after more sessions.')),
              ],
            ),
            const SizedBox(height: 22),
            InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () async {
                await AppHaptics.mediumImpact();
                if (!hasLatestAnalysis) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Latest analysis details are not available in the summary yet. Start a new upload to view full results.')),
                    );
                  }
                  return;
                }
                if (context.mounted) {
                  Navigator.pushNamed(context, AppRoutes.results, arguments: LatestAnalysisStore.latestResult);
                }
              },
              child: GlassCard(
                radius: 26,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                color: Colors.white.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.dustyRose, AppColors.burntOrange]), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.analytics_rounded, color: AppColors.white)),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Open Latest Analysis Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: AppColors.white, fontWeight: FontWeight.w700))),
                    Icon(Icons.arrow_forward_ios_rounded, size: 20, color: AppColors.white.withValues(alpha: 0.45)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Recovery Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: 'New Analysis',
                    subtitle: 'Upload or record again',
                    icon: Icons.cloud_upload_rounded,
                    tint: AppColors.terracotta,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.upload),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
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

  BarChartData _weeklyBarData(BuildContext context, List<double> values) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BarChartData(
      maxY: 100,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      alignment: BarChartAlignment.spaceAround,
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= labels.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(labels[index], style: Theme.of(context).textTheme.bodyMedium),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(values.length, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: values[index],
              width: 18,
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [AppColors.burntOrange, AppColors.terracotta]),
            ),
          ],
        );
      }),
    );
  }

  List<double> _buildWeeklySeries(Map<String, dynamic> summary) {
    const orderedKeys = [
      'safe_session_rate',
      'avg_stability',
      'avg_symmetry',
    ];
    final numericValues = <double>[];
    for (final key in orderedKeys) {
      final value = _toDouble(summary[key]);
      if (value != null) {
        numericValues.add(value);
      }
    }
    final totalSessions = _toDouble(summary['total_sessions']) ?? 0;
    if (totalSessions <= 1) {
      return const <double>[];
    }
    return numericValues;
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.title, required this.summary, required this.emptyLabel});

  final String title;
  final Map<String, dynamic> summary;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          if (summary.isEmpty)
            Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...summary.entries.take(5).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(_pretty(entry.key), style: Theme.of(context).textTheme.bodyMedium)),
                        const SizedBox(width: 10),
                        Flexible(child: Text(_formatValue(entry.value), textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleSmall)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.tint, required this.onTap});

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
            Container(width: 46, height: 46, decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: tint)),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
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

double _average(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
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
