class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    if (value is DateTime) return value;

    if (value is Object && value.toString().startsWith('Timestamp')) {
      try {
        final dynamic ts = value;
        if (ts.toDate != null) return ts.toDate() as DateTime;
      } catch (_) {}
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: _parseDate(map['lastSeen']),
      createdAt: _parseDate(map['createdAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
