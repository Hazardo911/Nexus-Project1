import 'package:flutter/material.dart';

import 'route_names.dart';
import 'theme/app_colors.dart';

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
            colors: AppColors.darkSurfaceGradient,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Row(
                children: [
                  _BackButton(onTap: () => Navigator.maybePop(context)),
                  const Spacer(),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(color: AppColors.sageGreen, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.center_focus_weak_rounded, color: AppColors.terracotta.withValues(alpha: 0.95)),
                  const SizedBox(width: 8),
                  Text('LIVE TRACKING', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.terracotta, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 18),
              Text('3D Pose Skeleton', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 30)),
              const SizedBox(height: 8),
              Text('Realtime joint alignment and confidence tracking', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
              const SizedBox(height: 22),
              Container(
                height: 520,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [BoxShadow(color: AppColors.terracotta.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 18))],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                    Positioned(
                      left: 26,
                      right: 26,
                      top: 26,
                      bottom: 26,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.terracotta.withValues(alpha: 0.04), Colors.transparent, AppColors.burntOrange.withValues(alpha: 0.06)],
                          ),
                        ),
                        child: CustomPaint(painter: _PosePainter()),
                      ),
                    ),
                    const Positioned(top: 26, left: 26, child: _FrameCorner(top: true, left: true)),
                    const Positioned(top: 26, right: 26, child: _FrameCorner(top: true, left: false)),
                    const Positioned(bottom: 26, left: 26, child: _FrameCorner(top: false, left: true)),
                    const Positioned(bottom: 26, right: 26, child: _FrameCorner(top: false, left: false)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _MetricPanel(title: 'Left Hip Alignment', value: '11° Offset', progress: 0.74, tint: AppColors.burntOrange),
              const SizedBox(height: 14),
              const _MetricPanel(title: 'Knee Tracking', value: 'Stable', progress: 0.88, tint: AppColors.terracotta),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(child: _MiniStat(label: 'Hip', value: '92°', tint: AppColors.terracotta)),
                  SizedBox(width: 12),
                  Expanded(child: _MiniStat(label: 'Knee', value: '87°', tint: AppColors.burntOrange)),
                  SizedBox(width: 12),
                  Expanded(child: _MiniStat(label: 'Ankle', value: '95°', tint: AppColors.sageGreen)),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: AppColors.terracotta.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.terracotta),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detection Confidence', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.heatMap),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: AppColors.white,
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white))),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  const _FrameCorner({required this.top, required this.left});
  final bool top;
  final bool left;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: AppColors.terracotta.withValues(alpha: 0.95), width: 2.4) : BorderSide.none,
            bottom: top ? BorderSide.none : BorderSide(color: AppColors.terracotta.withValues(alpha: 0.95), width: 2.4),
            left: left ? BorderSide(color: AppColors.terracotta.withValues(alpha: 0.95), width: 2.4) : BorderSide.none,
            right: left ? BorderSide.none : BorderSide(color: AppColors.terracotta.withValues(alpha: 0.95), width: 2.4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.title, required this.value, required this.progress, required this.tint});
  final String title;
  final String value;
  final double progress;
  final Color tint;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Column(children: [Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)), const SizedBox(width: 10), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18))), Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: tint))]), const SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white.withValues(alpha: 0.08), valueColor: AlwaysStoppedAnimation<Color>(tint)))]),
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
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(22), border: Border.all(color: tint.withValues(alpha: 0.22))),
      child: Column(children: [Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.72))), const SizedBox(height: 10), Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tint, fontSize: 22))]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
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
    final core = Paint()..color = AppColors.terracotta..strokeWidth = 4.5..strokeCap = StrokeCap.round;
    final support = Paint()..color = AppColors.burntOrange..strokeWidth = 4.5..strokeCap = StrokeCap.round;
    final neutral = Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final pts = <String, Offset>{
      'head': Offset(cx, 72),
      'neck': Offset(cx, 118),
      'ls': Offset(cx - 72, 150),
      'rs': Offset(cx + 72, 150),
      'le': Offset(cx - 110, 235),
      're': Offset(cx + 110, 235),
      'hip': Offset(cx, 260),
      'lh': Offset(cx - 42, 300),
      'rh': Offset(cx + 42, 300),
      'lk': Offset(cx - 52, 390),
      'rk': Offset(cx + 54, 395),
      'la': Offset(cx - 64, 470),
      'ra': Offset(cx + 62, 474),
    };
    void seg(String a, String b, Paint p) => canvas.drawLine(pts[a]!, pts[b]!, p);
    seg('head', 'neck', neutral);
    seg('neck', 'ls', neutral);
    seg('neck', 'rs', neutral);
    seg('ls', 'le', support);
    seg('rs', 're', support);
    seg('neck', 'hip', neutral);
    seg('hip', 'lh', core);
    seg('hip', 'rh', core);
    seg('lh', 'lk', core);
    seg('rh', 'rk', support);
    seg('lk', 'la', core);
    seg('rk', 'ra', support);
    for (final p in pts.values) {
      canvas.drawCircle(p, 7, Paint()..color = AppColors.terracotta.withValues(alpha: 0.95));
    }
    for (final key in ['hip', 'lh', 'rh', 'lk', 'rk']) {
      canvas.drawCircle(pts[key]!, 18, Paint()..color = AppColors.terracotta.withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
