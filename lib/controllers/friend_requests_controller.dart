import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/friends_controller.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendRequestsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<FriendRequestModel> _receivedRequests =
      <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxInt _selectedTabIndex = 0.obs;

  List<FriendRequestModel> get receivedRequests => _receivedRequests;
  List<FriendRequestModel> get sentRequests => _sentRequests;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get selectedTabIndex => _selectedTabIndex.value;

  @override
  void onInit() {
    super.onInit();
    _loadFriendRequests();
    _loadUsers();
  }

  void _loadFriendRequests() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );
      _sentRequests.bindStream(
        _firestoreService.getSentFriendRequestsStrean(currentUserId),
      );
    }
  }

  void _loadUsers() {
    _users.bindStream(
      _firestoreService.getAllUsersStream().map((userList) {
        Map<String, UserModel> userMap = {};
        for (var u in userList) {
          userMap[u.id] = u;
        }
        return userMap;
      }),
    );
  }

  void changeTab(int index) {
    _selectedTabIndex.value = index;
  }

  UserModel? getUser(String userId) {
    return _users[userId];
  }

  Future<void> acceptRequest(FriendRequestModel req) async {
    try {
      _isLoading.value = true;
      await _firestoreService.respondToFriendRequest(
        req.id,
        FriendRequestStatus.accepted,
      );
      try {
        Get.find<FriendsController>().refreshFriends();
      } catch (e) {
        print(e.toString());
      }
      Get.snackbar('Success', "Friend request accepted");
    } catch (e) {
      print(e.toString());
      _error.value = 'Failed to accept friend request';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> declineFriendRequest(FriendRequestModel req) async {
    try {
      _isLoading.value = true;
      await _firestoreService.respondToFriendRequest(
        req.id,
        FriendRequestStatus.declined,
      );
      Get.snackbar('Success', "Friend request declined");
    } catch (e) {
      print(e.toString());
      _error.value = 'Failed to decline friend request';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      _isLoading.value = true;
      await _firestoreService.unBlockUser(_authController.user!.uid, userId);
      Get.snackbar('Success', "User unblocked successfully");
    } catch (e) {
      print(e.toString());
      _error.value = 'Failed to unblock user';
    } finally {
      _isLoading.value = false;
    }
  }

  String getRequestTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inHours < 1) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inDays < 1) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays < 7) {
      return "${diff.inHours} days ago";
    } else {
      return "${createdAt.day}/${createdAt.month}/${createdAt.year}";
    }
  }

  String getStatusText(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return "Pending";
      case FriendRequestStatus.accepted:
        return "Accepted";
      case FriendRequestStatus.declined:
        return "Declined";
    }
  }

  Color getStatusColor(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return Colors.orange;
      case FriendRequestStatus.accepted:
        return Colors.green;
      case FriendRequestStatus.declined:
        return Colors.redAccent;
    }
  }

  void clearError() {
    _error.value = '';
  }
}
