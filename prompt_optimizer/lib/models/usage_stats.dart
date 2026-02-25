class UsageStats {
  final int usedToday;
  final int remainingToday;
  final int maxPerDay;
  final String resetsAt;

  const UsageStats({
    required this.usedToday,
    required this.remainingToday,
    required this.maxPerDay,
    required this.resetsAt,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      usedToday: (json['usedToday'] ?? json['used_today'] ?? 0) as int,
      remainingToday: (json['remainingToday'] ?? json['remaining_today'] ?? 0) as int,
      maxPerDay: (json['maxPerDay'] ?? json['max_per_day'] ?? 10) as int,
      resetsAt: json['resetsAt']?.toString() ?? json['resets_at']?.toString() ?? '',
    );
  }
}
