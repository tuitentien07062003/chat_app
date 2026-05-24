import 'package:chat_app/controllers/call_controller.dart';
import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:chat_app/views/call_view.dart';
import 'package:chat_app/views/widgets/message_bubble.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final String chatId;
  late final ChatController controller;

  @override
  void initState() {
    super.initState();
    chatId = Get.arguments?['chatId'] ?? '';

    if (!Get.isRegistered<ChatController>(tag: chatId)) {
      Get.put<ChatController>(ChatController(), tag: chatId);
    }

    controller = Get.find<ChatController>(tag: chatId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
          if (controller.isSearching.value) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => controller.toggleSearch(),
            );
          }
          return IconButton(
            onPressed: () {
              Get.delete<ChatController>(tag: chatId);
              Get.back();
            },
            icon: Icon(Icons.arrow_back),
          );
        }),

        title: Obx(() {
          if (controller.isSearching.value) {
            return TextField(
              controller: controller.searchController,
              autofocus: true,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: "Tìm trong đoạn chat...",
                hintStyle: TextStyle(color: AppTheme.textPrimaryColor),
                border: InputBorder.none,
              ),
              onChanged: (val) => controller.performSearch(val),
            );
          }

          final otherUser = controller.otherUser;
          if (otherUser == null) return Text("Chat");
          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor,
                child: otherUser.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          otherUser.photoUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              otherUser.displayName.isNotEmpty
                                  ? otherUser.displayName[0].toUpperCase()
                                  : "?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        otherUser.displayName.isNotEmpty
                            ? otherUser.displayName[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      otherUser.isOnline ? "Online" : "Offline",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: otherUser.isOnline
                            ? AppTheme.successColor
                            : AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),

        actions: [
          Obx(() {
            // 🎯 NÚT ĐIỀU HƯỚNG KẾT QUẢ TÌM KIẾM
            if (controller.isSearching.value) {
              return Row(
                children: [
                  // Hiển thị số lượng: "1/5"
                  if (controller.searchResultIndices.isNotEmpty)
                    Text(
                      "${controller.currentSearchIndex.value + 1}/${controller.searchResultIndices.length}",
                      style: const TextStyle(color: AppTheme.textPrimaryColor),
                    ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: controller.searchResultIndices.isNotEmpty
                        ? controller.nextSearchResult
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: controller.searchResultIndices.isNotEmpty
                        ? controller.previousSearchResult
                        : null,
                  ),
                ],
              );
            }
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => controller.toggleSearch(),
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    final otherUser = controller.otherUser;
                    if (otherUser == null) return;
                    final callController = Get.find<CallController>();

                    // Gọi hàm tạo cuộc gọi đi
                    callController.makeCall(
                      calleeId: otherUser.id,
                      calleeName: otherUser.displayName,
                      calleePic: otherUser.photoUrl,
                    );

                    // Chuyển luôn sang trang Video Call
                    Get.to(() => CallScreen());
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        controller.deleteChat();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppTheme.errorColor,
                        ),
                        title: Text('Delete Conversation'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                controller: controller.scrollController,
                reverse: true,
                padding: EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final bubbleKey = controller.messageKeys.putIfAbsent(
                    message.id,
                    () => GlobalKey(),
                  );
                  final isMyMessage = controller.isMyMessage(message);
                  final showTime =
                      index == 0 ||
                      controller.messages[index - 1].timestamp
                              .difference(message.timestamp)
                              .inMinutes
                              .abs() >
                          5;

                  return Obx(() {
                    return MessageBubble(
                      key: bubbleKey,
                      message: message,
                      isMyMessage: isMyMessage,
                      showTime: showTime,
                      timeText: controller.formatMessTime(message.timestamp),
                      dynamicReplyContent: controller.getDynamicReplyContent(
                        message,
                      ),
                      onLongPress: !message.isDeleted
                          ? () => _showMessageOptions(message)
                          : null,
                      onSwipeToReply: () => controller.startReply(message),
                      onReplySnippetTap: () => controller.handleReplySnippetTap(
                        message.replyToId,
                        message.replyToTimestamp,
                      ),
                      isHighlighted:
                          controller.highlightedMessageId.value == message.id,
                    );
                  });
                },
              );
            }),
          ),
          _buildMessInput(),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        controller.onChatResumed();
        break;
      case AppLifecycleState.detached:
        controller.onChatPaused();
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
    }
  }

  Widget _buildMessInput() {
    return Obx(() {
      final friendship = controller.friendship.value;
      final bool isBlocked = friendship != null && friendship.isBlocked;
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderColor.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: isBlocked
              ? _buildBlockedInputState()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.isOtherUserTyping.value)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
                        child: Text(
                          "Đang soạn tin",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    _buildNormalInputState(),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildBlockedInputState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Không thể gửi tin nhắn do tài khoản này đã bị chặn hoặc bạn đã chặn họ.",
        style: TextStyle(
          color: AppTheme.textSecondaryColor.withOpacity(0.6),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNormalInputState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final replyMsg = controller.replyingMessage.value;
          if (replyMsg == null) return SizedBox.shrink();

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.reply_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Đang trả lời",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        replyMsg.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20),
                  onPressed: controller.cancelReply,
                ),
              ],
            ),
          );
        }),

        Obx(() {
          // TRƯỜNG HỢP 1: ĐANG GHI ÂM VOICE CHAT (Giao diện ghi âm mới)
          if (controller.isRecording.value) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Đang ghi âm...",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Thời gian chạy (Ví dụ: 00:05) lấy từ Controller của ông
                        Text(
                          controller.recordDurationText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút Hủy ghi âm (Icon Thùng rác)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 26,
                  ),
                  onPressed: controller.cancelRecording,
                ),

                // Nút Gửi Voice chat (Dùng chung màu chủ đạo hệ thống)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: controller.isSending
                        ? null
                        : controller.stopAndSendRecording,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // 1. Nút chọn Ảnh
                    IconButton(
                      icon: const Icon(
                        Icons.image,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () =>
                          controller.openFilePickerAndUpload(context),
                    ),
                    // 2. Nút chọn File
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () =>
                          controller.openFilePickerAndUpload(context),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          decoration: const InputDecoration(
                            hintText: "Type a message",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => controller.sendMessage(),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Get.bottomSheet(
                            SizedBox(
                              height: 320,
                              child: EmojiPicker(
                                textEditingController:
                                    controller.messageController,

                                config: Config(
                                  checkPlatformCompatibility: true,
                                  emojiViewConfig: EmojiViewConfig(
                                    columns: 7,
                                    emojiSizeMax: 28,
                                    backgroundColor: Colors.white,
                                  ),
                                  searchViewConfig: const SearchViewConfig(
                                    backgroundColor: Colors.white,
                                    buttonIconColor: Colors.transparent,
                                  ),
                                  categoryViewConfig: const CategoryViewConfig(
                                    backgroundColor: Colors.white,
                                    indicatorColor: AppTheme.primaryColor,
                                    iconColorSelected: AppTheme.primaryColor,
                                    iconColor: Colors.grey,
                                  ),
                                  bottomActionBarConfig:
                                      const BottomActionBarConfig(
                                        backgroundColor: Colors.white,
                                        buttonColor: Colors.white,
                                        buttonIconColor: Colors.grey,
                                      ),
                                ),
                              ),
                            ),
                            backgroundColor: Colors.white,
                            isScrollControlled: false,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.mic_none_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: controller.startRecording,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: controller.isTyping
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: controller.isSending
                      ? null
                      : controller.sendMessage,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
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
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Start the conversation",
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Send a message to get the conversation",
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

  void _showMessageOptions(dynamic message) {
    final List<String> reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "💩"];
    final isMyMessage = controller.isMyMessage(message);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Thả cảm xúc",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: reactionEmojis.map((emoji) {
                bool isMyReaction =
                    message.reactions?[controller.currentUserId] == emoji;
                return GestureDetector(
                  onTap: () {
                    Get.back();
                    controller.toggleReaction(message, emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isMyReaction
                          ? AppTheme.primaryColor.withOpacity(0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 32, thickness: 1),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActionItem(
                  icon: Icons.copy_rounded,
                  tooltip: "Sao chép",
                  onTap: () {
                    Get.back();
                    controller.copyMessage(message.content);
                  },
                ),

                _buildActionItem(
                  icon: Icons.shortcut_rounded,
                  tooltip: "Chuyển tiếp",
                  onTap: () {
                    Get.back();
                    _showForwardBottomSheet(message);
                  },
                ),

                if (isMyMessage && message.type == MessageType.text)
                  _buildActionItem(
                    icon: Icons.edit_rounded,
                    tooltip: "Chỉnh sửa",
                    onTap: () {
                      Get.back();
                      _showEditDialog(message);
                    },
                  ),

                if (isMyMessage)
                  _buildActionItem(
                    icon: Icons.delete_outline_rounded,
                    tooltip: "Xóa",
                    onTap: () {
                      Get.back();
                      _showDeleteDialog(message);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.grey[800], size: 24),
        ),
      ),
    );
  }

  void _showEditDialog(dynamic mess) {
    final editController = TextEditingController(text: mess.content);
    Get.dialog(
      AlertDialog(
        title: Text("Edit Message"),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(hintText: "Enter new message"),
          maxLines: null,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                controller.editMessage(mess, editController.text.trim());
                Get.back();
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(dynamic mess) {
    Get.dialog(
      AlertDialog(
        title: Text("Delete Message"),
        content: Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              controller.deleteMessage(mess);
              Get.back();
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showForwardBottomSheet(MessageModel message) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Chuyển tiếp đến",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: controller.getForwardableFriends(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "Không có bạn bè nào hợp lệ để chuyển tiếp",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final validFriends = snapshot.data!;

                  return ListView.builder(
                    itemCount: validFriends.length,
                    itemBuilder: (context, index) {
                      final user = validFriends[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryColor,
                          child: user.photoUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    user.photoUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        title: Text(user.displayName),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () {
                            controller.forwardMessage(message, user);
                            Get.back();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
