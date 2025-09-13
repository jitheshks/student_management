import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:student_management/controller/otp_verification_controller.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Expecting arguments: {'email': String}
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final email = (args?['email'] as String?) ?? '';

    return const _OtpBody();
  }
}

class _OtpBody extends StatelessWidget {
  const _OtpBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OtpVerificationController>();

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter code'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Please enter the 6 digit that sent to your email address',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Pinput(
                    length: 6,
                    controller: ctrl.otpController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: Colors.blue),
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: Colors.red),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 16),
                // Resend row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "If you don’t receive the code? ",
                      style: TextStyle(fontSize: 13),
                    ),
                    if (!ctrl.canResend)
                      Text(
                        'Resend in ${_formatCooldown(ctrl.cooldown)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          await context.read<OtpVerificationController>().resendOtp(
                            onTooManyRequests: () {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Too many requests. Please try again later.'),
                                ),
                              );
                            },
                            onResent: () {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('A new code was sent to your email.')),
                              );
                            },
                            onError: (msg) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            },
                          );
                        },
                        child: const Text('Resend'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Verify button
ElevatedButton(
  onPressed: ctrl.isVerifying
      ? null
      : () async {
          await context.read<OtpVerificationController>().verifyAndProceed(
            context: context,
            onError: (msg) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            },
          );
        },
  child: ctrl.isVerifying
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
      : const Text('Verify and proceed'),
)


              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCooldown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    // Show mm:ss when >=60, else ss
    return seconds >= 60 ? '$m:$s' : '$s';
  }
}
