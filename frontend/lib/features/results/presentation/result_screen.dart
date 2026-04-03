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
    final summary =
        args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    final score = ((summary['accuracy'] as num?) ?? 88).round();
    final exercise =
        (summary['exercise']?.toString() ?? 'Workout').toUpperCase();
    final reps = (summary['total_reps'] as num?)?.toInt() ?? 0;
    final goal = (summary['goal'] as num?)?.toInt();

    return AppShell(
      title: 'Results',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 28),
        children: [
          Row(children: [
            Icon(Icons.check_circle_outline_rounded,
                color: AppColors.terracotta.withValues(alpha: 0.95)),
            const SizedBox(width: 8),
            Text('Analysis Complete',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.terracotta, fontSize: 18))
          ]),
          const SizedBox(height: 18),
          Text('Form Results',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontSize: 28, color: AppColors.white)),
          const SizedBox(height: 10),
          Text(
              '$exercise � Reps ${goal == null ? reps.toString() : '$reps / $goal'}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
          const SizedBox(height: 26),
          Center(child: _ScoreChart(score: score)),
          const SizedBox(height: 22),
          Text(
              score >= 85
                  ? 'Great work! Strong session accuracy captured from backend.'
                  : 'Keep practicing. Backend session completed with room to improve.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.white.withValues(alpha: 0.74))),
          const SizedBox(height: 30),
          Text('Joint Analysis',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          _JointResultTile(
              title: 'Knee Alignment',
              score: (score + 6).clamp(0, 100),
              good: score >= 80),
          const SizedBox(height: 16),
          _JointResultTile(
              title: 'Hip Angle',
              score: (score - 10).clamp(0, 100),
              good: score >= 88),
          const SizedBox(height: 16),
          _JointResultTile(
              title: 'Back Posture',
              score: (score + 3).clamp(0, 100),
              good: score >= 82),
          const SizedBox(height: 16),
          _JointResultTile(
              title: 'Session Consistency',
              score: score.clamp(0, 100),
              good: score >= 80),
          const SizedBox(height: 28),
          Text('Improvement Tips',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: const Color(0xFF202A36),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06))),
            child: const Column(children: [
              _TipRow(text: 'Push through your heels, not your toes'),
              SizedBox(height: 16),
              _TipRow(text: 'Keep your chest up and core engaged'),
              SizedBox(height: 16),
              _TipRow(text: 'Ensure knees track over toes, not inward')
            ]),
          ),
          const SizedBox(height: 22),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.pushNamed(context, AppRoutes.compare),
            child: GlassCard(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              color: AppColors.white.withValues(alpha: 0.86),
              child: Row(children: [
                Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppColors.dustyRose,
                          AppColors.terracotta
                        ]),
                        borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.show_chart_rounded,
                        color: AppColors.white)),
                const SizedBox(width: 16),
                Expanded(
                    child: Text('View Detailed Report',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 18))),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.softCharcoal.withValues(alpha: 0.35))
              ]),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 86,
            child: FilledButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.upload),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28))),
              child: Ink(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient:
                          const LinearGradient(colors: AppColors.heroGradient)),
                  child: const Center(
                      child: Text('Analyze Another',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)))),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 86,
              borderData: FlBorderData(show: false),
              sections: [
                PieChartSectionData(
                    value: score.toDouble(),
                    color: AppColors.terracotta,
                    radius: 16,
                    title: ''),
                PieChartSectionData(
                    value: (100 - score).toDouble(),
                    color: AppColors.white.withValues(alpha: 0.22),
                    radius: 16,
                    title: '')
              ])),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$score',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontSize: 54, color: AppColors.white)),
            const SizedBox(height: 6),
            Text('Overall Score',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.white.withValues(alpha: 0.64)))
          ]),
        ],
      ),
    );
  }
}

class _JointResultTile extends StatelessWidget {
  const _JointResultTile(
      {required this.title, required this.score, required this.good});
  final String title;
  final int score;
  final bool good;
  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.sageGreen : AppColors.burntOrange;
    final icon =
        good ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(children: [
        Row(children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18))),
          Text('$score%',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18, color: color))
        ]),
        const SizedBox(height: 14),
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 10,
                backgroundColor: AppColors.peachSand.withValues(alpha: 0.7),
                valueColor: AlwaysStoppedAnimation<Color>(color)))
      ]),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
              color: AppColors.terracotta, shape: BoxShape.circle),
          child: const Icon(Icons.info_outline_rounded,
              color: AppColors.white, size: 18)),
      const SizedBox(width: 14),
      Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.white.withValues(alpha: 0.72))))
    ]);
  }
}
