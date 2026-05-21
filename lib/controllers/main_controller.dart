import 'package:chat_app/controllers/friends_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/controllers/notifications_controller.dart';
import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  final PageController pageController = PageController();

  int get currentIndex => _currentIndex.value;

  @override
  void onInit() {
    super.onInit();

    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => FriendsController());
    Get.lazyPut(() => UsersListController());
    Get.lazyPut(() => ProfileController());

    Get.put(NotificationsController(), permanent: true);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void changeTabIndex(int index) {
    _currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void onPageChanged(int index) {
    _currentIndex.value = index;
  }

  int getUnreadCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getTotalUnreadCount();

      // return 5;
    } catch (e) {
      return 0;
    }
  }

  int getNotiCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getUnreadNotisCount();

      // return 36;
    } catch (e) {
      return 0;
    }
  }
}
