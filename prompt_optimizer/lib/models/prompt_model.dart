class PromptModel {
  final String id;
  final String rawPrompt;
  final String optimizedPrompt;
  final String optimizationType;
  final int tokensUsed;
  final DateTime createdAt;

  const PromptModel({
    required this.id,
    required this.rawPrompt,
    required this.optimizedPrompt,
    required this.optimizationType,
    required this.tokensUsed,
    required this.createdAt,
  });

  factory PromptModel.fromJson(Map<String, dynamic> json) {
    return PromptModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      rawPrompt: json['rawPrompt']?.toString() ?? json['raw_prompt']?.toString() ?? '',
      optimizedPrompt: json['optimizedPrompt']?.toString() ?? json['optimized_prompt']?.toString() ?? '',
      optimizationType: json['optimizationType']?.toString() ?? json['optimization_type']?.toString() ?? 'general',
      tokensUsed: (json['tokensUsed'] ?? json['tokens_used'] ?? 0) as int,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
