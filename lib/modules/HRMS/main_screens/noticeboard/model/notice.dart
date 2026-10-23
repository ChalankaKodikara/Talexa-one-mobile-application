class Notice {
  final int id;
  final String title;
  final String description;
  final DateTime? publishedDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.publishedDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    DateTime? _parse(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.parse(v).toLocal();

    return Notice(
      id: (json['id'] ?? 0) as int,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      publishedDate: _parse(json['published_date']?.toString()),
      status: (json['status'] ?? '').toString(),
      createdAt: _parse(json['createdAt']?.toString()),
      updatedAt: _parse(json['updatedAt']?.toString()),
    );
  }
}
