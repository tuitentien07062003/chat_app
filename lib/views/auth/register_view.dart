import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthController _authController = Get.find<AuthController>();
  bool _obsecurePassword = true;
  bool _obsecureConfirmPassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.arrow_back),
                    ),
                    SizedBox(width: 8),
                    Center(
                      child: Text(
                        "Create Account",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    "Let's get started with creating your account. Fill in the details below.",
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
                SizedBox(height: 20),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: "Display Name",
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: "Enter your display name",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Display name is required";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
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
                SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obsecureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: "Re-enter your password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obsecureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obsecureConfirmPassword = !_obsecureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isEmpty) {
                      return "Please confirm your password";
                    }
                    if (value != _passwordController.text) {
                      return "Passwords do not match";
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
                                _authController.registerWithEmailAndPassword(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                  _displayNameController.text.trim(),
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
                          : Text("Create Account"),
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
                      "Already have an account?",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(AppRoutes.login);
                      },
                      child: Text(
                        " Sign In",
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
