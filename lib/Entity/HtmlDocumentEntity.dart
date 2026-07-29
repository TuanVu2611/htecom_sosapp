// ignore_for_file: file_names

class HtmlDocumentEntity {
  const HtmlDocumentEntity({
    required this.title,
    required this.content,
    this.version,
    this.updatedAt,
  });

  final String title;
  final String content;
  final String? version;
  final DateTime? updatedAt;

  factory HtmlDocumentEntity.fromJson(Object? value) {
    if (value is! Map) {
      throw FormatException('Invalid html document data: $value');
    }

    final json = Map<String, dynamic>.from(value);
    return HtmlDocumentEntity(
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      version: json['version']?.toString(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}
