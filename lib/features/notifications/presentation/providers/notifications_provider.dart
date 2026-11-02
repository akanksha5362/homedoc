import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(
    NotificationsRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsController, NotificationPageResult>(NotificationsController.new);

class NotificationsController extends AutoDisposeAsyncNotifier<NotificationPageResult> {
  String? get _uid => ref.read(authStateProvider).user?.id;

  @override
  Future<NotificationPageResult> build() {
    final uid = ref.watch(authStateProvider).user?.id;
    if (uid == null) throw StateError('Sign in to view notifications.');
    return ref.watch(notificationsRepositoryProvider).getNotifications(uid);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final uid = _uid;
    final cursor = current?.nextCursor;
    if (current == null || uid == null || cursor == null) return;
    final next = await ref.read(notificationsRepositoryProvider).getNotifications(
          uid,
          after: cursor,
        );
    final existingIds = current.notifications.map((item) => item.id).toSet();
    state = AsyncData(NotificationPageResult(
      notifications: [
        ...current.notifications,
        ...next.notifications.where((item) => !existingIds.contains(item.id)),
      ],
      nextCursor: next.nextCursor,
    ));
  }
}

final notificationsActionsProvider = Provider<NotificationsActions>((ref) {
  return NotificationsActions(ref);
});

class NotificationsActions {
  const NotificationsActions(this._ref);

  final Ref _ref;

  String get _uid {
    final user = _ref.read(authStateProvider).user;
    if (user == null) throw StateError('Sign in to manage notifications.');
    return user.id;
  }

  Future<void> markRead(String notificationId) async {
    await _ref.read(notificationsRepositoryProvider).markRead(_uid, notificationId);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllRead() async {
    await _ref.read(notificationsRepositoryProvider).markAllRead(_uid);
    _ref.invalidate(notificationsProvider);
  }
}
