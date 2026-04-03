import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'latest_analysis_store.dart';
import 'route_names.dart';
import 'services/nexus_api_service.dart';
import 'theme/app_colors.dart';

class LiveHeatMapScreen extends StatefulWidget {
  const LiveHeatMapScreen({super.key});

  @override
  State<LiveHeatMapScreen> createState() => _LiveHeatMapScreenState();
}

class _LiveHeatMapScreenState extends State<LiveHeatMapScreen> {
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
    final features = _extractFeatureSet(visual);
    final landmarks = _extractLandmarks(visual?['landmarks']);
    final riskFlags = _stringList(visual?['risk_flags']);
    final warnings = _stringList(visual?['warnings']);
    final exercise = visual?['selected_exercise']?.toString() ?? visual?['exercise']?.toString() ?? 'latest session';
    final hasData = features.isNotEmpty || landmarks.isNotEmpty;
    final spots = _buildHeatSpots(landmarks, features);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.darkSurfaceGradient),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Row(
                children: [
                  _BackButton(onTap: () => Navigator.maybePop(context)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.compare),
                    child: const Text('Compare', style: TextStyle(color: AppColors.terracotta)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Movement Heat Map',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                _loading
                    ? 'Loading the latest body load map from your backend session.'
                    : hasData
                        ? 'Stress zones and control hotspots for the latest $exercise capture.'
                        : (_error ?? 'Run Go Live or Analyze Upload first to unlock the heat map.'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF221A28),
                      const Color(0xFF161D26),
                      AppColors.burntOrange.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: SizedBox(
                  height: 500,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                          : hasData
                              ? Stack(
                                  children: [
                                    Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                                    Positioned.fill(child: CustomPaint(painter: _HeatGlowPainter(spots: spots))),
                                    Positioned.fill(child: CustomPaint(painter: _BodySilhouettePainter(landmarks: landmarks))),
                                  ],
                                )
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 28),
                                    child: Text(
                                      'No latest body-load metrics found.\nAnalyze a session first.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.72)),
                                    ),
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _HeatLegend(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _TopChip(
                      label: 'Back Load',
                      value: _statusFor(features['back_angle'], high: 60, medium: 35),
                      tint: AppColors.burntOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TopChip(
                      label: 'Depth',
                      value: _statusFor(features['depth'], high: 0.60, medium: 0.35, positive: true),
                      tint: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TopChip(
                      label: 'Stability',
                      value: _statusFor(features['stability'], high: 0.75, medium: 0.45, positive: true),
                      tint: AppColors.sageGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (riskFlags.isNotEmpty || warnings.isNotEmpty) ...[
                ...riskFlags.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _HeatInsight(title: 'Risk Flag', value: item, tint: AppColors.burntOrange),
                  ),
                ),
                ...warnings.take(2).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _HeatInsight(title: 'Warning', value: item, tint: AppColors.terracotta),
                  ),
                ),
              ] else ...[
                _HeatInsight(title: 'Symmetry Control', value: _formatMetric(features['symmetry_score'], asPercent: true), tint: AppColors.terracotta),
                const SizedBox(height: 14),
                _HeatInsight(title: 'Coordination Score', value: _formatMetric(features['coordination_score'], asPercent: true), tint: AppColors.gold),
                const SizedBox(height: 14),
                _HeatInsight(title: 'Speed Signature', value: _formatMetric(features['speed']), tint: AppColors.sageGreen),
              ],
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()..color = Colors.white.withValues(alpha: 0.02);
    final major = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const minorStep = 26.0;
    const majorStep = 104.0;
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

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _LegendItem(label: 'Cool', color: AppColors.sageGreen),
          _LegendItem(label: 'Medium', color: AppColors.terracotta),
          _LegendItem(label: 'Peak', color: AppColors.burntOrange),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white)),
      ],
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({required this.label, required this.value, required this.tint});

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.72))),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tint)),
        ],
      ),
    );
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tint))),
        ],
      ),
    );
  }
}

class _BodySilhouettePainter extends CustomPainter {
  const _BodySilhouettePainter({required this.landmarks});

  final List<Map<String, dynamic>> landmarks;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    if (landmarks.length >= 17) {
      final fitted = _fitPoints(landmarks, size);
      void seg(int a, int b) => canvas.drawLine(fitted[a], fitted[b], paint);
      canvas.drawCircle(fitted[0], 20, Paint()..color = Colors.white.withValues(alpha: 0.08));
      seg(5, 6);
      seg(5, 11);
      seg(6, 12);
      seg(11, 12);
      seg(11, 13);
      seg(13, 15);
      seg(12, 14);
      seg(14, 16);
      seg(5, 7);
      seg(7, 9);
      seg(6, 8);
      seg(8, 10);
      return;
    }

    final cx = size.width / 2;
    canvas.drawCircle(Offset(cx, 92), 28, Paint()..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawLine(Offset(cx, 120), Offset(cx, 230), paint);
    canvas.drawLine(Offset(cx, 150), Offset(cx - 60, 215), paint);
    canvas.drawLine(Offset(cx, 150), Offset(cx + 60, 215), paint);
    canvas.drawLine(Offset(cx, 230), Offset(cx - 42, 340), paint);
    canvas.drawLine(Offset(cx, 230), Offset(cx + 42, 340), paint);
    canvas.drawLine(Offset(cx - 42, 340), Offset(cx - 58, 444), paint);
    canvas.drawLine(Offset(cx + 42, 340), Offset(cx + 58, 444), paint);
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter oldDelegate) => oldDelegate.landmarks != landmarks;
}

