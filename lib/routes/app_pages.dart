import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/controllers/friend_requests_controller.dart';
import 'package:chat_app/controllers/friends_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/controllers/main_controller.dart';
import 'package:chat_app/controllers/notifications_controller.dart';
import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/views/auth/forgot_password_view.dart';
import 'package:chat_app/views/auth/login_view.dart';
import 'package:chat_app/views/auth/register_view.dart';
import 'package:chat_app/views/auth/splash_view.dart';
import 'package:chat_app/views/blocked_user_view.dart';
import 'package:chat_app/views/chat_view.dart';
import 'package:chat_app/views/find_people_view.dart';
import 'package:chat_app/views/friend_requests_view.dart';
import 'package:chat_app/views/friends_view.dart';
import 'package:chat_app/views/home_view.dart';
import 'package:chat_app/views/main_view.dart';
import 'package:chat_app/views/notification_view.dart';
import 'package:chat_app/views/profile/change_password_view.dart';
import 'package:chat_app/views/profile/profile_view.dart';
import 'package:chat_app/views/widgets/users_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(
      name: AppRoutes.home,
      page: () => HomeScreen(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => MainScreen(),
      binding: BindingsBuilder(() {
        Get.put(MainController());
      }),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
    ),
    // GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    // GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      binding: BindingsBuilder(() {
        Get.put(ChatController());
      }),
    ),
    GetPage(
      name: AppRoutes.usersList,
      page: () => FindPeopleScreen(),
      binding: BindingsBuilder(() {
        Get.put(UsersListController());
      }),
    ),
    GetPage(
      name: AppRoutes.friends,
      page: () => FriendsScreen(),
      binding: BindingsBuilder(() {
        Get.put(FriendsController());
      }),
    ),
    GetPage(
      name: AppRoutes.friendRequests,
      page: () => FriendRequestsScreen(),
      binding: BindingsBuilder(() {
        Get.put(FriendRequestsController());
      }),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => NotificationScreen(),
      binding: BindingsBuilder(() {
        Get.put(NotificationsController());
      }),
    ),
    GetPage(
      name: AppRoutes.blockedUser,
      page: () => BlockedUsersScreen(),
      binding: BindingsBuilder(() {
        Get.put(UsersListController());
      }),
    ),
  ];
}
