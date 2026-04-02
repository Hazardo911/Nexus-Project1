import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  double _divider = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.darkSurfaceGradient)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Row(children: [_BackButton(onTap: () => Navigator.maybePop(context)), const Spacer(), TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.results), child: const Text('Results', style: TextStyle(color: AppColors.terracotta)))]),
              const SizedBox(height: 16),
              Text('Form Comparison', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30, color: AppColors.white)),
              const SizedBox(height: 8),
              Text('Drag the split line to compare your rep against the target form.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final dividerX = width * _divider;
                  return GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _divider = (_divider + (details.delta.dx / width)).clamp(0.22, 0.78);
                      });
                    },
                    child: Container(
                      height: 520,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(34), color: Colors.white.withValues(alpha: 0.04), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Stack(
                          children: [
                            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                            Positioned.fill(
                              child: Row(
                                children: [
                                  Expanded(flex: (_divider * 1000).round(), child: Container(color: AppColors.burntOrange.withValues(alpha: 0.16))),
                                  Expanded(flex: ((1 - _divider) * 1000).round(), child: Container(color: AppColors.terracotta.withValues(alpha: 0.16))),
                                ],
                              ),
                            ),
                            const Positioned(top: 20, left: 20, child: _CompareTag(label: 'Your Form', good: false)),
                            const Positioned(top: 20, right: 20, child: _CompareTag(label: 'Target', good: true)),
                            Positioned.fill(child: CustomPaint(painter: _DualFigurePainter(divider: _divider))),
                            Positioned(left: dividerX - 2, top: 0, bottom: 0, child: Container(width: 4, color: Colors.white.withValues(alpha: 0.95))),
                            Positioned(
                              left: dividerX - 30,
                              top: 220,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.compare_arrows_rounded, size: 28, color: AppColors.softCharcoal),
                              ),
                            ),
                            Positioned(
                              left: 24,
                              right: 24,
                              bottom: 24,
                              child: Row(
                                children: [
                                  Expanded(child: _BottomNote(title: 'Issue', value: 'Knees collapse inward', tint: AppColors.burntOrange)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _BottomNote(title: 'Target', value: 'Drive out over toes', tint: AppColors.terracotta)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text('Key Differences', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppColors.white)),
              const SizedBox(height: 16),
              const _DifferenceCard(title: 'Knee Alignment', text: 'Your knees collapse inward at the bottom. Keep them stacked over the feet.', good: false),
              const SizedBox(height: 14),
              const _DifferenceCard(title: 'Hip Depth', text: 'You are slightly above target depth. Sit back and finish the rep lower.', good: false),
              const SizedBox(height: 14),
              const _DifferenceCard(title: 'Back Position', text: 'Good torso control. Your back stays neutral through most of the movement.', good: true),
              const SizedBox(height: 22),
              SizedBox(
                height: 88,
                child: FilledButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.upload),
                  style: FilledButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: AppColors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  child: Ink(decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: AppColors.heroGradient)), child: const Center(child: Text('Practice Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
                ),
              ),
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

class _CompareTag extends StatelessWidget {
  const _CompareTag({required this.label, required this.good});
  final String label;
  final bool good;
  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.terracotta : AppColors.burntOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }
}

class _BottomNote extends StatelessWidget {
  const _BottomNote({required this.title, required this.value, required this.tint});
  final String title;
  final String value;
  final Color tint;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tint, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white, fontSize: 14))]),
    );
  }
}

class _DifferenceCard extends StatelessWidget {
  const _DifferenceCard({required this.title, required this.text, required this.good});
  final String title;
  final String text;
  final bool good;
  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.sageGreen : AppColors.burntOrange;
    final icon = good ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: Colors.white.withValues(alpha: 0.9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.white)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)), const SizedBox(height: 8), Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.softCharcoal.withValues(alpha: 0.62)))]))]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    const step = 34.0;
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

class _DualFigurePainter extends CustomPainter {
  const _DualFigurePainter({required this.divider});
  final double divider;
  @override
  void paint(Canvas canvas, Size size) {
    _drawFigure(canvas, size, size.width * 0.32, false, AppColors.burntOrange);
    _drawFigure(canvas, size, size.width * 0.68, true, AppColors.terracotta);
  }

  void _drawFigure(Canvas canvas, Size size, double cx, bool good, Color tint) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.72)..strokeWidth = 7..strokeCap = StrokeCap.round;
    final accent = Paint()..color = tint..strokeWidth = 7..strokeCap = StrokeCap.round;
    final head = Offset(cx, 140);
    final neck = Offset(cx, 196);
    final ls = Offset(cx - 42, 232);
    final rs = Offset(cx + 42, 232);
    final hip = Offset(cx, 314);
    final lk = good ? Offset(cx - 24, 408) : Offset(cx - 42, 394);
    final rk = good ? Offset(cx + 24, 408) : Offset(cx + 14, 422);
    final la = Offset(cx - 24, 498);
    final ra = Offset(cx + 30, 498);
    canvas.drawCircle(head, 28, Paint()..color = Colors.white.withValues(alpha: 0.42));
    canvas.drawLine(head, neck, paint);
    canvas.drawLine(neck, ls, paint);
    canvas.drawLine(neck, rs, paint);
    canvas.drawLine(ls, hip, accent);
    canvas.drawLine(rs, hip, accent);
    canvas.drawLine(hip, lk, accent);
    canvas.drawLine(hip, rk, accent);
    canvas.drawLine(lk, la, paint);
    canvas.drawLine(rk, ra, paint);
  }

  @override
  bool shouldRepaint(covariant _DualFigurePainter oldDelegate) => oldDelegate.divider != divider;
}
