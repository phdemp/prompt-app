import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/prompt_model.dart';

class PromptCard extends StatelessWidget {
  final PromptModel prompt;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PromptCard({
    super.key,
    required this.prompt,
    required this.onTap,
    this.onDelete,
  });

  Color _badgeColor(String type) {
    switch (type) {
      case 'coding':
        return const Color(0xFF3B82F6); // blue
      case 'creative':
        return const Color(0xFFEC4899); // pink
      case 'analysis':
        return const Color(0xFFF97316); // orange
      case 'instruction':
        return const Color(0xFF14B8A6); // teal
      default:
        return const Color(0xFF7C3AED); // purple (general)
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(prompt.optimizationType);
    final timeStr = timeago.format(prompt.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      prompt.optimizationType.substring(0, 1).toUpperCase() +
                          prompt.optimizationType.substring(1),
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                prompt.rawPrompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
