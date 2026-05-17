import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _authService = AuthService();
  final RxBool _isLoading = false.obs;
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RxString _errorMessage = ''.obs;
  final RxBool _emailSent = false.obs;

  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get emailSent => _emailSent.value;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      await _authService.sendPasswordResetEmail(emailController.text.trim());
      _emailSent.value = true;

      Get.snackbar(
        "Success",
        "Password reset email sent. Please check your inbox.",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        "Error",
        _errorMessage.value,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void goBackToLogin() {
    Get.back();
  }

  void resendEmail() {
    _emailSent.value = false;
    sendPasswordResetEmail();
  }

  String? validateEMail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
