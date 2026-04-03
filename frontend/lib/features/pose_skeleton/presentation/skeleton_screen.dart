import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SkeletonScreen extends StatelessWidget {
  const SkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F2B28), Color(0xFF47403A), Color(0xFF6E655E)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                  ),
                  const Spacer(),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: Color(0xFFE85047), shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.center_focus_weak_rounded, color: AppColors.sageGreen.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  Text('LIVE TRACKING', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.sageGreen, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 18),
              Text('3D Pose Skeleton', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 28)),
              const SizedBox(height: 20),
              Container(
                height: 520,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                  color: AppColors.white.withValues(alpha: 0.04),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 24,
                      child: CustomPaint(painter: _PosePainter()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _MetricPanel(title: 'Left Hip Alignment', value: '15° Off', progress: 0.78),
              const SizedBox(height: 16),
              const _MetricPanel(title: 'Left Knee Tracking', value: 'Inward', progress: 0.64),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(child: _MiniStat(label: 'Hip', value: '92°', tint: AppColors.sageGreen)),
                  SizedBox(width: 12),
                  Expanded(child: _MiniStat(label: 'Knee', value: '87°', tint: AppColors.burntOrange)),
                  SizedBox(width: 12),
                  Expanded(child: _MiniStat(label: 'Ankle', value: '95°', tint: Color(0xFF9DC29C))),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.sageGreen.withValues(alpha: 0.85), size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detection Confidence', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text('98.4%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 24)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: 0.984,
                        strokeWidth: 6,
                        backgroundColor: AppColors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sageGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/heatmap'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: const Text('Open Heat Map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.title, required this.value, required this.progress});

  final String title;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.burntOrange, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18))),
              Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.burntOrange)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.burntOrange),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.tint});

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tint, fontSize: 22)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.white.withValues(alpha: 0.05);
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leftPaint = Paint()
      ..color = const Color(0xFFA8C2A2)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final rightPaint = Paint()
      ..color = const Color(0xFFD69245)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final points = <String, Offset>{
      'head': Offset(centerX, 70),
      'neck': Offset(centerX, 110),
      'ls': Offset(centerX - 74, 140),
      'rs': Offset(centerX + 74, 140),
      'le': Offset(centerX - 110, 220),
      're': Offset(centerX + 110, 220),
      'lh': Offset(centerX - 38, 290),
      'rh': Offset(centerX + 38, 290),
      'lk': Offset(centerX - 48, 390),
      'rk': Offset(centerX + 48, 390),
      'la': Offset(centerX - 62, 470),
      'ra': Offset(centerX + 58, 470),
    };

    void line(String a, String b, Paint paint) => canvas.drawLine(points[a]!, points[b]!, paint);

    line('head', 'neck', leftPaint);
    line('neck', 'ls', leftPaint);
    line('neck', 'rs', leftPaint);
    line('ls', 'le', leftPaint);
    line('rs', 're', leftPaint);
    line('neck', 'lh', leftPaint);
    line('neck', 'rh', rightPaint);
    line('lh', 'lk', rightPaint);
    line('rh', 'rk', leftPaint);
    line('lk', 'la', rightPaint);
    line('rk', 'ra', leftPaint);

    for (final entry in points.entries) {
      final isRight = entry.key.startsWith('r') || entry.key == 'rh';
      final color = isRight ? const Color(0xFFA8C2A2) : const Color(0xFFD69245);
      canvas.drawCircle(entry.value, 8, Paint()..color = color);
      if (entry.key == 'lh' || entry.key == 'rh' || entry.key == 'lk') {
        canvas.drawCircle(entry.value, 22, Paint()..color = color.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
