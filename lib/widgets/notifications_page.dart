import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:agri_frontend/models/notification_model.dart';
import 'package:agri_frontend/service/notification_service.dart';
import 'package:agri_frontend/utils/weather_message_helper.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Mode sélection
  bool _isSelectionMode = false;
  Set<String> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _initFCM();
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<UserProvider>().userId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('Chargement des notifications...');
    print('User ID: ${userId.substring(0, 20)}...');

    final result = await NotificationService.getNotifications(userId);

    print('Résultat reçu: ${result['success']}');
    print('Nombre de notifications: ${result['notifications']?.length ?? 0}');

    if (result['success'] && result['notifications'] != null) {
      for (var notif in result['notifications']) {
        print('  ${notif.title}: ${notif.message}');
      }
    } else {
      print('Erreur: ${result['error']}');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _notifications = result['notifications'];
          print('${_notifications.length} notifications chargées');
        } else {
          _errorMessage = result['error'];
        }
      });
    }
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    final userId = context.read<UserProvider>().userId;
    final success = await NotificationService.markAsRead(userId, notificationId);

    if (success && mounted) {
      setState(() {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          createdAt: _notifications[index].createdAt,
          isRead: true,
        );
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = context.read<UserProvider>().userId;
    final success = await NotificationService.markAllAsRead(userId);

    if (success) {
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('all_notifications_marked_read'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    final userId = context.read<UserProvider>().userId;
    final success = await NotificationService.deleteNotification(userId, notificationId);

    if (success && mounted) {
      setState(() {
        _notifications.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('notification_deleted'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(String notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedNotifications = _notifications.map((n) => n.id).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedNotifications.clear();
    });
  }

  Future<void> _deleteSelectedNotifications() async {
    final userId = context.read<UserProvider>().userId;
    if (_selectedNotifications.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_deletion'.tr()),
        content: Text(
          'delete_notifications_confirmation'.tr(args: [_selectedNotifications.length.toString()]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int deletedCount = 0;
    final selectedIds = List<String>.from(_selectedNotifications);

    for (String notificationId in selectedIds) {
      final success = await NotificationService.deleteNotification(
        userId,
        notificationId,
      );
      if (success) deletedCount++;
    }

    if (mounted) {
      setState(() {
        _notifications.removeWhere((n) => selectedIds.contains(n.id));
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('notifications_deleted_count'.tr(args: [deletedCount.toString()])),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _initFCM() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Permission notifications accordée');

        String? token = await messaging.getToken();
        if (token != null) {
          print('FCM Token: ${token.substring(0, 30)}...');

          final userId = context.read<UserProvider>().userId;
          await NotificationService.saveFCMToken(userId, token);
          print('Token FCM envoyé au backend');
        }
      } else {
        print('Permission notifications refusée');
      }

      // Notification en foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Notification reçue en foreground');
        print('Titre: ${message.notification?.title}');
        print('Corps: ${message.notification?.body}');

        _loadNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.notification?.body ?? 'new_notification'.tr()),
              action: SnackBarAction(
                label: 'view'.tr(),
                onPressed: _loadNotifications,
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      // Notification ouverte
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification ouverte par l\'utilisateur');
        _loadNotifications();
      });

      // App ouverte depuis notification
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('App ouverte depuis une notification');
        _loadNotifications();
      }

      // Rafraîchissement du token
      messaging.onTokenRefresh.listen((String newToken) {
        print('Token FCM rafraîchi: ${newToken.substring(0, 30)}...');
        final userId = context.read<UserProvider>().userId;
        NotificationService.saveFCMToken(userId, newToken);
      });

    } catch (e) {
      print('Erreur lors de l\'initialisation FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isSelectionMode ? Colors.blue.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _toggleSelectionMode,
        )
            : null,
        title: _isSelectionMode
            ? Text('selected_count'.tr(args: [_selectedNotifications.length.toString()]))
            : Text('notifications_title'.tr()),
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedNotifications.length < _notifications.length)
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: _selectAll,
                tooltip: 'select_all'.tr(),
              )
            else
              IconButton(
                icon: const Icon(Icons.deselect),
                onPressed: _deselectAll,
                tooltip: 'deselect_all'.tr(),
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedNotifications.isEmpty
                  ? null
                  : _deleteSelectedNotifications,
              tooltip: 'delete_selection'.tr(),
            ),
          ] else ...[
            if (_notifications.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    _markAllAsRead();
                  } else if (value == 'select_mode') {
                    _toggleSelectionMode();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Text('mark_all_as_read'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'select_mode',
                    child: Text('select'.tr()),
                  ),
                ],
              ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'no_notifications'.tr(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'notification_description'.tr(),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index], index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    final isUnread = !notification.isRead;
    final isSelected = _selectedNotifications.contains(notification.id);
    final timeAgo = _getTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'delete'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onDismissed: (_) => _deleteNotification(notification.id, index),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleNotificationSelection(notification.id);
          } else if (isUnread) {
            _markAsRead(notification.id, index);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedNotifications.add(notification.id);
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade50
                : (isUnread ? Colors.white : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUnread ? Colors.green.shade400 : Colors.grey.shade300,
              width: isUnread ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WeatherMessageHelper.parseTitle(notification.title),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      WeatherMessageHelper.parseMessage(notification.message),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicateur non lu
              if (isUnread && !_isSelectionMode)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 12, top: 6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),

              // Checkbox en mode sélection
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleNotificationSelection(notification.id),
                  activeColor: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    final locale = context.locale.languageCode;

    if (difference.inDays > 0) {
      return 'time_ago_days'.tr(args: [difference.inDays.toString()]);
    } else if (difference.inHours > 0) {
      return 'time_ago_hours'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inMinutes > 0) {
      return 'time_ago_minutes'.tr(args: [difference.inMinutes.toString()]);
    } else {
      return 'time_ago_now'.tr();
    }
  }
}