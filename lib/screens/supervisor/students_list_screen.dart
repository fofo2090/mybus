import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/student_model.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/responsive_widgets.dart';
import '../../utils/responsive_helper.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _supervisorRoute = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supervisorId = _authService.currentUser?.uid ?? '';
      debugPrint('🔍 Loading students for supervisor: $supervisorId');

      // استخدم نفس الدالة التي تعمل في الصفحة الرئيسية
      final students = await _loadSupervisorStudents(supervisorId);

      debugPrint('👥 Found ${students.length} students for supervisor');
      for (final student in students) {
        debugPrint('   - ${student.name} (Route: "${student.busRoute}", BusId: "${student.busId}", Active: ${student.isActive})');
      }

      if (mounted) {
        // Sort students by QR code
        students.sort((a, b) => a.qrCode.compareTo(b.qrCode));

        setState(() {
          _students = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading students: $e');
      if (mounted) {
        setState(() {
          _students = [];
          _filteredStudents = [];
          _isLoading = false;
        });
      }
    }
  }

  /// نفس الدالة المستخدمة في الصفحة الرئيسية للمشرف
  Future<List<StudentModel>> _loadSupervisorStudents(String supervisorId) async {
    try {
      debugPrint('🔄 Loading supervisor students for: $supervisorId');

      // استخدام الطريقة البسيطة
      final assignments = await _databaseService.getSupervisorAssignmentsSimple(supervisorId);
      debugPrint('📋 Found ${assignments.length} assignments for supervisor');

      if (assignments.isEmpty) {
        debugPrint('⚠️ No assignments found for supervisor $supervisorId');
        return <StudentModel>[];
      }

      final assignment = assignments.first;
      var busRoute = assignment.busRoute;
      var busId = assignment.busId;
      debugPrint('🚌 Assignment busRoute: "$busRoute"');
      debugPrint('🚌 Assignment busId: "$busId"');

      // إذا كان busRoute فارغ، احصل عليه من بيانات الباص
      if (busRoute.isEmpty && busId.isNotEmpty) {
        debugPrint('⚠️ busRoute is empty, fetching from bus data...');
        try {
          final bus = await _databaseService.getBusById(busId);
          if (bus != null) {
            busRoute = bus.route;
            debugPrint('✅ Got busRoute from bus: "$busRoute"');
          } else {
            debugPrint('❌ Bus not found for ID: $busId');
          }
        } catch (e) {
          debugPrint('❌ Error getting bus data: $e');
        }
      }

      // جلب الطلاب بطرق متعددة للتأكد من الحصول على البيانات
      List<StudentModel> students = [];

      // الطريقة الأولى: البحث بـ busRoute
      if (busRoute.isNotEmpty) {
        students = await _databaseService.getStudentsByRouteSimple(busRoute);
        debugPrint('👥 Found ${students.length} students by route "$busRoute"');
      }

      // الطريقة الثانية: البحث بـ busId إذا لم نجد طلاب بـ busRoute
      if (students.isEmpty && busId.isNotEmpty) {
        debugPrint('🔍 No students found by route, trying busId: $busId');
        students = await _databaseService.getStudentsByBusIdSimple(busId);
        debugPrint('👥 Found ${students.length} students by busId "$busId"');
      }

      // الطريقة الثالثة: البحث في الطلاب المسكنين فقط إذا لم نجد أي طلاب
      if (students.isEmpty) {
        debugPrint('🔍 No students found by route or busId, checking assigned students...');
        final assignedStudents = await _databaseService.getAssignedStudents();
        debugPrint('👥 Total assigned students in database: ${assignedStudents.length}');

        // فلترة الطلاب حسب busRoute أو busId
        students = assignedStudents.where((student) {
          final matchesRoute = busRoute.isNotEmpty && student.busRoute == busRoute;
          final matchesBusId = busId.isNotEmpty && student.busId == busId;
          debugPrint('🔍 Checking assigned student ${student.name}: route="${student.busRoute}", busId="${student.busId}"');
          return matchesRoute || matchesBusId;
        }).toList();

        debugPrint('👥 Found ${students.length} matching assigned students');
      }

      // طباعة تفاصيل الطلاب الموجودين
      for (final student in students) {
        debugPrint('   - ${student.name} (Route: "${student.busRoute}", BusId: "${student.busId}", Active: ${student.isActive})');
      }

      return students;
    } catch (e) {
      debugPrint('❌ Error loading supervisor students: $e');
      return <StudentModel>[];
    }
  }



  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          return student.name.toLowerCase().contains(query.toLowerCase()) ||
                 student.grade.toLowerCase().contains(query.toLowerCase()) ||
                 student.qrCode.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  int _getActiveStudentsCount() {
    return _students.where((student) => student.isActive).length;
  }

  int _getStudentsOnBusCount() {
    return _students.where((student) =>
      student.currentStatus == StudentStatus.onBus
    ).length;
  }

  int _getStudentsAtSchoolCount() {
    return _students.where((student) =>
      student.currentStatus == StudentStatus.atSchool
    ).length;
  }

  int _getStudentsAtHomeCount() {
    return _students.where((student) =>
      student.currentStatus == StudentStatus.home
    ).length;
  }

  int _getAbsentStudentsCount() {
    // يمكن تحسين هذا لاحقاً بناءً على بيانات الغياب الفعلية
    return _students.where((student) => !student.isActive).length;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Modern Header
          _buildModernHeader(),
          
          // Search Bar
          _buildSearchBar(),
          
          // Students List
          Expanded(
            child: _buildStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E88E5),
            const Color(0xFF1976D2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              // Top Row
              Row(
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'قائمة الطلاب',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_supervisorRoute.isNotEmpty)
                          Text(
                            'خط السير: $_supervisorRoute',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(204),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // QR Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats Row - More Compact
              if (_students.isEmpty && !_isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(76)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'لا يوجد طلاب مسجلين في هذا الخط حالياً',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _buildStatCard('إجمالي', _students.length.toString(), Icons.people)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('نشط', _getActiveStudentsCount().toString(), Icons.check_circle, Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('في الباص', _getStudentsOnBusCount().toString(), Icons.directions_bus, Colors.blue)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('في المدرسة', _getStudentsAtSchoolCount().toString(), Icons.school, Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('في المنزل', _getStudentsAtHomeCount().toString(), Icons.home, Colors.orange)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('غائب', _getAbsentStudentsCount().toString(), Icons.event_busy, Colors.red)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, [Color? color]) {
    final cardColor = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardColor.withAlpha(76),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withAlpha(204),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withAlpha(51),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterStudents,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'البحث بالاسم، الصف، أو رمز QR...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF1E88E5),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterStudents('');
                  },
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  padding: EdgeInsets.zero,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E88E5)),
            SizedBox(height: 16),
            Text('جاري تحميل الطلاب...'),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا يوجد طلاب',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'جرب البحث بكلمات مختلفة',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                _supervisorRoute.isNotEmpty
                    ? 'لا يوجد طلاب في خط السير: $_supervisorRoute'
                    : 'لم يتم تعيين خط سير لهذا المشرف',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _loadStudents();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة تحميل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 80, // إضافة مساحة كافية في الأسفل لعرض الطالب الأخير بالكامل
      ),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Student Header - Compact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(student.currentStatus).withAlpha(13),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Student Avatar - Smaller
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.currentStatus).withAlpha(38),
                    borderRadius: BorderRadius.circular(22.5),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _getStatusColor(student.currentStatus),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // Student Info - Flexible
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.grade,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status Badge - Compact
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.currentStatus).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(student.currentStatus).withAlpha(76),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(student.currentStatus),
                        size: 12,
                        color: _getStatusColor(student.currentStatus),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(student.currentStatus),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(student.currentStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Student Details - Compact
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Info Grid - 2x2 Layout
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _getParentName(student.parentId),
                        builder: (context, snapshot) {
                          final parentName = snapshot.data ?? student.parentName;
                          return _buildCompactInfoItem(
                            icon: Icons.person,
                            label: 'اسم ولي الأمر',
                            value: parentName.isNotEmpty ? parentName : 'غير محدد',
                            color: Colors.purple,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactInfoItem(
                        icon: Icons.phone,
                        label: 'هاتف الوالدة',
                        value: student.parentPhone.isNotEmpty ? student.parentPhone : 'غير محدد',
                        color: Colors.green,
                        onTap: student.parentPhone.isNotEmpty ? () => _callParent(student.parentPhone) : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Second Row - Address from Parent Profile
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _getParentAddress(student.parentId),
                        builder: (context, snapshot) {
                          final address = snapshot.data ?? 'جاري التحميل...';
                          return _buildCompactInfoItem(
                            icon: Icons.home,
                            label: 'عنوان ولي الأمر',
                            value: address,
                            color: Colors.blue,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // QR Code Section - Horizontal Layout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withAlpha(13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1E88E5).withAlpha(51),
                    ),
                  ),
                  child: Row(
                    children: [
                      // QR Code - Smaller
                      Container(
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: student.qrCode,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // QR Info - Flexible
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                const Text(
                                  'رمز QR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.qrCode,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Action Buttons - Vertical
                      Column(
                        children: [
                          // Copy Button
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () => _copyQRCode(student.qrCode),
                              icon: const Icon(
                                Icons.copy,
                                size: 16,
                                color: Color(0xFF1E88E5),
                              ),
                              tooltip: 'نسخ',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // View Button
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () => _showQRCodeDialog(student),
                              icon: Icon(
                                Icons.fullscreen,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              tooltip: 'عرض كامل',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value.isNotEmpty ? value : 'غير محدد',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: value.isNotEmpty ? Colors.grey[800] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null && value.isNotEmpty)
              Icon(
                Icons.phone_enabled,
                color: color,
                size: 12,
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.grey;
      case StudentStatus.onBus:
        return Colors.orange;
      case StudentStatus.atSchool:
        return Colors.green;
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



  Future<void> _callParent(String phoneNumber) async {
    try {
      // تنظيف رقم الهاتف من المسافات والرموز الإضافية
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // إضافة +20 إذا كان الرقم مصري ولا يبدأ بـ +
      if (!cleanedNumber.startsWith('+') && cleanedNumber.startsWith('01')) {
        cleanedNumber = '+2$cleanedNumber';
      } else if (!cleanedNumber.startsWith('+') && cleanedNumber.startsWith('2')) {
        cleanedNumber = '+$cleanedNumber';
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

      // محاولة فتح تطبيق الاتصال
      bool launched = false;

      try {
        launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('❌ Error with launchUrl: $e');
        launched = false;
      }

      if (!launched) {
        // محاولة بديلة باستخدام intent على Android
        try {
          final Uri dialerUri = Uri.parse('tel:$cleanedNumber');
          launched = await launchUrl(dialerUri);
        } catch (e) {
          debugPrint('❌ Error with alternative launch: $e');
        }
      }

      if (!launched && mounted) {
        // عرض dialog مع خيارات بديلة
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('الاتصال بولي الأمر'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('لا يمكن فتح تطبيق الاتصال تلقائياً'),
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
                              content: Text('تم نسخ الرقم'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'نسخ الرقم',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _callParent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في معالجة رقم الهاتف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyQRCode(String qrCode) async {
    try {
      await Clipboard.setData(ClipboardData(text: qrCode));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم نسخ رمز QR: $qrCode'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error copying QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في نسخ رمز QR'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQRCodeDialog(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - Compact
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Color(0xFF1E88E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رمز QR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          student.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Large QR Code - Responsive
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: student.qrCode,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // QR Code Text - Compact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withAlpha(13),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF1E88E5).withAlpha(51),
                  ),
                ),
                child: Text(
                  student.qrCode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons - Compact
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _copyQRCode(student.qrCode);
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.copy,
                        size: 16,
                        color: Color(0xFF1E88E5),
                      ),
                      label: const Text(
                        'نسخ',
                        style: TextStyle(
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5).withAlpha(25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.withAlpha(25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'إغلاق',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // Get parent name from profile
  Future<String> _getParentName(String parentId) async {
    try {
      final profile = await _databaseService.getParentProfile(parentId);
      if (profile != null && profile.fullName.isNotEmpty) {
        return profile.fullName;
      }
      return 'غير محدد';
    } catch (e) {
      debugPrint('Error getting parent name: $e');
      return 'غير محدد';
    }
  }

  // Get parent address from profile
  Future<String> _getParentAddress(String parentId) async {
    try {
      final profile = await _databaseService.getParentProfile(parentId);
      if (profile != null && profile.address.isNotEmpty) {
        return profile.address;
      }
      return 'غير محدد';
    } catch (e) {
      debugPrint('Error getting parent address: $e');
      return 'غير محدد';
    }
  }
}


