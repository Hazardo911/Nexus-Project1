import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final summary = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    final mode = _firstString(summary, const ['mode']) ?? 'fitness';
    final isRehabMode = mode.toLowerCase() == 'rehab';
    final selectedExercise = _firstString(summary, const ['selected_exercise', 'exercise']) ?? 'Workout';
    final formStatus = _firstString(summary, const ['form_status']) ?? 'Pending';
    final score = _resolveDisplayScore(summary, isRehabMode);
    final confidence = _firstNum(summary, const ['confidence', 'model.confidence']);
    final errorCategories = _stringList(summary['error_categories']);
    final warnings = _stringList(summary['warnings']);
    final riskFlags = _stringList(summary['risk_flags']);
    final feedback = _stringList(summary['feedback']);
    final features = _extractFeatureMap(summary);
    final weeklySummary = _extractMap(summary['weekly_summary']);
    final monthlySummary = _extractMap(summary['monthly_summary']);
    final topSuggestions = _extractSuggestions(summary);
    final scoreTint = _scoreColor(score, formStatus, isRehabMode, summary);

    final coachStatus = _coachStatus(formStatus, score, isRehabMode, summary);
    final wins = _buildWins(features, feedback, formStatus, isRehabMode, summary);
    final fixes = _buildFixes(errorCategories, warnings, riskFlags, features, isRehabMode);
    final nextSteps = _buildNextSteps(selectedExercise, errorCategories, features, isRehabMode);
    final quickStats = _buildQuickStats(features, confidence, score, isRehabMode, summary);
    final topFix = fixes.isNotEmpty ? fixes.first : 'Keep repeating the same setup and try to make the next rep smoother.';
    final keyMetrics = _buildKeyMetrics(features);

    return AppShell(
      title: 'Results',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _statusColor(formStatus, isRehabMode).withValues(alpha: 0.22),
                  const Color(0xFF1C2633),
                  const Color(0xFF141B24),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _statusColor(formStatus, isRehabMode).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        coachStatus.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _statusColor(formStatus, isRehabMode),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const Spacer(),
                    if (confidence != null)
                      Text(
                        '${_displayPercent(confidence).toStringAsFixed(0)}% confidence',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.72)),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '$selectedExercise Analysis',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 30,
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  _headlineMessage(formStatus, score, selectedExercise, isRehabMode),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.76),
                        height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _HeroStat(label: isRehabMode ? 'Safety Score' : 'Form Score', value: '$score/100', tint: scoreTint)),
                    const SizedBox(width: 12),
                    Expanded(child: _HeroStat(label: isRehabMode ? 'Safety' : 'Form', value: _friendlyForm(formStatus, isRehabMode), tint: _statusColor(formStatus, isRehabMode))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Quick Read', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: quickStats
                .map(
                  (stat) => SizedBox(
                    width: 116,
                    child: _QuickStatCard(stat: stat),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          _CoachCard(
            title: isRehabMode ? 'What Looked Safe' : 'What You Did Well',
            tint: AppColors.sageGreen,
            icon: Icons.thumb_up_alt_rounded,
            items: wins,
          ),
          const SizedBox(height: 16),
          _CoachCard(
            title: 'Fix One Thing First',
            tint: AppColors.gold,
            icon: Icons.track_changes_rounded,
            items: [topFix],
          ),
          const SizedBox(height: 16),
          _CoachCard(
            title: isRehabMode ? 'What To Be Careful About' : 'What To Fix',
            tint: AppColors.burntOrange,
            icon: Icons.build_circle_rounded,
            items: fixes,
          ),
          const SizedBox(height: 16),
          _CoachCard(
            title: isRehabMode ? 'Next Safe Steps' : 'Next Rep Cues',
            tint: AppColors.terracotta,
            icon: Icons.play_circle_fill_rounded,
            items: nextSteps,
          ),
          if (keyMetrics.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Key Metrics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.spaceBetween,
              children: keyMetrics
                  .map(
                    (metric) => SizedBox(
                      width: 162,
                      child: _QuickStatCard(
                        stat: _QuickStat(label: metric.label, value: metric.value, tint: metric.tint),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (topSuggestions.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('If This Wasn\'t The Exercise You Meant', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
            const SizedBox(height: 14),
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(18),
              color: AppColors.white.withValues(alpha: 0.9),
              child: Column(
                children: topSuggestions
                    .map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(suggestion.label, style: Theme.of(context).textTheme.titleMedium)),
                            Text(
                              suggestion.confidence == null ? 'Detected' : '${_displayPercent(suggestion.confidence!).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.softCharcoal.withValues(alpha: 0.65)),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(isRehabMode ? 'Rehab Snapshot' : 'Recovery Snapshot', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 14),
          Column(
            children: [
              _SummaryCard(
                title: 'This Week',
                summary: weeklySummary,
                fallback: 'Weekly recovery analytics will start showing up as you log more sessions.',
              ),
              const SizedBox(height: 14),
              _SummaryCard(
                title: 'This Month',
                summary: monthlySummary,
                fallback: 'Monthly recovery analytics will appear as your session history grows.',
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.progress, arguments: summary),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: AppColors.softCharcoal,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Open Recovery Analytics'),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.upload, arguments: {'exercise': selectedExercise}),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: BorderSide(color: AppColors.white.withValues(alpha: 0.24)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Analyze Another Session'),
          ),
        ],
      ),
    );
  }
}

int _resolveDisplayScore(Map<String, dynamic> summary, bool isRehabMode) {
  final direct = _firstNum(summary, const ['score', 'accuracy']);
  if (direct != null && direct > 0) {
    return direct.round();
  }

  if (!isRehabMode) {
    return 0;
  }

  var score = summary['is_safe'] == true ? 88 : 62;
  final warnings = _stringList(summary['warnings']);
  final errors = _stringList(summary['error_categories']);
  final features = _extractFeatureMap(summary);
  final stability = _toDouble(features['stability']);
  final symmetry = _toDouble(features['symmetry_score']);

  score -= warnings.length * 8;
  score -= errors.length * 10;

  if (stability != null) {
    final display = stability <= 1 ? stability * 100 : stability;
    if (display < 60) score -= 12;
  }
  if (symmetry != null) {
    final display = symmetry <= 1 ? symmetry * 100 : symmetry;
    if (display < 65) score -= 10;
  }

  return score.clamp(0, 100).round();
}

class _SuggestionData {
  const _SuggestionData({required this.label, this.confidence});

  final String label;
  final double? confidence;
}

class _QuickStat {
  const _QuickStat({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tint, fontSize: 22)),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({required this.stat});

  final _QuickStat stat;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.25),
          ),
          const SizedBox(height: 10),
          Text(
            stat.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: stat.tint, fontSize: 20),
          ),
          const SizedBox(height: 2),
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
                  color: AppColors.softCharcoal.withValues(alpha: 0.72),
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.softCharcoal),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.title,
    required this.tint,
    required this.icon,
    required this.items,
  });

  final String title;
  final Color tint;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19))),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item, style: Theme.of(context).textTheme.bodyLarge)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.summary, required this.fallback});

  final String title;
  final Map<String, dynamic> summary;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          if (summary.isEmpty)
            Text(fallback, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...summary.entries
                .where((entry) => entry.value != null && entry.key != 'message')
                .take(4)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SummaryValueRow(
                      label: _pretty(entry.key),
                      value: _formatDynamic(entry.value),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

String _headlineMessage(String formStatus, int score, String exercise, bool isRehabMode) {
  if (isRehabMode) {
    if (formStatus.toLowerCase() == 'correct' || formStatus.toLowerCase() == 'safe') {
      return 'This $exercise looked safe enough for your current rehab flow. Keep the movement controlled and repeatable.';
    }
    if (score >= 50) {
      return 'This rep is close, but there are a few safety concerns to clean up before it becomes a good rehab rep.';
    }
    return 'This rep is not a good rehab rep yet. Reduce intensity, simplify the movement, and focus on safety first.';
  }
  if (_isPositive(formStatus, score)) {
    return 'Nice work. Your $exercise looked controlled enough to count as a solid rep. Keep repeating the same setup.';
  }
  if (score >= 50) {
    return 'You are close, but a few form issues are holding this rep back. Clean up the basics below and try again.';
  }
  return 'This rep needs a reset. Slow down, simplify the movement, and focus on the main fixes before pushing harder.';
}

String _coachStatus(String formStatus, int score, bool isRehabMode, Map<String, dynamic> summary) {
  if (isRehabMode) {
    if ((summary['is_safe'] == true) || formStatus.toLowerCase() == 'safe' || formStatus.toLowerCase() == 'correct') return 'Safe rep';
    if (score >= 50) return 'Use caution';
    return 'Not safe yet';
  }
  if (_isPositive(formStatus, score)) return 'Solid rep';
  if (score >= 50) return 'Needs cleanup';
  return 'Reset and retry';
}

String _friendlyForm(String formStatus, bool isRehabMode) {
  if (isRehabMode) {
    switch (formStatus.toLowerCase()) {
      case 'correct':
      case 'safe':
        return 'Safe';
      case 'incorrect':
      case 'unsafe':
      case 'danger':
        return 'Needs Care';
      default:
        return formStatus;
    }
  }
  switch (formStatus.toLowerCase()) {
    case 'correct':
      return 'Good';
    case 'incorrect':
      return 'Needs Fix';
    default:
      return formStatus;
  }
}

bool _isPositive(String formStatus, int score) {
  final normalized = formStatus.toLowerCase();
  return normalized == 'correct' || normalized == 'safe' || score >= 80;
}

List<String> _buildWins(Map<String, dynamic> features, List<String> feedback, String formStatus, bool isRehabMode, Map<String, dynamic> summary) {
  final wins = <String>[];
  final stability = _toDouble(features['stability']);
  final symmetry = _toDouble(features['symmetry_score']);
  final coordination = _toDouble(features['coordination_score']);
  final depth = _toDouble(features['depth']);
  final allowedExercises = _stringList(summary['allowed_exercises']);

  if (isRehabMode) {
    if ((summary['is_safe'] == true) || formStatus.toLowerCase() == 'safe' || formStatus.toLowerCase() == 'correct') {
      wins.add('This movement looked safe for your current rehab stage.');
    }
    if (allowedExercises.isNotEmpty) {
      wins.add('Your rehab plan currently allows exercises like ${allowedExercises.take(3).join(', ')}.');
    }
  } else if (_isPositive(formStatus, 100)) {
    wins.add('Your overall movement pattern looked safe and clean.');
  }
  if (stability != null && stability >= 0.75) {
    wins.add('You stayed fairly stable through the movement.');
  }
  if (symmetry != null && symmetry >= 0.75) {
    wins.add('Left and right sides looked balanced.');
  }
  if (coordination != null && coordination >= 0.80) {
    wins.add('Your movement timing looked coordinated.');
  }
  if (depth != null && depth >= 0.45) {
    wins.add('You reached a useful amount of depth for the rep.');
  }

  for (final item in feedback) {
    final lower = item.toLowerCase();
    if ((lower.contains('good') || lower.contains('stable') || lower.contains('matches')) && wins.length < 3) {
      wins.add(item);
    }
  }

  if (wins.isEmpty) {
    wins.add('You completed the rep and gave the system enough movement to analyze.');
  }
  return wins.take(3).toList();
}

List<String> _buildFixes(List<String> errors, List<String> warnings, List<String> risks, Map<String, dynamic> features, bool isRehabMode) {
  final fixes = <String>[];
  final buckets = [...errors, ...warnings, ...risks].map((item) => item.toLowerCase()).toSet();

  if (buckets.contains('knee_overload')) {
    fixes.add('Keep your knees tracking in line with your toes and avoid forcing the rep deeper than you can control.');
  }
  if (buckets.contains('back_strain')) {
    fixes.add('Brace your core and keep your chest prouder so your back stays more organized.');
  }
  if (buckets.contains('imbalance')) {
    fixes.add('Slow down and make both sides move evenly instead of shifting weight to one side.');
  }
  if (buckets.contains('poor_depth')) {
    fixes.add('Work on a cleaner range of motion, but only go as deep as you can stay stable.');
  }
  if (buckets.contains('instability')) {
    fixes.add('Own the bottom and top positions instead of rushing through them.');
  }

  final stability = _toDouble(features['stability']);
  if (fixes.isEmpty && stability != null && stability < 0.5) {
    fixes.add('Your base looked shaky. Plant your feet and move with more control.');
  }

  if (isRehabMode && fixes.isEmpty) {
    fixes.add('Stay within a pain-free range and prioritize smooth, controlled reps over harder effort.');
  }
  if (fixes.isEmpty) {
    fixes.add('Keep repeating the same setup and try to make the next rep even smoother.');
  }
  return fixes.take(3).toList();
}

List<String> _buildNextSteps(String exercise, List<String> errors, Map<String, dynamic> features, bool isRehabMode) {
  final tips = <String>[];
  final normalizedExercise = exercise.toLowerCase();

  if (isRehabMode) {
    tips.add('Keep the next rep slower and smoother so the movement stays safe and repeatable.');
  } else if (normalizedExercise.contains('squat')) {
    tips.add('On the next squat, sit down and back first, then drive up through the full foot.');
  } else if (normalizedExercise.contains('lunge')) {
    tips.add('On the next lunge, shorten the step slightly and keep your front knee stacked better.');
  } else if (normalizedExercise.contains('press') || normalizedExercise.contains('push')) {
    tips.add('On the next press, lock the ribs down and keep the path smoother from start to finish.');
  } else {
    tips.add('On the next rep, reduce speed a little and focus on one clean movement path.');
  }

  final depth = _toDouble(features['depth']);
  if (depth != null && depth < 0.3) {
    tips.add('Use a slightly bigger range of motion only if you can keep the same control.');
  }
  if (errors.isNotEmpty) {
    tips.add('Fix just one issue first, then record again instead of trying to correct everything at once.');
  }
  return tips.take(3).toList();
}

List<_QuickStat> _buildQuickStats(Map<String, dynamic> features, double? confidence, int score, bool isRehabMode, Map<String, dynamic> summary) {
  final safeTint = _scoreColor(score, _firstString(summary, const ['form_status']) ?? '', isRehabMode, summary);
  return [
    _QuickStat(
      label: 'Stability',
      value: _formatPercentish(features['stability']),
      tint: AppColors.sageGreen,
    ),
    _QuickStat(
      label: 'Symmetry',
      value: _formatPercentish(features['symmetry_score']),
      tint: AppColors.terracotta,
    ),
    _QuickStat(
      label: isRehabMode ? 'Safe Now' : (confidence == null ? 'Form Score' : 'Confidence'),
      value: isRehabMode
          ? ((summary['is_safe'] == true) ? 'Yes' : 'Check')
          : (confidence == null ? '$score%' : '${_displayPercent(confidence).toStringAsFixed(0)}%'),
      tint: isRehabMode ? safeTint : (confidence == null ? AppColors.gold : AppColors.burntOrange),
    ),
  ];
}

List<_MetricData> _buildKeyMetrics(Map<String, dynamic> features) {
  final metrics = <_MetricData>[];

  void addMetric(String label, Object? value, Color tint, {bool percent = false, String suffix = ''}) {
    final formatted = _formatMetricValue(value, percent: percent, suffix: suffix);
    if (formatted == 'N/A') return;
    metrics.add(_MetricData(label: label, value: formatted, tint: tint));
  }

  addMetric('Knee Angle', features['avg_knee_angle'], AppColors.terracotta, suffix: 'deg');
  addMetric('Hip Angle', features['hip_angle_avg'], AppColors.gold, suffix: 'deg');
  addMetric('Back Angle', features['back_angle'], AppColors.burntOrange, suffix: 'deg');
  addMetric('Stability', features['stability'], AppColors.sageGreen, percent: true);
  addMetric('Symmetry', features['symmetry_score'], AppColors.terracotta, percent: true);

  return metrics.take(5).toList();
}

double _displayPercent(double value) {
  return value <= 1 ? value * 100 : value;
}

Color _statusColor(String status, bool isRehabMode) {
  if (isRehabMode) {
    switch (status.toLowerCase()) {
      case 'correct':
      case 'safe':
        return AppColors.sageGreen;
      case 'incorrect':
      case 'unsafe':
      case 'danger':
        return AppColors.burntOrange;
      default:
        return AppColors.gold;
    }
  }
  switch (status.toLowerCase()) {
    case 'correct':
    case 'safe':
      return AppColors.sageGreen;
    case 'incorrect':
    case 'unsafe':
      return AppColors.terracotta;
    default:
      return AppColors.gold;
  }
}

Color _scoreColor(int score, String status, bool isRehabMode, Map<String, dynamic> summary) {
  if (isRehabMode) {
    if (summary['is_safe'] == true || status.toLowerCase() == 'safe' || status.toLowerCase() == 'correct' || score >= 80) {
      return AppColors.sageGreen;
    }
    if (score >= 50) {
      return AppColors.gold;
    }
    return AppColors.burntOrange;
  }
  if (score >= 80 || status.toLowerCase() == 'correct') {
    return AppColors.sageGreen;
  }
  if (score >= 50) {
    return AppColors.gold;
  }
  return AppColors.burntOrange;
}

String? _firstString(Map<String, dynamic> source, List<String> paths) {
  for (final path in paths) {
    final value = _readPath(source, path);
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

double? _firstNum(Map<String, dynamic> source, List<String> paths) {
  for (final path in paths) {
    final value = _readPath(source, path);
    final numValue = _toDouble(value);
    if (numValue != null) return numValue;
  }
  return null;
}

Object? _readPath(Map<String, dynamic> source, String path) {
  Object? current = source;
  for (final segment in path.split('.')) {
    if (current is Map) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}

Map<String, dynamic> _extractMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, dynamic val) => MapEntry(key.toString(), val));
  return <String, dynamic>{};
}

Map<String, dynamic> _extractFeatureMap(Map<String, dynamic> summary) {
  final nested = _extractMap(summary['features']);
  const keys = [
    'avg_knee_angle',
    'min_knee_angle',
    'max_knee_angle',
    'hip_angle_avg',
    'back_angle',
    'symmetry_score',
    'speed',
    'stability',
    'depth',
    'coordination_score',
  ];
  final extracted = <String, dynamic>{};
  if (nested.isNotEmpty) {
    extracted.addAll(nested);
  }
  for (final key in keys) {
    if (summary.containsKey(key) && summary[key] != null && !extracted.containsKey(key)) {
      extracted[key] = summary[key];
    }
  }
  return extracted;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
  }
  return const <String>[];
}

List<_SuggestionData> _extractSuggestions(Map<String, dynamic> summary) {
  final raw = summary['top_k_suggestions'] ?? summary['suggestions'] ?? _readPath(summary, 'model.top_k');
  if (raw is! List) return const <_SuggestionData>[];
  return raw.map((item) {
    if (item is Map) {
      final map = item.map((key, dynamic value) => MapEntry(key.toString(), value));
      return _SuggestionData(
        label: map['label']?.toString() ?? map['exercise']?.toString() ?? map['name']?.toString() ?? 'Suggestion',
        confidence: _toDouble(map['confidence'] ?? map['score']),
      );
    }
    return _SuggestionData(label: item.toString());
  }).toList();
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _pretty(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDynamic(Object? value) {
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

String _formatPercentish(Object? value) {
  final numeric = _toDouble(value);
  if (numeric == null) return 'N/A';
  final display = numeric <= 1 ? numeric * 100 : numeric;
  return '${display.toStringAsFixed(0)}%';
}

String _formatMetricValue(Object? value, {bool percent = false, String suffix = ''}) {
  final numeric = _toDouble(value);
  if (numeric == null) return 'N/A';
  if (percent) {
    final display = numeric <= 1 ? numeric * 100 : numeric;
    return '${display.toStringAsFixed(0)}%';
  }
  if (suffix.isNotEmpty) {
    return '${numeric.toStringAsFixed(1)} $suffix';
  }
  return numeric.toStringAsFixed(2);
}
