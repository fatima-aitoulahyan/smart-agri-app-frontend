class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type; // ← AJOUT DU CHAMP TYPE

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.type = 'weather', // ← Valeur par défaut
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      type: json['type'] ?? 'weather', // ← PARSER LE TYPE
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type, // ← AJOUTER AU JSON
    };
  }
}