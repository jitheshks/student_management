import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/custom_text_form_field.dart';
import 'package:student_management/controller/create_new_password_controller.dart';

class CreateNewPasswordScreen extends StatelessWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CreateNewPasswordController>();
    final formKey = GlobalKey<FormState>();
    final passwordNode = FocusNode();
    final confirmNode = FocusNode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter New Password'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Your new password must be different from previously used passwords',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Password
                 CustomTextFormField(
  controller: ctrl.passwordController,
  labelText: 'Password',
  prefixIcon: Icons.lock,
  obscureText: true,
  hasToggle: true,
  focusNode: passwordNode,
  validator: (v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Enter a password';
    if (val.length < 6) return 'Min 6 characters';
    return null;
  },
),

                  const SizedBox(height: 16),

                  // Confirm password
              CustomTextFormField(
  controller: ctrl.confirmController,
  labelText: 'Confirm password',
  prefixIcon: Icons.lock,
  obscureText: true,
  hasToggle: true,
  focusNode: confirmNode,
  validator: (v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Confirm the password';
    if (val != ctrl.passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  },
),

                  const SizedBox(height: 24),

                  // Change password
                  ElevatedButton(
                    onPressed: ctrl.isSubmitting
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() != true) return;
                            final ok = await context.read<CreateNewPasswordController>().changePassword(
                              onError: (msg) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              },
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password changed successfully')),
                              );
                              // Decide where to go next; often back to login
                              Navigator.pushNamedAndRemoveUntil(context, '/loginScreen', (_) => false);
                            }
                          },
                    child: ctrl.isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Change password'),
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
