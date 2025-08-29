import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/trip_model.dart';
import '../../widgets/student_avatar.dart';

class StudentActivityScreen extends StatefulWidget {
  final String studentId;
  
  const StudentActivityScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentActivityScreen> createState() => _StudentActivityScreenState();
}

class _StudentActivityScreenState extends State<StudentActivityScreen> {
  final DatabaseService _databaseService = DatabaseService();
  StudentModel? _student;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 StudentActivityScreen initialized for student: ${widget.studentId}');
    _loadStudentData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      debugPrint('🔍 Loading student data for ID: ${widget.studentId}');

      if (widget.studentId.isEmpty) {
        debugPrint('❌ Student ID is empty');
        return;
      }

      final student = await _databaseService.getStudent(widget.studentId);
      debugPrint('📚 Student data loaded: ${student?.name ?? 'null'}');

      if (mounted) {
        setState(() {
          _student = student;
        });

        // If student is still null after loading, show error
        if (student == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على بيانات الطالب'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading student data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 Building StudentActivityScreen for student: ${widget.studentId}');

    // Validate student ID
    if (widget.studentId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('خطأ'),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'معرف الطالب غير صحيح',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('يرجى المحاولة مرة أخرى'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_student?.name ?? 'سجل الأنشطة'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: SafeArea(
        child: _student == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل بيانات الطالب...'),
                ],
              ),
            )
          : SingleChildScrollView(
            child: Column(
                children: [
                  // Student Info Card
                  _buildStudentInfoCard(),

                  // Date Filter
                  _buildDateFilter(),

                  // Quick Stats
                  _buildQuickStats(),

                  // Activities List
                  _buildActivitiesList(),
                ],
              ),
          ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    if (_student == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(
                photoUrl: _student!.photoUrl,
                studentName: _student!.name,
                radius: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _student!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Color(0xFF1E88E5), size: 28),
                tooltip: 'View on Map',
                onPressed: () {
                  if (_student != null) {
                    context.goNamed(
                      'student-location',
                      pathParameters: {'studentId': _student!.id},
                    );
                  }
                },
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.class_, 'الصف', _student!.grade),
          if (_student!.busRoute.isNotEmpty)
            _buildInfoRow(Icons.directions_bus, 'خط الباص', _student!.busRoute),
          _buildInfoRow(Icons.info, 'الحالة', _student!.statusDisplayText),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusChip(StudentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case StudentStatus.home:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green;
        icon = Icons.home;
        text = 'في المنزل';
        break;
      case StudentStatus.onBus:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange;
        icon = Icons.directions_bus;
        text = 'في الباص';
        break;
      case StudentStatus.atSchool:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue;
        icon = Icons.school;
        text = 'في المدرسة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Color(0xFF1E88E5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _selectDate,
            child: const Text('تغيير التاريخ'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: StreamBuilder<List<TripModel>>(
        stream: _databaseService.getTripsByStudentAndDate(widget.studentId, _selectedDate),
        builder: (context, snapshot) {
          // Handle loading and error states
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Row(
              children: [
                Expanded(child: _buildStatCard('رحلات الصعود', '...', Icons.directions_bus, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('رحلات النزول', '...', Icons.home, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('إجمالي الرحلات', '...', Icons.timeline, const Color(0xFF1E88E5))),
              ],
            );
          }

          final studentTrips = snapshot.data ?? [];

          final boardingTrips = studentTrips
              .where((trip) => trip.action == TripAction.boardBus)
              .length;
          final leavingTrips = studentTrips
              .where((trip) => trip.action == TripAction.leaveBus)
              .length;

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'رحلات الصعود',
                  boardingTrips.toString(),
                  Icons.directions_bus,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'رحلات النزول',
                  leavingTrips.toString(),
                  Icons.home,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'إجمالي الرحلات',
                  studentTrips.length.toString(),
                  Icons.timeline,
                  const Color(0xFF1E88E5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color == Colors.green ? Colors.green.shade50 :
                     color == Colors.orange ? Colors.orange.shade50 :
                     Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'أنشطة اليوم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FutureBuilder<List<TripModel>>(
          future: _databaseService.getStudentTrips(widget.studentId, _selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('خطأ: ${snapshot.error}'),
                ),
              );
            }

            final studentTrips = snapshot.data ?? [];

            if (studentTrips.isEmpty) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد أنشطة في هذا التاريخ',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: studentTrips.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final trip = studentTrips[index];
                return _buildActivityItem(trip);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(TripModel trip) {
    final isBoarding = trip.action == TripAction.boardBus;
    final iconColor = isBoarding ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isBoarding ? Icons.directions_bus_filled : Icons.home_work,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.actionDisplayText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.tripTypeDisplayText,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ملاحظة: ${trip.notes}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trip.formattedTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'بواسطة: ${trip.supervisorName}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
