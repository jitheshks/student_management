import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/custom_text_form_field.dart';
import 'package:student_management/controller/login_screen_controller.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LoginScreenController>(context, listen: false);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32.0),
                 CustomTextFormField(
  controller: controller.emailController,
  labelText: 'Email',
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  textCapitalization: TextCapitalization.none,
  validator: (value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  },
),

                  const SizedBox(height: 16.0),
                CustomTextFormField(
  controller: controller.passwordController,
  labelText: 'Password',
  prefixIcon: Icons.lock,
  obscureText: true, // start hidden
  hasToggle: true,   // 👈 enables eye toggle
  textCapitalization: TextCapitalization.none,
  validator: (value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters long';
    return null;
  },
),

                  const SizedBox(height: 24.0),

                  /// 🟢 Optimized Button
                  Consumer<LoginScreenController>(
                    builder: (context, controller, child) {
                      return ElevatedButton(
                        onPressed: controller.isLoading
                            ? null
                            : () {
                                if (formKey.currentState?.validate() == true) {
                                  controller.login(context);
                                }
                              },
                        child: controller.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Login'),
                      );
                    },
                  ),

                  const SizedBox(height: 12.0),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/resetPassword');
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
