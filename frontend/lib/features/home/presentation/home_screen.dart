import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/latest_analysis_store.dart';
import '../../../core/route_names.dart';
import '../../../core/services/nexus_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _exercises = [
    _ExerciseData(title: 'Squat', assetPath: 'assets/images/squat.png'),
    _ExerciseData(title: 'Lunge', assetPath: 'assets/images/lunge.png'),
    _ExerciseData(title: 'Press', assetPath: 'assets/images/press.png'),
    _ExerciseData(title: 'Deadlift', assetPath: 'assets/images/deadlift.png'),
  ];

  static const _searchableExercises = [
    _ExerciseOption(label: 'BodyWeightSquats', hint: 'Bodyweight squat pattern'),
    _ExerciseOption(label: 'Lunges', hint: 'Split-stance lower-body pattern'),
    _ExerciseOption(label: 'BenchPress', hint: 'Horizontal pressing pattern'),
    _ExerciseOption(label: 'PushUps', hint: 'Bodyweight pressing pattern'),
    _ExerciseOption(label: 'WallPushups', hint: 'Beginner-friendly push pattern'),
    _ExerciseOption(label: 'PullUps', hint: 'Vertical pulling pattern'),
    _ExerciseOption(label: 'CleanAndJerk', hint: 'Explosive full-body lift'),
  ];

  Future<void> _openRoute(BuildContext context, String route, {Object? arguments}) async {
    await AppHaptics.lightImpact();
    if (context.mounted) {
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  Future<void> _openLatestResults(BuildContext context) async {
    await AppHaptics.lightImpact();
    final localLatest = LatestAnalysisStore.latestResult;
    if (localLatest != null && localLatest.isNotEmpty && context.mounted) {
      Navigator.pushNamed(context, AppRoutes.results, arguments: localLatest);
      return;
    }
    try {
      final latest = await NexusApiService.getLatestResult();
      if (!context.mounted) return;
      if ((latest['message']?.toString().contains('No analysis') ?? false) || latest.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No latest analysis found yet. Upload a session first.')),
        );
        return;
      }
      LatestAnalysisStore.save(latest);
      Navigator.pushNamed(context, AppRoutes.results, arguments: latest);
    } on NexusApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openSearchExercises(BuildContext context) async {
    await AppHaptics.lightImpact();
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ExerciseSearchSheet(
        exercises: _searchableExercises,
        onSelected: (exercise) {
          Navigator.pop(sheetContext);
          _openRoute(context, AppRoutes.upload, arguments: {'exercise': exercise});
        },
      ),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                boxShadow: [BoxShadow(color: AppColors.terracotta.withValues(alpha: 0.22), blurRadius: 16)],
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo_mark.png', fit: BoxFit.cover, filterQuality: FilterQuality.high),
              ),
            ),
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 30),
        children: [
          _HeroCard(
            onTrainingTap: () => _openRoute(context, AppRoutes.upload, arguments: const {'mode': 'training'}),
            onRehabTap: () => _openRoute(context, AppRoutes.upload, arguments: const {'mode': 'rehab'}),
            onHistoryTap: () => _openRoute(context, AppRoutes.history),
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
                onTap: () => _openRoute(context, AppRoutes.upload, arguments: {'exercise': exercise.title}),
              );
            },
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _openSearchExercises(context),
            child: GlassCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              color: Colors.white.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.manage_search_rounded, color: AppColors.sageGreen),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('See More Exercises', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)),
                        const SizedBox(height: 4),
                        Text(
                          'Search the full supported exercise list and jump into analysis.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withValues(alpha: 0.34)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Quick Actions', subtitle: 'Jump into the part of the experience you need.'),
          const SizedBox(height: 14),
          _QuickActionTile(
            title: 'Training Mode',
            subtitle: 'Form coaching and movement quality',
            icon: Icons.cloud_upload_rounded,
            tint: AppColors.terracotta,
            onTap: () => _openRoute(context, AppRoutes.upload, arguments: const {'mode': 'training'}),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            title: 'Rehab Mode',
            subtitle: 'Safety and recovery-stage guidance',
            icon: Icons.monitor_heart_rounded,
            tint: AppColors.sageGreen,
            onTap: () => _openRoute(context, AppRoutes.upload, arguments: const {'mode': 'rehab'}),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            title: 'Session History',
            subtitle: 'Open past workouts and compare progress',
            icon: Icons.history_rounded,
            tint: AppColors.burntOrange,
            onTap: () => _openRoute(context, AppRoutes.history),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            title: 'Latest Results',
            subtitle: 'Open your most recent analysis',
            icon: Icons.insights_rounded,
            tint: AppColors.gold,
            onTap: () => _openLatestResults(context),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTrainingTap, required this.onRehabTap, required this.onHistoryTap});
  final VoidCallback onTrainingTap;
  final VoidCallback onRehabTap;
  final VoidCallback onHistoryTap;

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
            child: Text('Biomechanics-first coaching', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.terracotta, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 18),
          Text('Make every rep readable.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30, height: 1.0, fontWeight: FontWeight.w900, color: AppColors.white)),
          const SizedBox(height: 12),
          Text('Jump into a training session, start a rehab-safe analysis, or review your progress history from one place.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.74), fontSize: 15)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onTrainingTap,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.terracotta, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: const Text('Start Training'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRehabTap,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.18)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: const Text('Start Rehab'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onHistoryTap,
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), foregroundColor: AppColors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.14)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Text('View Session History', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)),
          ),
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

class _ExerciseOption {
  const _ExerciseOption({required this.label, required this.hint});
  final String label;
  final String hint;
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 10))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(exercise.assetPath, fit: BoxFit.cover, filterQuality: FilterQuality.high),
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
            Container(width: 52, height: 52, decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: tint, size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withValues(alpha: 0.34)),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSearchSheet extends StatefulWidget {
  const _ExerciseSearchSheet({required this.exercises, required this.onSelected});
  final List<_ExerciseOption> exercises;
  final ValueChanged<String> onSelected;

  @override
  State<_ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<_ExerciseSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.exercises.where((exercise) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return exercise.label.toLowerCase().contains(q) || exercise.hint.toLowerCase().contains(q);
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(color: const Color(0xFF1B2430), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 18),
            Text('More Exercises', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 22)),
            const SizedBox(height: 8),
            Text('Search the supported exercise list and go straight to analysis.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search exercise',
                hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.40)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.sageGreen),
                filled: true,
                fillColor: const Color(0xFF243040),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppColors.sageGreen.withValues(alpha: 0.6))),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: filtered.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('No exercises match that search.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.68)))))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => widget.onSelected(exercise.label),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(color: const Color(0xFF243040), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                            child: Row(
                              children: [
                                Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.terracotta.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.fitness_center_rounded, color: AppColors.terracotta)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(exercise.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 17)),
                                  const SizedBox(height: 4),
                                  Text(exercise.hint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
                                ])),
                                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white.withValues(alpha: 0.3)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
