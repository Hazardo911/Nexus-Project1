import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_preferences.dart';
import 'route_names.dart';
import 'services/nexus_api_service.dart';
import 'theme/app_colors.dart';
import '../shared/widgets/widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  static const Map<String, Map<String, Object>> _exerciseMeta = {
    'Squat': {'icon': Icons.fitness_center_rounded, 'tint': AppColors.terracotta, 'focus': 'Glutes + Quads', 'tip1': 'Keep knees tracking over toes', 'tip2': 'Keep chest lifted through the descent', 'tip3': 'Capture a side or front full-body view'},
    'Lunge': {'icon': Icons.directions_run_rounded, 'tint': AppColors.burntOrange, 'focus': 'Balance + Legs', 'tip1': 'Keep front knee stacked over ankle', 'tip2': 'Avoid torso collapse during the step', 'tip3': 'Film from the side to track stride depth'},
    'Press': {'icon': Icons.sports_gymnastics_rounded, 'tint': AppColors.gold, 'focus': 'Shoulders + Core', 'tip1': 'Keep wrists stacked over elbows', 'tip2': 'Brace your core before pressing overhead', 'tip3': 'Use a front view to track bar path symmetry'},
    'Deadlift': {'icon': Icons.bolt_rounded, 'tint': AppColors.ember, 'focus': 'Hips + Back', 'tip1': 'Keep a neutral spine throughout the lift', 'tip2': 'Start with bar close to the legs', 'tip3': 'Use a side view to check hip hinge mechanics'},
  };

  final ImagePicker _picker = ImagePicker();
  String? _selectedVideoName;
  String? _selectedVideoSource;
  String? _selectedVideoPath;
  bool _startingAnalysis = false;

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

  Future<void> _showInfoPlaceholder(String message) async {
    await AppHaptics.selection();
    if (!mounted) return;
    _showInfoMessage(message);
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startBackendSession(String? selectedExercise) async {
    if (_startingAnalysis) return;
    setState(() => _startingAnalysis = true);
    try {
      await NexusApiService.resetSession();
    } catch (_) {}

    try {
      if (selectedExercise == 'Deadlift' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deadlift is not directly mapped in the backend yet, so the backend camera window will open in manual selection mode.')),
        );
      }
      await NexusApiService.startSession(exercise: selectedExercise);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.analysis,
        arguments: {'exercise': selectedExercise},
      );
    } on NexusApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _startingAnalysis = false);
      }
    }
  }

  Future<void> _showSourceSheet({required String title, required String subtitle, required List<_SourceOptionData> options}) async {
    await AppHaptics.selection();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2430),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 14))],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 52, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)))),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24, color: AppColors.white)),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.68))),
                const SizedBox(height: 22),
                ...options.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SourceOptionTile(
                        option: option,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await option.action();
                        },
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final mapArgs = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    final selectedExercise = mapArgs['exercise'] as String?;
    final exerciseData = _exerciseMeta[selectedExercise] ?? const <String, Object>{};
    final exerciseIcon = exerciseData['icon'] as IconData? ?? Icons.file_upload_outlined;
    final exerciseTint = exerciseData['tint'] as Color? ?? AppColors.terracotta;
    final exerciseFocus = exerciseData['focus'] as String? ?? 'General Movement';
    final uploadTitle = selectedExercise == null ? 'Upload Workout' : 'Upload $selectedExercise Video';
    final uploadSubtitle = selectedExercise == null ? 'Record live or upload a saved video for AI analysis' : 'Selected exercise: $selectedExercise • Focus on $exerciseFocus';
    final tip1 = exerciseData['tip1'] as String? ?? 'Position camera to show full body';
    final tip2 = exerciseData['tip2'] as String? ?? 'Ensure good lighting and clear background';
    final tip3 = exerciseData['tip3'] as String? ?? 'Film from side or front angle';

    return AppShell(
      title: 'Upload',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 28),
        children: [
          Text(uploadTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white)),
          const SizedBox(height: 10),
          Text(uploadSubtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72), fontSize: 15)),
          if (selectedExercise != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: exerciseTint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(22), border: Border.all(color: exerciseTint.withValues(alpha: 0.16))),
              child: Row(
                children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: exerciseTint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)), child: Icon(exerciseIcon, color: exerciseTint)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(selectedExercise, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white)), const SizedBox(height: 4), Text(exerciseFocus, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.7)))])),
                  TextButton(onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home), child: Text('Change', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: exerciseTint))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.darkCameraPreview,
            builder: (context, darkPreview, _) {
              return InkWell(
                borderRadius: BorderRadius.circular(34),
                onTap: () => _showSourceSheet(
                  title: 'Choose Video Source',
                  subtitle: 'Pick where you want to upload the workout video from.',
                  options: [
                    _SourceOptionData(label: 'Gallery', subtitle: 'Select a video from your phone gallery', icon: Icons.photo_library_outlined, tint: AppColors.terracotta, action: _pickFromGallery),
                    _SourceOptionData(label: 'Files', subtitle: 'Browse local folders and downloads', icon: Icons.folder_open_rounded, tint: AppColors.burntOrange, action: _pickFromFiles),
                    _SourceOptionData(label: 'Rear Camera', subtitle: 'Capture a new workout clip now', icon: Icons.videocam_outlined, tint: AppColors.sageGreen, action: () => _pickFromCamera(ImageSource.camera, 'Rear Camera')),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF262F3B), const Color(0xFF303B49), exerciseTint.withValues(alpha: 0.42)]),
                    border: Border.all(color: exerciseTint.withValues(alpha: 0.32), width: 1.8),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.12,
                    child: Stack(
                      children: [
                        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.02), Colors.black.withValues(alpha: 0.16)])))),
                        const Positioned(top: 22, left: 22, child: _PreviewCorner(alignment: Alignment.topLeft)),
                        const Positioned(top: 22, right: 22, child: _PreviewCorner(alignment: Alignment.topRight)),
                        const Positioned(bottom: 22, left: 22, child: _PreviewCorner(alignment: Alignment.bottomLeft)),
                        const Positioned(bottom: 22, right: 22, child: _PreviewCorner(alignment: Alignment.bottomRight)),
                        Positioned(left: 20, right: 20, top: 112, child: Container(height: 3, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: LinearGradient(colors: [Colors.transparent, exerciseTint.withValues(alpha: 0.1), exerciseTint.withValues(alpha: 0.75), exerciseTint.withValues(alpha: 0.1), Colors.transparent])))),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.08)),
                              child: _selectedVideoPath != null && File(_selectedVideoPath!).existsSync()
                                  ? ClipOval(child: Container(color: exerciseTint.withValues(alpha: 0.32), child: const Icon(Icons.play_arrow_rounded, size: 52, color: AppColors.white)))
                                  : Icon(exerciseIcon, size: 50, color: AppColors.white),
                            ),
                            const SizedBox(height: 28),
                            Text(_selectedVideoName == null ? (selectedExercise == null ? 'Choose Video Source' : 'Upload $selectedExercise Clip') : _selectedVideoName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(_selectedVideoSource ?? (darkPreview ? 'Dark preview mode is on for cleaner recording focus' : (selectedExercise == null ? 'Select from library or capture new' : 'Best results come from a clear full-body ${selectedExercise.toLowerCase()} view')), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.74)), textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          AnimatedCtaButton(
            label: 'Choose from Library',
            icon: Icons.videocam_outlined,
            height: 94,
            onPressed: () => _showSourceSheet(
              title: 'Upload From',
              subtitle: 'Choose how you want to import your workout video.',
              options: [
                _SourceOptionData(label: 'Phone Gallery', subtitle: 'Open photos and videos on this device', icon: Icons.photo_library_outlined, tint: AppColors.terracotta, action: _pickFromGallery),
                _SourceOptionData(label: 'File Manager', subtitle: 'Browse folders, downloads, and storage', icon: Icons.folder_open_rounded, tint: AppColors.burntOrange, action: _pickFromFiles),
                _SourceOptionData(label: 'Cloud Import', subtitle: 'Frontend placeholder for future Drive integration', icon: Icons.cloud_outlined, tint: AppColors.sageGreen, action: () => _showInfoPlaceholder('Cloud import UI placeholder added.')), 
              ],
            ),
            colors: AppColors.heroGradient,
          ),
          const SizedBox(height: 18),
          _SecondaryActionButton(
            label: 'Record Live',
            icon: Icons.photo_camera_outlined,
            onTap: () => _showSourceSheet(
              title: 'Record Live',
              subtitle: AppPreferences.darkCameraPreview.value ? 'Dark preview overlay is enabled for capture guidance.' : 'Choose a capture mode before starting recording.',
              options: [
                _SourceOptionData(label: 'Rear Camera', subtitle: 'Best for tripod full-body workout capture', icon: Icons.videocam_outlined, tint: AppColors.terracotta, action: () => _pickFromCamera(ImageSource.camera, 'Rear Camera')),
                _SourceOptionData(label: 'Front Camera', subtitle: 'Use selfie mode for quick preview capture', icon: Icons.cameraswitch_outlined, tint: AppColors.burntOrange, action: () => _pickFromCamera(ImageSource.camera, 'Front Camera')),
                _SourceOptionData(label: 'Guided Capture', subtitle: 'Show setup instructions before recording', icon: Icons.center_focus_strong_rounded, tint: AppColors.sageGreen, action: () => _showInfoPlaceholder('Guided capture setup shown.')), 
              ],
            ),
          ),
          if (_selectedVideoName != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _startingAnalysis ? null : () => _startBackendSession(selectedExercise),
              style: FilledButton.styleFrom(backgroundColor: AppColors.sageGreen, foregroundColor: AppColors.softCharcoal, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: Text(_startingAnalysis ? 'Connecting Backend...' : 'Start Analysis'),
            ),
          ],
          const SizedBox(height: 28),
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            color: const Color(0xFF202A36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Icon(Icons.lightbulb_rounded, color: AppColors.gold, size: 22), const SizedBox(width: 10), Text(selectedExercise == null ? 'Recording Tips' : '$selectedExercise Tips', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white))]),
                const SizedBox(height: 18),
                _TipLine(text: tip1),
                const SizedBox(height: 14),
                _TipLine(text: tip2),
                const SizedBox(height: 14),
                _TipLine(text: AppPreferences.darkCameraPreview.value ? '$tip3 • Dark preview overlay enabled' : tip3),
              ],
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(color: const Color(0xFF243040), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.06)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 10))]),
        child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: option.tint.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)), child: Icon(option.icon, color: option.tint)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(option.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, color: AppColors.white)), const SizedBox(height: 4), Text(option.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.66)))])), Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withValues(alpha: 0.3))]),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 94,
        decoration: BoxDecoration(color: const Color(0xFFEAF1FA), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: 0.68)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppColors.terracotta, size: 30), const SizedBox(width: 14), Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: AppColors.terracotta, fontWeight: FontWeight.w700))]),
      ),
    );
  }
}

class _PreviewCorner extends StatelessWidget {
  const _PreviewCorner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: AppColors.sageGreen.withValues(alpha: 0.82), width: 2.6) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: AppColors.sageGreen.withValues(alpha: 0.82), width: 2.6) : BorderSide.none,
            left: isLeft ? BorderSide(color: AppColors.sageGreen.withValues(alpha: 0.82), width: 2.6) : BorderSide.none,
            right: !isLeft ? BorderSide(color: AppColors.sageGreen.withValues(alpha: 0.82), width: 2.6) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft ? const Radius.circular(8) : Radius.zero,
            topRight: alignment == Alignment.topRight ? const Radius.circular(8) : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft ? const Radius.circular(8) : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.terracotta, fontWeight: FontWeight.w800)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withValues(alpha: 0.72)))),
      ],
    );
  }
}









