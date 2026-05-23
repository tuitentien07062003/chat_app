import 'dart:async';
import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController messageController = TextEditingController();
  final Uuid _uuid = Uuid();
  final Rxn<MessageModel> replyingMessage = Rxn<MessageModel>();
  final Map<String, GlobalKey> messageKeys = {};

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

  final Rxn<FriendshipModel> friendship = Rxn<FriendshipModel>();
  String get currentUserId => _authController.user?.uid ?? '';
  final ImagePicker _picker = ImagePicker();

  Timer? _typingTimer;
  final RxBool isOtherUserTyping = false.obs;
  StreamSubscription? _chatDocSub;

  // ========== Tìm kiếm tin nhắn ==========
  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();
  final RxList<int> searchResultIndices = <int>[].obs;
  final RxInt currentSearchIndex = 0.obs;
  final Map<String, int> _messageIndexMap = {};
  final RxString highlightedMessageId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
    _listenToTypingStatus();
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
    _typingTimer?.cancel();
    messageController.removeListener(_onMessageChanged);
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
      _listenToFriendshipRealtime();
    }
  }

  void _listenToTypingStatus() {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    if (currentUserId == null || otherUserId == null) return;

    _chatDocSub = _firestoreService
        .streamChatDocument(currentUserId, otherUserId)
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            final typingMap = data['typing'] as Map<String, dynamic>? ?? {};

            isOtherUserTyping.value = typingMap[otherUserId] == true;
          }
        });
  }

  void _listenToFriendshipRealtime() {
    final currentId = _authController.user?.uid;
    final otherId = _otherUser.value?.id;

    if (currentId != null && otherId != null) {
      _firestoreService.getAllRelationshipsStream(currentId).listen((list) {
        final match = list.firstWhereOrNull(
          (f) =>
              (f.userId == currentId && f.friendId == otherId) ||
              (f.userId == otherId && f.friendId == currentId),
        );
        friendship.value = match;
      });
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

        _messageIndexMap.clear();
        for (int i = 0; i < messageList.length; i++) {
          _messageIndexMap[messageList[i].id] = i;
        }

        if (isSearching.value) {
          if (searchController.text.isNotEmpty) {
            performSearch(searchController.text, autoScroll: false);
          }
        } else {
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          0.0,
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
    final isCurrentlyTyping = messageController.text.isNotEmpty;
    if (_isTyping.value == isCurrentlyTyping) return;

    _isTyping.value = messageController.text.isNotEmpty;

    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    if (currentUserId == null || otherUserId == null) return;

    _firestoreService.updateTypingStatus(
      currentUserId,
      otherUserId,
      isCurrentlyTyping,
    );

    // Nếu đang gõ -> Mở Timer 3 giây. Nếu ngừng gõ 3s -> Tự tắt
    _typingTimer?.cancel();
    if (isCurrentlyTyping) {
      _typingTimer = Timer(const Duration(minutes: 3), () {
        _isTyping.value = false;
        _firestoreService.updateTypingStatus(currentUserId, otherUserId, false);
      });
    }
  }

  void startReply(MessageModel message) {
    if (message.isDeleted) return;
    replyingMessage.value = message;
  }

  void cancelReply() {
    replyingMessage.value = null;
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

    if (friendship.value != null && friendship.value!.isBlocked) {
      return;
    }

    if (await _firestoreService.isUnFriended(currentUserId, otherUserId)) {
      Get.snackbar("Error", "You and them are not a friend");
      return;
    }

    try {
      _isSending.value = true;

      _typingTimer?.cancel();
      _firestoreService.updateTypingStatus(currentUserId, otherUserId, false);

      final replyMsg = replyingMessage.value;
      replyingMessage.value = null;

      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
        replyToId: replyMsg?.id,
        replyToContent: replyMsg?.content,
        replyToSenderId: replyMsg?.senderId,
        replyToTimestamp: replyMsg?.timestamp,
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

  Future<void> handleReplySnippetTap(
    String? replyToId,
    DateTime? replyTimestamp,
  ) async {
    if (replyToId == null || replyTimestamp == null) return;
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null || _chatId.value.isEmpty) return;

    try {
      final chatDoc = await _firestoreService.getChatDoc(_chatId.value);

      if (chatDoc.exists) {
        ChatModel chat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        DateTime? deletedAt = chat.getDeletedAt(currentUserId);

        if (deletedAt != null && replyTimestamp.isBefore(deletedAt)) {
          Get.dialog(
            AlertDialog(
              title: Text("Lỗi"),
              content: Text("Tin nhắn bạn đã xóa trước đó. Không thể xem lại."),
              actions: [
                TextButton(onPressed: () => Get.back(), child: Text("Đóng")),
              ],
            ),
          );
          return;
        }
      }

      int targetIndex = messages.indexWhere((m) => m.id == replyToId);

      if (targetIndex != -1) {
        double estimatedOffset = targetIndex * 85.0;

        await scrollController.animateTo(
          estimatedOffset.clamp(0.0, scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );

        await Future.delayed(const Duration(milliseconds: 80));

        final targetKey = messageKeys[replyToId];

        if (targetKey != null && targetKey.currentContext != null) {
          await Scrollable.ensureVisible(
            targetKey.currentContext!,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOutCubic,
          );
        }
      } else {
        Get.snackbar(
          "Thông báo",
          "Tin nhắn gốc nằm ở quá xa hoặc không còn tồn tại",
        );
      }
    } catch (e) {
      print("Error check reply tap: $e");
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null && _chatId.value.isNotEmpty) {
      try {
        await _firestoreService.restoreUnreadCount(
          _chatId.value,
          currentUserId,
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
      if (_messages.isNotEmpty && _messages.last.id == mess.id) {
        await _firestoreService.updateChatLastMessage(
          _chatId.value,
          "Tin nhắn đã bị xóa",
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to delete message");
      print(e);
    }
  }

  Future<void> editMessage(MessageModel mess, String newContent) async {
    try {
      await _firestoreService.editMessage(mess.id, newContent);

      if (_chatId.value.isNotEmpty &&
          _messages.isNotEmpty &&
          _messages.last.id == mess.id) {
        await _firestoreService.updateChatLastMessage(
          _chatId.value,
          newContent,
        );
      }
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

  Future<void> sendIconMessage(String emoji) async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    if (currentUserId == null || otherUserId == null || _chatId.value.isEmpty)
      return;

    final messageId = _uuid.v4();
    final message = MessageModel(
      id: messageId,
      senderId: currentUserId,
      receiverId: otherUserId,
      type: MessageType.icon,
      content: emoji,
      timestamp: DateTime.now(),
      replyToId: replyingMessage.value?.id,
      replyToContent: replyingMessage.value?.content,
      replyToSenderId: replyingMessage.value?.senderId,
      replyToTimestamp: replyingMessage.value?.timestamp,
    );

    try {
      await _firestoreService.sendMessage(message);
      replyingMessage.value = null;
    } catch (e) {
      Get.snackbar("Error", "Không thể gửi icon");
    }
  }

  Future<void> toggleReaction(MessageModel message, String emoji) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    String? targetIcon = message.reactions[currentUserId] == emoji
        ? null
        : emoji;

    try {
      await _firestoreService.updateMessageReaction(
        message.id,
        currentUserId,
        targetIcon,
      );
    } catch (e) {
      print("Lỗi thả cảm xúc: $e");
    }
  }

  void copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    Get.snackbar(
      "Thành công",
      "Đã sao chép tin nhắn",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> forwardMessage(
    MessageModel originalMessage,
    UserModel targetUser,
  ) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    final messageId = _uuid.v4();
    final message = MessageModel(
      id: messageId,
      senderId: currentUserId,
      receiverId: targetUser.id,
      type: originalMessage.type,
      content: originalMessage.content,
      timestamp: DateTime.now(),
    );

    try {
      await _firestoreService.sendMessage(message);
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể chuyển tiếp tin nhắn");
      print(e);
    }
  }

  Future<List<UserModel>> getForwardableFriends() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return [];

    try {
      List<UserModel> friends = await _firestoreService.getForwardableFriends(
        currentUserId,
      );

      final currentChatPartnerId = _otherUser.value?.id;
      if (currentChatPartnerId != null) {
        friends.removeWhere((user) => user.id == currentChatPartnerId);
      }

      return friends;
    } catch (e) {
      print("Lỗi lấy danh sách bạn bè: $e");
      return [];
    }
  }

  String getDynamicReplyContent(MessageModel message) {
    if (message.replyToId == null) return message.replyToContent ?? "";

    try {
      final originalMsg = _messages.firstWhere(
        (m) => m.id == message.replyToId,
      );

      if (originalMsg.isDeleted) {
        return "Tin nhắn đã bị xóa";
      }

      return originalMsg.content;
    } catch (e) {
      return message.replyToContent ?? "";
    }
  }

  Future<void> openFilePickerAndUpload(BuildContext context) async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    if (currentUserId == null || otherUserId == null) return;

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile pickedFile = result.files.first;

        Uint8List? fileBytes = pickedFile.bytes;
        String fileName = pickedFile.name;

        if (fileBytes == null) {
          throw Exception("Không thể đọc dữ liệu byte của file này.");
        }

        if (pickedFile.size > 10 * 1024 * 1024) {
          throw Exception(
            "Dung lượng file quá lớn. Vui lòng chọn file dưới 15MB.",
          );
        }

        _isSending.value = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đang upload file: $fileName...')),
        );

        String finalUrl = await _firestoreService.uploadToCloudinary(
          fileBytes,
          fileName,
        );

        final String extension = p.extension(fileName).toLowerCase();

        MessageType msgType = MessageType.file;
        String msgContent = '$finalUrl|$fileName';
        String lastMsgText = "[Tập tin] $fileName";

        if ([
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.bmp',
          '.svg',
        ].contains(extension)) {
          msgType = MessageType.image;
          msgContent = finalUrl;
          lastMsgText = "[Hình ảnh]";
        } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(extension)) {
          msgType = MessageType.video;
          msgContent = finalUrl;
          lastMsgText = "[Video]";
        } else if (['.mp3', '.wav', '.aac'].contains(extension)) {
          msgType = MessageType.audio;
          msgContent = finalUrl;
          lastMsgText = "[Âm thanh]";
        }

        final messageId = _uuid.v4();
        final message = MessageModel(
          id: messageId,
          senderId: currentUserId,
          receiverId: otherUserId,
          type: msgType,
          content: msgContent,
          timestamp: DateTime.now(),
        );

        await _firestoreService.sendMessage(message);

        await _firestoreService.updateChatLastMessage(
          _chatId.value,
          lastMsgText,
        );

        print("Upload thành công! Đường dẫn file online: $finalUrl");

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload thành công!')));
      } else {
        print("Người dùng đã hủy chọn file.");
      }
    } catch (e) {
      print("Lỗi trong quá trình chọn/upload file: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: ${e.toString()}')));
    }
  }

  // ========== Tìm kiếm tin nhắn ==========
  void performSearch(String query, {bool autoScroll = true}) {
    if (query.trim().isEmpty) {
      searchResultIndices.clear();
      return;
    }

    final lowerQuery = query.toLowerCase();
    searchResultIndices.clear();

    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].type == MessageType.text &&
          !_messages[i].isDeleted &&
          _messages[i].content.toLowerCase().contains(lowerQuery)) {
        searchResultIndices.add(i);
      }
    }

    if (searchResultIndices.isNotEmpty) {
      currentSearchIndex.value = 0;
      scrollToSearchResult();
    }
  }

  void scrollToSearchResult() async {
    if (searchResultIndices.isEmpty) return;

    int targetIndex = searchResultIndices[currentSearchIndex.value];

    String targetMessageId = _messages[targetIndex].id;

    highlightedMessageId.value = targetMessageId;

    final key = messageKeys[targetMessageId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    } else {
      if (scrollController.hasClients) {
        double estimatedOffset = targetIndex * 80.0;
        double maxScroll = scrollController.position.maxScrollExtent;

        await scrollController.animateTo(
          estimatedOffset > maxScroll ? maxScroll : estimatedOffset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
        await Future.delayed(const Duration(milliseconds: 200));

        final newKey = messageKeys[targetMessageId];
        if (newKey != null && newKey.currentContext != null) {
          Scrollable.ensureVisible(
            newKey.currentContext!,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      }
    }
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (highlightedMessageId.value == targetMessageId) {
        highlightedMessageId.value = '';
      }
    });
  }

  void nextSearchResult() {
    if (currentSearchIndex.value < searchResultIndices.length - 1) {
      currentSearchIndex.value++;
      scrollToSearchResult();
    }
  }

  void previousSearchResult() {
    if (currentSearchIndex.value > 0) {
      currentSearchIndex.value--;
      scrollToSearchResult();
    }
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchController.clear();
      searchResultIndices.clear();
    }
  }

  void clearError() {
    _error.value = '';
  }
}
