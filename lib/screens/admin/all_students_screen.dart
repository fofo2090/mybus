import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/enhanced_notification_service.dart';
import '../../utils/constants.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  String _searchQuery = '';
  String _selectedGrade = 'الكل';
  String _selectedStatus = 'الكل';

  final List<String> _grades = [
    'الكل',
    'كي جي 1',
    'كي جي 2',
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'الأول الإعدادي',
    'الثاني الإعدادي',
    'الثالث الإعدادي',
  ];

  final List<String> _statuses = [
    'الكل',
    'في المنزل',
    'في الباص',
    'في المدرسة'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الطلاب',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'عرض وإدارة جميع الطلاب',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1976D2),
                Color(0xFF1565C0),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/admin/add-student'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة طالب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E88E5),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'البحث والفلترة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن طالب...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[400], size: 16),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filters Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                            color: Colors.white,
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGrade,
                            decoration: InputDecoration(
                              hintText: 'الصف الدراسي',
                              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 4),
                                child: Icon(Icons.class_, color: Colors.grey[500], size: 16),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF2D3748)),
                            items: _grades.map((grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(
                                  grade,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGrade = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                            color: Colors.white,
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              hintText: 'حالة الطالب',
                              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 4),
                                child: Icon(Icons.location_on, color: Colors.grey[500], size: 16),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF2D3748)),
                            items: _statuses.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getStatusColorFromText(status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      status,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Students List
          Expanded(
            child: StreamBuilder<List<StudentModel>>(
              stream: _databaseService.getAllStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1E88E5).withAlpha(25),
                                  const Color(0xFF1976D2).withAlpha(25),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(
                              color: Color(0xFF1E88E5),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'جاري تحميل الطلاب...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى الانتظار قليلاً',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'خطأ في تحميل البيانات',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'حدث خطأ أثناء تحميل قائمة الطلاب',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allStudents = snapshot.data ?? [];
                final filteredStudents = _filterStudents(allStudents);

                // Sort students by QR code from smallest to largest (robustly)
                filteredStudents.sort((a, b) {
                  final int aQr = int.tryParse(a.qrCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  final int bQr = int.tryParse(b.qrCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  return aQr.compareTo(bQr);
                });

                if (filteredStudents.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey[100]!,
                                  Colors.grey[50]!,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              allStudents.isEmpty ? Icons.school_outlined : Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            allStudents.isEmpty ? 'لا يوجد طلاب مسجلين' : 'لا توجد نتائج للبحث',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            allStudents.isEmpty
                                ? 'ابدأ بإضافة أول طالب في النظام'
                                : 'جرب تغيير معايير البحث أو الفلترة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (allStudents.isEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E88E5).withAlpha(76),
                                    spreadRadius: 0,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/admin/add-student'),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text(
                                  'إضافة طالب جديد',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedGrade = 'الكل';
                                      _selectedStatus = 'الكل';
                                    });
                                  },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('إعادة تعيين الفلاتر'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E88E5),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Statistics Cards
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'الكل',
                              '${allStudents.length}',
                              Icons.school,
                              const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'المعروض',
                              '${filteredStudents.length}',
                              Icons.filter_list,
                              const Color(0xFF43A047),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'بالباص',
                              '${filteredStudents.where((s) => s.currentStatus == StudentStatus.onBus).length}',
                              Icons.directions_bus,
                              const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Students List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return _buildModernStudentCard(student, index);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

    );
  }

  List<StudentModel> _filterStudents(List<StudentModel> students) {
    return students.where((student) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.schoolName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.busRoute.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.parentName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by grade - more flexible matching
      final matchesGrade = _selectedGrade == 'الكل' ||
          student.grade == _selectedGrade ||
          student.grade.contains(_selectedGrade) ||
          _selectedGrade.contains(student.grade);

      // Filter by status
      final matchesStatus = _selectedStatus == 'الكل' ||
          _getStatusText(student.currentStatus) == _selectedStatus;

      return matchesSearch && matchesGrade && matchesStatus;
    }).toList();
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

  Color _getStatusColorFromText(String status) {
    switch (status) {
      case 'في المنزل':
        return Colors.green;
      case 'في الباص':
        return Colors.orange;
      case 'في المدرسة':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: color.withAlpha(51), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStudentCard(StudentModel student, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showStudentDetails(student),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Student Avatar
                    Hero(
                      tag: 'student_avatar_${student.id}',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1E88E5),
                              const Color(0xFF1976D2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E88E5).withAlpha(76),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            student.name.isNotEmpty ? student.name[0] : 'ط',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Student Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${student.schoolName} - ${student.grade}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'ولي الأمر: ${student.parentName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(student.currentStatus).withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(student.currentStatus).withAlpha(76),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(student.currentStatus),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(student.currentStatus),
                            style: TextStyle(
                              color: _getStatusColor(student.currentStatus),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Details Row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.directions_bus,
                          'خط الباص',
                          student.busRoute.isNotEmpty ? student.busRoute : 'غير محدد',
                          const Color(0xFF1E88E5),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.qr_code,
                          'رمز QR',
                          student.qrCode,
                          const Color(0xFF43A047),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.phone,
                          'هاتف ولي الأمر',
                          student.parentPhone.isNotEmpty ? student.parentPhone : 'غير محدد',
                          const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'عرض التفاصيل',
                        Icons.visibility,
                        const Color(0xFF1E88E5),
                        () => _showStudentDetails(student),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'تعديل',
                        Icons.edit,
                        const Color(0xFF43A047),
                        () => context.push('/admin/students/edit/${student.id}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'تسكين باص',
                        Icons.directions_bus,
                        const Color(0xFFFF9800),
                        () => _showBusAssignmentDialog(student),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          radius: 25,
          child: Text(
            student.name.isNotEmpty ? student.name[0] : 'ط',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.school, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${student.schoolName} - ${student.grade}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'خط الباص: ${student.busRoute}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(student.currentStatus).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(student.currentStatus),
                style: TextStyle(
                  color: _getStatusColor(student.currentStatus),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[700],
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
                splashRadius: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                offset: const Offset(0, 40),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'عرض التفاصيل',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
                          SizedBox(width: 12),
                          Text(
                            'تعديل البيانات',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'assign_bus',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.directions_bus_outlined, size: 18, color: Colors.green),
                          SizedBox(width: 12),
                          Text(
                            'تسكين الباص',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'حذف الطالب',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onSelected: (String value) {
                  // Add a small delay to ensure the menu closes properly
                  Future.delayed(const Duration(milliseconds: 100), () {
                    switch (value) {
                      case 'edit':
                        context.push('/admin/students/edit/${student.id}');
                        break;
                      case 'assign_bus':
                        _showBusAssignmentDialog(student);
                        break;
                      case 'view':
                        _showStudentDetails(student);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(student);
                        break;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الاسم', student.name),
            _buildDetailRow('المدرسة', student.schoolName),
            _buildDetailRow('الصف', student.grade),
            _buildDetailRow('خط الباص', student.busRoute),
            _buildDetailRow('ولي الأمر', student.parentName),
            _buildDetailRow('هاتف ولي الأمر', student.parentPhone),
            _buildDetailRow('الحالة', _getStatusText(student.currentStatus)),
            _buildDetailRow('رمز QR', student.qrCode),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الطالب "${student.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _databaseService.deleteStudent(student.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الطالب بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف الطالب: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showBusAssignmentDialog(StudentModel student) {
    String? selectedBusId = student.busId.isNotEmpty ? student.busId : null;
    String selectedBusRoute = student.busRoute;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسكين الباص',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current assignment info
                if (student.busId.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(76)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الطالب مسكن حالياً في خط: ${student.busRoute}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'اختر الباص المناسب للطالب:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<BusModel>>(
                  stream: _databaseService.getAllBuses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('جاري تحميل الباصات...'),
                            ],
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withAlpha(76)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'خطأ في تحميل الباصات: ${snapshot.error}',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final buses = snapshot.data?.where((bus) => bus.isActive).toList() ?? [];

                    if (buses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withAlpha(76)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('لا توجد باصات نشطة متاحة'),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedBusId,
                      decoration: InputDecoration(
                        labelText: 'اختيار الباص',
                        hintText: 'اختر باص من القائمة',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.directions_bus, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
                              SizedBox(width: 8),
                              Text('بدون باص', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        ...buses.map((bus) {
                          return DropdownMenuItem<String>(
                            value: bus.id,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bus.plateNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        bus.route,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedBusId = value;
                          if (value != null) {
                            final selectedBus = buses.firstWhere((bus) => bus.id == value);
                            selectedBusRoute = selectedBus.route;
                          } else {
                            selectedBusRoute = '';
                          }
                        });
                      },
                    );
                  },
                ),

                if (selectedBusId != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.withAlpha(25), Colors.blue.withAlpha(51)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withAlpha(76)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.info,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'معلومات الباص المختار',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.route, 'خط السير', selectedBusRoute),
                        const SizedBox(height: 4),
                        FutureBuilder<BusModel?>(
                          future: _databaseService.getBus(selectedBusId!),
                          builder: (context, busSnapshot) {
                            if (busSnapshot.hasData) {
                              final bus = busSnapshot.data!;
                              return Column(
                                children: [
                                  _buildInfoRow(Icons.person, 'السائق', bus.driverName),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.people, 'السعة', '${bus.capacity} طالب'),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: selectedBusId != null || student.busId.isNotEmpty
                  ? () => _assignStudentToBus(student, selectedBusId, selectedBusRoute)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedBusId != null ? Icons.save : Icons.remove_circle,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedBusId != null ? 'حفظ التسكين' : 'إلغاء التسكين',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignStudentToBus(StudentModel student, String? busId, String busRoute) async {
    // Close the assignment dialog first
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    // Get current user for admin exclusion
    final currentUser = FirebaseAuth.instance.currentUser;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري حفظ التسكين...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    try {

      // Validate input data
      if (busId != null && busId.isEmpty) {
        throw Exception('معرف الباص غير صحيح');
      }

      if (busId != null && busRoute.isEmpty) {
        throw Exception('خط السير مطلوب عند اختيار باص');
      }

      // Create updated student with proper validation
      final updatedStudent = student.copyWith(
        busId: busId ?? '',
        busRoute: busRoute.trim(),
        updatedAt: DateTime.now(),
      );

      // Validate student data before update
      if (updatedStudent.id.isEmpty) {
        throw Exception('معرف الطالب مفقود');
      }

      // Update student in database
      await _databaseService.updateStudent(updatedStudent);

      // إرسال إشعارات التحديث
      await _sendBusAssignmentNotifications(student, updatedStudent, busId, busRoute);

      // إرسال إشعار التسكين أو إلغاء التسكين مع الصوت (النظام القديم للتوافق)
      if (busId != null) {
        // تسكين جديد
        final busDoc = await FirebaseFirestore.instance
            .collection('buses')
            .doc(busId)
            .get();

        if (busDoc.exists) {
          final busData = busDoc.data()!;
          await NotificationService().notifyStudentAssignmentWithSound(
            studentId: student.id,
            studentName: student.name,
            busId: busId,
            busRoute: busRoute,
            parentId: student.parentId,
            supervisorId: busData['supervisorId'] ?? '',
            parentName: student.parentName ?? 'ولي الأمر',
            parentPhone: student.parentPhone ?? 'غير محدد',
            excludeAdminId: currentUser?.uid, // استبعاد الإدمن الحالي
          );
        }
      } else if (student.busId.isNotEmpty) {
        // إلغاء تسكين
        final busDoc = await FirebaseFirestore.instance
            .collection('buses')
            .doc(student.busId)
            .get();

        if (busDoc.exists) {
          final busData = busDoc.data()!;
          await NotificationService().notifyStudentUnassignmentWithSound(
            studentId: student.id,
            studentName: student.name,
            busId: student.busId,
            parentId: student.parentId,
            supervisorId: busData['supervisorId'] ?? '',
            excludeAdminId: currentUser?.uid, // استبعاد الإدمن الحالي
          );
        }
      }

      // Close loading dialog and show success message
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  busId != null ? Icons.check_circle : Icons.remove_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    busId != null
                        ? 'تم تسكين ${student.name} في الباص بنجاح'
                        : 'تم إلغاء تسكين ${student.name} من الباص',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خطأ في تحديث تسكين الباص: ${e.toString().replaceAll('Exception: ', '')}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _assignStudentToBus(student, busId, busRoute),
            ),
          ),
        );
      }
    }
  }

  // Helper method to build info rows with icon, label and value
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(25),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// إرسال إشعارات تحديث تسكين الباص
  Future<void> _sendBusAssignmentNotifications(
    StudentModel originalStudent,
    StudentModel updatedStudent,
    String? newBusId,
    String busRoute,
  ) async {
    try {
      // Get current user for admin exclusion
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final adminName = adminDoc.data()?['name'] ?? 'الإدارة';

      // تحديد نوع التغيير
      final updatedFields = <String, dynamic>{};

      if (originalStudent.busId != updatedStudent.busId) {
        // الحصول على أسماء الباصات للعرض
        String oldBusName = 'غير محدد';
        String newBusName = 'غير محدد';

        if (originalStudent.busId.isNotEmpty) {
          final oldBusDoc = await FirebaseFirestore.instance
              .collection('buses')
              .doc(originalStudent.busId)
              .get();
          if (oldBusDoc.exists) {
            oldBusName = oldBusDoc.data()?['plateNumber'] ?? 'غير محدد';
          }
        }

        if (updatedStudent.busId.isNotEmpty) {
          final newBusDoc = await FirebaseFirestore.instance
              .collection('buses')
              .doc(updatedStudent.busId)
              .get();
          if (newBusDoc.exists) {
            newBusName = newBusDoc.data()?['plateNumber'] ?? 'غير محدد';
          }
        }

        updatedFields['busId'] = {
          'old': oldBusName,
          'new': newBusName,
        };
      }

      // إرسال الإشعارات إذا كان هناك تغييرات
      if (updatedFields.isNotEmpty) {
        await _notificationService.notifyStudentDataUpdate(
          studentId: updatedStudent.id,
          studentName: updatedStudent.name,
          parentId: updatedStudent.parentId,
          busId: updatedStudent.busId,
          updatedFields: updatedFields,
          adminName: adminName,
          adminId: currentUser?.uid, // استبعاد الإدمن الحالي من الإشعارات
        );
      }

      debugPrint('✅ Bus assignment notifications sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending bus assignment notifications: $e');
    }
  }
}