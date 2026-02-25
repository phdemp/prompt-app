import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/usage_stats.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  UsageStats? _stats;
  bool _isLoading = false;
  String? _error;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(StorageService());
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await _apiService.getUsageStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Usage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _stats == null
                  ? const Center(child: Text('No data available.'))
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchStats, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final stats = _stats!;
    final fraction = stats.maxPerDay > 0 ? stats.usedToday / stats.maxPerDay : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Circular usage indicator
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: fraction.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF334155),
                  progressColor: fraction > 0.8
                      ? Colors.orangeAccent
                      : const Color(0xFF7C3AED),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.usedToday}',
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'of ${stats.maxPerDay}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'used today',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Stat cards
          _StatCard(
            icon: Icons.check_circle_outline,
            label: 'Used Today',
            value: '${stats.usedToday}',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.bolt,
            label: 'Remaining Today',
            value: '${stats.remainingToday}',
            color: stats.remainingToday > 0
                ? const Color(0xFF10B981)
                : Colors.orangeAccent,
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.calendar_today,
            label: 'Daily Limit',
            value: '${stats.maxPerDay}',
            color: const Color(0xFF3B82F6),
          ),
          if (stats.resetsAt.isNotEmpty) ...[
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.schedule,
              label: 'Resets At',
              value: stats.resetsAt,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 12.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress ||
      old.backgroundColor != backgroundColor ||
      old.progressColor != progressColor;
}
