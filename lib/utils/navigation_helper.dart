import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

class NavigationHelper {
  // Navigate based on user type
  static void navigateToHome(BuildContext context, UserType userType) {
    String route;
    
    switch (userType) {
      case UserType.parent:
        route = AppRoutes.parentHome;
        break;
      case UserType.supervisor:
        route = AppRoutes.supervisorHome;
        break;
      case UserType.admin:
        route = AppRoutes.adminHome;
        break;
    }
    
    context.go(route);
  }

  // Navigate to login
  static void navigateToLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }

  // Navigate to register
  static void navigateToRegister(BuildContext context) {
    context.go(AppRoutes.register);
  }

  // Navigate back safely
  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  // Show confirmation dialog before navigation
  static Future<bool> showNavigationConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'نعم',
    String cancelText = 'لا',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Navigate with confirmation
  static Future<void> navigateWithConfirmation(
    BuildContext context, {
    required String route,
    required String title,
    required String message,
  }) async {
    final confirmed = await showNavigationConfirmation(
      context,
      title: title,
      message: message,
    );
    
    if (confirmed) {
      context.go(route);
    }
  }

  // Show error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk?.call();
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  static void showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk?.call();
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message ?? 'جاري التحميل...'),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green,
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red,
    );
  }

  // Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange,
    );
  }

  // Navigate to student activity with validation
  static void navigateToStudentActivity(
    BuildContext context,
    String studentId, {
    bool validate = true,
  }) {
    if (validate && studentId.isEmpty) {
      showErrorSnackBar(context, 'معرف الطالب غير صحيح');
      return;
    }
    
    context.push('/parent/student-activity/$studentId');
  }

  // Navigate to bus info with validation
  static void navigateToBusInfo(
    BuildContext context,
    String studentId, {
    bool validate = true,
  }) {
    if (validate && studentId.isEmpty) {
      showErrorSnackBar(context, 'معرف الطالب غير صحيح');
      return;
    }
    
    context.push('/parent/bus-info/$studentId');
  }

  // Navigate to edit student with validation
  static void navigateToEditStudent(
    BuildContext context,
    String studentId, {
    bool validate = true,
  }) {
    if (validate && studentId.isEmpty) {
      showErrorSnackBar(context, 'معرف الطالب غير صحيح');
      return;
    }
    
    context.push('/admin/students/edit/$studentId');
  }

  // Get current route name
  static String getCurrentRoute(BuildContext context) {
    return GoRouterState.of(context).fullPath ?? '/';
  }

  // Check if can go back
  static bool canGoBack(BuildContext context) {
    return context.canPop();
  }
}
