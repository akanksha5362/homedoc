import '../datasources/notifications_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  const NotificationsRepository(this._remoteDataSource);

  final NotificationsRemoteDataSource _remoteDataSource;

  Future<NotificationPageResult> getNotifications(String uid, {String? after}) =>
      _remoteDataSource.getNotifications(uid, after: after);

  Future<void> markRead(String uid, String id) =>
      _remoteDataSource.markRead(uid, id);

  Future<void> markAllRead(String uid) =>
      _remoteDataSource.markAllRead(uid);
}
