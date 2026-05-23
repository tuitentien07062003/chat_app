import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final bool showTime;
  final String timeText;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeToReply;
  final VoidCallback? onReplySnippetTap;

  final String? dynamicReplyContent;

  final bool isHighlighted;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.showTime,
    required this.timeText,
    this.onLongPress,
    this.onSwipeToReply,
    this.onReplySnippetTap,
    this.dynamicReplyContent,
    this.isHighlighted = false,
  });

  String _getFormattedTime() {
    final dynamic timeData = message.timestamp;
    DateTime time;

    if (timeData is int) {
      time = DateTime.fromMillisecondsSinceEpoch(timeData);
    } else if (timeData is DateTime) {
      time = timeData;
    } else {
      time = DateTime.now();
    }

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    if (message.isEdited && !message.isDeleted) {
      return "$hour:$minute Edited";
    }
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      color: isHighlighted
          ? Colors.yellow.withOpacity(0.3)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Dismissible(
        key: ValueKey(message.id),
        direction: isMyMessage
            ? DismissDirection.endToStart
            : DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          if (!message.isDeleted) {
            onSwipeToReply?.call();
          }
          return false;
        },
        background: Container(
          alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Icon(Icons.reply_rounded, color: AppTheme.primaryColor),
        ),
        child: Column(
          children: [
            if (showTime) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 4),
            Row(
              mainAxisAlignment: isMyMessage
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isMyMessage) ...[const SizedBox(width: 8)],
                Flexible(
                  child: GestureDetector(
                    onLongPress: onLongPress,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isMyMessage
                            ? AppTheme.primaryColor
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMyMessage ? 20 : 4),
                          bottomRight: Radius.circular(isMyMessage ? 4 : 20),
                        ),
                        border: isMyMessage
                            ? null
                            : Border.all(color: AppTheme.borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.replyToId != null &&
                                    !message.isDeleted)
                                  GestureDetector(
                                    onTap: onReplySnippetTap,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border(
                                          left: BorderSide(
                                            color: isMyMessage
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.replyToSenderId ==
                                                    message.senderId
                                                ? "Đã trả lời chính mình"
                                                : "Đã trả lời",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isMyMessage
                                                  ? Colors.white70
                                                  : AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dynamicReplyContent ?? "Tin nhắn",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isMyMessage
                                                  ? Colors.white
                                                  : AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                _buildMessageContent(context),

                                if (!message.isDeleted) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        _getFormattedTime(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              color: isMyMessage
                                                  ? Colors.white.withOpacity(
                                                      0.65,
                                                    )
                                                  : AppTheme.textSecondaryColor,
                                              fontStyle: message.isEdited
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (message.reactions != null &&
                              message.reactions!.isNotEmpty)
                            Positioned(
                              bottom: -20,
                              right: isMyMessage ? 4 : null,
                              left: !isMyMessage ? 4 : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: message.reactions!.entries.map((
                                    entry,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isMyMessage) ...[
                  const SizedBox(width: 8),
                  _buildMessageStatus(),
                ],
              ],
            ),

            if (message.reactions != null && message.reactions!.isNotEmpty)
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Icon(
        message.isRead ? Icons.done_all : Icons.done,
        size: 16,
        color: message.isRead
            ? AppTheme.primaryColor
            : AppTheme.textSecondaryColor,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.isDeleted) {
      return Text(
        message.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isMyMessage ? Colors.white.withOpacity(0.6) : Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.content,
            width: MediaQuery.of(context).size.width * 0.6,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 200,
                color: isMyMessage ? Colors.white24 : Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    color: isMyMessage ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image,
              size: 50,
              color: isMyMessage ? Colors.white : Colors.grey,
            ),
          ),
        );

      case MessageType.file:
        final splitData = message.content.split('|');
        final fileUrl = splitData[0];
        final fileName = splitData.length > 1
            ? splitData[1]
            : "Tập tin đính kèm";

        return GestureDetector(
          onTap: () async {
            try {
              final Uri url = Uri.parse(fileUrl);
              if (await canLaunchUrl(url)) {
                // Dùng LaunchMode.externalApplication để mở bằng trình duyệt/app bên ngoài
                // Việc này giúp HĐH tự động xử lý việc tải file (PDF, DOCX, ZIP...) rất mượt
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                debugPrint("Không thể mở đường dẫn: $fileUrl");
              }
            } catch (e) {
              debugPrint("Lỗi khi mở file: $e");
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMyMessage
                  ? Colors.black.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: isMyMessage ? Colors.white : AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      color: isMyMessage
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: message.isDeleted
                ? (isMyMessage
                      ? Colors.white.withOpacity(0.6)
                      : Colors.grey[500])
                : (isMyMessage ? Colors.white : AppTheme.textPrimaryColor),
            fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
          ),
        );
    }
  }
}
