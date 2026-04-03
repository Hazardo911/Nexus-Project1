import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
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
    final selectedExercise = _firstString(summary, const ['selected_exercise', 'exercise']) ?? 'Workout';
    final formStatus = _firstString(summary, const ['form_status']) ?? 'Pending';
    final score = _firstNum(summary, const ['score', 'accuracy'])?.round() ?? 0;
    final confidence = _firstNum(summary, const ['confidence', 'model.confidence']);
    final modelAgreementText = _firstString(summary, const ['model_agreement']);
    final topSuggestions = _extractSuggestions(summary);
    final errorCategories = _stringList(summary['error_categories']);
    final warnings = _stringList(summary['warnings']);
    final riskFlags = _stringList(summary['risk_flags']);
    final features = _extractFeatureMap(summary);
    final weeklySummary = _extractMap(summary['weekly_summary']);
    final monthlySummary = _extractMap(summary['monthly_summary']);
    final responseJson = _buildPreviewJson(summary);

    return AppShell(
      title: 'Results',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 28),
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.sageGreen.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Text('Analysis Complete', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.sageGreen, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 18),
          Text('Movement Validation', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28, color: AppColors.white)),
          const SizedBox(height: 10),
          Text(selectedExercise, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.82), fontSize: 20)),
          const SizedBox(height: 20),
          Center(child: _ScoreChart(score: score, label: formStatus)),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusChip(label: 'Form: ${formStatus.toUpperCase()}', tint: _statusColor(formStatus)),
              if (confidence != null) _StatusChip(label: 'Confidence ${confidence.toStringAsFixed(1)}%', tint: AppColors.terracotta),
              if (modelAgreementText != null) _StatusChip(label: modelAgreementText, tint: AppColors.gold),
              _StatusChip(label: 'Top-K Suggestions ${topSuggestions.length}', tint: AppColors.burntOrange),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Model Signals'),
          const SizedBox(height: 16),
          _KeyValueCard(entries: [
            _KeyValueEntry(label: 'Selected Exercise', value: selectedExercise),
            _KeyValueEntry(label: 'Form Status', value: formStatus),
            _KeyValueEntry(label: 'Model Agreement', value: modelAgreementText ?? 'N/A'),
            _KeyValueEntry(label: 'Confidence', value: confidence == null ? 'N/A' : '${confidence.toStringAsFixed(1)}%'),
          ]),
          if (topSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              color: AppColors.white.withValues(alpha: 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top-K Suggestions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                  const SizedBox(height: 14),
                  ...topSuggestions.map((suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SuggestionRow(label: suggestion.label, confidence: suggestion.confidence),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle(title: 'Biomechanics Features'),
          const SizedBox(height: 16),
          if (features.isEmpty)
            _EmptyCard(message: 'Feature values will appear here when the backend returns biomechanical metrics.')
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: features.entries.map((entry) => _FeatureCard(label: _pretty(entry.key), value: _formatDynamic(entry.value))).toList(),
            ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Errors And Safety'),
          const SizedBox(height: 16),
          if (errorCategories.isEmpty && warnings.isEmpty && riskFlags.isEmpty)
            _EmptyCard(message: 'No error categories, warnings, or risk flags were returned for this run.')
          else
            Column(
              children: [
                if (errorCategories.isNotEmpty) _ListCard(title: 'Error Categories', items: errorCategories, tint: AppColors.burntOrange),
                if (errorCategories.isNotEmpty && (warnings.isNotEmpty || riskFlags.isNotEmpty)) const SizedBox(height: 14),
                if (warnings.isNotEmpty) _ListCard(title: 'Warnings', items: warnings, tint: AppColors.gold),
                if (warnings.isNotEmpty && riskFlags.isNotEmpty) const SizedBox(height: 14),
                if (riskFlags.isNotEmpty) _ListCard(title: 'Risk Flags', items: riskFlags, tint: AppColors.terracotta),
              ],
            ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Recovery Analytics'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SummaryCard(title: 'Weekly Rehab Summary', summary: weeklySummary, fallback: 'Weekly rehab recovery analytics will appear here.')),
              const SizedBox(width: 14),
              Expanded(child: _SummaryCard(title: 'Monthly Rehab Summary', summary: monthlySummary, fallback: 'Monthly rehab recovery analytics will appear here.')),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Raw Response'),
          const SizedBox(height: 16),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF202A36),
            child: SelectableText(
              responseJson,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.82), height: 1.45),
            ),
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

class _SuggestionData {
  const _SuggestionData({required this.label, this.confidence});

  final String label;
  final double? confidence;
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bounded = score.clamp(0, 100);
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 86,
              borderData: FlBorderData(show: false),
              sections: [
                PieChartSectionData(value: bounded.toDouble(), color: AppColors.terracotta, radius: 16, title: ''),
                PieChartSectionData(value: (100 - bounded).toDouble(), color: AppColors.white.withValues(alpha: 0.22), radius: 16, title: ''),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$bounded', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 54, color: AppColors.white)),
              const SizedBox(height: 6),
              Text('Score', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.64))),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999), border: Border.all(color: tint.withValues(alpha: 0.28))),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tint, fontWeight: FontWeight.w700)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white));
  }
}

class _KeyValueEntry {
  const _KeyValueEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _KeyValueCard extends StatelessWidget {
  const _KeyValueCard({required this.entries});

  final List<_KeyValueEntry> entries;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.label, style: Theme.of(context).textTheme.bodyLarge)),
                    const SizedBox(width: 12),
                    Flexible(child: Text(entry.value, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleMedium)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.label, required this.confidence});

  final String label;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.peachSand.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          Text(confidence == null ? 'No confidence' : '${confidence!.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.softCharcoal.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        color: AppColors.white.withValues(alpha: 0.9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.title, required this.items, required this.tint});

  final String title;
  final List<String> items;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
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
      padding: const EdgeInsets.all(18),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          if (summary.isEmpty)
            Text(fallback, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...summary.entries.take(4).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(_pretty(entry.key), style: Theme.of(context).textTheme.bodyMedium)),
                        const SizedBox(width: 12),
                        Flexible(child: Text(_formatDynamic(entry.value), textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleSmall)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

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

Color _statusColor(String status) {
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
  if (nested.isNotEmpty) return nested;
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
  for (final key in keys) {
    if (summary.containsKey(key) && summary[key] != null) {
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

String _buildPreviewJson(Map<String, dynamic> summary) {
  final preview = <String, dynamic>{};
  for (final entry in summary.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is Map) {
      preview[key] = '${value.length} fields';
    } else if (value is List) {
      preview[key] = value.length > 12 ? '${value.length} items' : value;
    } else {
      preview[key] = value;
    }
  }
  return const JsonEncoder.withIndent('  ').convert(preview);
}
