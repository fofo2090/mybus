import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/absence_model.dart';
import '../../services/database_service.dart';
import '../../widgets/curved_app_bar.dart';

class AbsenceManagementScreen extends StatefulWidget {
  const AbsenceManagementScreen({super.key});

  @override
  State<AbsenceManagementScreen> createState() => _AbsenceManagementScreenState();
}

class _AbsenceManagementScreenState extends State<AbsenceManagementScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: EnhancedCurvedAppBar(
        title: 'إشعارات الغياب',
        subtitle: const Text('متابعة إشعارات الغياب من أولياء الأمور'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        actions: [],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Header with Statistics
          _buildHeader(),
          const SizedBox(height: 16),

          // Tab Bar - Enhanced for better visibility
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1E88E5),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1E88E5),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  height: 1.2,
                ),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.notifications_active, size: 20),
                    text: 'إشعارات حديثة',
                    height: 70,
                  ),
                  Tab(
                    icon: Icon(Icons.history, size: 20),
                    text: 'جميع الإشعارات',
                    height: 70,
                  ),
                  Tab(
                    icon: Icon(Icons.analytics, size: 20),
                    text: 'الإحصائيات',
                    height: 70,
                  ),
                  Tab(
                    icon: Icon(Icons.assessment, size: 20),
                    text: 'التقرير الشامل',
                    height: 70,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentAbsences(),
                _buildAllAbsences(),
                _buildAbsenceStatistics(),
                _buildComprehensiveReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE91E63),
            Color(0xFFAD1457),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إشعارات الغياب',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'متابعة إشعارات الغياب من أولياء الأمور',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Stats
          StreamBuilder<List<AbsenceModel>>(
            stream: _databaseService.getAllAbsencesStream(),
            builder: (context, snapshot) {
              final allAbsences = snapshot.data ?? [];
              final parentAbsences = allAbsences.where((a) => a.source == AbsenceSource.parent).toList();
              final pendingCount = parentAbsences.where((a) => a.status == AbsenceStatus.pending).length;
              final approvedCount = parentAbsences.where((a) => a.status == AbsenceStatus.approved).length;
              final rejectedCount = parentAbsences.where((a) => a.status == AbsenceStatus.rejected).length;
              final totalCount = parentAbsences.length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'اليوم',
                      _getTodayAbsencesCount(parentAbsences).toString(),
                      Icons.today,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'هذا الأسبوع',
                      _getWeekAbsencesCount(parentAbsences).toString(),
                      Icons.date_range,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'هذا الشهر',
                      _getMonthAbsencesCount(parentAbsences).toString(),
                      Icons.calendar_month,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'الإجمالي',
                      totalCount.toString(),
                      Icons.assessment,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAbsences() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header indicator - Compact
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.blue.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.blue, size: 18),
                SizedBox(width: 6),
                Text(
                  'الإشعارات الحديثة (آخر 7 أيام)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getAllAbsencesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('خطأ: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final allAbsences = snapshot.data ?? [];

                // فلترة الإشعارات الحديثة من أولياء الأمور (آخر 7 أيام)
                final recentDate = DateTime.now().subtract(const Duration(days: 7));
                final recentParentNotifications = allAbsences
                    .where((absence) =>
                        absence.source == AbsenceSource.parent &&
                        absence.createdAt.isAfter(recentDate))
                    .toList();

                // ترتيب حسب التاريخ (الأحدث أولاً)
                recentParentNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (recentParentNotifications.isEmpty) {
                  return _buildEmptyState(
                    'لا توجد إشعارات حديثة',
                    'لم يتم إرسال إشعارات غياب في آخر 7 أيام',
                    Icons.notifications_off,
                    Colors.blue,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: recentParentNotifications.length,
                  itemBuilder: (context, index) {
                    final absence = recentParentNotifications[index];
                    return _buildSimpleAbsenceCard(absence);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAbsences() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'جميع الإشعارات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getAllAbsencesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAbsences = snapshot.data ?? [];
                final parentAbsences = allAbsences
                    .where((absence) => absence.source == AbsenceSource.parent)
                    .toList();

                // ترتيب حسب التاريخ (الأحدث أولاً)
                parentAbsences.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (parentAbsences.isEmpty) {
                  return _buildEmptyState(
                    'لا توجد إشعارات غياب',
                    'لم يرسل أولياء الأمور أي إشعارات غياب بعد',
                    Icons.notifications_off,
                    Colors.green,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: parentAbsences.length,
                  itemBuilder: (context, index) {
                    final absence = parentAbsences[index];
                    return _buildSimpleAbsenceCard(absence);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceStatistics() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.purple.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'الإحصائيات والتقارير',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getAllAbsencesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAbsences = snapshot.data ?? [];
                final parentAbsences = allAbsences
                    .where((absence) => absence.source == AbsenceSource.parent)
                    .toList();

                if (parentAbsences.isEmpty) {
                  return _buildEmptyState(
                    'لا توجد بيانات للإحصائيات',
                    'لا توجد إشعارات غياب لعرض الإحصائيات',
                    Icons.analytics,
                    Colors.purple,
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatisticsCard('إحصائيات الغياب', [
                        _buildStatRow('إجمالي الإشعارات', parentAbsences.length.toString()),
                        _buildStatRow('إشعارات اليوم', _getTodayAbsencesCount(parentAbsences).toString()),
                        _buildStatRow('إشعارات هذا الأسبوع', _getWeekAbsencesCount(parentAbsences).toString()),
                        _buildStatRow('إشعارات هذا الشهر', _getMonthAbsencesCount(parentAbsences).toString()),
                      ]),
                      const SizedBox(height: 16),
                      _buildStatisticsCard('أنواع الغياب', [
                        _buildStatRow('مرض', _getAbsenceTypeCount(parentAbsences, AbsenceType.sick).toString()),
                        _buildStatRow('ظروف عائلية', _getAbsenceTypeCount(parentAbsences, AbsenceType.family).toString()),
                        _buildStatRow('سفر', _getAbsenceTypeCount(parentAbsences, AbsenceType.travel).toString()),
                        _buildStatRow('طوارئ', _getAbsenceTypeCount(parentAbsences, AbsenceType.emergency).toString()),
                        _buildStatRow('أخرى', _getAbsenceTypeCount(parentAbsences, AbsenceType.other).toString()),
                      ]),
                      const SizedBox(height: 16),
                      _buildStatisticsCard('حالة الإشعارات', [
                        _buildStatRow('معلقة', parentAbsences.where((a) => a.status == AbsenceStatus.pending).length.toString()),
                        _buildStatRow('مقبولة', parentAbsences.where((a) => a.status == AbsenceStatus.approved).length.toString()),
                        _buildStatRow('مرفوضة', parentAbsences.where((a) => a.status == AbsenceStatus.rejected).length.toString()),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 64,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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



  Widget _buildSimpleAbsenceCard(AbsenceModel absence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(absence.status).withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person_off,
                    color: _getStatusColor(absence.status),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absence.studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        absence.typeDisplayText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(absence.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    absence.statusDisplayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Details
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'تاريخ الغياب: ${_formatDate(absence.date)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (absence.endDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'إلى تاريخ: ${_formatDate(absence.endDate!)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'تم الإرسال: ${_formatDateTime(absence.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'السبب: ${absence.reason}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (absence.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ملاحظات: ${absence.notes}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),

            // Notification Status
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'تم استلام الإشعار',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'من ${absence.approvedBy ?? 'ولي الأمر'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Helper methods for statistics
  int _getTodayAbsencesCount(List<AbsenceModel> absences) {
    final today = DateTime.now();
    return absences.where((absence) {
      return absence.date.year == today.year &&
          absence.date.month == today.month &&
          absence.date.day == today.day;
    }).length;
  }

  int _getWeekAbsencesCount(List<AbsenceModel> absences) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return absences.where((absence) => absence.date.isAfter(weekStart)).length;
  }

  int _getMonthAbsencesCount(List<AbsenceModel> absences) {
    final now = DateTime.now();
    return absences.where((absence) {
      return absence.date.year == now.year && absence.date.month == now.month;
    }).length;
  }

  int _getAbsenceTypeCount(List<AbsenceModel> absences, AbsenceType type) {
    return absences.where((absence) => absence.type == type).length;
  }

  Widget _buildStatisticsCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }



  Color _getStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  // Helper methods for formatting
  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  Widget _buildComprehensiveReport() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(Icons.assessment, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'التقرير الشامل للحضور والغياب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _databaseService.getAllStudentsWithAbsenceData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    'خطأ في تحميل البيانات',
                    'حدث خطأ أثناء تحميل بيانات الطلاب',
                    Icons.error,
                    Colors.red,
                  );
                }

                final studentsData = snapshot.data ?? [];

                if (studentsData.isEmpty) {
                  return _buildEmptyState(
                    'لا توجد بيانات',
                    'لا يوجد طلاب مسجلين في النظام',
                    Icons.school,
                    Colors.teal,
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Summary Statistics Card
                      _buildReportSummaryCard(studentsData),
                      const SizedBox(height: 16),

                      // Students Report List
                      ...studentsData.map((studentData) =>
                        _buildStudentReportCard(studentData)
                      ).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummaryCard(List<Map<String, dynamic>> studentsData) {
    final totalStudents = studentsData.length;
    final totalAbsences = studentsData.fold<int>(
      0,
      (sum, student) => sum + (student['absences'] as List).length,
    );

    final studentsWithAbsences = studentsData
        .where((student) => (student['absences'] as List).isNotEmpty)
        .length;

    final averageAbsenceRate = totalStudents > 0
        ? (totalAbsences / totalStudents).toStringAsFixed(1)
        : '0.0';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.teal.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'ملخص التقرير الشامل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'إجمالي الطلاب',
                    totalStudents.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'إجمالي الغيابات',
                    totalAbsences.toString(),
                    Icons.event_busy,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'طلاب لديهم غيابات',
                    studentsWithAbsences.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'متوسط الغيابات',
                    averageAbsenceRate,
                    Icons.analytics,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentReportCard(Map<String, dynamic> studentData) {
    final student = studentData['student'];
    final absences = studentData['absences'] as List<AbsenceModel>;

    // Calculate statistics
    final totalAbsences = absences.length;
    final approvedAbsences = absences.where((a) => a.status == AbsenceStatus.approved).length;
    final pendingAbsences = absences.where((a) => a.status == AbsenceStatus.pending).length;
    final rejectedAbsences = absences.where((a) => a.status == AbsenceStatus.rejected).length;

    // Calculate attendance rate (assuming 30 days per month for simplicity)
    final totalSchoolDays = 30; // This could be made dynamic
    final attendanceRate = totalSchoolDays > 0
        ? ((totalSchoolDays - approvedAbsences) / totalSchoolDays * 100).toStringAsFixed(1)
        : '100.0';

    // Determine status color
    Color statusColor = Colors.green;
    String statusText = 'ممتاز';
    if (double.parse(attendanceRate) < 70) {
      statusColor = Colors.red;
      statusText = 'يحتاج متابعة';
    } else if (double.parse(attendanceRate) < 85) {
      statusColor = Colors.orange;
      statusText = 'مقبول';
    } else if (double.parse(attendanceRate) < 95) {
      statusColor = Colors.blue;
      statusText = 'جيد';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(51),
          child: Text(
            student['name']?.substring(0, 1) ?? 'ط',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student['name'] ?? 'غير محدد',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${student['schoolName']} - ${student['grade']}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.analytics, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  'نسبة الحضور: $attendanceRate% ($statusText)',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalAbsences غياب',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatisticItem(
                        'مقبولة',
                        approvedAbsences.toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildStatisticItem(
                        'معلقة',
                        pendingAbsences.toString(),
                        Colors.orange,
                        Icons.pending,
                      ),
                    ),
                    Expanded(
                      child: _buildStatisticItem(
                        'مرفوضة',
                        rejectedAbsences.toString(),
                        Colors.red,
                        Icons.cancel,
                      ),
                    ),
                  ],
                ),

                if (absences.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Recent Absences
                  Row(
                    children: [
                      const Icon(Icons.history, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        'آخر الغيابات:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...absences.take(3).map((absence) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getAbsenceStatusColor(absence.status).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getAbsenceStatusColor(absence.status).withAlpha(76),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getAbsenceTypeIcon(absence.type),
                          size: 16,
                          color: _getAbsenceStatusColor(absence.status),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getAbsenceTypeText(absence.type),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                DateFormat('yyyy/MM/dd').format(absence.date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getAbsenceStatusColor(absence.status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getAbsenceStatusText(absence.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  if (absences.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'و ${absences.length - 3} غيابات أخرى...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 2),
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
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAbsenceStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getAbsenceTypeIcon(AbsenceType type) {
    switch (type) {
      case AbsenceType.sick:
        return Icons.local_hospital;
      case AbsenceType.family:
        return Icons.family_restroom;
      case AbsenceType.travel:
        return Icons.flight;
      case AbsenceType.emergency:
        return Icons.emergency;
      case AbsenceType.other:
        return Icons.help;
    }
  }

  String _getAbsenceTypeText(AbsenceType type) {
    switch (type) {
      case AbsenceType.sick:
        return 'مرض';
      case AbsenceType.family:
        return 'ظروف عائلية';
      case AbsenceType.travel:
        return 'سفر';
      case AbsenceType.emergency:
        return 'طوارئ';
      case AbsenceType.other:
        return 'أخرى';
    }
  }

  String _getAbsenceStatusText(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return 'معلق';
      case AbsenceStatus.approved:
        return 'مقبول';
      case AbsenceStatus.rejected:
        return 'مرفوض';
    }
  }

}


