import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_cta_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _logoAsset = 'assets/images/logo_mark.png';

  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _splashController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _splashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  void _openGetStarted() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _openLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30, color: AppColors.white, fontWeight: FontWeight.w900);
    final subtitleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white, fontWeight: FontWeight.w700);
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.9), height: 1.45, fontSize: 15);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.darkSurfaceGradient)),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _SplashGridPainter())),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(-0.2, -0.3), radius: 1.0, colors: [AppColors.terracotta.withValues(alpha: 0.18), Colors.transparent])))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                child: Column(
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: Listenable.merge([_orbitController, _pulseController, _splashController]),
                      builder: (context, _) {
                        final pulse = 1 + (_pulseController.value * 0.05);
                        return Transform.scale(
                          scale: pulse,
                          child: SizedBox(
                            width: 190,
                            height: 190,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _SplashRing(progress: _splashController.value, rotation: _orbitController.value * math.pi * 2),
                                const _LogoMark(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text('Kinetic', style: titleStyle, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('AI', style: subtitleStyle, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 290), child: Text('AI-powered exercise form analysis to prevent injury and optimize performance', style: bodyStyle, textAlign: TextAlign.center)),
                    const SizedBox(height: 10),
                    Text('Powered by AI & Pose Estimation', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.74), fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 36),
                    const _PagerDots(),
                    const Spacer(),
                    AnimatedCtaButton(
                      label: 'Get Started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _openGetStarted,
                      height: 68,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: OutlinedButton(
                        onPressed: _openLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded, color: AppColors.white.withValues(alpha: 0.92)),
                            const SizedBox(width: 10),
                            Text('Login', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 17, color: AppColors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('New here? Get started to explore the app flow.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.62)), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const step = 38.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.terracotta.withValues(alpha: 0.2),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          _SplashScreenState._logoAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.terracotta,
              alignment: Alignment.center,
              child: Icon(Icons.show_chart_rounded, color: AppColors.white.withValues(alpha: 0.95), size: 52),
            );
          },
        ),
      ),
    );
  }
}

class _SplashRing extends StatelessWidget {
  const _SplashRing({required this.progress, required this.rotation});

  final double progress;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(size: const Size(190, 190), painter: _SplashRingPainter(progress)),
    );
  }
}

class _SplashRingPainter extends CustomPainter {
  _SplashRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppColors.terracotta.withValues(alpha: 0.18 * (1 - progress));
    canvas.drawCircle(center, 68 + (22 * progress), ringPaint);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.terracotta.withValues(alpha: 0.92 - (0.3 * progress));

    final dots = <Offset>[
      Offset(center.dx, center.dy - 82),
      Offset(center.dx + 72, center.dy),
      Offset(center.dx, center.dy + 82),
      Offset(center.dx - 72, center.dy),
      Offset(center.dx + 52, center.dy - 52),
      Offset(center.dx - 52, center.dy + 52),
    ];

    for (final point in dots) {
      canvas.drawCircle(point, 5 - (1.2 * progress), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashRingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _PagerDots extends StatelessWidget {
  const _PagerDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => Container(width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: index == 1 ? AppColors.terracotta : AppColors.white.withValues(alpha: 0.42), shape: BoxShape.circle))),
    );
  }
}
