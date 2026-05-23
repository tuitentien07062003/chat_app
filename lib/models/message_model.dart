enum MessageType { text, icon, image, video, audio, file }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final DateTime? replyToTimestamp;
  final Map<String, String> reactions;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.type = MessageType.text,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
    this.deletedAt,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToTimestamp,
    this.reactions = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToSenderId': replyToSenderId,
      'replyToTimestamp': replyToTimestamp?.millisecondsSinceEpoch,
      'reactions': reactions,
    };
  }

  static MessageModel fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'])
          : null,
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      replyToSenderId: map['replyToSenderId'],
      replyToTimestamp: map['replyToTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['replyToTimestamp'])
          : null,
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    bool? isDeleted,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    DateTime? replyToTimestamp,
    Map<String, String>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToTimestamp: replyToTimestamp ?? this.replyToTimestamp,
      reactions: reactions ?? this.reactions,
    );
  }
}
