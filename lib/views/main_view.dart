import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/main_controller.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:chat_app/views/find_people_view.dart';
import 'package:chat_app/views/home_view.dart';
import 'package:chat_app/views/profile/profile_view.dart';
import 'package:chat_app/views/friends_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MainController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        children: [
          HomeScreen(),
          FriendsScreen(),
          FindPeopleScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex,
          onTap: controller.changeTabIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondaryColor,
          backgroundColor: Colors.white,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: _buildIconWithBadge(
                Icons.chat_outlined,
                controller.getUnreadCount(),
              ),
              activeIcon: _buildIconWithBadge(
                Icons.chat,
                controller.getUnreadCount(),
              ),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              activeIcon: Icon(Icons.person_search),
              label: 'Find Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(IconData icon, int count) {
    return Stack(
      children: [
        Icon(icon, size: 26),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: BoxConstraints(minHeight: 12, minWidth: 12),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(color: Colors.white, fontSize: 7),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
