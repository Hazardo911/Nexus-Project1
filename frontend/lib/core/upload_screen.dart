import 'dart:io';

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

class _UploadScreenState extends State<UploadScreen> {
  static const List<String> _exerciseOrder = ['Squat', 'Lunge', 'Press', 'Deadlift'];

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
  String? _selectedVideoName;
  String? _selectedVideoSource;
  String? _selectedVideoPath;
  bool _startingAnalysis = false;
  String? _activeAction;
  bool _didLoadArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    _didLoadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final mapArgs = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    _selectedExercise = mapArgs['exercise'] as String?;
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

  Future<void> _captureLiveFrame() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted || image == null) return;

    setState(() {
      _startingAnalysis = true;
      _activeAction = 'live';
    });

    try {
      final result = await NexusApiService.analyzeLiveFrame(
        imagePath: image.path,
        selectedExercise: _selectedExercise!,
      );
      final cleanedResult = _sanitizeResultForUi(result);
      LatestAnalysisStore.save(cleanedResult);
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

  Future<void> _startBackendSession({required bool liveMode}) async {
    if (_startingAnalysis) return;
    final selectedExercise = _selectedExercise;
    if (selectedExercise == null || selectedExercise.isEmpty) {
      _showInfoMessage('Select an exercise first.');
      return;
    }
    if (liveMode) {
      await _captureLiveFrame();
      return;
    }
    if (_selectedVideoName == null || _selectedVideoPath == null) {
      _showInfoMessage('Choose a video before starting uploaded analysis.');
      return;
    }

    setState(() {
      _startingAnalysis = true;
      _activeAction = liveMode ? 'live' : 'upload';
    });
    try {
      final result = await NexusApiService.analyzeUploadedVideo(
        videoPath: _selectedVideoPath!,
        selectedExercise: selectedExercise,
      );
      final cleanedResult = _sanitizeResultForUi(result);
      LatestAnalysisStore.save(cleanedResult);
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
            'Train with cleaner feedback.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  height: 1.0,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select the exercise, add a clip or go live, then let the backend validate movement quality.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72), fontSize: 15),
          ),
          const SizedBox(height: 22),
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            color: const Color(0xFF1E2834),
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
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF243247), const Color(0xFF1A2430), exerciseTint.withValues(alpha: 0.28)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      backgroundColor: AppColors.terracotta,
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
                subtitle: 'Run selected clip',
                icon: Icons.analytics_rounded,
                tint: AppColors.terracotta,
                isActive: _activeAction == 'upload',
                onTap: _startingAnalysis ? null : () => _startBackendSession(liveMode: false),
              ),
              _ActionCard(
                title: 'Go Live',
                subtitle: 'Use webcam flow',
                icon: Icons.videocam_rounded,
                tint: AppColors.sageGreen,
                isActive: _activeAction == 'live',
                onTap: _startingAnalysis ? null : () => _startBackendSession(liveMode: true),
              ),
              _ActionCard(
                title: 'Skeleton View',
                subtitle: 'Preview overlay',
                icon: Icons.accessibility_new_rounded,
                tint: AppColors.gold,
                isActive: false,
                onTap: () => Navigator.pushNamed(context, AppRoutes.skeleton),
              ),
              _ActionCard(
                title: 'Recovery Analytics',
                subtitle: 'Track rehab',
                icon: Icons.monitor_heart_outlined,
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
            color: const Color(0xFF202A36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What You Get Back', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 18)),
                const SizedBox(height: 12),
                const _InfoLine(text: 'Form status and error categories'),
                const SizedBox(height: 8),
                const _InfoLine(text: 'Model agreement and confidence signal'),
                const SizedBox(height: 8),
                const _InfoLine(text: 'Top-k exercise suggestions'),
                const SizedBox(height: 8),
                const _InfoLine(text: 'Weekly and monthly rehab summaries'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            color: const Color(0xFF202A36),
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
