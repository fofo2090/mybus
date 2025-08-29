import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class SimpleConnectivityService {
  static final SimpleConnectivityService _instance = SimpleConnectivityService._internal();
  factory SimpleConnectivityService() => _instance;
  SimpleConnectivityService._internal();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // فحص الاتصال بالإنترنت
  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      return _isConnected;
    } catch (e) {
      debugPrint('❌ Internet connection check failed: $e');
      // في حالة الخطأ، نفترض أن الاتصال موجود
      _isConnected = true;
      return _isConnected;
    }
  }

  // عرض رسالة عدم الاتصال
  static void showNoConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('لا يوجد اتصال بالإنترنت'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'يجب أن يكون الإنترنت متصل لاستخدام التطبيق',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'تأكد من اتصالك بالواي فاي أو بيانات الهاتف',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // فحص الاتصال مرة أخرى
              final connectivity = SimpleConnectivityService();
              final isConnected = await connectivity.checkConnection();
              if (!isConnected) {
                // عرض الرسالة مرة أخرى إذا لم يكن متصل
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (context.mounted) {
                    showNoConnectionDialog(context);
                  }
                });
              }
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // عرض SnackBar لعدم الاتصال
  static void showNoConnectionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('لا يوجد اتصال بالإنترنت'),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: () async {
            final connectivity = SimpleConnectivityService();
            await connectivity.checkConnection();
          },
        ),
      ),
    );
  }
}

// Widget مبسط لمراقبة الاتصال
class SimpleConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool showDialogOnStart;

  const SimpleConnectivityWrapper({
    super.key,
    required this.child,
    this.showDialogOnStart = false,
  });

  @override
  State<SimpleConnectivityWrapper> createState() => _SimpleConnectivityWrapperState();
}

class _SimpleConnectivityWrapperState extends State<SimpleConnectivityWrapper> {
  final SimpleConnectivityService _connectivityService = SimpleConnectivityService();
  bool _hasCheckedInitial = false;

  @override
  void initState() {
    super.initState();
    if (widget.showDialogOnStart) {
      _checkInitialConnection();
    }
  }

  Future<void> _checkInitialConnection() async {
    if (_hasCheckedInitial) return;
    _hasCheckedInitial = true;

    // انتظار قليل للتأكد من أن الواجهة جاهزة
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected && mounted) {
      SimpleConnectivityService.showNoConnectionDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
