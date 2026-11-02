import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationPageResult> getNotifications(String uid, {String? after}) {
    return _apiClient.get<NotificationPageResult>(
      ApiEndpoints.patientNotifications(uid),
      queryParameters: {
        'limit': 50,
        'after': ?after,
      },
      parser: (data) => NotificationPageResult.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<void> markRead(String uid, String notificationId) async {
    await _apiClient.patch<void>(
      ApiEndpoints.patientNotificationRead(uid, notificationId),
      parser: (_) {},
    );
  }

  Future<void> markAllRead(String uid) async {
    await _apiClient.patch<void>(
      ApiEndpoints.patientNotificationsReadAll(uid),
      parser: (_) {},
    );
  }
}
