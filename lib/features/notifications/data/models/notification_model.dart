class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['read'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      data: rawData == null
          ? const {}
          : Map<String, dynamic>.from(rawData as Map),
    );
  }
}

class NotificationPageResult {
  const NotificationPageResult({required this.notifications, this.nextCursor});

  final List<NotificationModel> notifications;
  final String? nextCursor;

  factory NotificationPageResult.fromJson(Map<String, dynamic> json) {
    return NotificationPageResult(
      notifications: (json['notifications'] as List<dynamic>)
          .map((item) => NotificationModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
