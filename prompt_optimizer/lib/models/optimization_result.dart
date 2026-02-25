class OptimizationResult {
  final String promptId;
  final String optimizedPrompt;
  final String optimizationType;
  final int tokensUsed;
  final int remainingRequests;

  const OptimizationResult({
    required this.promptId,
    required this.optimizedPrompt,
    required this.optimizationType,
    required this.tokensUsed,
    required this.remainingRequests,
  });

  factory OptimizationResult.fromJson(Map<String, dynamic> json) {
    return OptimizationResult(
      promptId: json['promptId']?.toString() ?? json['prompt_id']?.toString() ?? json['id']?.toString() ?? '',
      optimizedPrompt: json['optimizedPrompt']?.toString() ?? json['optimized_prompt']?.toString() ?? '',
      optimizationType: json['optimizationType']?.toString() ?? json['optimization_type']?.toString() ?? 'general',
      tokensUsed: (json['tokensUsed'] ?? json['tokens_used'] ?? 0) as int,
      remainingRequests: (json['remainingRequests'] ?? json['remaining_requests'] ?? 0) as int,
    );
  }
}
