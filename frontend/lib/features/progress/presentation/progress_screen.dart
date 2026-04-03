import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Progress',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 30),
        children: [
          Text('Your Progress', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28, color: AppColors.white)),
          const SizedBox(height: 10),
          Text('Track your form improvement over time', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
          const SizedBox(height: 24),
          GlassCard(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            color: AppColors.white.withValues(alpha: 0.88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('This Week', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                    const Spacer(),
                    TextButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined), label: const Text('View All')),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(height: 190, child: BarChart(_weeklyBarData(context))),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: AppColors.warmCream.withValues(alpha: 0.82)),
                  child: Row(
                    children: [
                      Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.trending_up_rounded, color: AppColors.white)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Weekly Average', style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 6), Text('88.8%', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22))])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('vs last week', style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 6), Text('+5.2%', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.terracotta, fontSize: 20))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () async {
              await AppHaptics.mediumImpact();
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.gamification);
              }
            },
            child: GlassCard(
              radius: 26,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              color: Colors.white.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.dustyRose, AppColors.burntOrange]), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.emoji_events_rounded, color: AppColors.white)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Open Gamification', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: AppColors.white, fontWeight: FontWeight.w700))),
                  Icon(Icons.arrow_forward_ios_rounded, size: 20, color: AppColors.white.withValues(alpha: 0.45)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Recent Sessions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          _SessionTile(icon: Icons.fitness_center_rounded, tint: AppColors.terracotta, title: 'Squat', time: 'Today, 9:30 AM', score: 88, delta: '+4', onTap: () => Navigator.pushNamed(context, AppRoutes.results)),
          const SizedBox(height: 16),
          _SessionTile(icon: Icons.sports_gymnastics_rounded, tint: AppColors.dustyRose, title: 'Shoulder Press', time: 'Yesterday, 6:15 PM', score: 91, delta: '+7', onTap: () => Navigator.pushNamed(context, AppRoutes.results)),
          const SizedBox(height: 16),
          _SessionTile(icon: Icons.directions_run_rounded, tint: AppColors.sageGreen, title: 'Lunge', time: 'Mar 24, 8:00 AM', score: 85, delta: '-3', onTap: () => Navigator.pushNamed(context, AppRoutes.results)),
          const SizedBox(height: 28),
          Text('Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _AchievementCard(title: '7 Day Streak', icon: Icons.local_fire_department_rounded, colors: const [AppColors.terracotta, AppColors.burntOrange], onTap: () => Navigator.pushNamed(context, AppRoutes.gamification))),
              const SizedBox(width: 14),
              Expanded(child: _AchievementCard(title: 'Form Master', icon: Icons.adjust_rounded, colors: const [AppColors.sageGreen, AppColors.terracotta], onTap: () => Navigator.pushNamed(context, AppRoutes.gamification))),
              const SizedBox(width: 14),
              Expanded(child: _AchievementCard(title: '50 Sessions', icon: Icons.star_rounded, colors: const [AppColors.dustyRose, AppColors.terracotta], onTap: () => Navigator.pushNamed(context, AppRoutes.gamification))),
            ],
          ),
        ],
      ),
    );
  }

  BarChartData _weeklyBarData(BuildContext context) {
    const values = [48.0, 62.0, 70.0, 58.0, 82.0, 76.0, 88.0];
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
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.icon, required this.tint, required this.title, required this.time, required this.score, required this.delta, required this.onTap});

  final IconData icon;
  final Color tint;
  final String title;
  final String time;
  final int score;
  final String delta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        color: AppColors.white.withValues(alpha: 0.9),
        child: Row(
          children: [
            Container(width: 68, height: 68, decoration: BoxDecoration(color: tint.withValues(alpha: 0.84), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: AppColors.white, size: 34)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)), const Spacer(), Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.softCharcoal.withValues(alpha: 0.35))]),
                  const SizedBox(height: 4),
                  Text(time, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('$score%', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.peachSand.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
                        child: Text(delta, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: delta.startsWith('-') ? AppColors.burntOrange : AppColors.sageGreen, fontSize: 16)),
                      ),
                      const Spacer(),
                      ...List.generate(5, (index) {
                        return Container(width: 8, height: 44, margin: const EdgeInsets.only(left: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: index < 4 ? tint.withValues(alpha: 0.92) : AppColors.peachSand.withValues(alpha: 0.65)));
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.title, required this.icon, required this.colors, required this.onTap});

  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 12))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.white, size: 34),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