class _HeatGlowPainter extends CustomPainter {
  const _HeatGlowPainter({required this.spots});
  final List<_HeatSpot> spots;

  @override
  void paint(Canvas canvas, Size size) {
    for (final spot in spots) {
      final center = Offset(size.width * spot.x, size.height * spot.y);
      final shader = RadialGradient(
        colors: [
          spot.color.withValues(alpha: 0.82),
          spot.color.withValues(alpha: 0.36),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: spot.radius));
      canvas.drawCircle(center, spot.radius, Paint()..shader = shader);
    }
  }

  @override
  bool shouldRepaint(covariant _HeatGlowPainter oldDelegate) => oldDelegate.spots != spots;
}

class _HeatSpot {
  const _HeatSpot({required this.x, required this.y, required this.radius, required this.color});
  final double x;
  final double y;
  final double radius;
  final Color color;
}

List<_HeatSpot> _buildHeatSpots(List<Map<String, dynamic>> landmarks, Map<String, dynamic> features) {
  final fitted = landmarks.length >= 17 ? _fitNormalizedPoints(landmarks) : null;
  final back = ((_toDouble(features['back_angle']) ?? 0).clamp(0, 120)) / 120;
  final depth = ((_toDouble(features['depth']) ?? 0).clamp(0, 1));
  final stability = ((_toDouble(features['stability']) ?? 0).clamp(0, 1));
  final symmetry = ((_toDouble(features['symmetry_score']) ?? 0).clamp(0, 1));

  Offset point(int index, Offset fallback) {
    if (fitted == null || index >= fitted.length) return fallback;
    return fitted[index];
  }

  final neck = point(0, const Offset(0.5, 0.18));
  final leftHip = point(11, const Offset(0.42, 0.58));
  final rightHip = point(12, const Offset(0.58, 0.58));
  final leftKnee = point(13, const Offset(0.42, 0.76));
  final rightKnee = point(14, const Offset(0.58, 0.76));
  final leftAnkle = point(15, const Offset(0.42, 0.92));
  final rightAnkle = point(16, const Offset(0.58, 0.92));

  return [
    _HeatSpot(x: neck.dx, y: 0.24, radius: 36 + (depth * 18), color: AppColors.terracotta),
    _HeatSpot(x: 0.50, y: ((leftHip.dy + rightHip.dy) / 2) - 0.05, radius: 40 + (back * 40), color: AppColors.burntOrange),
    _HeatSpot(x: leftHip.dx, y: leftHip.dy, radius: 38 + (depth * 28), color: symmetry < 0.7 ? AppColors.burntOrange : AppColors.terracotta),
    _HeatSpot(x: rightHip.dx, y: rightHip.dy, radius: 38 + (depth * 28), color: symmetry < 0.7 ? AppColors.burntOrange : AppColors.terracotta),
    _HeatSpot(x: leftKnee.dx, y: leftKnee.dy, radius: 34 + ((1 - stability) * 20), color: AppColors.gold),
    _HeatSpot(x: rightKnee.dx, y: rightKnee.dy, radius: 34 + ((1 - stability) * 20), color: AppColors.gold),
    _HeatSpot(x: leftAnkle.dx, y: leftAnkle.dy, radius: 28 + ((1 - stability) * 18), color: stability > 0.7 ? AppColors.sageGreen : AppColors.burntOrange),
    _HeatSpot(x: rightAnkle.dx, y: rightAnkle.dy, radius: 28 + ((1 - stability) * 18), color: stability > 0.7 ? AppColors.sageGreen : AppColors.burntOrange),
  ];
}

List<Offset> _fitPoints(List<Map<String, dynamic>> points, Size size) {
  final normalized = _fitNormalizedPoints(points);
  return normalized.map((point) => Offset(point.dx * size.width, point.dy * size.height)).toList();
}

List<Offset> _fitNormalizedPoints(List<Map<String, dynamic>> points) {
  final xs = points.map((p) => _toDouble(p['x']) ?? 0.5).toList();
  final ys = points.map((p) => _toDouble(p['y']) ?? 0.5).toList();
  final minX = xs.reduce(math.min);
  final maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min);
  final maxY = ys.reduce(math.max);
  final width = math.max(maxX - minX, 0.2);
  final height = math.max(maxY - minY, 0.2);

  return points.map((point) {
    final x = _toDouble(point['x']) ?? 0.5;
    final y = _toDouble(point['y']) ?? 0.5;
    final fittedX = 0.18 + (((x - minX) / width) * 0.64);
    final fittedY = 0.10 + (((y - minY) / height) * 0.82);
    return Offset(fittedX.clamp(0.0, 1.0), fittedY.clamp(0.0, 1.0));
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

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
  }
  return const <String>[];
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _statusFor(Object? value, {required double high, required double medium, bool positive = false}) {
  final numeric = _toDouble(value);
  if (numeric == null) return 'N/A';
  if (positive) {
    if (numeric >= high) return 'Strong';
    if (numeric >= medium) return 'Okay';
    return 'Low';
  }
  if (numeric >= high) return 'High';
  if (numeric >= medium) return 'Medium';
  return 'Low';
}

String _formatMetric(Object? value, {bool asPercent = false}) {
  final numeric = _toDouble(value);
  if (numeric == null) return 'N/A';
  if (asPercent) {
    final display = numeric <= 1 ? numeric * 100 : numeric;
    return '${display.toStringAsFixed(1)}%';
  }
  return numeric.toStringAsFixed(2);
}
