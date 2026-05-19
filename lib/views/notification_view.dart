import 'package:chat_app/controllers/notifications_controller.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:chat_app/views/widgets/notification_item_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends GetView<NotificationsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          Obx(() {
            final unreadCount = controller.getUnreadCount();
            return unreadCount > 0
                ? TextButton(
                    onPressed: controller.markAllAsRead,
                    child: Text('Mark all read'),
                  )
                : SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.noti.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.separated(
          padding: EdgeInsets.all(16),
          separatorBuilder: (context, index) => SizedBox(height: 8),
          itemCount: controller.noti.length,
          itemBuilder: (context, index) {
            final noti = controller.noti[index];
            final user = noti.data['senderId'] != null
                ? controller.getUser(noti.data['senderId'])
                : noti.data['userId'] != null
                ? controller.getUser(noti.data['userId'])
                : null;

            return NotificationItem(
              noti: noti,
              user: user,
              timeText: controller.getNotiTimeText(noti.createdAt),
              icon: controller.getNotiIcon(noti.type),
              iconColor: controller.getNotiIconColor(noti.type),
              onTap: () => controller.handleNotiTap(noti),
              onDelete: () => controller.deleteNoti(noti),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No notifications",
              style: Theme.of(Get.context!).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Notifications will be appear soon here",
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
