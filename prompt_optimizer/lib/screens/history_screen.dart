import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prompt_provider.dart';
import '../widgets/prompt_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromptProvider>().fetchHistory(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PromptProvider>().loadMoreHistory();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<PromptProvider>().fetchHistory(refresh: true);
  }

  Future<void> _confirmDelete(BuildContext context, String id, String preview) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Prompt?',
          style: TextStyle(color: Color(0xFFF1F5F9)),
        ),
        content: Text(
          'Are you sure you want to delete this prompt?\n\n"$preview"',
          style: const TextStyle(color: Color(0xFF94A3B8)),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<PromptProvider>().deletePrompt(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt deleted.'),
            backgroundColor: Color(0xFF334155),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<PromptProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingHistory && provider.prompts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.prompts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.prompts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No optimizations yet',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start optimizing prompts to see them here.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF7C3AED),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.prompts.length + (provider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.prompts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final prompt = provider.prompts[index];
                return Dismissible(
                  key: Key(prompt.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    final preview = prompt.rawPrompt.length > 60
                        ? '${prompt.rawPrompt.substring(0, 60)}...'
                        : prompt.rawPrompt;
                    await _confirmDelete(context, prompt.id, preview);
                    return false; // Let deletePrompt handle the removal
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                  child: PromptCard(
                    prompt: prompt,
                    onTap: () => Navigator.of(context).pushNamed(
                      '/history/detail',
                      arguments: prompt,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
