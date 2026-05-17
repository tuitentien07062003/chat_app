import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    final AuthController _auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, _auth),
      body: Column(
        children: [
          _buildSearchBar(),
          Obx(
            () => controller.isSearching && controller.searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildQuickFilters(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthController authController,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimaryColor,
      elevation: 0,
      title: Obx(
        () => Text(
          controller.isSearching ? "Search Results" : "Messages",
          // style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      automaticallyImplyLeading: false,
      actions: [
        Obx(
          () => controller.isSearching
              ? IconButton(
                  onPressed: controller.clearSearch,
                  icon: Icon(Icons.clear_rounded),
                )
              : _buildNotiButton(),
        ),
      ],
    );
  }

  Widget _buildNotiButton() {
    return Obx(() {
      final unreadNoti = controller.getUnreadNotisCount();

      return Container(
        margin: EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: controller.openNotis,
                icon: Icon(Icons.notifications_outlined),
                iconSize: 22,
                splashRadius: 20,
              ),
            ),
            if (unreadNoti > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: BoxConstraints(minHeight: 16, minWidth: 16),
                  child: Text(
                    unreadNoti > 99 ? "99+" : unreadNoti.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 15, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: "Search conversations",
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
            prefixIcon: Icon(
              Icons.source_rounded,
              color: Colors.grey[500],
              size: 20,
            ),
            suffixIcon: Obx(
              () => controller.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: controller.clearSearch,
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                    )
                  : SizedBox.shrink(),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Obx(
              () => _buildFilterChip(
                "All",
                () => controller.setFilter("All"),
                controller.activeFilter == "All",
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                "Unread (${controller.getUnreadCount()})",
                () => controller.setFilter("Unread"),
                controller.activeFilter == "Unread",
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                "Recent (${controller.getRecentCount()})",
                () => controller.setFilter("Recent"),
                controller.activeFilter == "Recent",
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                "Active (${controller.getActiveCount()})",
                () => controller.setFilter("Active"),
                controller.activeFilter == "Active",
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 18, 8),
      child: Row(
        children: [
          Obx(
            () => Text(
              'Found ${controller.filteredChats.length} result${controller.filteredChats.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Spacer(),
          TextButton(
            onPressed: controller.clearSearch,
            child: Text(
              "Clear",
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                "No conversations found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Obx(
                () => Text(
                  "No results for ${controller.searchQuery}",
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFilterIcon(controller.activeFilter),
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                "No ${controller.activeFilter.toLowerCase()} conversations",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _getFilterEmptyMessage(controller.activeFilter),
                style: TextStyle(color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => controller.setFilter("All"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                ),
                child: Text("Show All Conversations"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
