import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../../../shared/widgets/states/app_empty_state.dart';
import '../../../../shared/widgets/states/app_error_state.dart';
import '../../../../shared/widgets/states/app_loading.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationCentrePage extends ConsumerStatefulWidget {
  const NotificationCentrePage({super.key});

  @override
  ConsumerState<NotificationCentrePage> createState() => _NotificationCentrePageState();
}

class _NotificationCentrePageState extends ConsumerState<NotificationCentrePage> {
  bool _loadingMore = false;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notifications.whenOrNull(
                data: (page) => page.notifications.any((item) => !item.isRead)
                    ? TextButton(
                        onPressed: () => _markAllRead(context, ref),
                        child: const Text('Mark all read'),
                      )
                    : null,
              ) ?? const SizedBox.shrink(),
        ],
      ),
      body: notifications.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(
          message: _safeMessage(error),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (page) {
          if (page.notifications.isEmpty) {
            return const AppEmptyState(
              message: 'New appointment updates and reminders will appear here.',
              icon: Icons.notifications_none_rounded,
            );
          }
          final unreadCount = page.notifications.where((item) => !item.isRead).length;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    unreadCount == 0
                        ? 'You’re all caught up.'
                        : '$unreadCount unread ${unreadCount == 1 ? 'notification' : 'notifications'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ),
                for (final notification in page.notifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _NotificationTile(
                      notification: notification,
                      onTap: () => _openNotification(context, ref, notification),
                    ),
                  ),
                if (page.nextCursor != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: TextButton.icon(
                        onPressed: _loadingMore ? null : _loadMore,
                        icon: _loadingMore
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(_loadingMore ? 'Loading…' : 'Load more'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      await ref.read(notificationsProvider.notifier).loadMore();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_safeMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsActionsProvider).markAllRead();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_safeMessage(error))),
        );
      }
    }
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    if (!notification.isRead) {
      try {
        await ref.read(notificationsActionsProvider).markRead(notification.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_safeMessage(error))),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;
    final String? destination = switch (notification.type) {
      'chat_message' => RoutePaths.patientChatList,
      'appointment_confirmed' => RoutePaths.patientAppointments,
      'doctor_arriving' => RoutePaths.patientAppointments,
      'medication_missed' => RoutePaths.patientReminders,
      'follow_up_due' => RoutePaths.patientReminders,
      _ => null,
    };
    if (destination != null) await context.push(destination);
  }

  String _safeMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('NetworkException:')) {
      return "We couldn't reach HomeDoc AI. Please check your connection.";
    }
    if (message.startsWith('AuthenticationException:')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (message.startsWith('AuthorizationException:')) {
      return "You don't have permission to view these notifications.";
    }
    if (message.startsWith('ServerException:')) {
      return "We couldn't load notifications right now.";
    }
    return "We couldn't load notifications right now. Please try again.";
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (notification.type) {
      'appointment_confirmed' => Icons.event_available_outlined,
      'chat_message' => Icons.chat_bubble_outline_rounded,
      'doctor_arriving' => Icons.directions_car_outlined,
      'medication_missed' => Icons.medication_outlined,
      'follow_up_due' => Icons.event_repeat_outlined,
      _ => Icons.notifications_outlined,
    };
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(notification.body, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat('MMM d, y · h:mm a').format(notification.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
