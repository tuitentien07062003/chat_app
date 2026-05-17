import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';

class FriendRequestItem extends StatelessWidget {
  final FriendRequestModel req;
  final UserModel user;
  final String timeText;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final String? statusText;
  final Color? statusColor;

  const FriendRequestItem({
    super.key,
    required this.req,
    required this.user,
    required this.timeText,
    required this.isReceived,
    this.onAccept,
    this.onDecline,
    this.statusText,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor,
                  child: user.photoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            user.photoUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeText,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondaryColor),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isReceived && req.status == FriendRequestStatus.pending) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: Icon(Icons.close),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                      label: Text("Decline"),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: Icon(Icons.check),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                      label: Text("Accept"),
                    ),
                  ),
                ],
              ),
            ] else if (!isReceived && statusText != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: statusColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor ?? AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(), size: 16, color: statusColor),
                    SizedBox(width: 6),
                    Text(
                      statusText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor ?? AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (req.status) {
      case FriendRequestStatus.accepted:
        return Icons.check_circle;
      case FriendRequestStatus.declined:
        return Icons.cancel;
      case FriendRequestStatus.pending:
        return Icons.check_circle;
      default:
        return Icons.hourglass_top;
    }
  }
}
