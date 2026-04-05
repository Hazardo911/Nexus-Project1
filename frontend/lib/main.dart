import 'package:flutter/material.dart';
import 'package:exercise_form_frontend/core/app_preferences.dart';
import 'package:exercise_form_frontend/core/latest_analysis_store.dart';
import 'package:exercise_form_frontend/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AppPreferences.init();
  LatestAnalysisStore.load();
  
  runApp(const ExerciseFormApp());
}
