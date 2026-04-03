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
    await _openRoute(
      context,
      AppRoutes.upload,
      arguments: {'exercise': exercise.title},
    );
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 34),
        children: [
          Text(
            'Exercise Library',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ExerciseImageCard(
                  exercise: _exercises[0],
                  onTap: () => _openExerciseUpload(context, _exercises[0]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ExerciseImageCard(
                  exercise: _exercises[1],
                  onTap: () => _openExerciseUpload(context, _exercises[1]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ExerciseImageCard(
                  exercise: _exercises[2],
                  onTap: () => _openExerciseUpload(context, _exercises[2]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ExerciseImageCard(
                  exercise: _exercises[3],
                  onTap: () => _openExerciseUpload(context, _exercises[3]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Quick Access',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 18),
          _QuickAccessTile(
            title: 'Upload Workout',
            icon: Icons.cloud_upload_rounded,
            tint: AppColors.terracotta,
            onTap: () => _openRoute(context, AppRoutes.upload),
          ),
          const SizedBox(height: 16),
          _QuickAccessTile(
            title: 'Latest Results',
            icon: Icons.insights_rounded,
            tint: AppColors.sageGreen,
            onTap: () => _openRoute(context, AppRoutes.results),
          ),
          const SizedBox(height: 16),
          _QuickAccessTile(
            title: 'Progress Trends',
            icon: Icons.trending_up_rounded,
            tint: AppColors.burntOrange,
            onTap: () => _openRoute(context, AppRoutes.progress),
          ),
          const SizedBox(height: 16),
          _QuickAccessTile(
            title: 'Account & Settings',
            icon: Icons.person_outline_rounded,
            tint: AppColors.dustyRose,
            onTap: () => _openRoute(context, AppRoutes.profile),
          ),
          const SizedBox(height: 30),
          Text(
            'Feature Views',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeatureTile(
                  title: '3D Skeleton',
                  icon: Icons.accessibility_new_rounded,
                  tint: AppColors.sageGreen,
                  onTap: () => _openRoute(context, AppRoutes.skeleton),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FeatureTile(
                  title: 'Heat Map',
                  icon: Icons.local_fire_department_rounded,
                  tint: AppColors.burntOrange,
                  onTap: () => _openRoute(context, AppRoutes.heatMap),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FeatureTile(
                  title: 'Compare',
                  icon: Icons.compare_arrows_rounded,
                  tint: AppColors.terracotta,
                  onTap: () => _openRoute(context, AppRoutes.compare),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FeatureTile(
                  title: 'Gamification',
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

class _ExerciseData {
  const _ExerciseData({required this.title, required this.assetPath});

  final String title;
  final String assetPath;
}

class _ExerciseImageCard extends StatelessWidget {
  const _ExerciseImageCard({required this.exercise, required this.onTap});

  final _ExerciseData exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.74,
        child: Image.asset(
          exercise.assetPath,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.title, required this.icon, required this.tint, required this.onTap});

  final String title;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tint.withValues(alpha: 0.9), tint],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.title, required this.icon, required this.tint, required this.onTap});

  final String title;
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
