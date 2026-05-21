import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<NotificationModel> _noti = <NotificationModel>[].obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  final Set<String> _knownNotiIds = {};
  bool _isFirstLoad = true;

  List<NotificationModel> get noti => _noti;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    _loadNoti();
    _loadUser();
  }

  void _loadNoti() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      final Stream<List<NotificationModel>> stream = _firestoreService
          .getNotificationsStream(currentUserId);
      _noti.bindStream(stream);

      stream.listen((notifications) {
        if (_isFirstLoad) {
          _knownNotiIds.addAll(notifications.map((n) => n.id));
          _isFirstLoad = false;
          return;
        }

        for (var noti in notifications) {
          if (noti.type == NotificationType.newMessage && !noti.isRead) {
            final senderId = noti.data['senderId'] ?? noti.data['userId'];
            if (senderId == null) continue;

            bool isInsideThisChatRoom = false;
            if (Get.currentRoute == AppRoutes.chat) {
              final args = Get.arguments;
              if (args is Map && args['otherUser'] != null) {
                if (args['otherUser'].id == senderId) {
                  isInsideThisChatRoom = true;
                }
              }
            }
            if (!isInsideThisChatRoom && !_knownNotiIds.contains(noti.id)) {
              _knownNotiIds.add(noti.id);
              _showNewMessageSnackbar(noti, senderId);
            }
          }
        }
      });
    }
  }

  void _loadUser() {
    _users.bindStream(
      _firestoreService.getAllUsersStream().map((userList) {
        Map<String, UserModel> userMap = {};
        for (var user in userList) {
          userMap[user.id] = user;
        }
        return userMap;
      }),
    );
  }

  void _showNewMessageSnackbar(NotificationModel noti, String senderId) {
    final sender = getUser(senderId);
    if (sender == null) return;

    String displayContent = noti.body;
    if (displayContent.length > 35) {
      displayContent = "${displayContent.substring(0, 35)}...";
    }

    Get.snackbar(
      sender.displayName,
      displayContent,
      icon: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primaryColor,
          child: sender.photoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    sender.photoUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatarText(sender.displayName),
                  ),
                )
              : _buildDefaultAvatarText(sender.displayName),
        ),
      ),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      onTap: (_) {
        handleNotiTap(noti);
      },
    );
  }

  Widget _buildDefaultAvatarText(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : "?",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  UserModel? getUser(String userId) {
    return _users[userId];
  }

  Future<void> markAsRead(NotificationModel noti) async {
    try {
      if (noti.isRead) {
        await _firestoreService.markNotiAsRead(noti.id);
      }
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        await _firestoreService.markAllNotiAsRead(currentUserId);
        Get.snackbar('Success', 'All notifications marked as read');
      }
    } catch (e) {
      _error.value = e.toString();
      print(e.toString());
      Get.snackbar('Error', "All notifications marked as read failed");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteNoti(NotificationModel noti) async {
    try {
      await _firestoreService.deleteNotifications(noti.id);
    } catch (e) {
      _error.value = e.toString();
      print(e.toString());
      Get.snackbar('Error', "All notifications failed to delete");
    }
  }

  void handleNotiTap(NotificationModel noti) {
    markAsRead(noti);

    switch (noti.type) {
      case NotificationType.friendRequest:
        Get.toNamed(AppRoutes.friendRequests);
        break;
      case NotificationType.friendRequestAccepted:
      case NotificationType.friendRequestDeclined:
        Get.toNamed(AppRoutes.friends);
        break;
      case NotificationType.newMessage:
        final userId = noti.data['userId'];
        if (userId != null) {
          final user = getUser(userId);
          if (user != null) {
            Get.toNamed(AppRoutes.chat, arguments: {'otherUser': user});
          }
        }
        break;
      case NotificationType.friendRemoved:
        break;
    }
  }

  String getNotiTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inHours} days ago";
    } else {
      return "${createdAt.day}/${createdAt.month}/${createdAt.year}";
    }
  }

  IconData getNotiIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.check_circle;
      case NotificationType.friendRequestDeclined:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.friendRemoved:
        return Icons.person_remove;
    }
  }

  Color getNotiIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return AppTheme.primaryColor;
      case NotificationType.friendRequestAccepted:
        return AppTheme.successColor;
      case NotificationType.friendRequestDeclined:
        return AppTheme.errorColor;
      case NotificationType.newMessage:
        return AppTheme.secondaryColor;
      case NotificationType.friendRemoved:
        return AppTheme.errorColor;
    }
  }

  int getUnreadCount() {
    return _noti.where((noti) => !noti.isRead).length;
  }

  void clearError() {
    _error.value = '';
  }
}
