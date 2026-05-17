import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _errorMessage = ''.obs;
  final Rx<UserModel?> _currentUser = Rxn<UserModel?>(null);

  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;
  String get errorMessage => _errorMessage.value;
  UserModel? get currentUser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    displayNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _currentUser.bindStream(_firestoreService.getUserStream(currentUserId));

      ever(_currentUser, (UserModel? user) {
        if (user != null) {
          displayNameController.text = user.displayName;
          emailController.text = user.email;
        }
      });
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;

    if (!_isEditing.value) {
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  Future<void> updateProfile() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final user = _currentUser.value;
      if (user == null) return;

      final updateUser = user.copyWith(
        displayName: displayNameController.text.trim(),
      );

      await _firestoreService.updateUser(updateUser);
      _isEditing.value = false;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      print('Error updating profile: ${e.toString()}');
      Get.snackbar('Error', errorMessage);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authController.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      print('Error signing out: ${e.toString()}');
      Get.snackbar('Error', 'An error occurred while signing out');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (result == true) {
        _isLoading.value = true;
        await _authController.deleteAccount();
        Get.offAllNamed('/login');
        Get.snackbar('Success', 'Account deleted successfully');
      }
    } catch (e) {
      print('Error deleting account: ${e.toString()}');
      Get.snackbar('Error', 'An error occurred while deleting account');
    } finally {
      _isLoading.value = false;
    }
  }

  String getJoinedData() {
    final user = _currentUser.value;
    if (user == null) return '';
    final date = user.createdAt;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return 'Joined: ${date.day}/${months[date.month - 1]}/${date.year}';
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
