class RandomCategory {
  const RandomCategory({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;

  factory RandomCategory.fromJson(Map<String, dynamic> json) {
    return RandomCategory(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class RandomEvent {
  const RandomEvent({
    required this.id,
    required this.category,
    required this.prompt,
    required this.createdAt,
    this.detail,
  });

  final String id;
  final String category;
  final String prompt;
  final String? detail;
  final DateTime createdAt;

  factory RandomEvent.fromJson(Map<String, dynamic> json) {
    return RandomEvent(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      detail: json['detail'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
