import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _exercises = [
    _ExerciseData(title: 'Squat', assetPath: 'assets/images/squat.png'),
    _ExerciseData(title: 'Lunge', assetPath: 'assets/images/lunge.png'),
    _ExerciseData(title: 'Press', assetPath: 'assets/images/press.png'),
    _ExerciseData(title: 'Deadlift', assetPath: 'assets/images/deadlift.png'),
  ];

  Future<void> _openRoute(BuildContext context, String route, {Object? arguments}) async {
    await AppHaptics.lightImpact();
    if (context.mounted) {
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  Future<void> _openExerciseUpload(BuildContext context, _ExerciseData exercise) async {
    await _openRoute(context, AppRoutes.upload, arguments: {'exercise': exercise.title});
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Home',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => _openRoute(context, AppRoutes.profile),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                boxShadow: [BoxShadow(color: AppColors.terracotta.withValues(alpha: 0.22), blurRadius: 16)],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_mark.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 30),
        children: [
          _HeroCard(
            onPrimaryTap: () => _openRoute(context, AppRoutes.upload),
            onSecondaryTap: () => _openRoute(context, AppRoutes.progress),
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            title: 'Pick Your Exercise',
            subtitle: 'Start from the movement you actually want validated.',
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final exercise = _exercises[index];
              return _ExerciseCard(
                exercise: exercise,
                onTap: () => _openExerciseUpload(context, exercise),
              );
            },
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            title: 'Quick Actions',
            subtitle: 'Jump into the part of the experience you need.',
          ),
          const SizedBox(height: 14),
          _QuickActionTile(
            title: 'Upload And Analyze',
            subtitle: 'Pick exercise, upload clip, validate form',
            icon: Icons.cloud_upload_rounded,
            tint: AppColors.terracotta,
            onTap: () => _openRoute(context, AppRoutes.upload),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            title: 'Recovery Analytics',
            subtitle: 'Weekly and monthly rehab progress summaries',
            icon: Icons.monitor_heart_rounded,
            tint: AppColors.sageGreen,
            onTap: () => _openRoute(context, AppRoutes.progress),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            title: 'Latest Results',
            subtitle: 'Form status, errors, confidence, suggestions',
            icon: Icons.insights_rounded,
            tint: AppColors.gold,
            onTap: () => _openRoute(context, AppRoutes.results),
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            title: 'Feature Views',
            subtitle: 'Open deeper visual tools and comparison screens.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FeatureTile(
                  title: 'Skeleton',
                  subtitle: 'Live overlay',
                  icon: Icons.accessibility_new_rounded,
                  tint: AppColors.sageGreen,
                  onTap: () => _openRoute(context, AppRoutes.skeleton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureTile(
                  title: 'Heat Map',
                  subtitle: 'Risk view',
                  icon: Icons.local_fire_department_rounded,
                  tint: AppColors.burntOrange,
                  onTap: () => _openRoute(context, AppRoutes.heatMap),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FeatureTile(
                  title: 'Compare',
                  subtitle: 'Mismatch check',
                  icon: Icons.compare_arrows_rounded,
                  tint: AppColors.terracotta,
                  onTap: () => _openRoute(context, AppRoutes.compare),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureTile(
                  title: 'Gamify',
                  subtitle: 'Streaks and goals',
                  icon: Icons.emoji_events_rounded,
                  tint: AppColors.dustyRose,
                  onTap: () => _openRoute(context, AppRoutes.gamification),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onPrimaryTap, required this.onSecondaryTap});

  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243247), Color(0xFF1C2633), Color(0xFF141B24)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: AppColors.terracotta.withValues(alpha: 0.14), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Biomechanics-first coaching',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.terracotta, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Make every rep readable.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose the exercise, validate movement quality, and track rehab recovery with cleaner session insights.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.74),
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimaryTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Start Analysis'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondaryTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Recovery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: _HeroStat(value: '10', label: 'Biomech features')),
              SizedBox(width: 10),
              Expanded(child: _HeroStat(value: 'Top-K', label: 'Exercise suggestions')),
              SizedBox(width: 10),
              Expanded(child: _HeroStat(value: '24/7', label: 'Session tracking')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white)),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
      ],
    );
  }
}

class _ExerciseData {
  const _ExerciseData({required this.title, required this.assetPath});

  final String title;
  final String assetPath;
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final _ExerciseData exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            exercise.assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.title, required this.subtitle, required this.icon, required this.tint, required this.onTap});

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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        color: Colors.white.withValues(alpha: 0.08),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: tint, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withValues(alpha: 0.34)),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.title, required this.subtitle, required this.icon, required this.tint, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        color: Colors.white.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
          ],
        ),
      ),
    );
  }
}
