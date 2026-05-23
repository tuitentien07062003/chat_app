import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/call_controller.dart';
import 'package:chat_app/models/call_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallScreen extends StatelessWidget {
  CallScreen({super.key});

  final CallController _callController = Get.find<CallController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Nền màu tối sang trọng
      body: SafeArea(
        child: Obx(() {
          final call = _callController.currentCall.value;

          // Nếu mất dữ liệu cuộc gọi thì tự động back về
          if (call == null) {
            Future.microtask(() => Get.back());
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final currentUserId = _authController.user?.uid;
          final isCallee = currentUserId == call.calleeId;
          final isIncoming =
              (call.status == CallStatus.calling ||
                  call.status == CallStatus.ringing) &&
              isCallee;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ==========================================
              // 1. PHẦN THÔNG TIN BÊN TRÊN (Avatar & Tên)
              // ==========================================
              Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: NetworkImage(
                        isCallee ? call.callerPic : call.calleePic,
                      ),
                      onBackgroundImageError: (_, __) => const Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      isCallee ? call.callerName : call.calleeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStatusText(call.status, isCallee),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 2. PHẦN NÚT ĐIỀU KHIỂN BÊN DƯỚI
              // ==========================================
              Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: isIncoming
                    ? _buildIncomingControls() // Bảng nút: Nghe / Từ chối
                    : _buildActiveControls(), // Bảng nút: Mic / Cúp máy
              ),
            ],
          );
        }),
      ),
    );
  }

  // --- UI: Bảng điều khiển khi ĐANG DIỄN RA CUỘC GỌI hoặc ĐANG GỌI ĐI ---
  Widget _buildActiveControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Nút tắt/bật Mic
        CircleAvatar(
          radius: 35,
          backgroundColor: _callController.isMicOn.value
              ? Colors.white24
              : Colors.white,
          child: IconButton(
            iconSize: 30,
            icon: Icon(
              _callController.isMicOn.value ? Icons.mic : Icons.mic_off,
              color: _callController.isMicOn.value
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: _callController.toggleMic,
          ),
        ),

        // Nút Cúp máy (Đỏ)
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.redAccent,
          child: IconButton(
            iconSize: 35,
            icon: const Icon(Icons.call_end, color: Colors.white),
            onPressed: () {
              _callController.endCall();
            },
          ),
        ),
      ],
    );
  }

  // --- UI: Bảng điều khiển khi CÓ NGƯỜI GỌI ĐẾN (Chỉ dành cho Callee) ---
  Widget _buildIncomingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Nút Từ chối (Đỏ)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.redAccent,
              child: IconButton(
                iconSize: 35,
                icon: const Icon(Icons.call_end, color: Colors.white),
                onPressed: () {
                  _callController.endCall();
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text("Từ chối", style: TextStyle(color: Colors.white70)),
          ],
        ),

        // Nút Bắt máy (Xanh)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green,
              child: IconButton(
                iconSize: 35,
                icon: const Icon(Icons.call, color: Colors.white),
                onPressed: () {
                  _callController.answerCall();
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text("Trả lời", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  // --- Helper: Dịch Enum ra text hiển thị ---
  String _getStatusText(CallStatus status, bool isCallee) {
    switch (status) {
      case CallStatus.calling:
        return "Đang kết nối...";
      case CallStatus.ringing:
        return isCallee ? "Cuộc gọi đến..." : "Đang đổ chuông...";
      case CallStatus.accepted:
        return _callController.callDurationText.value;
      case CallStatus.rejected:
        return "Người dùng bận";
      case CallStatus.ended:
        return "Cuộc gọi kết thúc";
    }
  }
}
