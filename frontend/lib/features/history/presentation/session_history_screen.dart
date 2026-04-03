import 'package:flutter/material.dart';

import '../../../core/route_names.dart';
import '../../../core/services/nexus_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  List<Map<String, dynamic>> _sessions = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final response = await NexusApiService.getSessions();
      final raw = response['sessions'];
      final sessions = raw is List
          ? raw
              .map<Map<String, dynamic>?>((item) {
                if (item is Map<String, dynamic>) return item;
                if (item is Map) {
                  return item.map((key, dynamic value) => MapEntry(key.toString(), value));
                }
                return null;
              })
              .whereType<Map<String, dynamic>>()
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
        _error = null;
      });
    } on NexusApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _sessions.isNotEmpty ? _sessions.first : null;
    final previous = _sessions.length > 1 ? _sessions[1] : null;
    final comparisons = _buildComparisons(latest, previous);

    return AppShell(
      title: 'History',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 28),
        children: [
          Text(
            'Session History',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 30,
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review recent sessions and see if your movement is trending in the right direction.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _InfoCard(message: 'Loading session history...')
          else if (_error != null)
            _InfoCard(message: _error!)
          else if (_sessions.isEmpty)
            const _InfoCard(message: 'No sessions found yet. Run one workout first and your history will appear here.')
          else ...[
            GlassCard(
              radius: 28,
              padding: const EdgeInsets.all(20),
              color: Colors.white.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before vs Last Time',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (comparisons.isEmpty)
                    Text(
                      'One session logged so far. Do one more session to unlock progress comparison.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.68),
                          ),
                    )
                  else
                    ...comparisons.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ComparisonRow(item: item),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: 14),
            ..._sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionTile(session: session),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.results, arguments: _sessions.first),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Open Latest Session'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonItem {
  const _ComparisonItem({
    required this.label,
    required this.message,
    required this.tint,
  });

  final String label;
  final String message;
  final Color tint;
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.item});

  final _ComparisonItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: item.tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: item.tint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.74)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final exercise = session['selected_exercise']?.toString() ?? session['exercise']?.toString() ?? 'Workout';
    final isRehab = ((session['mode']?.toString() ?? '').toLowerCase() == 'rehab') ||
        (session['injury']?.toString() != 'None' && session['injury'] != null);
    final mode = isRehab ? 'Rehab' : 'Training';
    final status = session['form_status']?.toString() ?? session['status']?.toString() ?? 'captured';
    final score = _toDouble(session['score'])?.round();
    final timestamp = session['timestamp']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.pushNamed(context, AppRoutes.results, arguments: session),
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        color: Colors.white.withValues(alpha: 0.08),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.insights_rounded, color: _statusColor(status)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$mode | ${_friendlyStatus(status)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.68)),
                  ),
                  if (timestamp.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timestamp,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.52)),
                    ),
                  ],
                ],
              ),
            ),
            if (score != null)
              Text(
                '$score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontSize: 22,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      color: AppColors.white.withValues(alpha: 0.9),
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

List<_ComparisonItem> _buildComparisons(Map<String, dynamic>? latest, Map<String, dynamic>? previous) {
  if (latest == null || previous == null) return const [];
  final items = <_ComparisonItem>[];

  void compare(String label, String key, {bool higherIsBetter = true, bool percent = false, String suffix = ''}) {
    final a = _toDouble(latest[key]);
    final b = _toDouble(previous[key]);
    if (a == null || b == null) return;
    final delta = a - b;
    if (delta.abs() < 0.001) return;

    final improved = higherIsBetter ? delta > 0 : delta < 0;
    final tint = improved ? AppColors.sageGreen : AppColors.burntOrange;
    final amount = percent
        ? '${((delta.abs() <= 1 ? delta.abs() * 100 : delta.abs())).toStringAsFixed(1)}%'
        : suffix.isNotEmpty
            ? '${delta.abs().toStringAsFixed(1)} $suffix'
            : delta.abs().toStringAsFixed(2);
    final direction = improved ? 'improved' : 'dropped';

    items.add(
      _ComparisonItem(
        label: label,
        message: '$direction by $amount compared with your previous session.',
        tint: tint,
      ),
    );
  }

  compare('Stability', 'stability', percent: true);
  compare('Symmetry', 'symmetry_score', percent: true);
  compare('Back Angle', 'back_angle', higherIsBetter: false, suffix: 'deg');
  compare('Knee Angle', 'avg_knee_angle', suffix: 'deg');

  return items.take(4).toList();
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'correct':
    case 'safe':
      return AppColors.sageGreen;
    case 'incorrect':
    case 'unsafe':
    case 'danger':
      return AppColors.burntOrange;
    default:
      return AppColors.gold;
  }
}

String _friendlyStatus(String status) {
  switch (status.toLowerCase()) {
    case 'correct':
      return 'Good form';
    case 'incorrect':
      return 'Needs work';
    case 'safe':
      return 'Safe';
    case 'warning':
      return 'Watch form';
    default:
      return status;
  }
}
