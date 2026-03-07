class NotificationModel {
  final int notificationId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? link;

  const NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.link,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Be tolerant to different backend casing.
    final id =
        json['notificationId'] ??
        json['NotificationId'] ??
        json['id'] ??
        json['Id'] ??
        0;
    final title = (json['title'] ?? json['Title'] ?? '').toString();
    final message =
        (json['message'] ??
                json['Message'] ??
                json['content'] ??
                json['Content'] ??
                '')
            .toString();
    final createdAtRaw =
        json['createdAt'] ??
        json['CreatedAt'] ??
        json['createdDate'] ??
        json['CreatedDate'];
    final link = (json['link'] ?? json['Link'])?.toString();

    DateTime createdAt;
    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final isRead = (json['isRead'] ?? json['IsRead'] ?? false) == true;

    return NotificationModel(
      notificationId: id is int ? id : int.tryParse(id.toString()) ?? 0,
      title: title.isEmpty ? 'Notification' : title,
      message: message,
      createdAt: createdAt,
      isRead: isRead,
      link: (link != null && link.isNotEmpty) ? link : null,
    );
  }
}
