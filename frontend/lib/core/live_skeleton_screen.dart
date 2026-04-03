import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'latest_analysis_store.dart';
import 'route_names.dart';
import 'services/nexus_api_service.dart';
import 'theme/app_colors.dart';

class LiveSkeletonScreen extends StatefulWidget {
  const LiveSkeletonScreen({super.key});

  @override
  State<LiveSkeletonScreen> createState() => _LiveSkeletonScreenState();
}

class _LiveSkeletonScreenState extends State<LiveSkeletonScreen> {
  Map<String, dynamic>? _visual;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVisual();
  }

  Future<void> _loadVisual() async {
    final local = LatestAnalysisStore.latestVisualResult;
    if (local != null && local.isNotEmpty) {
      setState(() {
        _visual = local;
        _loading = false;
      });
    }

    try {
      final latest = await NexusApiService.getLatestResult();
      if (!mounted) return;
      if ((latest['message']?.toString().contains('No analysis') ?? false) || latest.isEmpty) {
        setState(() {
          _visual = local;
          _loading = false;
        });
        return;
      }
      LatestAnalysisStore.save(latest);
      if (latest['landmarks'] != null || latest['connections'] != null) {
        LatestAnalysisStore.saveVisual(latest);
      }
      setState(() {
        _visual = latest;
        _loading = false;
        _error = null;
      });
    } on NexusApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    final landmarks = _extractLandmarks(visual?['landmarks']);
    final connections = _extractConnections(visual?['connections']);
    final features = _extractFeatureSet(visual);
    final confidence = _toDouble(_readPath(visual, 'model.confidence')) ?? 0;
    final exercise = visual?['selected_exercise']?.toString() ?? visual?['exercise']?.toString() ?? 'Latest Session';
    final formStatus = visual?['form_status']?.toString() ?? visual?['status']?.toString() ?? 'Captured';
    final hasPose = landmarks.isNotEmpty && connections.isNotEmpty;

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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasPose ? AppColors.sageGreen.withValues(alpha: 0.16) : AppColors.burntOrange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: hasPose ? AppColors.sageGreen.withValues(alpha: 0.35) : AppColors.burntOrange.withValues(alpha: 0.32)),
                    ),
                    child: Text(
                      _loading ? 'Loading' : formStatus.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasPose ? AppColors.sageGreen : AppColors.burntOrange,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '3D Skeleton Replay',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.white,
                      fontSize: 30,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _loading
                    ? 'Refreshing the latest pose from your backend session.'
                    : hasPose
                        ? 'Latest $exercise capture with joint depth, alignment, and quality metrics.'
                        : (_error ?? 'Run a fresh Go Live or Analyze Upload session to unlock the pose replay.'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.72),
                    ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF223047),
                      const Color(0xFF171F2A),
                      AppColors.terracotta.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 430,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                              Positioned.fill(child: CustomPaint(painter: _AuraPainter(hasPose: hasPose))),
                              if (_loading)
                                const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                              else if (hasPose)
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: CustomPaint(
                                      painter: _LivePosePainter(
                                        landmarks: landmarks,
                                        connections: connections,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 28),
                                    child: Text(
                                      'No pose landmarks available yet.\nRecord a fresh session first.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.white.withValues(alpha: 0.72),
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroMetric(
                            label: 'Back',
                            value: _formatMetric(features['back_angle'], suffix: 'deg'),
                            tint: AppColors.burntOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeroMetric(
                            label: 'Knee',
                            value: _formatMetric(features['avg_knee_angle'], suffix: 'deg'),
                            tint: AppColors.terracotta,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeroMetric(
                            label: 'Stability',
                            value: _formatMetric(features['stability'], asPercent: true),
                            tint: AppColors.sageGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _MetricPanel(
                title: 'Spinal Alignment',
                caption: 'Back angle and hinge quality from the latest capture',
                value: _formatMetric(features['back_angle'], suffix: 'deg'),
                progress: _normalized(features['back_angle'], 120),
                tint: AppColors.burntOrange,
              ),
              const SizedBox(height: 14),
              _MetricPanel(
                title: 'Movement Stability',
                caption: 'How steady and repeatable the pose looked',
                value: _formatMetric(features['stability'], asPercent: true),
                progress: _normalized(features['stability'], 1),
                tint: AppColors.terracotta,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _MiniStat(label: 'Hip', value: _formatMetric(features['hip_angle_avg'], suffix: 'deg'), tint: AppColors.gold)),
                  const SizedBox(width: 12),
                  Expanded(child: _MiniStat(label: 'Depth', value: _formatMetric(features['depth'], asPercent: true), tint: AppColors.sageGreen)),
                  const SizedBox(width: 12),
                  Expanded(child: _MiniStat(label: 'Symmetry', value: _formatMetric(features['symmetry_score'], asPercent: true), tint: AppColors.terracotta)),
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
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.terracotta),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detection Confidence',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.72),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatMetric(confidence, asPercent: true),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppColors.white,
                                  fontSize: 24,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: CircularProgressIndicator(
                        value: _normalized(confidence <= 1 ? confidence * 100 : confidence, 100),
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
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, required this.tint});

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tint, fontSize: 20)),
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.title,
    required this.caption,
    required this.value,
    required this.progress,
    required this.tint,
  });

  final String title;
  final String caption;
  final String value;
  final double progress;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18))),
              Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: tint)),
            ],
          ),
          const SizedBox(height: 6),
          Text(caption, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.62))),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(tint),
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
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
    final major = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final minor = Paint()..color = Colors.white.withValues(alpha: 0.02);
    const minorStep = 24.0;
    const majorStep = 96.0;
    for (double x = 0; x <= size.width; x += minorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    for (double y = 0; y <= size.height; y += minorStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
    for (double x = 0; x <= size.width; x += majorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), major);
    }
    for (double y = 0; y <= size.height; y += majorStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), major);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({required this.hasPose});

  final bool hasPose;

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasPose) return;
    final center = Offset(size.width * 0.52, size.height * 0.42);
    final rect = Rect.fromCircle(center: center, radius: size.width * 0.42);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.terracotta.withValues(alpha: 0.14),
          AppColors.burntOrange.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawCircle(center, size.width * 0.42, paint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) => oldDelegate.hasPose != hasPose;
}

