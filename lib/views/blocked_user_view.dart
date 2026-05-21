import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/themes/app_theme.dart';

class BlockedUsersController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserId = Get.find<AuthController>().user?.uid ?? '';

  final RxList<Map<String, dynamic>> blockedUsersList =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId.isNotEmpty) {
      _listenToBlockedUsers();
    }
  }

  void _listenToBlockedUsers() {
    isLoading.value = true;
    _firestoreService
        .getBlockedUsersStream(currentUserId)
        .listen(
          (records) async {
            List<Map<String, dynamic>> tempParams = [];

            for (var record in records) {
              String blockedId = record.getOtherUserId(currentUserId);
              try {
                final user = await _firestoreService.getUser(blockedId);
                if (user != null) {
                  tempParams.add({
                    'record': record,
                    'user': user,
                    'blockedId': blockedId,
                  });
                }
              } catch (e) {
                print("Lỗi khi tải thông tin user bị block: $e");
              }
            }

            blockedUsersList.value = tempParams;
            isLoading.value = false;
          },
          onError: (err) {
            isLoading.value = false;
          },
        );
  }

  Future<void> unblockUser(String blockedId) async {
    try {
      await _firestoreService.unBlockUser(currentUserId, blockedId);
      blockedUsersList.removeWhere(
        (element) => element['blockedId'] == blockedId,
      );
      Get.snackbar("Success", "User unblocked successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to unblock user");
    }
  }
}

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BlockedUsersController());

    return Scaffold(
      appBar: AppBar(title: const Text("Blocked Users")),
      body: Obx(() {
        if (controller.isLoading.value && controller.blockedUsersList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.blockedUsersList.isEmpty) {
          return const Center(
            child: Text(
              "No blocked users",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.blockedUsersList.length,
          itemBuilder: (context, index) {
            final item = controller.blockedUsersList[index];
            final UserModel user = item['user'];
            final String blockedId = item['blockedId'];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(user.email),
                trailing: ElevatedButton(
                  onPressed: () => controller.unblockUser(blockedId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Unblock"),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
