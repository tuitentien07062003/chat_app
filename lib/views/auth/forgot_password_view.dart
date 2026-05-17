import 'package:chat_app/controllers/forgot_password_controller.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Row(
                children: [
                  IconButton(
                    onPressed: controller.goBackToLogin,
                    icon: Icon(Icons.arrow_back),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Forgot Password",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 56),
                child: Text(
                  "Enter your email address to receive a password reset link.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              SizedBox(height: 60),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Obx(() {
                if (controller.emailSent) {
                  return _buildEmailSentView(controller);
                } else {
                  return _buildEmailForm(controller);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(ForgotPasswordController controller) {
    return Column(
      children: [
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email_outlined),
            hintText: "Enter your email",
          ),
          validator: controller.validateEMail,
        ),
        SizedBox(height: 40),
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : controller.sendPasswordResetEmail,
              icon: controller.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send),
              label: Text(
                controller.isLoading ? "Sending..." : "Send Reset Link",
              ),
            ),
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Remember your password?",
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
            SizedBox(width: 4),
            GestureDetector(
              onTap: controller.goBackToLogin,
              child: Text(
                "Sign In",
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSentView(ForgotPasswordController controller) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                size: 60,
                color: AppTheme.successColor,
              ),
              SizedBox(height: 16),
              Text(
                "Email sent!",
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                controller.emailController.text.trim(),
                style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Please check your inbox for the password reset link.",
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.successColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.resendEmail,
            icon: Icon(Icons.refresh),
            label: Text("Resend Email"),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.goBackToLogin,
            icon: Icon(Icons.arrow_back),
            label: Text("Back to Sign In"),
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.secondaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "If you don't see the email, please check your spam folder or try resending.",
                  style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryColor.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