class _LivePosePainter extends CustomPainter {
  const _LivePosePainter({required this.landmarks, required this.connections});

  final List<Map<String, dynamic>> landmarks;
  final List<List<int>> connections;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = _fitLandmarks(landmarks, size);
    final linePaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.terracotta, AppColors.burntOrange, AppColors.sageGreen],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    final glowPaint = Paint()
      ..color = AppColors.terracotta.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    for (final connection in connections) {
      if (connection.length < 2) continue;
      final a = connection[0];
      final b = connection[1];
      if (a >= fitted.length || b >= fitted.length) continue;
      canvas.drawLine(fitted[a].offset, fitted[b].offset, glowPaint..strokeWidth = 10);
      canvas.drawLine(fitted[a].offset, fitted[b].offset, linePaint);
    }

    for (final point in fitted) {
      canvas.drawCircle(point.offset.translate(point.depth * 8, -point.depth * 6), 13, Paint()..color = AppColors.terracotta.withValues(alpha: 0.10));
      canvas.drawCircle(point.offset, point.radius + 2, Paint()..color = Colors.white.withValues(alpha: 0.08));
      canvas.drawCircle(
        point.offset,
        point.radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.95),
              point.color,
            ],
          ).createShader(Rect.fromCircle(center: point.offset, radius: point.radius)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LivePosePainter oldDelegate) => oldDelegate.landmarks != landmarks || oldDelegate.connections != connections;
}

class _ProjectedPoint {
  const _ProjectedPoint({
    required this.offset,
    required this.radius,
    required this.color,
    required this.depth,
  });

  final Offset offset;
  final double radius;
  final Color color;
  final double depth;
}

List<_ProjectedPoint> _fitLandmarks(List<Map<String, dynamic>> points, Size size) {
  if (points.isEmpty) return const <_ProjectedPoint>[];

  final xs = points.map((p) => _toDouble(p['x']) ?? 0.5).toList();
  final ys = points.map((p) => _toDouble(p['y']) ?? 0.5).toList();
  final minX = xs.reduce(math.min);
  final maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min);
  final maxY = ys.reduce(math.max);
  final width = math.max(maxX - minX, 0.2);
  final height = math.max(maxY - minY, 0.2);
  final scale = math.min((size.width * 0.78) / width, (size.height * 0.82) / height);
  final offsetX = (size.width - (width * scale)) / 2;
  final offsetY = (size.height - (height * scale)) / 2;

  return points.map((point) {
    final x = _toDouble(point['x']) ?? 0.5;
    final y = _toDouble(point['y']) ?? 0.5;
    final z = (_toDouble(point['z']) ?? 0).clamp(-1.0, 1.0);
    final visibility = (_toDouble(point['visibility']) ?? 1).clamp(0.15, 1.0);
    final normalizedDepth = ((z + 1) / 2).clamp(0.0, 1.0);
    final color = Color.lerp(AppColors.sageGreen, AppColors.terracotta, 1 - normalizedDepth) ?? AppColors.terracotta;
    return _ProjectedPoint(
      offset: Offset(offsetX + ((x - minX) * scale), offsetY + ((y - minY) * scale)),
      radius: 4.5 + (visibility * 2.8),
      color: color,
      depth: z,
    );
  }).toList();
}

Map<String, dynamic> _extractFeatureSet(Map<String, dynamic>? source) {
  final features = <String, dynamic>{};
  final nested = source?['features'];
  if (nested is Map) {
    for (final entry in nested.entries) {
      features[entry.key.toString()] = entry.value;
    }
  }

  for (final key in const [
    'avg_knee_angle',
    'min_knee_angle',
    'max_knee_angle',
    'hip_angle_avg',
    'back_angle',
    'symmetry_score',
    'speed',
    'stability',
    'depth',
    'coordination_score',
    'shoulder_angle',
  ]) {
    final value = source?[key];
    if (value != null && !features.containsKey(key)) {
      features[key] = value;
    }
  }
  return features;
}

List<Map<String, dynamic>> _extractLandmarks(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map((item) => item.map((key, dynamic val) => MapEntry(key.toString(), val))).toList();
  }
  return const <Map<String, dynamic>>[];
}

List<List<int>> _extractConnections(Object? value) {
  if (value is List) {
    return value.whereType<List>().map((pair) => pair.whereType<num>().map((n) => n.toInt()).toList()).where((pair) => pair.length >= 2).toList();
  }
  return const <List<int>>[];
}

Object? _readPath(Map<String, dynamic>? source, String path) {
  if (source == null) return null;
  Object? current = source;
  for (final segment in path.split('.')) {
    if (current is Map) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double _normalized(Object? value, double max) {
  final numeric = _toDouble(value) ?? 0;
  if (max <= 0) return 0;
  return (numeric / max).clamp(0.0, 1.0);
}

String _formatMetric(Object? value, {bool asPercent = false, String suffix = ''}) {
  final numeric = _toDouble(value);
  if (numeric == null) return 'N/A';
  if (asPercent) {
    final display = numeric <= 1 ? numeric * 100 : numeric;
    return '${display.toStringAsFixed(1)}%';
  }
  if (suffix.isNotEmpty) return '${numeric.toStringAsFixed(1)} $suffix';
  return numeric.toStringAsFixed(2);
}
