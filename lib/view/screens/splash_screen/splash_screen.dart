import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/splash_screen_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger session check after widget is built
    Future.microtask(() {
      Provider.of<SplashScreenController>(context, listen: false)
          .checkSession(context);
    });

    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/splash_animation.json',
          width: 400,
          height: 400,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
