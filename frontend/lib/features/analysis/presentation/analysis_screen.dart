import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/theme/app_colors.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final mapArgs = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    final selectedExercise = mapArgs['exercise']?.toString();

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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_alt_rounded, color: AppColors.terracotta, size: 44),
                    const SizedBox(height: 18),
                    Text(
                      selectedExercise == null ? 'Backend Flow Updated' : '$selectedExercise Flow Updated',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.white, fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Uploaded-video analysis is now connected directly to the new backend. Use the upload screen to send the clip and open results.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.74)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.upload, arguments: mapArgs),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Back To Upload'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
