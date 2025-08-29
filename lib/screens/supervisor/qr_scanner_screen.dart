import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../utils/permissions_helper.dart';
import '../../models/student_model.dart';
import '../../models/trip_model.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../widgets/custom_button.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProcessing = false;
  String? _lastScannedCode;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  int _studentsOnBusCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadStudentsCount();
  }

  Future<void> _initializeCamera() async {
    try {
      // طلب إذن الكاميرا
      final hasPermission = await PermissionsHelper.requestCameraPermission();

      if (!hasPermission) {
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }

      setState(() {
        _hasPermission = true;
        _isCameraInitialized = true;
      });

      debugPrint('✅ Camera initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing camera: $e');
      setState(() {
        _isCameraInitialized = false;
        _hasPermission = false;
      });
      if (mounted) {
        _showErrorDialog('خطأ في تشغيل الكاميرا: $e');
      }
    }
  }

  Future<void> _loadStudentsCount() async {
    try {
      // احصل على خط السير الخاص بالمشرف
      final supervisorId = _authService.currentUser?.uid ?? '';
      final assignments = await _databaseService.getSupervisorAssignments(supervisorId).first;

      if (assignments.isNotEmpty) {
        final supervisorRoute = assignments.first.busRoute;

        // احصل على عدد الطلاب في الباص لخط السير الخاص بالمشرف
        final studentsSnapshot = await _firestore
            .collection('students')
            .where('currentStatus', isEqualTo: 'onBus')
            .where('isActive', isEqualTo: true)
            .where('busRoute', isEqualTo: supervisorRoute)
            .get();

        setState(() {
          _studentsOnBusCount = studentsSnapshot.docs.length;
        });
      } else {
        setState(() {
          _studentsOnBusCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading students count: $e');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Professional Students Counter
          GestureDetector(
            onTap: _showDetailedCounter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _studentsOnBusCount > 0 ? Colors.green[400]! : Colors.grey[400]!,
                    _studentsOnBusCount > 0 ? Colors.green[600]! : Colors.grey[600]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_studentsOnBusCount > 0 ? Colors.green : Colors.grey).withAlpha(76),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _studentsOnBusCount > 0 ? Icons.directions_bus : Icons.directions_bus_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_studentsOnBusCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                if (_isCameraInitialized && _hasPermission)
                  Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: _onDetect,
                      ),
                      // خلفية شفافة مع فتحة للمسح
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF1E88E5),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E88E5).withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // زوايا المسح
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: 280,
                            height: 280,
                            child: Stack(
                              children: [
                                // الزاوية العلوية اليسرى
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.white, width: 4),
                                        left: BorderSide(color: Colors.white, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                                // الزاوية العلوية اليمنى
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.white, width: 4),
                                        right: BorderSide(color: Colors.white, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                                // الزاوية السفلية اليسرى
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.white, width: 4),
                                        left: BorderSide(color: Colors.white, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                                // الزاوية السفلية اليمنى
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.white, width: 4),
                                        right: BorderSide(color: Colors.white, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // نص التوجيه
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ضع الباركود داخل الإطار للمسح',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (!_hasPermission)
                  Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 100,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'إذن الكاميرا مطلوب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'يرجى السماح للتطبيق بالوصول للكاميرا',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _initializeCamera,
                            child: Text('طلب الإذن'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'جاري تشغيل الكاميرا...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withAlpha(178),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'جاري المعالجة...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: const Color(0xFF1E88E5),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'وجه الكاميرا نحو باركود الطالب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم تسجيل ركوب أو نزول الطالب تلقائياً',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF1E88E5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _showManualEntryDialog,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.keyboard,
                                    color: Color(0xFF1E88E5),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'إدخال يدوي',
                                    style: TextStyle(
                                      color: Color(0xFF1E88E5),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() {
    controller.toggleTorch();
  }

  void _resumeScanning() {
    try {
      if (_isCameraInitialized && _hasPermission && !_isProcessing) {
        controller.start();
        debugPrint('✅ Camera scanning resumed');
      }
    } catch (e) {
      debugPrint('❌ Error resuming camera: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.orange),
            SizedBox(width: 8),
            Text('إذن الكاميرا مطلوب'),
          ],
        ),
        content: const Text(
          'يحتاج التطبيق إلى إذن الكاميرا لمسح أكواد QR الخاصة بالطلاب.\n\nيرجى السماح بالوصول للكاميرا في الإعدادات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionsHelper.openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    try {
      final barcodes = capture.barcodes;

      if (barcodes.isNotEmpty && !_isProcessing) {
        final code = barcodes.first.rawValue;
        if (code != null && code != _lastScannedCode) {
          _lastScannedCode = code;
          // إيقاف المسح مؤقتاً لمنع المسح المتكرر
          controller.stop();
          _processQRCode(code);
        }
      }
    } catch (e) {
      debugPrint('❌ Error detecting barcode: $e');
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;

    // Validate QR code format
    if (qrCode.trim().isEmpty) {
      _showErrorDialog('رمز الباركود فارغ');
      return;
    }

    // Basic QR code validation (should be numeric and reasonable length)
    if (!RegExp(r'^\d{4,10}$').hasMatch(qrCode.trim())) {
      _showErrorDialog('رمز الباركود غير صالح. يجب أن يكون رقمياً من 4-10 أرقام');
      return;
    }

    // فحص الاتصال بالإنترنت أولاً
    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected) {
      _showErrorDialog('لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('ًں”چ Processing QR code: $qrCode');

      // البحث عن الطالب بالباركود مع timeout
      final student = await _databaseService.getStudentByQRCode(qrCode.trim()).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('انتهت مهلة البحث عن الطالب'),
      );

      if (student == null) {
        _showErrorDialog('لم يتم العثور على طالب بهذا الباركود: $qrCode');
        return;
      }

      // Verify student is active
      if (!student.isActive) {
        _showErrorDialog('هذا الطالب غير نشط في النظام');
        return;
      }

      debugPrint('âœ… Student found: ${student.name}');

      // عرض خيارات العملية للمشرف
      _showActionSelectionDialog(student);

    } catch (e) {
      debugPrint('❌ Error processing QR code: $e');
      _showErrorDialog('حدث خطأ: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
      // استئناف المسح في حالة حدوث خطأ
      _resumeScanning();
    }
  }

  void _showActionSelectionDialog(StudentModel student) {
    // فحص حالة الطالب الحالية لمنع التكرار
    final currentStatus = student.currentStatus;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('اختر العملية للطالب: ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(currentStatus).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor(currentStatus).withAlpha(76)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(currentStatus),
                    color: _getStatusColor(currentStatus),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الحالة الحالية: ${student.statusDisplayText}',
                    style: TextStyle(
                      color: _getStatusColor(currentStatus),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'اختر العملية المطلوبة:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          // ركب الباص إلى المدرسة
          if (currentStatus == StudentStatus.onBus)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الطالب موجود في الباص بالفعل',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processStudentAction(student, TripAction.boardBusToSchool, StudentStatus.onBus);
              },
              icon: const Icon(Icons.directions_bus, color: Colors.green),
              label: const Text('ركب الباص إلى المدرسة'),
            ),

          // وصل إلى المدرسة
          if (currentStatus == StudentStatus.atSchool)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الطالب في المدرسة بالفعل',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processStudentAction(student, TripAction.arriveAtSchool, StudentStatus.atSchool);
              },
              icon: const Icon(Icons.school, color: Colors.orange),
              label: const Text('وصل إلى المدرسة'),
            ),

          // ركب الباص إلى المنزل
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _processStudentAction(student, TripAction.boardBusToHome, StudentStatus.onBus);
            },
            icon: const Icon(Icons.home_work, color: Colors.blue),
            label: const Text('ركب الباص إلى المنزل'),
          ),

          // وصل إلى المنزل
          if (currentStatus == StudentStatus.home)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الطالب وصل للمنزل بالفعل',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processStudentAction(student, TripAction.arriveAtHome, StudentStatus.home);
              },
              icon: const Icon(Icons.home, color: Colors.purple),
              label: const Text('وصل إلى المنزل'),
            ),
          // إلغاء
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning(); // استئناف المسح
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _processStudentAction(StudentModel student, TripAction action, StudentStatus newStatus) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // فحص الاتصال مرة أخرى قبل العملية
      final isConnected = await _connectivityService.checkConnection();
      if (!isConnected) {
        _showErrorDialog('فقد الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.');
        return;
      }

      // فحص حالة الحافلة قبل السماح بالعملية
      if (student.busId.isNotEmpty) {
        final busDoc = await _firestore.collection('buses').doc(student.busId).get();
        if (busDoc.exists) {
          final busData = busDoc.data()!;
          final isActive = busData['isActive'] ?? true;

          if (!isActive) {
            _showErrorDialog('⚠️ الحافلة المخصصة للطالب غير نشطة حالياً\n\nيرجى التواصل مع الإدارة لتفعيل الحافلة أو تغيير التسكين');
            return;
          }
        }
      }

      // تحديث حالة الطالب
      await _databaseService.updateStudentStatus(student.id, newStatus);

      // تحديث حالة الطالب محلياً لعرضها في الحوار
      final updatedStudent = student.copyWith(
        currentStatus: newStatus,
        updatedAt: DateTime.now(),
      );

      // تسجيل الرحلة
      final currentUser = _authService.currentUser;
      final supervisorName = currentUser?.displayName ??
                           currentUser?.email?.split('@').first ??
                           'مشرف النقل';

      final trip = TripModel(
        id: _databaseService.generateTripId(),
        studentId: student.id,
        studentName: student.name,
        supervisorId: currentUser?.uid ?? '',
        supervisorName: supervisorName,
        busRoute: student.busRoute,
        tripType: _determineTripType(),
        action: action,
        timestamp: DateTime.now(),
      );

      await _databaseService.recordTrip(trip);

      // إرسال إشعار بدء الرحلة إذا كان أول طالب يركب الباص
      if (action == TripAction.boardBus) {
        await _checkAndSendTripStartNotification(student);
      }

      // إرسال إشعار مخصص لولي الأمر مع الصوت
      await _sendCustomNotificationWithSound(student, action);

      // تحديث العداد
      _updateStudentsCounter(action);

      // عرض رسالة نجاح مع الحالة المحدثة
      _showActionSuccessDialog(updatedStudent, action);

    } catch (e) {
      _showErrorDialog('حدث خطأ: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
      // استئناف المسح بعد انتهاء العملية
      _resumeScanning();
    }
  }

  void _updateStudentsCounter(TripAction action) {
    setState(() {
      switch (action) {
        case TripAction.boardBus:
        case TripAction.boardBusToSchool:
        case TripAction.boardBusToHome:
          _studentsOnBusCount++;
          break;
        case TripAction.leaveBus:
        case TripAction.arriveAtSchool:
        case TripAction.arriveAtHome:
          if (_studentsOnBusCount > 0) {
            _studentsOnBusCount--;
          }
          break;
      }
    });
  }

  Future<void> _sendCustomNotificationWithSound(StudentModel student, TripAction action) async {
    final currentUser = _authService.currentUser;
    final supervisorId = currentUser?.uid ?? '';

    switch (action) {
      case TripAction.boardBus:
      case TripAction.boardBusToSchool:
      case TripAction.boardBusToHome:
        await _notificationService.notifyStudentBoardedWithSound(
          studentId: student.id,
          studentName: student.name,
          busId: student.busRoute,
          parentId: student.parentId,
          supervisorId: supervisorId,
        );
        break;
      case TripAction.leaveBus:
      case TripAction.arriveAtSchool:
      case TripAction.arriveAtHome:
        await _notificationService.notifyStudentAlightedWithSound(
          studentId: student.id,
          studentName: student.name,
          busId: student.busRoute,
          parentId: student.parentId,
          supervisorId: supervisorId,
        );
        break;
    }
  }

  Future<void> _sendCustomNotification(StudentModel student, TripAction action) async {
    final currentUser = _authService.currentUser;
    final supervisorName = currentUser?.displayName ??
                         currentUser?.email?.split('@').first ??
                         'مشرف النقل';
    final timestamp = DateTime.now();

    try {
      switch (action) {
        case TripAction.boardBusToSchool:
          await _notificationService.sendStudentBoardedNotification(
            student: student,
            supervisorName: supervisorName,
            timestamp: timestamp,
          );
          // إشعار إضافي أن الطالب في الباص متوجه للمدرسة
          await _notificationService.sendStudentOnBusNotification(
            student: student,
            supervisorName: supervisorName,
            timestamp: timestamp,
            busRoute: student.busRoute,
          );
          break;

        case TripAction.arriveAtSchool:
          await _notificationService.sendStudentArrivedAtSchoolNotification(
            student: student,
            supervisorName: supervisorName,
            timestamp: timestamp,
          );
          break;

        case TripAction.boardBusToHome:
          await _notificationService.sendStudentBoardedNotification(
            student: student,
            supervisorName: supervisorName,
            timestamp: timestamp,
          );
          // إشعار إضافي أن الطالب في الباص متوجه للمنزل
          await _notificationService.sendStudentOnBusNotification(
            student: student,
            supervisorName: supervisorName,
            timestamp: timestamp,
            busRoute: student.busRoute,
          );
          break;

        case TripAction.arriveAtHome:
          await _notificationService.sendStudentArrivedAtHomeNotification(
            student: student,
            supervisorName: supervisorName,
            timestamp: timestamp,
          );
          break;

        default:
          // إشعار عام للحالات الأخرى
          await _notificationService.sendGeneralNotification(
            title: 'تحديث حالة ${student.name}',
            body: 'تم تحديث حالة ${student.name} بواسطة $supervisorName في ${_formatTime(timestamp)}',
            recipientId: student.parentId,
            data: {
              'studentId': student.id,
              'action': action.toString().split('.').last,
              'timestamp': timestamp.toIso8601String(),
            },
          );
      }

      debugPrint('✅ Notification sent for action: $action');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  TripType _determineTripType() {
    final now = DateTime.now();
    // إذا كان الوقت قبل الظهر، فهي رحلة ذهاب، وإلا فهي رحلة عودة
    return now.hour < 12 ? TripType.toSchool : TripType.fromSchool;
  }

  // دالة للتحقق من إرسال إشعار بدء الرحلة
  Future<void> _checkAndSendTripStartNotification(StudentModel student) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // التحقق من وجود رحلات أخرى اليوم لنفس الخط
      final existingTrips = await _firestore
          .collection('trips')
          .where('busRoute', isEqualTo: student.busRoute)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .where('action', isEqualTo: 'boardBus')
          .get();

      // إذا كان هذا أول طالب يركب الباص اليوم، أرسل إشعار بدء الرحلة
      if (existingTrips.docs.length <= 1) { // <= 1 لأن الرحلة الحالية تم تسجيلها بالفعل
        // إرسال إشعار بدء الرحلة لجميع أولياء الأمور في نفس الخط
        await _sendTripStartNotificationToAllParents(student.busRoute);
      }
    } catch (e) {
      debugPrint('❌ Error checking trip start notification: $e');
    }
  }

  // دالة لإرسال إشعار بدء الرحلة لجميع أولياء الأمور في الخط
  Future<void> _sendTripStartNotificationToAllParents(String busRoute) async {
    try {
      // الحصول على جميع الطلاب في نفس الخط
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('busRoute', isEqualTo: busRoute)
          .where('isActive', isEqualTo: true)
          .get();

      // إرسال إشعار لكل ولي أمر
      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final parentId = studentData['parentId'];

        if (parentId != null && parentId.isNotEmpty) {
          await _notificationService.sendTripStartedNotification(
            recipientId: parentId,
            studentName: studentData['name'] ?? 'الطالب',
            timestamp: DateTime.now(),
          );
        }
      }

      debugPrint('✅ Trip start notifications sent to all parents on route: $busRoute');
    } catch (e) {
      debugPrint('❌ Error sending trip start notifications: $e');
    }
  }

  void _showActionSuccessDialog(StudentModel student, TripAction action) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          _getActionIcon(action),
          color: Colors.green,
          size: 48,
        ),
        title: Text(
          'تم تسجيل العملية بنجاح',
          style: const TextStyle(color: Colors.green),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الطالب: ${student.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الصف: ${student.grade}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'العملية: ${_getActionDisplayText(action)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الوقت: ${_formatTime(DateTime.now())}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(student.currentStatus).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(student.currentStatus).withAlpha(76),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(student.currentStatus),
                    color: _getStatusColor(student.currentStatus),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الحالة الجديدة: ${_getStatusDisplayText(student.currentStatus)}',
                      style: TextStyle(
                        color: _getStatusColor(student.currentStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'تم إرسال إشعار لولي الأمر',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // استئناف المسح
              _resumeScanning();
            },
            child: const Text('متابعة المسح'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
        return Icons.directions_bus;
      case TripAction.arriveAtSchool:
        return Icons.school;
      case TripAction.boardBusToHome:
        return Icons.home_work;
      case TripAction.arriveAtHome:
        return Icons.home;
      default:
        return Icons.check_circle;
    }
  }

  String _getActionDisplayText(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
        return 'ركب الباص إلى المدرسة';
      case TripAction.arriveAtSchool:
        return 'وصل إلى المدرسة';
      case TripAction.boardBusToHome:
        return 'ركب الباص إلى المنزل';
      case TripAction.arriveAtHome:
        return 'وصل إلى المنزل';
      default:
        return 'عملية غير محددة';
    }
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.green;
      case StudentStatus.onBus:
        return Colors.orange;
      case StudentStatus.atSchool:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Icons.home;
      case StudentStatus.onBus:
        return Icons.directions_bus;
      case StudentStatus.atSchool:
        return Icons.school;
    }
  }

  String _getStatusDisplayText(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return 'في المنزل';
      case StudentStatus.onBus:
        return 'في الباص';
      case StudentStatus.atSchool:
        return 'في المدرسة';
      default:
        return 'غير محدد';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: Colors.red,
          size: 48,
        ),
        title: const Text(
          'خطأ',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning(); // استئناف المسح
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController qrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال الباركود يدوياً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qrController,
              decoration: const InputDecoration(
                labelText: 'رمز الباركود',
                border: OutlineInputBorder(),
                hintText: 'أدخل رقم الباركود (4-10 أرقام)',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 10,
            ),
            const SizedBox(height: 8),
            const Text(
              'يجب أن يكون الباركود رقمياً من 4 إلى 10 أرقام',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final qrCode = qrController.text.trim();
              Navigator.pop(context);

              if (qrCode.isEmpty) {
                _showErrorDialog('يرجى إدخال رمز الباركود');
                return;
              }

              if (!RegExp(r'^\d{4,10}$').hasMatch(qrCode)) {
                _showErrorDialog('رمز الباركود يجب أن يكون رقمياً من 4-10 أرقام');
                return;
              }

              _processQRCode(qrCode);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }



  void _showDetailedCounter() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'إحصائيات الطلاب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Main Counter Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _studentsOnBusCount > 0 ? Colors.green[400]! : Colors.grey[400]!,
                      _studentsOnBusCount > 0 ? Colors.green[600]! : Colors.grey[600]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_studentsOnBusCount > 0 ? Colors.green : Colors.grey).withAlpha(76),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _studentsOnBusCount > 0 ? Icons.directions_bus : Icons.directions_bus_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_studentsOnBusCount',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _studentsOnBusCount == 1 ? 'طالب في الباص' : 'طلاب في الباص',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status Indicators
              Row(
                children: [
                  Expanded(
                    child: _buildStatusIndicator(
                      icon: Icons.home,
                      label: 'في المنزل',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusIndicator(
                      icon: Icons.directions_bus,
                      label: 'في الباص',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusIndicator(
                      icon: Icons.school,
                      label: 'في المدرسة',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadStudentsCount(); // Refresh counter
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('تحديث'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.blue.withAlpha(25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        backgroundColor: Colors.grey.withAlpha(25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


