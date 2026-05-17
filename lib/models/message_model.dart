enum MessageType {
  text,
  // image,
  // video,
  // audio,
  // file,
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.type = MessageType.text,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.editedAt,
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
      'editedAt': editedAt?.millisecondsSinceEpoch,
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
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
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
    DateTime? editedAt,
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
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
