import 'dart:async';

import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/call_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:get/get.dart' hide navigator;
import 'package:uuid/uuid.dart';

class CallController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = const Uuid();

  // ====== BIẾN TRẠNG THÁI WEB RTC ======
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  Rx<CallModel?> currentCall = Rx<CallModel?>(null);
  RxBool isMicOn = true.obs;

  DateTime? _callStartTime;
  StreamSubscription<CallModel>? _callStatusSubscription;
  StreamSubscription<List<CallModel>>? _incomingCallSubscription;

  RxString callDurationText = "00:00".obs;
  Timer? _durationTimer;

  // Máy chủ STUN miễn phí của Google để dò IP thiết bị
  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  @override
  void onInit() {
    super.onInit();
    _listenForIncomingCalls();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel(); // Đảm bảo không bị trùng lặp timer cũ
    callDurationText.value = "00:00";

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStartTime == null) return;

      final duration = DateTime.now().difference(_callStartTime!);
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');

      // Nếu cuộc gọi kéo dài hơn 1 tiếng thì thêm giờ vào
      if (duration.inHours > 0) {
        final hours = duration.inHours.toString().padLeft(2, '0');
        callDurationText.value = "$hours:$minutes:$seconds";
      } else {
        callDurationText.value = "$minutes:$seconds";
      }
    });
  }

  // 3. Hàm hủy timer khi cuộc gọi kết thúc (Cực kỳ quan trọng để tránh rò rỉ bộ nhớ)
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  // 1. Tự động lắng nghe nếu có người gọi mình
  void _listenForIncomingCalls() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    _incomingCallSubscription = _firestoreService
        .streamIncomingCalls(currentUserId)
        .listen((calls) {
          if (calls.isNotEmpty && currentCall.value == null) {
            final incomingCall = calls.first;
            currentCall.value = incomingCall;

            // Kích hoạt lắng nghe chi tiết trạng thái cuộc gọi ngay lập tức
            listenToCallStatus(incomingCall.id);

            Get.toNamed(AppRoutes.call);
          }
        });
  }

  // 2. Lắng nghe trạng thái xuyên suốt cuộc gọi (Bao gồm bắt máy, SDP Answer, Kết thúc)
  void listenToCallStatus(String callId) {
    _callStatusSubscription?.cancel();
    _callStatusSubscription = _firestoreService.streamCallStatus(callId).listen((
      call,
    ) async {
      currentCall.value = call;

      // Xử lý khi cuộc gọi được chấp nhận
      if (call.status == CallStatus.accepted) {
        // Ghi nhận thời gian bắt đầu nói chuyện
        if (_callStartTime == null) {
          _callStartTime = DateTime.now();
          _startDurationTimer();
        }

        // Dành cho Caller: Đọc SDP Answer của Callee để kết nối WebRTC thành công
        if (call.answer.isNotEmpty && peerConnection != null) {
          var answerState = await peerConnection?.getRemoteDescription();
          if (answerState == null) {
            await peerConnection?.setRemoteDescription(
              RTCSessionDescription(call.answer['sdp'], call.answer['type']),
            );
          }
        }
      }

      // Xử lý khi đối phương ngắt máy hoặc từ chối
      if (call.status == CallStatus.ended ||
          call.status == CallStatus.rejected) {
        _handleCallTermination(call);
      }
    });
  }

  // 3. Hàm xử lý kết thúc cuộc gọi đồng bộ cho cả 2 bên
  void _handleCallTermination(CallModel call) async {
    _callStatusSubscription?.cancel();
    _callStatusSubscription = null;

    _stopDurationTimer();
    callDurationText.value = "00:00";

    // Chỉ duy nhất Người gọi (Caller) mới ghi lịch sử để tránh trùng lặp tin nhắn
    await _saveCallHistoryMessage(call);

    // Dọn dẹp kết nối WebRTC
    await _cleanUpWebRTC();

    // Set biến về null để giải phóng UI
    currentCall.value = null;

    // Đưa người dùng về màn hình trước đó nếu đang ở màn hình gọi điện
    if (Get.currentRoute == AppRoutes.call) {
      Get.back();
    }
  }

  // 4. Tắt mic / dọn dẹp luồng dữ liệu WebRTC
  Future<void> _cleanUpWebRTC() async {
    try {
      isMicOn.value = true;
      _callStartTime = null;

      if (localStream != null) {
        localStream!.getTracks().forEach((track) => track.stop());
        await localStream!.dispose();
        localStream = null;
      }
      if (remoteStream != null) {
        remoteStream!.getTracks().forEach((track) => track.stop());
        await remoteStream!.dispose();
        remoteStream = null;
      }
      if (peerConnection != null) {
        await peerConnection!.close();
        peerConnection = null;
      }
    } catch (e) {
      print("Lỗi khi dọn dẹp WebRTC: $e");
    }
  }

  // 5. Mở Mic cho cuộc gọi thoại (Không Video)
  Future<void> openMediaStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  // 6. Hàm cấu hình PeerConnection (Dùng chung)
  Future<void> _setupPeerConnection(
    String callId, {
    required bool isCaller,
  }) async {
    peerConnection = await createPeerConnection(configuration);

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onAddStream = (MediaStream stream) {
      print("ĐÃ NHẬN ĐƯỢC STREAM CỦA ĐỐI PHƯƠNG!");
      remoteStream = stream;
      // Bật loa ngoài mặc định cho luồng âm thanh
      Helper.setSpeakerphoneOn(true);
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _firestoreService.addCandidate(
          callId,
          isCaller ? 'callerCandidates' : 'calleeCandidates',
          candidate.toMap(),
        );
      }
    };
  }

  // 7. HÀM TẠO CUỘC GỌI ĐI (DÀNH CHO CALLER)
  Future<void> makeCall({
    required String calleeId,
    required String calleeName,
    required String calleePic,
  }) async {
    final currentUser = _authController.user;
    if (currentUser == null) return;

    final callId = _uuid.v4();

    try {
      await openMediaStream();
      await _setupPeerConnection(callId, isCaller: true);

      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      final call = CallModel(
        id: callId,
        callerId: currentUser.uid,
        callerName: currentUser.displayName ?? "Vô danh",
        callerPic: currentUser.photoURL ?? "",
        calleeId: calleeId,
        calleeName: calleeName,
        calleePic: calleePic,
        status: CallStatus.calling,
        offer: offer.toMap(),
        createdAt: DateTime.now(),
      );

      currentCall.value = call;
      await _firestoreService.createCall(call);

      // Khởi động luồng lắng nghe chính
      listenToCallStatus(callId);

      // Lắng nghe ICE Candidates của đối phương
      _firestoreService.streamCandidates(callId, 'calleeCandidates').listen((
        candidates,
      ) {
        for (var candidateMap in candidates) {
          peerConnection?.addCandidate(
            RTCIceCandidate(
              candidateMap['candidate'],
              candidateMap['sdpMid'],
              candidateMap['sdpMLineIndex'],
            ),
          );
        }
      });

      Get.toNamed(AppRoutes.call);
    } catch (e) {
      print("Lỗi tạo cuộc gọi: $e");
      endCall();
    }
  }

  // 8. HÀM BẮT MÁY (DÀNH CHO CALLEE)
  Future<void> answerCall() async {
    final call = currentCall.value;
    if (call == null) return;

    try {
      // Báo Firestore là mình đã bắt máy
      await _firestoreService.updateCallStatus(call.id, CallStatus.accepted);

      _callStartTime ??= DateTime.now();
      await openMediaStream();
      await _setupPeerConnection(call.id, isCaller: false);

      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(call.offer['sdp'], call.offer['type']),
      );

      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);
      await _firestoreService.updateCallData(call.id, 'answer', answer.toMap());

      _firestoreService.streamCandidates(call.id, 'callerCandidates').listen((
        candidates,
      ) {
        for (var candidateMap in candidates) {
          peerConnection?.addCandidate(
            RTCIceCandidate(
              candidateMap['candidate'],
              candidateMap['sdpMid'],
              candidateMap['sdpMLineIndex'],
            ),
          );
        }
      });
      // (Không cần lắng nghe `streamCallStatus` ở đây nữa vì `_listenForIncomingCalls` đã làm việc đó rồi)
    } catch (e) {
      print("Lỗi bắt máy: $e");
      endCall();
    }
  }

  // 9. HÀM CHỦ ĐỘNG CÚP MÁY HOẶC TỪ CHỐI
  Future<void> endCall() async {
    final call = currentCall.value;
    if (call == null) return;

    try {
      CallStatus finalStatus =
          (call.status == CallStatus.calling ||
              call.status == CallStatus.ringing)
          ? CallStatus.rejected
          : CallStatus.ended;

      await _firestoreService.updateCallStatus(call.id, finalStatus);
      _handleCallTermination(call);
    } catch (e) {
      print("Lỗi khi kết thúc cuộc gọi: $e");
      _handleCallTermination(call);
    }
  }

  // 10. BẬT/TẮT MIC
  void toggleMic() {
    if (localStream != null) {
      isMicOn.value = !isMicOn.value;
      localStream!.getAudioTracks().forEach((track) {
        track.enabled = isMicOn.value;
      });
    }
  }

  // 11. HÀM LƯU LỊCH SỬ BUBBLE MESSAGE
  Future<void> _saveCallHistoryMessage(CallModel call) async {
    final String currentUserId = _authController.user?.uid ?? "";
    if (currentUserId.isEmpty) return;
    if (currentUserId != call.callerId) return; // Chỉ Caller lưu tin nhắn

    String durationText = "";
    bool isMissedCall = true;

    if (_callStartTime != null || call.status == CallStatus.ended) {
      isMissedCall = false;
    }

    if (!isMissedCall && _callStartTime != null) {
      final duration = DateTime.now().difference(_callStartTime!);
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      durationText = " ($minutes:$seconds)";
    }

    String messageContent = isMissedCall
        ? "Cuộc gọi thoại nhỡ"
        : "Cuộc gọi thoại đã kết thúc$durationText";

    final receiverId = (currentUserId == call.callerId)
        ? call.calleeId
        : call.callerId;

    try {
      final messageId = FirebaseFirestore.instance
          .collection('messages')
          .doc()
          .id;
      final callMessage = MessageModel(
        id: messageId,
        senderId: currentUserId,
        receiverId: receiverId,
        content: messageContent,
        type: MessageType.call,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestoreService.sendMessage(callMessage);
    } catch (e) {
      print("Lỗi khi lưu lịch sử cuộc gọi: $e");
    }
  }

  @override
  void onClose() {
    _incomingCallSubscription?.cancel();
    _callStatusSubscription?.cancel();
    _cleanUpWebRTC();
    super.onClose();
  }
}
