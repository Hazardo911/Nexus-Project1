import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/widgets.dart';

import '../../../core/services/nexus_api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await NexusApiService.logout();
    if (context.mounted) {
      // Clear everything and go back to the very beginning (Splash)
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.splash, (route) => false);
    }
  }

  Future<void> _updateToggle(void Function(bool) setter, bool value) async {
    setter(value);
    await AppHaptics.selection();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Account',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 30),
        children: [
          GlassCard(
            radius: 30,
            padding: const EdgeInsets.all(24),
            color: AppColors.white.withValues(alpha: 0.9),
            child: Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo_mark.png', fit: BoxFit.cover, filterQuality: FilterQuality.high),
                  ),
                ),

                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String?>(
                        future: NexusApiService.userName,
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? 'User', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22));
                        },
                      ),
                      const SizedBox(height: 6),
                      Text('Premium Member', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.terracotta)),
                      const SizedBox(height: 10),
                      Text('Form score average: 88.8%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.softCharcoal.withValues(alpha: 0.74))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Quick Stats', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _StatCard(label: 'Sessions', value: '50', tint: AppColors.terracotta, icon: Icons.fitness_center_rounded)),
              SizedBox(width: 14),
              Expanded(child: _StatCard(label: 'Streak', value: '7 Days', tint: AppColors.burntOrange, icon: Icons.local_fire_department_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _StatCard(label: 'Best Score', value: '96%', tint: AppColors.sageGreen, icon: Icons.workspace_premium_outlined)),
              SizedBox(width: 14),
              Expanded(child: _StatCard(label: 'Reports', value: '18', tint: AppColors.dustyRose, icon: Icons.description_outlined)),
            ],
          ),
          const SizedBox(height: 26),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.notifications,
            builder: (context, value, _) {
              return _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Workout reminders and result summaries',
                trailing: Switch(value: value, onChanged: (next) => _updateToggle(AppPreferences.setNotifications, next), activeThumbColor: AppColors.terracotta),
              );
            },
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.hapticFeedback,
            builder: (context, value, _) {
              return _SettingsTile(
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                subtitle: 'Subtle vibration during taps, buttons, and capture actions',
                trailing: Switch(value: value, onChanged: (next) => _updateToggle(AppPreferences.setHapticFeedback, next), activeThumbColor: AppColors.terracotta),
              );
            },
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.darkCameraPreview,
            builder: (context, value, _) {
              return _SettingsTile(
                icon: Icons.camera_alt_outlined,
                title: 'Dark Camera Preview',
                subtitle: 'Adds a darker recording overlay and framing guide on upload/capture screens',
                trailing: Switch(value: value, onChanged: (next) => _updateToggle(AppPreferences.setDarkCameraPreview, next), activeThumbColor: AppColors.terracotta),
              );
            },
          ),
          const SizedBox(height: 14),
          const _SettingsTile(icon: Icons.lock_outline_rounded, title: 'Privacy & Security', subtitle: 'Manage permissions and stored workout videos', trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18)),
          const SizedBox(height: 14),
          _SettingsTile(
            icon: Icons.emoji_events_outlined,
            title: 'Gamification',
            subtitle: 'View streaks, XP, challenges, and unlocked badges',
            trailing: IconButton(
              onPressed: () async {
                await AppHaptics.lightImpact();
                if (context.mounted) {
                  Navigator.pushNamed(context, AppRoutes.gamification);
                }
              },
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          const _SettingsTile(icon: Icons.tune_rounded, title: 'Analysis Preferences', subtitle: 'Default exercise type and feedback detail', trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18)),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: () => _logout(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.softCharcoal, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.tint, required this.icon});

  final String label;
  final String value;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: tint)),
          const SizedBox(height: 20),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Row(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.peachSand.withValues(alpha: 0.58), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: AppColors.terracotta)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}








