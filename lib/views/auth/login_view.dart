import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  bool _obsecurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Center(
                  child: Text(
                    "Welcome Back",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    "Please sign in to continue",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: "Enter your email",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!GetUtils.isEmail(value)) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obsecurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outlined),
                    hintText: "Enter your password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obsecurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obsecurePassword = !_obsecurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 28),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authController.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _authController.signInWithEmailAndPassword(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                              }
                            },
                      child: _authController.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text("Sign In"),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.forgotPassword);
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "OR",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                  ],
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(AppRoutes.register);
                      },
                      child: Text(
                        " Sign Up",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
