import 'package:chat_app/controllers/change_password_controller.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());
    return Scaffold(
      appBar: AppBar(title: Text("Change Password")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Enter your new password below.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Enter your current password, then choose a new password to secure your account.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 32),
                Obx(
                  () => TextFormField(
                    controller: controller.currentPasswordController,
                    obscureText: controller.obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscureCurrentPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: controller.toggleCurrentPasswordVisibility,
                      ),
                      hintText: "Enter your current password",
                    ),
                    validator: controller.validateCurrentPassword,
                  ),
                ),
                SizedBox(height: 20),
                Obx(
                  () => TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: controller.obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscureNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: controller.toggleNewPasswordVisibility,
                      ),
                      hintText: "Enter your new password",
                    ),
                    validator: controller.validateNewPassword,
                  ),
                ),
                SizedBox(height: 20),
                Obx(
                  () => TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                      hintText: "Confirm your new password",
                    ),
                    validator: controller.validateConfirmPassword,
                  ),
                ),
                SizedBox(height: 40),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : controller.changePassword,
                      icon: controller.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.security_outlined),
                      label: Text(
                        controller.isLoading
                            ? "Updating..."
                            : "Change Password",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
