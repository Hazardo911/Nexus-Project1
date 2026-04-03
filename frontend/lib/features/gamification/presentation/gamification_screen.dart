import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/widgets.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gamification',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 30),
        children: [
          Text('Level Up Your Form', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30, color: AppColors.white)),
          const SizedBox(height: 10),
          Text('Stay consistent, complete challenges, and unlock rewards.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.terracotta, AppColors.burntOrange]),
              boxShadow: [BoxShadow(color: AppColors.terracotta.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 16))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 62, height: 62, decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.local_fire_department_rounded, color: AppColors.white, size: 34)),
                    const Spacer(),
                    Text('Level 8', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Streak Warrior', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 34)),
                const SizedBox(height: 8),
                Text('7-day streak active. You are 220 XP away from Level 9.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.88))),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: 0.72, minHeight: 12, backgroundColor: AppColors.white.withValues(alpha: 0.18), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white)),
                ),
                const SizedBox(height: 10),
                Text('1,580 / 1,800 XP', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.88))),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Today\'s Challenge', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(22),
            color: AppColors.white.withValues(alpha: 0.9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.sageGreen.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.emoji_events_outlined, color: AppColors.sageGreen)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Perfect Squat Challenge', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)), const SizedBox(height: 4), Text('Submit 3 squat analyses above 85% score', style: Theme.of(context).textTheme.bodyMedium)])),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: 0.66, minHeight: 10, backgroundColor: AppColors.peachSand.withValues(alpha: 0.48), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sageGreen))),
                const SizedBox(height: 10),
                Row(children: [Text('2 / 3 complete', style: Theme.of(context).textTheme.bodyMedium), const Spacer(), Text('+120 XP', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.terracotta))]),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    await AppHaptics.mediumImpact();
                    if (context.mounted) {
                      Navigator.pushNamed(context, AppRoutes.upload, arguments: {'exercise': 'Squat'});
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.softCharcoal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  child: const Text('Continue Challenge'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Badges', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _BadgeCard(title: '7 Day Streak', subtitle: 'Consistency', colors: [AppColors.terracotta, AppColors.burntOrange], icon: Icons.local_fire_department_rounded)),
              SizedBox(width: 14),
              Expanded(child: _BadgeCard(title: 'Form Master', subtitle: 'Technique', colors: [AppColors.sageGreen, AppColors.terracotta], icon: Icons.verified_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _BadgeCard(title: '50 Sessions', subtitle: 'Commitment', colors: [AppColors.dustyRose, AppColors.terracotta], icon: Icons.star_rounded)),
              SizedBox(width: 14),
              Expanded(child: _BadgeCard(title: 'Comeback', subtitle: 'Momentum', colors: [AppColors.sageGreen, AppColors.dustyRose], icon: Icons.bolt_rounded)),
            ],
          ),
          const SizedBox(height: 26),
          Text('Reward Track', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          const _RewardTile(title: 'Bronze Motion Theme', subtitle: 'Unlocked at 1,500 XP', status: 'Unlocked', tint: AppColors.sageGreen),
          const SizedBox(height: 14),
          const _RewardTile(title: 'Coach Feedback Pack', subtitle: 'Unlocks at 1,800 XP', status: '220 XP left', tint: AppColors.terracotta),
          const SizedBox(height: 14),
          const _RewardTile(title: 'Elite Form Badge', subtitle: 'Reach 10 sessions above 90%', status: '4 sessions left', tint: AppColors.burntOrange),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.title, required this.subtitle, required this.colors, required this.icon});

  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors), boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 12))]),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.white, size: 34),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 17)),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.86))),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.title, required this.subtitle, required this.status, required this.tint});

  final String title;
  final String subtitle;
  final String status;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Row(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: tint.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)), child: Icon(Icons.card_giftcard_rounded, color: tint)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)])),
          const SizedBox(width: 12),
          Text(status, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tint)),
        ],
      ),
    );
  }
}
