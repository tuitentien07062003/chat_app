import 'package:chat_app/controllers/friend_requests_controller.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:chat_app/views/widgets/friend_request_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendRequestsScreen extends GetView<FriendRequestsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friend Requests"),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex == 0
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              color: controller.selectedTabIndex == 0
                                  ? Colors.white
                                  : AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Received (${controller.receivedRequests.length})',
                              style: TextStyle(
                                color: controller.selectedTabIndex == 0
                                    ? Colors.white
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex == 1
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              color: controller.selectedTabIndex == 1
                                  ? Colors.white
                                  : AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sent (${controller.sentRequests.length})',
                              style: TextStyle(
                                color: controller.selectedTabIndex == 1
                                    ? Colors.white
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              return IndexedStack(
                index: controller.selectedTabIndex,
                children: [
                  _buildReceivedRequestsTab(),
                  _buildSentRequestsTab(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedRequestsTab() {
    return Obx(() {
      if (controller.receivedRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: "No Friend Requests",
          message:
              "When someone sends you a friend request, it will appear here.",
        );
      }

      return ListView.separated(
        padding: EdgeInsets.all(16),
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemCount: controller.receivedRequests.length,
        itemBuilder: (context, index) {
          final req = controller.receivedRequests[index];
          final sender = controller.getUser(req.senderId);

          if (sender == null) {
            return SizedBox.shrink();
          }

          return FriendRequestItem(
            req: req,
            user: sender,
            timeText: controller.getRequestTimeText(req.createdAt),
            isReceived: true,
            onAccept: () => controller.acceptRequest(req),
            onDecline: () => controller.declineFriendRequest(req),
          );
        },
      );
    });
  }

  Widget _buildSentRequestsTab() {
    return Obx(() {
      if (controller.receivedRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: "No Sent Requests",
          message: "Friend Requests you send will appear here.",
        );
      }

      return ListView.separated(
        padding: EdgeInsets.all(16),
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemCount: controller.sentRequests.length,
        itemBuilder: (context, index) {
          final req = controller.sentRequests[index];
          final received = controller.getUser(req.receiverId);

          if (received == null) {
            return SizedBox.shrink();
          }

          return FriendRequestItem(
            req: req,
            user: received,
            timeText: controller.getRequestTimeText(req.createdAt),
            isReceived: false,
            statusText: controller.getStatusText(req.status),
            statusColor: controller.getStatusColor(req.status),
          );
        },
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: Get.textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
