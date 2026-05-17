import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isEditing
                  ? controller.toggleEditing
                  : controller.toggleEditing,
              child: Text(
                controller.isEditing ? "Cancel" : "Edit",
                style: TextStyle(
                  color: controller.isEditing
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Obx(() {
        final user = controller.currentUser;
        if (user == null) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor,
                        child: user.photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  user.photoUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar(user);
                                  },
                                ),
                              )
                            : _buildDefaultAvatar(user),
                      ),

                      if (controller.isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.8),
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Get.snackbar(
                                  'Info',
                                  'Change profile picture feature is not implemented yet.',
                                );
                              },
                              icon: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: Theme.of(Get.context!).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    user.email,
                    style: Theme.of(Get.context!).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSecondaryColor),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: user.isOnline
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: user.isOnline
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          user.isOnline ? "Online" : "Offline",
                          style: Theme.of(Get.context!).textTheme.bodySmall
                              ?.copyWith(
                                color: user.isOnline
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    controller.getJoinedData(),
                    style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Obx(
                () => Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "User Information",
                          style: Theme.of(Get.context!).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: controller.displayNameController,
                          enabled: controller.isEditing,
                          decoration: InputDecoration(
                            labelText: "Display Name",
                            prefix: Icon(Icons.person_outline),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: controller.emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefix: Icon(Icons.email_outlined),
                          ),
                        ),
                        if (controller.isEditing) ...[
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.isLoading
                                  ? null
                                  : controller.updateProfile,
                              child: controller.isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text("Save Changes"),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.security,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text("Change Password"),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Get.toNamed(AppRoutes.changePassword),
                    ),
                    Divider(height: 1, color: Colors.grey),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: AppTheme.errorColor,
                      ),
                      title: Text("Delete Account"),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: controller.deleteAccount,
                    ),
                    Divider(height: 1, color: Colors.grey),
                    ListTile(
                      leading: Icon(
                        Icons.logout_outlined,
                        color: AppTheme.accentColor,
                      ),
                      title: Text("Sign Out"),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: controller.signOut,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "App Version 1.0.0",
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDefaultAvatar(dynamic user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : "U",
      style: TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
