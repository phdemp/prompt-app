import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/optimization_result.dart';
import '../models/usage_stats.dart';
import '../providers/auth_provider.dart';
import '../providers/prompt_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/optimization_type_selector.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  String _selectedType = 'general';
  bool _isOptimizing = false;
  UsageStats? _usageStats;
  bool _loadingStats = false;

  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(StorageService());
    _fetchUsageStats();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsageStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _apiService.getUsageStats();
      if (mounted) setState(() => _usageStats = stats);
    } catch (_) {}
    if (mounted) setState(() => _loadingStats = false);
  }

  Future<void> _optimize() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isOptimizing = true);

    try {
      final result = await _apiService.optimizePrompt(
        _promptController.text.trim(),
        _selectedType,
      );

      if (!mounted) return;

      // Navigate to result screen
      await Navigator.of(context).pushNamed(
        '/result',
        arguments: {
          'result': result,
          'rawPrompt': _promptController.text.trim(),
        },
      );

      // Refresh stats after returning
      _fetchUsageStats();
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.code == 'unauthorized') {
        context.read<AuthProvider>().logout();
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      if (e.code == 'rate_limited') {
        _showRateLimitDialog();
        return;
      }

      ErrorDialog.show(
        context,
        title: 'Optimization Failed',
        message: e.message,
        onRetry: _optimize,
      );
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        title: 'Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  void _showRateLimitDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Color(0xFFF97316)),
            SizedBox(width: 8),
            Text(
              'Daily Limit Reached',
              style: TextStyle(color: Color(0xFFF1F5F9)),
            ),
          ],
        ),
        content: Text(
          _usageStats != null
              ? 'You have used ${_usageStats!.usedToday} of ${_usageStats!.maxPerDay} daily optimizations. Your quota resets at ${_usageStats!.resetsAt}.'
              : 'You have reached your daily limit. Please try again tomorrow.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final promptText = _promptController.text;
    final isValid = promptText.trim().length >= 10;

    return LoadingOverlay(
      isLoading: _isOptimizing,
      message: 'Optimizing your prompt...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Optimize Prompt'),
          actions: [
            if (user?.picture.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(user!.picture),
                  backgroundColor: const Color(0xFF334155),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF334155),
                  child: Icon(Icons.person, size: 20, color: Colors.white),
                ),
              ),
          ],
        ),
        drawer: _buildDrawer(context, auth),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prompt input
                const Text(
                  'Your Prompt',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _promptController,
                  minLines: 3,
                  maxLines: 10,
                  maxLength: 2000,
                  validator: validatePrompt,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Color(0xFFF1F5F9)),
                  decoration: const InputDecoration(
                    hintText: 'Enter your prompt here (min. 10 characters)...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                // Type selector
                const Text(
                  'Optimization Type',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                OptimizationTypeSelector(
                  selected: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(height: 24),
                // Optimize button
                CustomButton(
                  label: 'Optimize',
                  onPressed: isValid && !_isOptimizing ? _optimize : null,
                  isLoading: _isOptimizing,
                ),
                const SizedBox(height: 20),
                // Usage stats card
                _buildUsageCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    if (_loadingStats) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_usageStats == null) return const SizedBox.shrink();

    final remaining = _usageStats!.remainingToday;
    final total = _usageStats!.maxPerDay;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFF7C3AED), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$remaining of $total optimizations remaining today',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: remaining / total,
                    backgroundColor: const Color(0xFF334155),
                    color: remaining > total * 0.3
                        ? const Color(0xFF7C3AED)
                        : Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.picture.isNotEmpty == true
                  ? NetworkImage(user!.picture)
                  : null,
              backgroundColor: const Color(0xFF334155),
              child: user?.picture.isEmpty != false
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            accountName: Text(
              user?.displayName ?? 'User',
              style: const TextStyle(color: Color(0xFFF1F5F9)),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF94A3B8)),
            title: const Text('Home', style: TextStyle(color: Color(0xFFF1F5F9))),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF94A3B8)),
            title: const Text('History', style: TextStyle(color: Color(0xFFF1F5F9))),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Color(0xFF94A3B8)),
            title: const Text('Usage Stats', style: TextStyle(color: Color(0xFFF1F5F9))),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/usage');
            },
          ),
          const Spacer(),
          const Divider(color: Color(0xFF334155)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
