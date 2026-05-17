import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _obscureCurrentPassword = true.obs;
  final RxBool _obscureNewPassword = true.obs;
  final RxBool _obscureConfirmPassword = true.obs;

  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get obscureCurrentPassword => _obscureCurrentPassword.value;
  bool get obscureNewPassword => _obscureNewPassword.value;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage.value = "User not authenticated.";
        return;
      }

      await user.updatePassword(newPasswordController.text.trim());

      await _authController.signOut();

      Get.snackbar(
        "Success",
        "Password changed successfully. Please log in again.",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: Duration(seconds: 4),
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = "Current password is incorrect.";
          break;
        case 'weak-password':
          message = "The new password is too weak.";
          break;
        case 'requires-recent-login':
          message = "Please log in again to change your password.";
          break;
        default:
          message = e.message ?? "An error occurred while changing password.";
      }
      Get.snackbar(
        "Error",
        message,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  String? validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'New password is required';
    }
    if (value.trim().length < 6) {
      return 'New password must be at least 6 characters';
    }

    if (value.trim() == currentPasswordController.text.trim()) {
      return 'New password cannot be the same as current password';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your new password';
    }
    if (value.trim() != newPasswordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
