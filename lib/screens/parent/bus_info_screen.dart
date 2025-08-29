import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/bus_model.dart';
import '../../models/student_model.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../services/database_service.dart';

class BusInfoScreen extends StatefulWidget {
  final String studentId;

  const BusInfoScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<BusInfoScreen> createState() => _BusInfoScreenState();
}

class _BusInfoScreenState extends State<BusInfoScreen> {
  final DatabaseService _databaseService = DatabaseService();
  BusModel? _bus;
  StudentModel? _student;
  SupervisorAssignmentModel? _currentSupervisorAssignment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusInfo();
  }

  Future<void> _loadBusInfo() async {
    try {
      // Load student information
      final student = await _databaseService.getStudent(widget.studentId);
      if (student != null) {
        setState(() {
          _student = student;
        });

        // Load bus information if student has a bus assigned
        if (student.busId.isNotEmpty) {
          final bus = await _databaseService.getBus(student.busId);
          setState(() {
            _bus = bus;
          });

          // Load current supervisor assignment for this bus
          final currentTime = DateTime.now();
          final currentHour = currentTime.hour;

          // Determine trip direction based on time
          // Morning (6-10 AM) = to school, Afternoon (12-6 PM) = from school
          TripDirection currentDirection;
          if (currentHour >= 6 && currentHour <= 10) {
            currentDirection = TripDirection.toSchool;
          } else if (currentHour >= 12 && currentHour <= 18) {
            currentDirection = TripDirection.fromSchool;
          } else {
            // Default to both for other times
            currentDirection = TripDirection.both;
          }

          final supervisorAssignment = await _databaseService.getCurrentSupervisorAssignment(
            student.busId,
            currentDirection
          );
          setState(() {
            _currentSupervisorAssignment = supervisorAssignment;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading bus info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات السيارة'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E88E5),
              ),
            )
          : _bus == null
              ? _buildNoBusAssigned()
              : StreamBuilder<BusModel?>(
                  stream: _databaseService.getBusStream(_bus!.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('خطأ في تحميل البيانات: ${snapshot.error}'),
                      );
                    }

                    final updatedBus = snapshot.data;
                    if (updatedBus == null) {
                      return _buildNoBusAssigned();
                    }

                    // تحديث البيانات المحلية
                    _bus = updatedBus;

                    return _buildBusInfo();
                  },
                ),
    );
  }

  Widget _buildNoBusAssigned() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'لم يتم تعيين سيارة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لم يتم تعيين سيارة نقل لـ ${_student?.name ?? 'الطالب'} بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'يرجى التواصل مع إدارة المدرسة لتعيين سيارة النقل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF1E88E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _student?.name ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الصف: ${_student?.grade ?? ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bus Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Color(0xFFFF9800),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'معلومات السيارة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.directions_bus,
                    label: 'نوع الباص',
                    value: _bus?.description ?? 'غير محدد',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.route,
                    label: 'خط السير',
                    value: _bus?.route ?? '',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.people,
                    label: 'سعة السيارة',
                    value: _bus?.formattedCapacity ?? '',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: _bus?.hasAirConditioning == true ? Icons.ac_unit : Icons.ac_unit_outlined,
                    label: 'التكييف',
                    value: _bus?.airConditioningStatus ?? '',
                    color: _bus?.hasAirConditioning == true ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Driver Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_pin,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'معلومات المشرف',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Debug button (remove in production)
                  if (kDebugMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_bus != null) {
                            await _databaseService.debugSupervisorAssignments(_bus!.id);
                            setState(() {}); // Refresh the UI
                          }
                        },
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Debug Supervisor Info'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                  // Supervisor info with real data
                  FutureBuilder<Map<String, String>>(
                    future: _getSupervisorInfoWithDebug(),
                    builder: (context, supervisorSnapshot) {
                      if (supervisorSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final supervisorInfo = supervisorSnapshot.data ?? {};
                      final supervisorName = supervisorInfo['name'] ?? 'غير محدد';
                      final supervisorPhone = supervisorInfo['phone'] ?? '';
                      final supervisionPeriod = supervisorInfo['direction'] ?? 'غير محدد';

                      return Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'اسم المشرف',
                            value: supervisorName,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.phone,
                            label: 'رقم الهاتف',
                            value: supervisorPhone.isNotEmpty ? supervisorPhone : 'غير محدد',
                            color: Colors.blue,
                            isPhone: supervisorPhone.isNotEmpty,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.schedule,
                            label: 'فترة الإشراف',
                            value: supervisionPeriod,
                            color: Colors.purple,
                          ),

                          const SizedBox(height: 16),

                          // Quick Call Button
                          if (supervisorPhone.isNotEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withAlpha(76),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _makePhoneCall(supervisorPhone),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.call, color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'اتصال بالمشرف',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isPhone = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (isPhone && value.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Copy Button
              IconButton(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('تم نسخ رقم الهاتف: $value'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('â‌Œ Error copying phone number: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('خطأ في نسخ رقم الهاتف'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.copy, color: Colors.blue),
                tooltip: 'نسخ رقم الهاتف',
              ),

              // Call Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(76),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _makePhoneCall(value),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'اتصال',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // تنظيف رقم الهاتف من المسافات والرموز الإضافية
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // إضافة +20 إذا كان الرقم مصري ولا يبدأ بـ +
      if (!cleanedNumber.startsWith('+') && cleanedNumber.startsWith('01')) {
        cleanedNumber = '+2$cleanedNumber';
      } else if (!cleanedNumber.startsWith('+') && cleanedNumber.startsWith('2')) {
        cleanedNumber = '+$cleanedNumber';
      }

      if (cleanedNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الهاتف غير صحيح'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

      debugPrint('ًں“‍ Attempting to call: $cleanedNumber');

      // محاولة فتح تطبيق الاتصال
      bool launched = false;

      try {
        launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('â‌Œ Error with launchUrl: $e');
        launched = false;
      }

      if (!launched) {
        // ظ…ط­ط§ظˆظ„ط© ط¨ط¯ظٹظ„ط© ط¨ط§ط³طھط®ط¯ط§ظ… intent ط¹ظ„ظ‰ Android
        try {
          final Uri dialerUri = Uri.parse('tel:$cleanedNumber');
          launched = await launchUrl(dialerUri);
        } catch (e) {
          debugPrint('â‌Œ Error with alternative launch: $e');
        }
      }

      if (launched) {
        debugPrint('âœ… Phone call initiated successfully');
      } else {
        debugPrint('â‌Œ Cannot launch phone call');
        if (mounted) {
          // ط¹ط±ط¶ dialog ظ…ط¹ ط®ظٹط§ط±ط§طھ ط¨ط¯ظٹظ„ط©
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('الاتصال بالسائق'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ظ„ط§ ظٹظ…ظƒظ† ظپطھط­ طھط·ط¨ظٹظ‚ ط§ظ„ط§طھطµط§ظ„ طھظ„ظ‚ط§ط¦ظٹط§ظ‹'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cleanedNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: cleanedNumber));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('طھظ… ظ†ط³ط® ط±ظ‚ظ… ط§ظ„ط³ط§ط¦ظ‚'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          tooltip: 'ظ†ط³ط® ط§ظ„ط±ظ‚ظ…',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ط¥ط؛ظ„ط§ظ‚'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('â‌Œ Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('خطأ في الاتصال: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }



  // Get supervisor phone based on current time and assignment
  String _getSupervisorPhone() {
    if (_currentSupervisorAssignment == null) return '';

    // Use FutureBuilder to get supervisor info in the UI instead
    return 'جاري التحميل...';
  }

  // Get supervisor name
  String _getSupervisorName() {
    if (_currentSupervisorAssignment == null) return 'غير محدد';
    return _currentSupervisorAssignment!.supervisorName;
  }

  // Get supervision period description
  String _getSupervisionPeriod() {
    if (_currentSupervisorAssignment == null) return 'غير محدد';

    switch (_currentSupervisorAssignment!.direction) {
      case TripDirection.toSchool:
        return 'الذهاب للمدرسة (6:00 - 10:00 ص)';
      case TripDirection.fromSchool:
        return 'العودة من المدرسة (12:00 - 6:00 م)';
      case TripDirection.both:
        return 'الذهاب والعودة';
    }
  }

  // Get supervisor info with debug logging
  Future<Map<String, String>> _getSupervisorInfoWithDebug() async {
    if (_bus == null) {
      debugPrint('❌ Bus is null');
      return {
        'name': 'خطأ: لا توجد حافلة',
        'phone': '',
        'direction': '',
      };
    }

    debugPrint('🚌 Getting supervisor info for bus: ${_bus!.id} (${_bus!.plateNumber})');

    // Call debug function first
    await _databaseService.debugSupervisorAssignments(_bus!.id);

    // Then get the actual supervisor info
    final result = await _databaseService.getSupervisorInfoForParent(_bus!.id);

    debugPrint('📱 Final result: $result');
    return result;
  }
}


