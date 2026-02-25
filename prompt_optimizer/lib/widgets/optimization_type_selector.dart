import 'package:flutter/material.dart';
import '../utils/constants.dart';

class OptimizationTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const OptimizationTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kOptimizationTypes.map((type) {
        final isSelected = type['value'] == selected;
        return FilterChip(
          label: Text(type['label']!),
          selected: isSelected,
          onSelected: (_) => onChanged(type['value']!),
          backgroundColor: const Color(0xFF1E293B),
          selectedColor: const Color(0xFF7C3AED).withOpacity(0.3),
          checkmarkColor: const Color(0xFF7C3AED),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF334155),
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
