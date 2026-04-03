import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/services/nexus_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_cta_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _logoAsset = 'assets/images/logo_mark.png';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('isLogin')) {
        _isLogin = args['isLogin'] as bool;
      }
      _initialized = true;
    }
  }

  Future<void> _handleSubmit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    if (!_isLogin && _nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await NexusApiService.login(_emailController.text, _passwordController.text);
      } else {
        await NexusApiService.register(_nameController.text, _emailController.text, _passwordController.text);
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on NexusApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _isLogin ? 'Login' : 'Sign Up',
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
          Text(_isLogin ? 'Sign in to sync your sessions, progress, and personalized feedback.' : 'Create an account to track your progress and optimize your form.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 26),
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(22),
            color: AppColors.white.withValues(alpha: 0.92),
            child: Column(
              children: [
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      filled: true,
                      fillColor: AppColors.warmCream,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
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
                  controller: _passwordController,
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
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                  ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  AnimatedCtaButton(
                    label: _isLogin ? 'Sign In' : 'Register',
                    icon: _isLogin ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
                    onPressed: _handleSubmit,
                    height: 62,
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.softCharcoal,
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: AppColors.peachSand.withValues(alpha: 0.8)),
                    ),
                    child: Text(_isLogin ? 'Create Account' : 'Already have an account? Login'),
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
