class LifestyleEntryDto {
  final String domain;
  final String key;
  final dynamic value;
  final double confidence;
  final String source;

  const LifestyleEntryDto({
    required this.domain,
    required this.key,
    required this.value,
    this.confidence = 0.7,
    this.source = 'manual',
  });

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'key': key,
      'value': value,
      'confidence': confidence,
      'source': source,
    };
  }
}
