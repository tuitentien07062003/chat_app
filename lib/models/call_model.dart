enum CallStatus { calling, ringing, accepted, rejected, ended }

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String callerPic;
  final String calleeId;
  final String calleeName;
  final String calleePic;
  final CallStatus status;
  final Map<String, dynamic> offer;
  final Map<String, dynamic> answer;
  final int duration;
  final DateTime createdAt;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerPic,
    required this.calleeId,
    required this.calleeName,
    required this.calleePic,
    required this.status,
    this.offer = const {},
    this.answer = const {},
    this.duration = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerPic': callerPic,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleePic': calleePic,
      'status': status.name,
      'offer': offer,
      'answer': answer,
      'duration': duration,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static CallModel fromMap(Map<String, dynamic> map) {
    return CallModel(
      id: map['id'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPic: map['callerPic'] ?? '',
      calleeId: map['calleeId'] ?? '',
      calleeName: map['calleeName'] ?? '',
      calleePic: map['calleePic'] ?? '',
      status: CallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CallStatus.calling,
      ),
      offer: Map<String, dynamic>.from(map['offer'] ?? {}),
      answer: Map<String, dynamic>.from(map['answer'] ?? {}),
      duration: map['duration'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerPic,
    String? calleeId,
    String? calleeName,
    String? calleePic,
    CallStatus? status,
    Map<String, dynamic>? offer,
    Map<String, dynamic>? answer,
    int? duration,
    DateTime? createdAt,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPic: callerPic ?? this.callerPic,
      calleeId: calleeId ?? this.calleeId,
      calleeName: calleeName ?? this.calleeName,
      calleePic: calleePic ?? this.calleePic,
      status: status ?? this.status,
      offer: offer ?? this.offer,
      answer: answer ?? this.answer,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
