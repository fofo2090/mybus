import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// خدمة فحص الاتصال المحسنة والمستقرة
/// تستخدم فحص مباشر للإنترنت بدون dependencies خارجية
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  Timer? _connectionTimer;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Stream للاستماع لتغييرات الاتصال
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  // بدء مراقبة الاتصال
  Future<void> initialize() async {
    try {
      // فحص الاتصال الحالي
      await _checkInitialConnection();

      // بدء مراقبة دورية للاتصال
      _startPeriodicCheck();
    } catch (e) {
      debugPrint('❌ Error initializing connectivity: $e');
      // تعيين قيم افتراضية في حالة الخطأ
      _isConnected = true;
    }
  }

  // بدء فحص دوري للاتصال
  void _startPeriodicCheck() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final wasConnected = _isConnected;
        final isConnected = await _hasInternetConnection();

        if (wasConnected != isConnected) {
          _updateConnectionStatus(isConnected);
        }
      } catch (e) {
        debugPrint('❌ Error in periodic connectivity check: $e');
      }
    });
  }

  // فحص الاتصال الأولي
  Future<void> _checkInitialConnection() async {
    try {
      final bool hasInternet = await _hasInternetConnection();
      _updateConnectionStatus(hasInternet);
    } catch (e) {
      debugPrint('❌ Error checking initial connectivity: $e');
      _updateConnectionStatus(false);
    }
  }

  // فحص الاتصال الفعلي بالإنترنت
  Future<bool> _hasInternetConnection() async {
    try {
      // محاولة الاتصال بـ Google DNS
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Internet connection check failed: $e');
      // في حالة الخطأ، نفترض أن الاتصال موجود لتجنب إزعاج المستخدم
      return true;
    }
  }

  // تحديث حالة الاتصال
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(_isConnected);
      debugPrint('🌐 Connection status changed: ${_isConnected ? "Connected" : "Disconnected"}');
    }
  }

  // فحص الاتصال يدوياً
  Future<bool> checkConnection() async {
    try {
      final bool hasInternet = await _hasInternetConnection();
      _updateConnectionStatus(hasInternet);
      return hasInternet;
    } catch (e) {
      debugPrint('❌ Error checking connection: $e');
      _updateConnectionStatus(false);
      return false;
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
              final connectivity = ConnectivityService();
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
            final connectivity = ConnectivityService();
            await connectivity.checkConnection();
          },
        ),
      ),
    );
  }

  // تنظيف الموارد
  void dispose() {
    _connectionTimer?.cancel();
    _connectionController.close();
  }
}

// Widget لمراقبة الاتصال
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool showDialogOnDisconnect;
  final bool showSnackBarOnDisconnect;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.showDialogOnDisconnect = true,
    this.showSnackBarOnDisconnect = false,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectionSubscription;
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    
    // فحص الاتصال الأولي
    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected && widget.showDialogOnDisconnect && !_hasShownDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hasShownDialog = true;
          ConnectivityService.showNoConnectionDialog(context);
        }
      });
    }

    // الاستماع لتغييرات الاتصال
    _connectionSubscription = _connectivityService.connectionStream.listen(
      (isConnected) {
        if (!isConnected && mounted) {
          if (widget.showDialogOnDisconnect && !_hasShownDialog) {
            _hasShownDialog = true;
            ConnectivityService.showNoConnectionDialog(context);
          } else if (widget.showSnackBarOnDisconnect) {
            ConnectivityService.showNoConnectionSnackBar(context);
          }
        } else if (isConnected) {
          _hasShownDialog = false;
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
