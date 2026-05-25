import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final Rx<User?> _user = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxString _errorMessage = ''.obs;
  final RxBool _isInitialized = false.obs;

  User? get user => _user.value;
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => _currentUser.value;
  String get errorMessage => _errorMessage.value;
  bool get isInitialized => _isInitialized.value;
  bool get isAuthenticated => _user.value != null;

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_authService.authStateChanges);
    ever(_user, _handleAuthStateChanged);
  }

  void _handleAuthStateChanged(User? user) {
    // if (user == null) {
    //   if (Get.currentRoute != AppRoutes.login) {
    //     Get.offAllNamed(AppRoutes.login);
    //   }
    // } else {
    //   if (Get.currentRoute != AppRoutes.main) {
    //     Get.offAllNamed(AppRoutes.main);
    //   }
    // }
    // if (!_isInitialized.value) {
    //   _isInitialized.value = true;
    // }

    if (user == null) {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    } else {
      _firestoreService.setupUserPresence(user.uid);

      if (Get.currentRoute != AppRoutes.main) {
        Get.offAllNamed(AppRoutes.main);
      }
    }
    if (!_isInitialized.value) {
      _isInitialized.value = true;
    }
  }

  void checkInitialAuthState() {
    // final currentUser = FirebaseAuth.instance.currentUser;
    // if (currentUser != null) {
    //   _user.value = currentUser;
    //   Get.offAllNamed(AppRoutes.main);
    // } else {
    //   Get.offAllNamed(AppRoutes.login);
    // }
    // _isInitialized.value = true;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user.value = currentUser;

      _firestoreService.setupUserPresence(currentUser.uid);

      Get.offAllNamed(AppRoutes.main);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
    _isInitialized.value = true;
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      UserModel? userModel = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (userModel != null) {
        _currentUser.value = userModel;
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Login Error',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      UserModel? userModel = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      if (userModel != null) {
        _currentUser.value = userModel;
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Register Error',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      // _isLoading.value = true;
      // await _authService.signOut();
      // _currentUser.value = null;
      // Get.offAllNamed(AppRoutes.login);

      _isLoading.value = true;

      if (_user.value != null) {
        await _firestoreService.clearUserPresence(_user.value!.uid);
      }

      await _authService.signOut();
      _currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Logout Error',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      await _authService.deleteAccount();
      _currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Delete Account Error',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void clearErrorMessage() {
    _errorMessage.value = '';
  }
}
