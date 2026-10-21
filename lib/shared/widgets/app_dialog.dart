import 'package:material_ui/material_ui.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'app_button.dart';

class AppDialog {
  AppDialog._();

  /// Shows a confirmation dialog with Confirm and Cancel buttons.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14, color: AppColors.slate600),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  cancelText,
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDestructive ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  /// Shows a simple error or information dialog with an OK button.
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14, color: AppColors.slate600),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: buttonText,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
    );
  }
}
