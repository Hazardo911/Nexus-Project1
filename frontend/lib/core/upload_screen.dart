import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_preferences.dart';
import 'latest_analysis_store.dart';
import 'route_names.dart';
import 'services/nexus_api_service.dart';
import 'theme/app_colors.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  static const List<String> _exerciseOrder = ['Squat', 'Lunge', 'Press', 'Deadlift'];
  static const List<String> _injuryOptions = ['ACL', 'Back', 'Shoulder', 'Knee', 'Ankle'];
  static const List<String> _stageOptions = ['early', 'mid', 'late'];

  static const Map<String, Map<String, Object>> _exerciseMeta = {
    'Squat': {
      'icon': Icons.fitness_center_rounded,
      'tint': AppColors.terracotta,
      'focus': 'Depth, knee path, and balance',
      'tip1': 'Keep knees tracking over toes.',
      'tip2': 'Keep the chest lifted through the descent.',
      'tip3': 'Use a front or side full-body angle.',
    },
    'Lunge': {
      'icon': Icons.directions_run_rounded,
      'tint': AppColors.burntOrange,
      'focus': 'Stride depth and stability',
      'tip1': 'Keep the front knee stacked over the ankle.',
      'tip2': 'Avoid torso collapse during the step.',
      'tip3': 'Capture the full step from the side.',
    },
    'Press': {
      'icon': Icons.sports_gymnastics_rounded,
      'tint': AppColors.gold,
      'focus': 'Bar path and shoulder control',
      'tip1': 'Keep wrists stacked over elbows.',
      'tip2': 'Brace the core before pressing overhead.',
      'tip3': 'Front view works best for symmetry.',
    },
    'Deadlift': {
      'icon': Icons.bolt_rounded,
      'tint': AppColors.ember,
      'focus': 'Hip hinge and spinal alignment',
      'tip1': 'Keep a neutral spine throughout the lift.',
      'tip2': 'Start with the bar close to the legs.',
      'tip3': 'Use a clean side profile for hinge tracking.',
    },
  };

  final ImagePicker _picker = ImagePicker();
  String? _selectedExercise;
  String _analysisMode = 'training';
  String _selectedInjury = 'ACL';
  String _selectedStage = 'early';
  String? _selectedVideoName;
  String? _selectedVideoSource;
  String? _selectedVideoPath;
  bool _startingAnalysis = false;
  String? _activeAction;
  bool _didLoadArgs = false;
  late final AnimationController _rehabFlowController;

  @override
  void initState() {
    super.initState();
    _rehabFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _rehabFlowController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    _didLoadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final mapArgs = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    _selectedExercise = mapArgs['exercise'] as String?;
    final incomingMode = mapArgs['mode']?.toString();
    if (incomingMode == 'rehab') {
      _analysisMode = 'rehab';
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (!mounted || file == null) return;
    await _setSelectedVideo(file.name, 'Phone Gallery', file.path);
  }

  Future<void> _pickFromCamera(ImageSource source, String label) async {
    final file = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 45));
    if (!mounted || file == null) return;
    await _setSelectedVideo(file.name, label, file.path);
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false);
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.single;
    await _setSelectedVideo(file.name, 'File Manager', file.path);
  }

  Future<void> _setSelectedVideo(String name, String source, String? path) async {
    await AppHaptics.mediumImpact();
    setState(() {
      _selectedVideoName = name;
      _selectedVideoSource = source;
      _selectedVideoPath = path;
    });
    _showInfoMessage('$name selected from $source');
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startGoLiveSession() async {
    if (_startingAnalysis) return;
    final selectedExercise = _selectedExercise;
    if (selectedExercise == null) {
      _showInfoMessage('Please select an exercise first.');
      return;
    }

    setState(() {
      _startingAnalysis = true;
      _activeAction = 'live';
    });

    try {
      await NexusApiService.resetSession();
    } catch (_) {}

    try {
      await NexusApiService.startSession(exercise: selectedExercise);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.analysis,
        arguments: {'exercise': selectedExercise},
      );
    } on NexusApiException catch (error) {
      _showInfoMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _startingAnalysis = false;
          _activeAction = null;
        });
      }
    }
  }

  Future<void> _startUploadAnalysis() async {
    if (_startingAnalysis) return;
    final selectedExercise = _selectedExercise;
    if (selectedExercise == null) {
      _showInfoMessage('Please select an exercise first.');
      return;
    }
    if (_selectedVideoPath == null) {
      _showInfoMessage('Please choose a video first.');
      return;
    }

    setState(() {
      _startingAnalysis = true;
      _activeAction = 'upload';
    });

    try {
      final result = await NexusApiService.analyzeUploadedVideo(
        videoPath: _selectedVideoPath!,
        selectedExercise: selectedExercise,
        mode: _analysisMode == 'rehab' ? 'rehab' : 'fitness',
        injury: _selectedInjury,
        stage: _selectedStage,
        includeVisuals: true,
      );
      final cleanedResult = _sanitizeResultForUi(result);
      LatestAnalysisStore.save(cleanedResult);
      LatestAnalysisStore.saveVisual(result);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.results,
        arguments: cleanedResult,
      );
    } on NexusApiException catch (error) {
      _showInfoMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _startingAnalysis = false;
          _activeAction = null;
        });
      }
    }
  }

  Map<String, dynamic> _sanitizeResultForUi(Map<String, dynamic> result) {
    final cleaned = Map<String, dynamic>.from(result);
    cleaned.remove('landmarks');
    cleaned.remove('connections');
    return cleaned;
  }

  Future<void> _showSourceSheet({
    required String title,
    required String subtitle,
    required List<_SourceOptionData> options,
  }) async {
    await AppHaptics.selection();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2430),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 22)),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
                const SizedBox(height: 18),
                ...options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SourceOptionTile(
                      option: option,
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await option.action();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedExercise = _selectedExercise;
    final isRehabMode = _analysisMode == 'rehab';
    final exerciseData = _exerciseMeta[selectedExercise] ?? const <String, Object>{};
    final exerciseIcon = exerciseData['icon'] as IconData? ?? Icons.fitness_center_rounded;
    final exerciseTint = exerciseData['tint'] as Color? ?? AppColors.terracotta;
    final exerciseFocus = exerciseData['focus'] as String? ?? 'Movement validation';
    final tip1 = exerciseData['tip1'] as String? ?? 'Keep the full body in frame.';
    final tip2 = exerciseData['tip2'] as String? ?? 'Use stable lighting and camera position.';
    final tip3 = exerciseData['tip3'] as String? ?? 'Use a side or front angle for clean analysis.';

    return AppShell(
      title: 'Upload',
      showBack: true,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 28),
            children: [
          Text(
            isRehabMode ? 'Recover with safer guidance.' : 'Train with cleaner feedback.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  height: 1.0,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            isRehabMode
                ? 'Pick the rehab exercise, set injury stage, then let the backend check if the movement is safe for recovery.'
                : 'Select the exercise, add a clip or go live, then let the backend validate movement quality.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72), fontSize: 15),
          ),
          const SizedBox(height: 22),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            color: isRehabMode ? const Color(0xFF1A3233) : const Color(0xFF202A36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Mode', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 18)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ModeChip(
                        label: 'Training',
                        subtitle: 'Form and performance',
                        isSelected: !isRehabMode,
                        tint: AppColors.terracotta,
                        onTap: () => setState(() => _analysisMode = 'training'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeChip(
                        label: 'Rehab',
                        subtitle: 'Safety and recovery',
                        isSelected: isRehabMode,
                        tint: AppColors.sageGreen,
                        onTap: () => setState(() => _analysisMode = 'rehab'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isRehabMode) ...[
            const SizedBox(height: 18),
            _RehabFlowCard(
              controller: _rehabFlowController,
              stage: _selectedStage,
              injury: _selectedInjury,
            ),
          ],
          const SizedBox(height: 18),
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            color: isRehabMode ? const Color(0xFF193033) : const Color(0xFF1E2834),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Exercise', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 20)),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exerciseOrder.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemBuilder: (context, index) {
                    final exercise = _exerciseOrder[index];
                    final meta = _exerciseMeta[exercise]!;
                    final tint = meta['tint']! as Color;
                    final isSelected = exercise == selectedExercise;
                    return _ExercisePickerTile(
                      label: exercise,
                      icon: meta['icon']! as IconData,
                      tint: tint,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedExercise = exercise),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [exerciseTint.withValues(alpha: 0.18), const Color(0xFF27384E)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: exerciseTint.withValues(alpha: 0.24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(color: exerciseTint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
                        child: Icon(exerciseIcon, color: exerciseTint),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedExercise ?? 'Nothing selected yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedExercise == null ? 'Pick a movement to unlock the right validation flow.' : exerciseFocus,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.72)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isRehabMode) ...[
            const SizedBox(height: 18),
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              color: const Color(0xFF1A3233),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rehab Setup', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 18)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownCard<String>(
                          label: 'Injury',
                          value: _selectedInjury,
                          items: _injuryOptions,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedInjury = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownCard<String>(
                          label: 'Stage',
                          value: _selectedStage,
                          items: _stageOptions,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStage = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rehab mode checks whether this exercise is safe for your injury and current recovery stage.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRehabMode
                    ? [
                        const Color(0xFF163437),
                        const Color(0xFF1B3D46),
                        AppColors.sageGreen.withValues(alpha: 0.22),
                      ]
                    : [
                        const Color(0xFF243247),
                        const Color(0xFF1A2430),
                        exerciseTint.withValues(alpha: 0.28),
                      ],
              ),
              border: Border.all(
                color: isRehabMode
                    ? AppColors.sageGreen.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _selectedVideoPath != null && File(_selectedVideoPath!).existsSync()
                          ? const Icon(Icons.play_circle_fill_rounded, color: AppColors.white, size: 30)
                          : Icon(Icons.movie_creation_outlined, color: exerciseTint, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedVideoName ?? 'No video selected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedVideoSource ?? 'Use gallery, files, or camera to add your clip.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.68)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _showSourceSheet(
                      title: 'Choose Video Source',
                      subtitle: 'Import a clip for uploaded movement analysis.',
                      options: [
                        _SourceOptionData(label: 'Phone Gallery', subtitle: 'Open saved workout clips', icon: Icons.photo_library_outlined, tint: AppColors.terracotta, action: _pickFromGallery),
                        _SourceOptionData(label: 'File Manager', subtitle: 'Browse downloads and storage', icon: Icons.folder_open_rounded, tint: AppColors.burntOrange, action: _pickFromFiles),
                        _SourceOptionData(label: 'Rear Camera', subtitle: 'Record a new clip now', icon: Icons.videocam_outlined, tint: AppColors.sageGreen, action: () => _pickFromCamera(ImageSource.camera, 'Rear Camera')),
                      ],
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isRehabMode ? AppColors.sageGreen : AppColors.terracotta,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(_selectedVideoName == null ? 'Choose Video' : 'Replace Video'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppPreferences.darkCameraPreview.value
                      ? 'Dark preview is enabled for capture guidance.'
                      : 'Best result: full body visible, stable framing, no harsh crop.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: [
              _ActionCard(
                title: 'Analyze Upload',
                subtitle: isRehabMode ? 'Check rehab safety' : 'Run selected clip',
                icon: Icons.analytics_rounded,
                tint: AppColors.terracotta,
                isActive: _activeAction == 'upload',
                onTap: _startingAnalysis ? null : _startUploadAnalysis,
              ),
              _ActionCard(
                title: 'Go Live',
                subtitle: 'Real-time form tracking',
                icon: Icons.videocam_rounded,
                tint: AppColors.sageGreen,
                isActive: _activeAction == 'live',
                onTap: _startingAnalysis ? null : _startGoLiveSession,
              ),
              _ActionCard(
                title: 'Skeleton View',
                subtitle: 'Replay latest pose',
                icon: Icons.accessibility_new_rounded,
                tint: AppColors.gold,
                isActive: false,
                onTap: () => Navigator.pushNamed(context, AppRoutes.skeleton),
              ),
              _ActionCard(
                title: 'Progress Trends',
                subtitle: 'Track over time',
                icon: Icons.trending_up_rounded,
                tint: AppColors.burntOrange,
                isActive: false,
                onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            color: isRehabMode ? const Color(0xFF1A3233) : const Color(0xFF202A36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedExercise == null ? 'Recording Tips' : '$selectedExercise Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 18),
                ),
                const SizedBox(height: 12),
                _InfoLine(text: tip1),
                const SizedBox(height: 8),
                _InfoLine(text: tip2),
                const SizedBox(height: 8),
                _InfoLine(text: tip3),
              ],
            ),
          ),
            ],
          ),
          if (_startingAnalysis)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.38),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2834),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _activeAction == 'upload' ? 'Analyzing upload...' : 'Connecting...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while the backend processes your movement.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RehabFlowCard extends StatelessWidget {
  const _RehabFlowCard({
    required this.controller,
    required this.stage,
    required this.injury,
  });

  final AnimationController controller;
  final String stage;
  final String injury;

  @override
  Widget build(BuildContext context) {
    final stageLabel = switch (stage) {
      'early' => 'Restore calm, controlled motion',
      'mid' => 'Rebuild balance and confidence',
      'late' => 'Progress toward stronger movement',
      _ => 'Move safely and consistently',
    };

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment(-1 + (math.sin(t * math.pi * 2) * 0.18), -1),
              end: Alignment(1 - (math.cos(t * math.pi * 2) * 0.16), 1),
              colors: const [
                Color(0xFF173A36),
                Color(0xFF1A3F4D),
                Color(0xFF25324A),
              ],
            ),
            border: Border.all(color: AppColors.sageGreen.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.sageGreen.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.sageGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recovery Mode',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                                fontSize: 18,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$injury recovery stage',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.66),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                stageLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontSize: 24,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HealingStat(
                      label: 'Injury',
                      value: injury,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HealingStat(
                      label: 'Stage',
                      value: stage.toUpperCase(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HealingStat extends StatelessWidget {
  const _HealingStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.62),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePickerTile extends StatelessWidget {
  const _ExercisePickerTile({
    required this.label,
    required this.icon,
    required this.tint,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isSelected ? tint.withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: isSelected ? tint : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.softCharcoal : tint, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected ? AppColors.softCharcoal : AppColors.white,
                          fontSize: 16,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isSelected ? tint.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: isSelected ? tint.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isSelected ? tint : AppColors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  const _DropdownCard({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
          DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF243040),
            underline: const SizedBox.shrink(),
            iconEnabledColor: AppColors.white,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.tint, required this.onTap, required this.isActive});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? tint.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isActive ? tint.withValues(alpha: 0.34) : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.74)),
          ),
        ),
      ],
    );
  }
}

class _SourceOptionData {
  const _SourceOptionData({required this.label, required this.subtitle, required this.icon, required this.tint, required this.action});

  final String label;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Future<void> Function() action;
}

class _SourceOptionTile extends StatelessWidget {
  const _SourceOptionTile({required this.option, required this.onTap});

  final _SourceOptionData option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF243040),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: option.tint.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
              child: Icon(option.icon, color: option.tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(option.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.66))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
