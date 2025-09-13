import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/custom_text_form_field.dart';
import 'package:student_management/controller/forgot_password_screen_controller.dart';
import 'package:student_management/services/nav_service.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ForgotPasswordScreenController>();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
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
                    "Forgot Password",
                    style: TextStyle(
                        fontSize: 32.0, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    "Enter the email address associated with your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 28.0),
                  CustomTextFormField(
                    controller: controller.emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<ForgotPasswordScreenController>(
                    builder: (context, ctrl, _) => ElevatedButton(
                      onPressed: ctrl.isLoading
    ? null
    : () async {
        if (formKey.currentState?.validate() != true) return;

        final email = ctrl.emailController.text.trim();
        debugPrint('Forgot: requesting OTP for $email');

        // 1) Show spinner
        ctrl.setLoading(true);

        // 2) Send OTP
        final success = await ctrl.requestOtp();

        // 3) Stop spinner
        ctrl.setLoading(false);

        // 4) Prevent invalid context usage
        if (!context.mounted) return;

        // 5) Navigate only on success
if (success) {
  debugPrint('Forgot: navigating to /verifyOtp with $email');
  NavService.navigatorKey.currentState?.pushNamed(
    '/verifyOtp',
    arguments: {'email': email},
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Failed to send OTP')),
  );
}


      }
,
                      child: ctrl.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Request OTP"),
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
