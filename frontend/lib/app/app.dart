import 'package:flutter/material.dart';

import '../core/route_names.dart';
import '../core/skeleton_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/upload_screen.dart';
import '../features/analysis/presentation/analysis_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/compare/presentation/compare_screen.dart';
import '../features/gamification/presentation/gamification_screen.dart';
import '../features/heatmap/presentation/heatmap_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/results/presentation/results_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

class ExerciseFormApp extends StatelessWidget {
  const ExerciseFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kinetic AI',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.auth: (_) => const AuthScreen(),
        AppRoutes.upload: (_) => const UploadScreen(),
        AppRoutes.analysis: (_) => const AnalysisScreen(),
        AppRoutes.results: (_) => const ResultsScreen(),
        AppRoutes.progress: (_) => const ProgressScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.skeleton: (_) => const SkeletonScreen(),
        AppRoutes.heatMap: (_) => const HeatMapScreen(),
        AppRoutes.compare: (_) => const CompareScreen(),
        AppRoutes.gamification: (_) => const GamificationScreen(),
      },
    );
  }
}
