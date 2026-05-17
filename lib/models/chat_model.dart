class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;
  final Map<String, bool> deletedBy;
  final Map<String, DateTime?> deletedAt;
  final Map<String, DateTime?> lastSeenBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCounts,
    this.deletedBy = const {},
    this.deletedAt = const {},
    this.lastSeenBy = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt.map(
        (key, value) => MapEntry(key, value?.millisecondsSinceEpoch),
      ),
      'lastSeenBy': lastSeenBy.map(
        (key, value) => MapEntry(key, value?.millisecondsSinceEpoch),
      ),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static ChatModel fromMap(Map<String, dynamic> map) {
    Map<String, DateTime?> lastSeenMap = {};
    if (map['lastSeenBy'] != null) {
      Map<String, dynamic> rawLastSeen = Map<String, dynamic>.from(
        map['lastSeenBy'],
      );
      lastSeenMap = rawLastSeen.map(
        (key, value) => MapEntry(
          key,
          value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null,
        ),
      );
    }

    Map<String, DateTime?> deletedAtMap = {};
    if (map['deletedAt'] != null) {
      Map<String, dynamic> rawDeletedAt = Map<String, dynamic>.from(
        map['deletedAt'],
      );
      deletedAtMap = rawDeletedAt.map(
        (key, value) => MapEntry(
          key,
          value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null,
        ),
      );
    }

    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      deletedBy: Map<String, bool>.from(map['deletedBy'] ?? {}),
      deletedAt: deletedAtMap,
      lastSeenBy: lastSeenMap,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
    Map<String, bool>? deletedBy,
    Map<String, DateTime?>? deletedAt,
    Map<String, DateTime?>? lastSeenBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSeenBy: lastSeenBy ?? this.lastSeenBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool isDeletedBy(String userId) {
    return deletedBy[userId] ?? false;
  }

  DateTime? getDeletedAt(String userId) {
    return deletedAt[userId];
  }

  DateTime? getLastSeenBy(String userId) {
    return lastSeenBy[userId];
  }

  bool isMessageSeen(String currentUserId, String otherUserId) {
    if (lastMessageSenderId == currentUserId) {
      final otherUserLastSeen = getLastSeenBy(otherUserId);
      if (otherUserLastSeen == null || lastMessageTime == null) {
        return false;
      }
      return otherUserLastSeen.isAfter(lastMessageTime!) ||
          otherUserLastSeen.isAtSameMomentAs(lastMessageTime!);
    }
    return false;
  }
}
