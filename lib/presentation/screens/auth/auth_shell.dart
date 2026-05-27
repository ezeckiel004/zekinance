import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  final Widget? child;
  
  const AuthShell({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    // If we're using GoRouter, the nested child is in 'child' or passed via router
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Background ambient glows (top left teal, bottom right green)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.08),
                
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
          // Nested route view
          child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
