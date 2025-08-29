import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../models/student_model.dart';
import '../../models/trip_model.dart';
import '../../widgets/admin_bottom_navigation.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/responsive_grid_view.dart';
import '../../utils/responsive_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'اليوم';

  final List<String> _periods = ['اليوم', 'الأسبوع', 'الشهر', 'السنة'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Debug: تحقق من البيانات
    print('🔍 Periods list: $_periods');
    print('🔍 Selected period: $_selectedPeriod');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(
        title: 'التقارير والإحصائيات',
      ),
      body: Column(
      children: [
        // Tab Bar
        Container(
          color: const Color(0xFF1E88E5),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            isScrollable: false,
            tabs: const [
              Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics, size: 20)),
              Tab(text: 'الطلاب', icon: Icon(Icons.people, size: 20)),
              Tab(text: 'الرحلات', icon: Icon(Icons.directions_bus, size: 20)),
            ],
          ),
        ),

          // Period Selector - Compact Design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.date_range, color: Color(0xFF1E88E5), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'فترة التقرير',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.green, size: 20),
                      onPressed: _exportTripsReport,
                      tooltip: 'تصدير التقرير',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPeriod,
                        decoration: InputDecoration(
                          labelText: 'فترة التقرير',
                          hintText: 'اختر الفترة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        isExpanded: true,
                        items: _periods.map((period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(
                              period,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          print('🔄 Dropdown changed to: $value');
                          if (value != null) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                            print('✅ Period updated to: $_selectedPeriod');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          DateFormat('yyyy/MM/dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralStats(),
                _buildStudentsReport(),
                _buildTripsReport(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildGeneralStats() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getPadding(context,
        mobilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        tabletPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        desktopPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Column(
        children: [
          // Stats Cards - Responsive Grid
          ResponsiveGridView(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            largeDesktopColumns: 4,
            mobileAspectRatio: 1.5,
            tabletAspectRatio: 1.3,
            desktopAspectRatio: 1.2,
            largeDesktopAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCompactStatCard(
                title: 'إجمالي الطلاب',
                icon: Icons.people,
                color: Colors.blue,
                future: _getTotalStudents(),
              ),
              _buildCompactStatCard(
                title: 'المشرفين',
                icon: Icons.supervisor_account,
                color: Colors.green,
                future: _getTotalSupervisors(),
              ),
              _buildCompactStatCard(
                title: 'رحلات اليوم',
                icon: Icons.directions_bus,
                color: Colors.orange,
                future: _getTodayTrips(),
              ),
              _buildCompactStatCard(
                title: 'الطلاب النشطين',
                icon: Icons.timeline,
                color: Colors.purple,
                future: _getActiveStudents(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Distribution - Compact Design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.pie_chart,
                        color: Color(0xFF1E88E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'توزيع حالات الطلاب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, int>>(
                  future: _getStudentStatusDistribution(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('لا توجد بيانات')),
                      );
                    }

                    final data = snapshot.data!;
                    return Column(
                      children: [
                        _buildCompactStatusRow('في المنزل', data['home'] ?? 0, Colors.green),
                        _buildCompactStatusRow('في الباص', data['onBus'] ?? 0, Colors.blue),
                        _buildCompactStatusRow('في المدرسة', data['atSchool'] ?? 0, Colors.orange),
                        _buildCompactStatusRow('غائب', data['absent'] ?? 0, Colors.red),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('لا يوجد طلاب'),
          );
        }
        
        final students = snapshot.data!.docs
            .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getStatusColor(student.currentStatus),
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : 'ط',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Student Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${student.schoolName} • ${student.grade}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'خط ${student.busRoute} • ${student.parentName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(student.currentStatus).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(student.currentStatus).withAlpha(76),
                        ),
                      ),
                      child: Text(
                        _getStatusText(student.currentStatus),
                        style: TextStyle(
                          color: _getStatusColor(student.currentStatus),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTripsReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('trips')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartDate()))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_getEndDate()))
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyTripsState();
        }

        final trips = snapshot.data!.docs
            .map((doc) {
              try {
                return TripModel.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e) {
                debugPrint('â‌Œ Error parsing trip: $e');
                return null;
              }
            })
            .where((trip) => trip != null)
            .cast<TripModel>()
            .toList();
        
        return Column(
          children: [
            // إحصائيات الرحلات
            _buildTripsStatistics(trips),
            const SizedBox(height: 16),

            // قائمة الرحلات
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return _buildTripCard(trip);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // دالة لبناء حالة فارغة للرحلات
  Widget _buildEmptyTripsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد رحلات في هذه الفترة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير الفترة الزمنية أو التاريخ المحدد',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // دالة لبناء إحصائيات الرحلات
  Widget _buildTripsStatistics(List<TripModel> trips) {
    // حساب الإحصائيات
    final totalTrips = trips.length;
    final uniqueStudents = trips.map((trip) => trip.studentId).toSet().length;
    final uniqueSupervisors = trips.map((trip) => trip.supervisorId).toSet().length;
    final uniqueRoutes = trips.map((trip) => trip.busRoute).toSet().length;

    // تجميع الرحلات حسب النوع
    final tripsByAction = <TripAction, int>{};
    for (final trip in trips) {
      tripsByAction[trip.action] = (tripsByAction[trip.action] ?? 0) + 1;
    }

    // تجميع الرحلات حسب الساعة
    final tripsByHour = <int, int>{};
    for (final trip in trips) {
      final hour = trip.timestamp.hour;
      tripsByHour[hour] = (tripsByHour[hour] ?? 0) + 1;
    }

    // العثور على أكثر الساعات ازدحاماً
    int busiestHour = 0;
    int maxTripsInHour = 0;
    tripsByHour.forEach((hour, tripCount) {
      if (tripCount > maxTripsInHour) {
        maxTripsInHour = tripCount;
        busiestHour = hour;
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'إحصائيات الرحلات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الإحصائيات الرئيسية
          Row(
            children: [
              Expanded(
                child: _buildStatisticItem(
                  'إجمالي الرحلات',
                  totalTrips.toString(),
                  Icons.directions_bus,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatisticItem(
                  'الطلاب',
                  uniqueStudents.toString(),
                  Icons.people,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatisticItem(
                  'المشرفين',
                  uniqueSupervisors.toString(),
                  Icons.supervisor_account,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatisticItem(
                  'الخطوط',
                  uniqueRoutes.toString(),
                  Icons.route,
                  Colors.purple,
                ),
              ),
            ],
          ),

          if (maxTripsInHour > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'أكثر الأوقات ازدحاماً: ${busiestHour.toString().padLeft(2, '0')}:00 ($maxTripsInHour رحلة)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // دالة لبناء عنصر إحصائي صغير
  Widget _buildStatisticItem(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // دالة لبناء بطاقة رحلة محسنة
  Widget _buildTripCard(TripModel trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // أيقونة الرحلة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTripActionColor(trip.action).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTripActionIcon(trip.action),
                color: _getTripActionColor(trip.action),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // معلومات الرحلة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المشرف: ${trip.supervisorName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'الخط: ${trip.busRoute}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ملاحظات: ${trip.notes}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // الوقت والحالة
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(trip.timestamp),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM').format(trip.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTripActionColor(trip.action),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTripActionText(trip.action),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Compact Stat Card for better space utilization
  Widget _buildCompactStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Future<int> future,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          FutureBuilder<int>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return Text(
                '${snapshot.data ?? 0}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Compact Status Row
  Widget _buildCompactStatusRow(String status, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  DateTime _getStartDate() {
    switch (_selectedPeriod) {
      case 'اليوم':
        return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      case 'الأسبوع':
        return _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      case 'الشهر':
        return DateTime(_selectedDate.year, _selectedDate.month, 1);
      case 'السنة':
        return DateTime(_selectedDate.year, 1, 1);
      default:
        return _selectedDate;
    }
  }

  DateTime _getEndDate() {
    switch (_selectedPeriod) {
      case 'اليوم':
        return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      case 'الأسبوع':
        return _selectedDate.add(Duration(days: 7 - _selectedDate.weekday));
      case 'الشهر':
        return DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
      case 'السنة':
        return DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
      default:
        return DateTime.now();
    }
  }

  Future<int> _getTotalStudents() async {
    final snapshot = await _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalSupervisors() async {
    final snapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'supervisor')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getTodayTrips() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('trips')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getActiveStudents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // عدد الطلاب الذين لديهم أنشطة اليوم (ركبوا الباص أو وصلوا المدرسة)
    final snapshot = await _firestore
        .collection('student_activities')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // حساب الطلاب الفريدين الذين لديهم أنشطة اليوم
    final uniqueStudents = <String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['studentId'] != null) {
        uniqueStudents.add(data['studentId']);
      }
    }

    return uniqueStudents.length;
  }

  Future<Map<String, int>> _getStudentStatusDistribution() async {
    final snapshot = await _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .get();

    final distribution = <String, int>{
      'home': 0,
      'onBus': 0,
      'atSchool': 0,
      'absent': 0,
    };

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['currentStatus'] as String?;
      if (status != null && distribution.containsKey(status)) {
        distribution[status] = distribution[status]! + 1;
      }
    }

    return distribution;
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.green;
      case StudentStatus.onBus:
        return Colors.blue;
      case StudentStatus.atSchool:
        return Colors.orange;

    }
  }

  String _getStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return 'في المنزل';
      case StudentStatus.onBus:
        return 'في الباص';
      case StudentStatus.atSchool:
        return 'في المدرسة';

    }
  }

  Color _getTripActionColor(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
        return Colors.green;
      case TripAction.arriveAtSchool:
        return Colors.orange;
      case TripAction.boardBusToHome:
        return Colors.blue;
      case TripAction.arriveAtHome:
        return Colors.purple;
      case TripAction.boardBus:
        return Colors.green;
      case TripAction.leaveBus:
        return Colors.blue;
    }
  }

  IconData _getTripActionIcon(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
        return Icons.directions_bus;
      case TripAction.arriveAtSchool:
        return Icons.school;
      case TripAction.boardBusToHome:
        return Icons.home_work;
      case TripAction.arriveAtHome:
        return Icons.home;
      case TripAction.boardBus:
        return Icons.arrow_upward;
      case TripAction.leaveBus:
        return Icons.arrow_downward;
    }
  }

  String _getTripActionText(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
        return 'ركب الباص للمدرسة';
      case TripAction.arriveAtSchool:
        return 'وصل للمدرسة';
      case TripAction.boardBusToHome:
        return 'ركب الباص للمنزل';
      case TripAction.arriveAtHome:
        return 'وصل للمنزل';
      case TripAction.boardBus:
        return 'صعود';
      case TripAction.leaveBus:
        return 'نزول';
    }
  }

  // دالة تصدير تقرير الرحلات
  Future<void> _exportTripsReport() async {
    try {
      // جلب الرحلات للفترة المحددة
      final snapshot = await _firestore
          .collection('trips')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartDate()))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_getEndDate()))
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد رحلات لتصديرها في هذه الفترة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final trips = snapshot.docs
          .map((doc) {
            try {
              return TripModel.fromMap(doc.data());
            } catch (e) {
              return null;
            }
          })
          .where((trip) => trip != null)
          .cast<TripModel>()
          .toList();

      // إنشاء محتوى CSV
      final csvContent = StringBuffer();
      csvContent.writeln('اسم الطالب,المشرف,الخط,نوع الرحلة,الإجراء,التاريخ,الوقت,ملاحظات');

      for (final trip in trips) {
        csvContent.writeln([
          trip.studentName,
          trip.supervisorName,
          trip.busRoute,
          trip.tripType.toString().split('.').last,
          _getTripActionText(trip.action),
          DateFormat('yyyy/MM/dd').format(trip.timestamp),
          DateFormat('HH:mm').format(trip.timestamp),
          trip.notes ?? '',
        ].join(','));
      }

      // حفظ الملف على الجهاز
      final cleanContent = _cleanCsvContent(csvContent.toString());
      await _saveReportToFile(cleanContent, 'trips_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير ${trips.length} رحلة وحفظها بنجاح'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'عرض',
              onPressed: () {
                _showExportPreview(csvContent.toString());
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تصدير التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة لعرض معاينة التصدير
  void _showExportPreview(String csvContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Colors.green),
            SizedBox(width: 8),
            Text('معاينة التقرير المُصدر'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              csvContent,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _saveReportToFile(csvContent, 'report_${DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now())}.csv');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ التقرير بنجاح في مجلد التحميلات'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // وظيفة حفظ التقرير على الجهاز - حل جذري
  Future<void> _saveReportToFile(String content, String fileName) async {
    try {
      // التأكد من صحة المحتوى
      if (content.isEmpty) {
        throw Exception('المحتوى فارغ');
      }

      Directory directory;
      String finalPath;

      if (Platform.isAndroid) {
        // للأندرويد: استخدام مجلد Downloads إذا كان متاحاً
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            // إذا لم يكن متاحاً، استخدم مجلد التطبيق
            directory = await getApplicationDocumentsDirectory();
            final reportsDir = Directory('${directory.path}/KidsBus_Reports');
            if (!await reportsDir.exists()) {
              await reportsDir.create(recursive: true);
            }
            directory = reportsDir;
          }
        } catch (e) {
          // في حالة فشل الوصول لمجلد Downloads
          directory = await getApplicationDocumentsDirectory();
          final reportsDir = Directory('${directory.path}/KidsBus_Reports');
          if (!await reportsDir.exists()) {
            await reportsDir.create(recursive: true);
          }
          directory = reportsDir;
        }
      } else {
        // للـ iOS: استخدام مجلد Documents
        directory = await getApplicationDocumentsDirectory();
        final reportsDir = Directory('${directory.path}/KidsBus_Reports');
        if (!await reportsDir.exists()) {
          await reportsDir.create(recursive: true);
        }
        directory = reportsDir;
      }

      // إنشاء اسم ملف فريد لتجنب الكتابة فوق الملفات الموجودة
      final timestamp = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
      final uniqueFileName = fileName.replaceAll('.csv', '_$timestamp.csv');
      finalPath = '${directory.path}/$uniqueFileName';

      final file = File(finalPath);

      // تحويل النص إلى bytes مع التأكد من UTF-8
      List<int> bytes;
      try {
        bytes = utf8.encode(content);
      } catch (e) {
        // في حالة فشل UTF-8، استخدم latin1
        bytes = latin1.encode(content);
      }

      // كتابة الملف
      await file.writeAsBytes(bytes, flush: true);

      // التحقق من أن الملف تم إنشاؤه بنجاح
      if (await file.exists()) {
        final fileSize = await file.length();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ تم حفظ التقرير بنجاح'),
                  Text('📁 $finalPath',
                    style: const TextStyle(fontSize: 10),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('📊 حجم الملف: ${(fileSize / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'موافق',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('فشل في إنشاء الملف');
      }

    } catch (e) {
      debugPrint('خطأ في حفظ الملف: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ خطأ في حفظ الملف'),
                Text('التفاصيل: $e', style: const TextStyle(fontSize: 10)),
                const Text('💡 تأكد من وجود مساحة كافية على الجهاز',
                  style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'إغلاق',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  // وظيفة تنظيف محتوى CSV
  String _cleanCsvContent(String content) {
    // إزالة الأحرف الغير مرغوب فيها
    String cleaned = content
        .replaceAll('\r\n', '\n')  // توحيد نهايات الأسطر
        .replaceAll('\r', '\n')    // توحيد نهايات الأسطر
        .trim();                   // إزالة المسافات الزائدة

    // التأكد من وجود BOM للـ UTF-8 لدعم Excel
    if (!cleaned.startsWith('\uFEFF')) {
      cleaned = '\uFEFF$cleaned';
    }

    return cleaned;
  }
}


