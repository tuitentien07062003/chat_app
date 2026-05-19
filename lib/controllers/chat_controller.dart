import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController messageController = TextEditingController();
  final Uuid _uuid = Uuid();

  ScrollController? _scrollController;
  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _otherUser = Rx<UserModel?>(null);
  final RxString _chatId = ''.obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isChatActive = false.obs;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;
  String get error => _error.value;
  UserModel? get otherUser => _otherUser.value;
  String get chatId => _chatId.value;
  bool get isTyping => _isTyping.value;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
    messageController.addListener(_onMessageChanged);
  }

  @override
  void onReady() {
    super.onReady();
    _isChatActive.value = true;
  }

  @override
  void onClose() {
    _isChatActive.value = false;
    _markMessagesAsRead();
    super.onClose();
  }

  void _initializeChat() {
    final arg = Get.arguments;
    if (arg != null) {
      _chatId.value = arg['chatId'] ?? '';
      _otherUser.value = arg['otherUser'];
      _loadMessages();
      _markMessagesAsRead();
    }
  }

  void _loadMessages() {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;

    if (currentUserId != null && otherUserId != null) {
      _messages.bindStream(
        _firestoreService.getMessagesStream(currentUserId, otherUserId),
      );

      ever(_messages, (List<MessageModel> messageList) {
        if (_isChatActive.value) {
          _markUnreadMessagesAsRead(messageList);
        }

        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markUnreadMessagesAsRead(List<MessageModel> messageList) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;
    try {
      final unreadMessages = messageList
          .where(
            (mess) =>
                mess.receiverId == currentUserId &&
                !mess.isRead &&
                mess.senderId != currentUserId,
          )
          .toList();

      for (var mess in unreadMessages) {
        await _firestoreService.markMessageAsRead(mess.id);
      }

      if (unreadMessages.isNotEmpty && _chatId.isNotEmpty) {
        await _firestoreService.restoreUnreadCount(
          _chatId.value,
          currentUserId,
        );
      }

      if (_chatId.value.isNotEmpty) {
        await _firestoreService.updateUserLastSeen(
          _chatId.value,
          currentUserId,
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deleteChat() async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null || _chatId.value.isEmpty) return;

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Delete Conversation"),
          content: Text(
            "Are you sure you want to delete this conversation? This cannot be undone",
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text("Delete"),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value == true;
        await _firestoreService.deleteChatForUser(_chatId.value, currentUserId);

        Get.delete<ChatController>(tag: _chatId.value);
        Get.back();
        Get.snackbar("Success", "Chat Deleted");
      }
    } catch (e) {
      _error.value = e.toString();
      print(e.toString());
      Get.snackbar("Error", "Failed to delete conversation");
    } finally {
      _isLoading.value = false;
    }
  }

  void _onMessageChanged() {
    _isTyping.value = messageController.text.isNotEmpty;
  }

  Future<void> sendMessage() async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    final content = messageController.text.trim();
    messageController.clear();

    if (currentUserId == null || otherUserId == null || content.isEmpty) {
      Get.snackbar("Error", "You can't send messages to them");
      return;
    }

    if (await _firestoreService.isUnFriended(currentUserId, otherUserId)) {
      Get.snackbar("Error", "You and them are not a friend");
      return;
    }

    try {
      _isSending.value = true;

      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      await _firestoreService.sendMessage(message);
      _isTyping.value = false;

      _scrollToBottom();
    } catch (e) {
      Get.snackbar("Error", "You can't send messages to them");
      print(e.toString());
    } finally {
      _isSending.value = false;
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null || _chatId.value.isNotEmpty) {
      try {
        await _firestoreService.restoreUnreadCount(
          _chatId.value,
          currentUserId!,
        );
      } catch (e) {
        print(e.toString());
      }
    }
  }

  void onChatResumed() {
    _isChatActive.value = true;
    _markUnreadMessagesAsRead(_messages);
  }

  void onChatPaused() {
    _isChatActive.value = false;
  }

  Future<void> deleteMessage(MessageModel mess) async {
    try {
      await _firestoreService.deleteMessage(mess.id);
      Get.snackbar("Success", "Message Delete");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete message");
      print(e);
    }
  }

  Future<void> editMessage(MessageModel mess, String newContent) async {
    try {
      await _firestoreService.editMessage(mess.id, newContent);
      Get.snackbar("Success", "Message Edit");
    } catch (e) {
      Get.snackbar("Error", "Failed to edit message");
      print(e);
    }
  }

  bool isMyMessage(MessageModel mess) {
    return mess.senderId == _authController.user?.uid;
  }

  String formatMessTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inHours < 1) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inDays < 1) {
      return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return "${days[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
    }
  }

  void clearError() {
    _error.value = '';
  }
}
