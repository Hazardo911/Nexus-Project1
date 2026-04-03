import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_cta_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/widgets.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  static const _logoAsset = 'assets/images/logo_mark.png';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Login',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 30),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: ClipOval(
                child: Image.asset(_logoAsset, fit: BoxFit.cover, filterQuality: FilterQuality.high),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Welcome To Kinetic AI', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 30)),
          const SizedBox(height: 10),
          Text('Sign in to sync your sessions, progress, and personalized feedback.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 26),
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(22),
            color: AppColors.white.withValues(alpha: 0.92),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    filled: true,
                    fillColor: AppColors.warmCream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    filled: true,
                    fillColor: AppColors.warmCream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                ),
                const SizedBox(height: 8),
                AnimatedCtaButton(label: 'Sign In', icon: Icons.login_rounded, onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home), height: 62),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.softCharcoal,
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: AppColors.peachSand.withValues(alpha: 0.8)),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('By continuing, you agree to the app terms and privacy policy.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
