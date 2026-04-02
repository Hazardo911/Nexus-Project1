import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/services/nexus_api_service.dart';
import '../../../core/theme/app_colors.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _pollTimer;
  int _progress = 12;
  bool _navigated = false;
  String _subtitle = 'Connecting to backend analysis engine';
  String _stage1 = 'Starting session...';
  String _stage2 = 'Waiting for live camera processing...';
  String _stage3 = 'Collecting summary output...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _startPolling();
  }

  void _startPolling() {
    _pollBackend();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) => _pollBackend());
  }

  Future<void> _pollBackend() async {
    if (!mounted || _navigated) return;
    try {
      final summary = await NexusApiService.getSummary();
      _goResults(summary);
      return;
    } on NexusApiException {
      // summary is not ready yet
    }

    try {
      final status = await NexusApiService.getStatus();
      final running = status['running'] == true;
      final elapsed = ((status['elapsed_seconds'] as num?) ?? 0).toDouble();

      int nextProgress = _progress;
      if (running) {
        nextProgress = (18 + (elapsed * 6)).clamp(18, 88).toInt();
      }

      String stage1 = running ? 'Backend session running' : 'Backend idle';
      String stage2 = 'Waiting for pose and rep data';
      String stage3 = 'Summary will appear when session completes';
      String subtitle = running
          ? 'Backend is live. Complete the movement on the backend camera window.'
          : 'Trying to reach active backend session';

      try {
        final session = await NexusApiService.getSession();
        final reps = (session['reps'] as num?)?.toInt() ?? 0;
        final goal = (session['goal'] as num?)?.toInt();
        final feedback = (session['feedback'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
        final done = session['done'] == true;
        final exercise = session['exercise']?.toString();

        stage1 = exercise == null ? 'Exercise not detected yet' : 'Tracking ${exercise.toUpperCase()}';
        stage2 = goal == null ? 'Set goal inside backend camera window' : 'Reps: $reps / $goal';
        stage3 = feedback.isEmpty ? 'Waiting for feedback...' : feedback.first;
        subtitle = 'Backend camera and logic are processing live movement.';

        if (goal != null && goal > 0) {
          nextProgress = ((reps / goal) * 100).clamp(nextProgress.toDouble(), 96).toInt();
        }
        if (done) {
          nextProgress = 100;
        }
      } on NexusApiException {
        // session not ready yet
      }

      if (!mounted) return;
      setState(() {
        _progress = nextProgress;
        _subtitle = subtitle;
        _stage1 = stage1;
        _stage2 = stage2;
        _stage3 = stage3;
      });
    } on NexusApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _subtitle = error.message;
        _stage1 = 'Make sure FastAPI is running';
        _stage2 = 'Use adb reverse tcp:8000 tcp:8000';
        _stage3 = 'Then tap Start Analysis again';
        _progress = _progress.clamp(12, 24);
      });
    }
  }

  void _goResults(Map<String, dynamic> summary) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, AppRoutes.results, arguments: summary);
  }

  Future<void> _cancelAnalysis() async {
    try {
      await NexusApiService.stopSession();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.upload);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF151A20), Color(0xFF1D2631), Color(0xFF283342)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(onPressed: _cancelAnalysis, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white)),
                        const SizedBox(height: 6),
                        Center(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              final wave = _pulseController.value;
                              return SizedBox(
                                width: 240,
                                height: 240,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _PulseRing(size: 210 + (20 * wave), opacity: 0.10 * (1 - wave)),
                                    _PulseRing(size: 150 + (16 * wave), opacity: 0.14 * (1 - wave)),
                                    Container(
                                      width: 118,
                                      height: 118,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
                                        boxShadow: [BoxShadow(color: AppColors.terracotta.withValues(alpha: 0.28), blurRadius: 30, spreadRadius: 6)],
                                      ),
                                      child: Transform.rotate(angle: wave * math.pi * 2, child: const Icon(Icons.center_focus_weak_rounded, color: AppColors.white, size: 48)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(child: Text('Analyzing Your Form', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 30))),
                        const SizedBox(height: 10),
                        Center(child: Text(_subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.75), fontSize: 15))),
                        const SizedBox(height: 28),
                        _StageCard(tint: const Color(0xFFA8B694), icon: Icons.monitor_heart_outlined, title: 'Backend Status', subtitle: _stage1),
                        const SizedBox(height: 16),
                        _StageCard(tint: const Color(0xFF4DA8FF), icon: Icons.center_focus_weak_rounded, title: 'Session Progress', subtitle: _stage2),
                        const SizedBox(height: 16),
                        _StageCard(tint: const Color(0xFFA78BFA), icon: Icons.psychology_alt_outlined, title: 'Feedback Feed', subtitle: _stage3),
                        const Spacer(),
                        const SizedBox(height: 24),
                        Center(child: Text('$_progress%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.white, fontSize: 54))),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: _progress / 100,
                            minHeight: 10,
                            backgroundColor: AppColors.white.withValues(alpha: 0.14),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Backend tip: start the FastAPI server, then use adb reverse tcp:8000 tcp:8000 before running on phone.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.62))),
                        const SizedBox(height: 28),
                        Center(
                          child: OutlinedButton(
                            onPressed: _cancelAnalysis,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.white,
                              side: BorderSide(color: AppColors.white.withValues(alpha: 0.45)),
                              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                            child: const Text('Cancel Analysis'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.size, required this.opacity});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.terracotta.withValues(alpha: opacity), width: 2)));
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.tint, required this.icon, required this.title, required this.subtitle});
  final Color tint;
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.white.withValues(alpha: 0.08))),
      child: Row(
        children: [
          Container(width: 62, height: 62, decoration: BoxDecoration(color: tint, shape: BoxShape.circle), child: Icon(icon, color: AppColors.white, size: 30)),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 18)), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.7), fontSize: 14))])),
          const SizedBox(width: 12),
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, backgroundColor: AppColors.white.withValues(alpha: 0.08), valueColor: AlwaysStoppedAnimation<Color>(AppColors.white.withValues(alpha: 0.72)))),
        ],
      ),
    );
  }
}
