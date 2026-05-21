import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final bool showTime;
  final String timeText;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.showTime,
    required this.timeText,
    this.onLongPress,
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
    return Column(
      children: [
        if (showTime) ...[
          SizedBox(height: 16),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
          SizedBox(height: 16),
        ] else
          SizedBox(height: 4),
        Row(
          mainAxisAlignment: isMyMessage
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,

          children: [
            if (!isMyMessage) ...[SizedBox(width: 8)],
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? AppTheme.primaryColor
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: isMyMessage
                          ? Radius.circular(20)
                          : Radius.circular(4),
                      bottomRight: isMyMessage
                          ? Radius.circular(4)
                          : Radius.circular(20),
                    ),
                    border: isMyMessage
                        ? null
                        : Border.all(color: AppTheme.borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: message.isDeleted
                                    ? (isMyMessage
                                          ? Colors.white.withOpacity(0.6)
                                          : Colors.grey[500])
                                    : (isMyMessage
                                          ? Colors.white
                                          : AppTheme.textPrimaryColor),
                                fontStyle: message.isDeleted
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                        ),
                        if (!message.isDeleted) ...[
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                _getFormattedTime(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: isMyMessage
                                          ? Colors.white.withOpacity(0.65)
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
                ),
              ),
            ),
            if (isMyMessage) ...[SizedBox(width: 8), _buildMessageStatus()],
          ],
        ),
      ],
    );
  }

  Widget _buildMessageStatus() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Icon(
        message.isRead ? Icons.done_all : Icons.done,
        size: 16,
        color: message.isRead
            ? AppTheme.primaryColor
            : AppTheme.textSecondaryColor,
      ),
    );
  }
}
