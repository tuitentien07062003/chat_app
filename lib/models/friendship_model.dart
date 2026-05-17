class FriendshipModel {
  final String id;
  final String userId;
  final String friendId;
  final DateTime createdAt;
  final bool isBlocked;
  final String? blockedBy;

  FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
    this.isBlocked = false,
    this.blockedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isBlocked': isBlocked,
      'blockedBy': blockedBy,
    };
  }

  static FriendshipModel fromMap(Map<String, dynamic> map) {
    return FriendshipModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      friendId: map['friendId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isBlocked: map['isBlocked'] ?? false,
      blockedBy: map['blockedBy'],
    );
  }

  FriendshipModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    DateTime? createdAt,
    bool? isBlocked,
    String? blockedBy,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == userId ? friendId : userId;
  }

  bool isBlockedBy(String userId) {
    return isBlocked && blockedBy == userId;
  }
}
