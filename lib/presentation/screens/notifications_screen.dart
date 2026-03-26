import 'package:flutter/material.dart';
import '../../domain/models/notification.dart' as models;
import '../../data/repositories/notification_repository_impl.dart';
import 'order_detail_screen.dart';
import 'chat_screen.dart';
import 'reviews_screen.dart';

/// Screen for viewing notifications
class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepositoryImpl _notificationRepo = NotificationRepositoryImpl();
  List<models.Notification> _notifications = [];
  bool _isLoading = true;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await _notificationRepo.initialize();
    final notifications = await _notificationRepo.getNotificationsByUserId(
      widget.userId,
      unreadOnly: _showUnreadOnly,
    );

    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(models.Notification notification) async {
    if (notification.isRead) return;

    await _notificationRepo.markAsRead(notification.id!);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _notificationRepo.markAllAsRead(widget.userId);
    await _loadNotifications();
  }

  void _handleNotificationTap(models.Notification notification) async {
    await _markAsRead(notification);

    switch (notification.type) {
      case models.NotificationType.order:
        if (notification.relatedId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: notification.relatedId!),
            ),
          );
        }
        break;
      case models.NotificationType.message:
        if (notification.relatedId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(specialistId: notification.relatedId!),
            ),
          );
        }
        break;
      case models.NotificationType.review:
        if (notification.relatedId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewsScreen(
                specialistId: notification.relatedId!,
                specialistName: 'Reviews',
              ),
            ),
          );
        }
        break;
      case models.NotificationType.system:
        // Show dialog or navigate to relevant screen
        break;
    }
  }

  IconData _getNotificationIcon(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.order:
        return Icons.shopping_cart;
      case models.NotificationType.message:
        return Icons.chat;
      case models.NotificationType.review:
        return Icons.star;
      case models.NotificationType.system:
        return Icons.info;
    }
  }

  Color _getNotificationColor(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.order:
        return Colors.blue;
      case models.NotificationType.message:
        return Colors.green;
      case models.NotificationType.review:
        return Colors.amber;
      case models.NotificationType.system:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          PopupMenuButton(
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(_showUnreadOnly ? null : Icons.check, size: 20),
                    const SizedBox(width: 8),
                    const Text('All Notifications'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(_showUnreadOnly ? Icons.check : null, size: 20),
                    const SizedBox(width: 8),
                    const Text('Unread Only'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              setState(() {
                _showUnreadOnly = value;
              });
              _loadNotifications();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _notificationRepo.deleteNotification(notification.id!);
                          _loadNotifications();
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: notification.isRead ? null : Colors.blue[50],
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.2),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: _getNotificationColor(notification.type),
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(notification.message),
                            trailing: notification.isRead
                                ? null
                                : const Icon(Icons.circle, size: 8, color: Colors.blue),
                            onTap: () => _handleNotificationTap(notification),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

