import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';

class HeatMapScreen extends StatelessWidget {
  const HeatMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.darkSurfaceGradient)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Row(children: [_BackButton(onTap: () => Navigator.maybePop(context)), const Spacer(), TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.compare), child: const Text('Compare', style: TextStyle(color: AppColors.terracotta)))]),
              const SizedBox(height: 16),
              Text('Heat Map', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 30)),
              const SizedBox(height: 8),
              Text('Stress zones and movement intensity overlay', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
              const SizedBox(height: 22),
              Container(
                height: 480,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                    Positioned.fill(child: CustomPaint(painter: _HeatGlowPainter())),
                    Positioned.fill(child: CustomPaint(painter: _BodySilhouettePainter())),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _HeatLegend(),
              const SizedBox(height: 18),
              const _HeatInsight(title: 'Lower Back Load', value: 'High', tint: AppColors.burntOrange),
              const SizedBox(height: 14),
              const _HeatInsight(title: 'Hip Drive', value: 'Peak', tint: AppColors.terracotta),
              const SizedBox(height: 14),
              const _HeatInsight(title: 'Ankle Stability', value: 'Stable', tint: AppColors.sageGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.white.withValues(alpha: 0.1), shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white))));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const step = 28.0;
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

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [_LegendItem(label: 'Cool', color: AppColors.sageGreen), _LegendItem(label: 'Medium', color: AppColors.terracotta), _LegendItem(label: 'Peak', color: AppColors.burntOrange)]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white))]);
  }
}

class _HeatInsight extends StatelessWidget {
  const _HeatInsight({required this.title, required this.value, required this.tint});
  final String title;
  final String value;
  final Color tint;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Row(children: [Container(width: 16, height: 16, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)), const SizedBox(width: 14), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18))), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tint))]),
    );
  }
}

class _BodySilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.14)..strokeWidth = 12..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    canvas.drawCircle(Offset(cx, 88), 30, Paint()..color = Colors.white.withValues(alpha: 0.12));
    canvas.drawLine(Offset(cx, 120), Offset(cx, 220), paint);
    canvas.drawLine(Offset(cx, 145), Offset(cx - 62, 210), paint);
    canvas.drawLine(Offset(cx, 145), Offset(cx + 62, 210), paint);
    canvas.drawLine(Offset(cx, 220), Offset(cx - 42, 330), paint);
    canvas.drawLine(Offset(cx, 220), Offset(cx + 42, 330), paint);
    canvas.drawLine(Offset(cx - 42, 330), Offset(cx - 58, 432), paint);
    canvas.drawLine(Offset(cx + 42, 330), Offset(cx + 58, 432), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeatGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final spots = [
      (Offset(size.width * 0.5, size.height * 0.26), AppColors.terracotta, 58.0),
      (Offset(size.width * 0.42, size.height * 0.46), AppColors.burntOrange, 64.0),
      (Offset(size.width * 0.58, size.height * 0.46), AppColors.burntOrange, 64.0),
      (Offset(size.width * 0.5, size.height * 0.60), AppColors.terracotta, 74.0),
      (Offset(size.width * 0.44, size.height * 0.82), AppColors.sageGreen, 48.0),
      (Offset(size.width * 0.56, size.height * 0.82), AppColors.sageGreen, 48.0),
    ];
    for (final spot in spots) {
      final paint = Paint()..shader = RadialGradient(colors: [spot.$2.withValues(alpha: 0.72), spot.$2.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: spot.$1, radius: spot.$3));
      canvas.drawCircle(spot.$1, spot.$3, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
