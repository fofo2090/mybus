import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/database_service.dart';
import '../../services/notification_sender_service.dart';
import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/base64_image_widget.dart';
import '../../widgets/admin_bottom_navigation.dart';
import '../../widgets/responsive_grid_view.dart';
import '../../widgets/responsive_text.dart';
import '../../utils/responsive_helper.dart';

// فئة لتجميع الطلاب حسب ولي الأمر
class ParentGroup {
  final String parentId;
  final String parentName;
  final String parentPhone;
  final List<StudentModel> students;

  ParentGroup({
    required this.parentId,
    required this.parentName,
    required this.parentPhone,
    required this.students,
  });
}

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationSenderService _notificationSender = NotificationSenderService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StudentStatus? _selectedStatus;
  String? _selectedGrade;
  String? _selectedSchool;
  bool _isFABExpanded = false;
  bool _groupByParent = true; // العرض المجمع افتراضياً

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5),
            const Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة الطلاب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'إدارة بيانات الطلاب والتسكين',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<StudentModel>>(
              stream: _databaseService.getAllStudents(),
              builder: (context, snapshot) {
                final students = snapshot.data ?? [];
                final activeStudents = students.where((s) => s.isActive).length;
                final assignedStudents = students.where((s) => s.busId.isNotEmpty).length;

                return Row(
                  children: [
                    _buildStatCard('إجمالي الطلاب', students.length.toString(), Icons.people),
                    const SizedBox(width: 12),
                    _buildStatCard('الطلاب النشطين', activeStudents.toString(), Icons.check_circle),
                    const SizedBox(width: 12),
                    _buildStatCard('المسكنين', assignedStudents.toString(), Icons.directions_bus),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(76)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          _buildHeader(),

          // Search Bar
          _buildSearchBar(),

          // Filters
          _buildFilters(),

          // Students List
          Expanded(
            child: _buildStudentsList(),
          ),
        ],
      ),
      floatingActionButton: _buildExpandableFAB(),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'البحث عن طالب بالاسم أو المدرسة أو رقم الهاتف...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search,
                color: Colors.grey[600],
                size: 22,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
          ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // First Row: Status and Grade
          Row(
            children: [
              // Status Filter
              Expanded(
                flex: 2,
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StudentStatus?>(
                      value: _selectedStatus,
                      hint: const Text('الحالة', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      items: [
                        const DropdownMenuItem<StudentStatus?>(
                          value: null,
                          child: Text('الكل', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem<StudentStatus?>(
                          value: StudentStatus.home,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home, size: 14, color: Colors.green),
                              const SizedBox(width: 6),
                              const Text('منزل', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem<StudentStatus?>(
                          value: StudentStatus.onBus,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_bus, size: 14, color: Colors.orange),
                              const SizedBox(width: 6),
                              const Text('باص', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem<StudentStatus?>(
                          value: StudentStatus.atSchool,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school, size: 14, color: Colors.blue),
                              const SizedBox(width: 6),
                              const Text('مدرسة', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Grade Filter
              Expanded(
                flex: 2,
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedGrade,
                      hint: const Text('الصف', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('الكل', style: TextStyle(fontSize: 13)),
                        ),
                        ...['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس']
                            .map((grade) => DropdownMenuItem<String?>(
                                  value: grade,
                                  child: Text('$grade', style: const TextStyle(fontSize: 13)),
                                )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGrade = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Group Toggle Button
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: _groupByParent ? const Color(0xFF1E88E5) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _groupByParent = !_groupByParent;
                    });
                  },
                  icon: Icon(
                    _groupByParent ? Icons.group : Icons.list,
                    size: 18,
                    color: _groupByParent ? Colors.white : Colors.grey[600],
                  ),
                  tooltip: _groupByParent ? 'عرض قائمة' : 'تجميع حسب ولي الأمر',
                ),
              ),
              const SizedBox(width: 8),
              // Clear Filters Button
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedGrade = null;
                      _selectedSchool = null;
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  tooltip: 'مسح',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second Row: School Filter
          StreamBuilder<List<StudentModel>>(
            stream: _databaseService.getAllStudents(),
            builder: (context, snapshot) {
              final students = snapshot.data ?? [];
              final schools = students
                  .where((s) => s.schoolName.isNotEmpty)
                  .map((s) => s.schoolName)
                  .toSet()
                  .toList();
              schools.sort();

              return Row(
                children: [
                  // School Filter
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedSchool,
                          hint: const Text('المدرسة', style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('جميع المدارس', style: TextStyle(fontSize: 13)),
                            ),
                            ...schools.map((school) => DropdownMenuItem<String?>(
                                  value: school,
                                  child: Text(
                                    school,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSchool = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Empty space to align with buttons above
                  Container(
                    height: 45,
                    width: 45 + 8 + 45, // Width of two buttons + spacing
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
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
                CustomButton(
                  text: 'إعادة المحاولة',
                  onPressed: () => setState(() {}),
                  width: 200,
                ),
              ],
            ),
          );
        }

        final allStudents = snapshot.data ?? [];
        final filteredStudents = allStudents.where((student) {
          // Search filter
          bool matchesSearch = _searchQuery.isEmpty ||
              student.name.toLowerCase().contains(_searchQuery) ||
              student.grade.toLowerCase().contains(_searchQuery) ||
              student.schoolName.toLowerCase().contains(_searchQuery) ||
              student.parentName.toLowerCase().contains(_searchQuery);

          // Status filter
          bool matchesStatus = _selectedStatus == null ||
              student.currentStatus == _selectedStatus;

          // Grade filter
          bool matchesGrade = _selectedGrade == null ||
              student.grade.contains(_selectedGrade!);

          // School filter
          bool matchesSchool = _selectedSchool == null ||
              student.schoolName == _selectedSchool;

          return matchesSearch && matchesStatus && matchesGrade && matchesSchool;
        }).toList();

        // ترتيب الطلاب حسب QR Code من الأصغر إلى الأكبر
        filteredStudents.sort((a, b) {
          // استخراج الأرقام من QR Code وترتيبها رقمياً
          final int aQr = int.tryParse(a.qrCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final int bQr = int.tryParse(b.qrCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return aQr.compareTo(bQr);
        });

        if (filteredStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isEmpty ? Icons.school : Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'لا يوجد طلاب مسجلين'
                      : 'لا توجد نتائج للبحث',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'اضغط على زر إضافة طالب لبدء التسجيل'
                      : 'جرب البحث بكلمات مختلفة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        if (_groupByParent) {
          // العرض المجمع حسب ولي الأمر
          final groupedStudents = _groupStudentsByParent(filteredStudents);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groupedStudents.length,
            itemBuilder: (context, index) {
              final parentGroup = groupedStudents[index];
              return _buildParentGroup(parentGroup);
            },
          );
        } else {
          // العرض العادي كقائمة
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              return _buildStudentCard(student, isInGroup: false);
            },
          );
        }
      },
    );
  }

  // تجميع الطلاب حسب ولي الأمر
  List<ParentGroup> _groupStudentsByParent(List<StudentModel> students) {
    final Map<String, List<StudentModel>> groupedMap = {};

    for (final student in students) {
      final parentKey = '${student.parentId}_${student.parentName}';
      if (!groupedMap.containsKey(parentKey)) {
        groupedMap[parentKey] = [];
      }
      groupedMap[parentKey]!.add(student);
    }

    // تحويل إلى قائمة مرتبة
    final groups = groupedMap.entries.map((entry) {
      final students = entry.value;
      
      // ترتيب الطلاب داخل كل مجموعة حسب QR Code
      students.sort((a, b) {
        // استخراج الأرقام من QR Code وترتيبها رقمياً
        final int aQr = int.tryParse(a.qrCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final int bQr = int.tryParse(b.qrCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return aQr.compareTo(bQr);
      });
      
      return ParentGroup(
        parentId: students.first.parentId,
        parentName: students.first.parentName,
        parentPhone: students.first.parentPhone,
        students: students,
      );
    }).toList();

    // ترتيب المجموعات حسب اسم ولي الأمر
    groups.sort((a, b) => a.parentName.compareTo(b.parentName));

    return groups;
  }

  Widget _buildParentGroup(ParentGroup parentGroup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1E88E5).withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E88E5).withOpacity(0.1),
                  const Color(0xFF1E88E5).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: Color(0xFF1E88E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentGroup.parentName.isNotEmpty
                            ? parentGroup.parentName
                            : 'ولي أمر غير محدد',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      if (parentGroup.parentPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          parentGroup.parentPhone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${parentGroup.students.length} طالب',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Students List
          ...parentGroup.students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            final isLast = index == parentGroup.students.length - 1;

            return Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: isLast ? 16 : 8,
              ),
              child: _buildStudentCard(student, isInGroup: true),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student, {bool isInGroup = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isInGroup ? 0 : 8),
      decoration: BoxDecoration(
        color: isInGroup ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(isInGroup ? 8 : 12),
        boxShadow: isInGroup ? [] : [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isInGroup
              ? const Color(0xFF1E88E5).withOpacity(0.1)
              : Colors.grey.withAlpha(25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getStatusColor(student.currentStatus).withAlpha(76),
                      width: 2,
                    ),
                  ),
                  child: StudentAvatarWidget(
                    imageUrl: student.photoUrl,
                    studentName: student.name,
                    radius: 22,
                  ),
                ),
                const SizedBox(width: 12),
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
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${student.grade}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                student.schoolName,
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(student.currentStatus),
              ],
            ),

            const SizedBox(height: 10),

            // Information Section
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(51)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person_outline, 'ولي الأمر', student.parentName),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone_outlined, 'الهاتف', student.parentPhone),
                  const SizedBox(height: 8),
                  _buildBusInfoRow(student),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.qr_code_outlined, 'رمز QR', student.qrCode),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'عرض',
                    Icons.visibility_outlined,
                    Colors.blue,
                    () => _showStudentDetails(student),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'تعديل',
                    Icons.edit_outlined,
                    Colors.orange,
                    () => _showEditStudentDialog(student),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'حذف',
                    Icons.delete_outline,
                    Colors.red,
                    () => _showDeleteConfirmation(student),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withAlpha(25),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withAlpha(76)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 3),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBusInfoRow(StudentModel student) {
    if (student.busId.isEmpty) {
      return Row(
        children: [
          Icon(Icons.directions_bus_outlined, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'السيارة: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              'لم يتم تعيين سيارة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange[600],
              ),
            ),
          ),
        ],
      );
    }

    return FutureBuilder<BusModel?>(
      future: _databaseService.getBus(student.busId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Icon(Icons.directions_bus, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'السيارة: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1),
              ),
            ],
          );
        }

        final bus = snapshot.data;
        if (bus == null) {
          return Row(
            children: [
              Icon(Icons.directions_bus_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'السيارة: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  'سيارة غير موجودة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Icon(Icons.directions_bus, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'السيارة: ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                '${bus.plateNumber} - ${bus.driverName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(StudentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case StudentStatus.home:
        backgroundColor = Colors.green.withAlpha(25);
        textColor = Colors.green[700]!;
        icon = Icons.home_rounded;
        text = 'في المنزل';
        break;
      case StudentStatus.onBus:
        backgroundColor = Colors.orange.withAlpha(25);
        textColor = Colors.orange[700]!;
        icon = Icons.directions_bus_rounded;
        text = 'في الباص';
        break;
      case StudentStatus.atSchool:
        backgroundColor = Colors.blue.withAlpha(25);
        textColor = Colors.blue[700]!;
        icon = Icons.school_rounded;
        text = 'في المدرسة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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

  void _showAddStudentDialog() {
    context.push('/admin/students/add');
  }

  void _showStudentDetails(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1E88E5),
              child: Text(
                student.name.isNotEmpty ? student.name[0] : 'ط',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                student.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('معرف الطالب', student.id),
              _buildDetailRow('الصف الدراسي', student.grade),
              _buildDetailRow('اسم المدرسة', student.schoolName),
              _buildDetailRow('ولي الأمر', student.parentName),
              _buildDetailRow('رقم الهاتف', student.parentPhone),
              _buildDetailRow('رمز QR', student.qrCode),
              _buildDetailRow('تاريخ التسجيل', _formatDate(student.createdAt)),
              _buildDetailRow('آخر تحديث', _formatDate(student.updatedAt)),
              if (student.busId.isNotEmpty) ...[
                const Divider(),
                FutureBuilder<BusModel?>(
                  future: _databaseService.getBus(student.busId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final bus = snapshot.data;
                    if (bus == null) {
                      return _buildDetailRow('السيارة', 'غير موجودة');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات السيارة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('رقم اللوحة', bus.plateNumber),
                        _buildDetailRow('السائق', bus.driverName),
                        _buildDetailRow('رقم السائق', bus.driverPhone),
                        _buildDetailRow('خط السير', bus.route),
                        _buildDetailRow('السعة', '${bus.capacity} راكب'),
                        _buildDetailRow('التكييف', bus.hasAirConditioning ? 'مكيفة' : 'غير مكيفة'),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditStudentDialog(student);
            },
            child: const Text('تعديل'),
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditStudentDialog(StudentModel student) {
    context.push('/admin/students/edit/${student.id}');
  }

  void _showDeleteConfirmation(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الطالب: ${student.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStudent(student);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(StudentModel student) async {
    try {
      await _databaseService.deleteStudent(student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الطالب ${student.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// تحديث حالة الطالب مع إرسال إشعار لولي الأمر
  Future<void> _updateStudentStatus({
    required StudentModel student,
    required StudentStatus newStatus,
    String? location,
    String? notes,
  }) async {
    try {
      // تحديث حالة الطالب في قاعدة البيانات
      final updatedStudent = student.copyWith(
        currentStatus: newStatus,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateStudent(updatedStudent);

      // إرسال إشعار لولي الأمر
      if (student.parentId.isNotEmpty) {
        String statusText;
        switch (newStatus) {
          case StudentStatus.home:
            statusText = 'home';
            break;
          case StudentStatus.onBus:
            statusText = 'onBus';
            break;
          case StudentStatus.atSchool:
            statusText = 'atSchool';
            break;
          default:
            statusText = newStatus.toString().split('.').last;
        }

        await _notificationSender.sendStudentStatusNotificationToParent(
          parentId: student.parentId,
          studentName: student.name,
          status: statusText,
          busNumber: student.busId, // استخدام busId بدلاً من busNumber
          location: location,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة الطالب ${student.name} وإرسال إشعار لولي الأمر'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث حالة الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// إرسال رسالة إدارية لولي أمر محدد
  Future<void> _sendMessageToParent({
    required String parentId,
    required String studentName,
    required String title,
    required String message,
  }) async {
    try {
      await _notificationSender.sendAdminMessage(
        title: title,
        message: message,
        targetUserId: parentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال الرسالة لولي أمر $studentName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرسالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportExcelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('استيراد الطلاب من Excel'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يمكنك استيراد قائمة الطلاب من ملف Excel بالتنسيق التالي:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الأعمدة المطلوبة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• اسم الطالب'),
                  Text('• اسم ولي الأمر'),
                  Text('• رقم هاتف ولي الأمر'),
                  Text('• بريد ولي الأمر الإلكتروني'),
                  Text('• اسم المدرسة'),
                  Text('• الصف'),
                  Text('• العنوان'),
                  Text('• خط الحافلة'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadTemplate();
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('تحميل النموذج'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickExcelFile();
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text('اختيار ملف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
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

  void _downloadTemplate() async {
    try {
      // إنشاء ملف Excel جديد
      var excelFile = excel.Excel.createExcel();
      excel.Sheet sheetObject = excelFile['نموذج الطلاب'];

      // إضافة العناوين
      final headers = [
        'اسم الطالب',
        'اسم ولي الأمر',
        'رقم هاتف ولي الأمر',
        'بريد ولي الأمر الإلكتروني',
        'اسم المدرسة',
        'الصف',
        'العنوان',
        'خط الحافلة'
      ];

      for (int i = 0; i < headers.length; i++) {
        sheetObject.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = excel.TextCellValue(headers[i]);
      }

      // إضافة صف مثال
      final exampleData = [
        'أحمد محمد علي',
        'محمد علي أحمد',
        '01234567890',
        'mohamed.ali@example.com',
        'مدرسة النور الابتدائية',
        'الصف الثالث',
        'شارع الجمهورية، المنصورة',
        'خط 1'
      ];

      for (int i = 0; i < exampleData.length; i++) {
        sheetObject.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          .value = excel.TextCellValue(exampleData[i]);
      }

      // حفظ الملف
      final bytes = excelFile.encode();
      if (bytes != null) {
        // في التطبيق الحقيقي، يمكن حفظ الملف في مجلد التحميلات
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء نموذج Excel بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء النموذج: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _pickExcelFile() async {
    try {
      // اختيار ملف Excel
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري معالجة ملف Excel...'),
            backgroundColor: Colors.orange,
          ),
        );

        Uint8List? fileBytes;
        if (kIsWeb) {
          fileBytes = result.files.single.bytes;
        } else {
          final file = File(result.files.single.path!);
          fileBytes = await file.readAsBytes();
        }

        if (fileBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم قراءة الملف بنجاح'), backgroundColor: Colors.red),
          );
          return;
        }

        final excelFile = excel.Excel.decodeBytes(fileBytes);
        List<Map<String, String>> studentsData = [];

        // قراءة البيانات من أول ورقة عمل
        for (var table in excelFile.tables.keys) {
          final sheet = excelFile.tables[table];
          if (sheet != null && sheet.maxRows > 1) {
            // تخطي الصف الأول (العناوين)
            for (int row = 1; row < sheet.maxRows; row++) {
              final rowData = sheet.row(row);

              // التأكد من وجود بيانات في الصف
              if (rowData.isNotEmpty && rowData[0]?.value != null) {
                studentsData.add({
                  'studentName': _getCellValue(rowData, 0),
                  'parentName': _getCellValue(rowData, 1),
                  'parentPhone': _getCellValue(rowData, 2),
                  'parentEmail': _getCellValue(rowData, 3),
                  'schoolName': _getCellValue(rowData, 4),
                  'grade': _getCellValue(rowData, 5),
                  'address': _getCellValue(rowData, 6),
                  'busRoute': _getCellValue(rowData, 7),
                });
              }
            }
            break; // قراءة أول ورقة عمل فقط
          }
        }

        if (studentsData.isNotEmpty) {
          _showImportPreview(studentsData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على بيانات صالحة في الملف'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في قراءة الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCellValue(List<excel.Data?> row, int index) {
    if (index < row.length && row[index]?.value != null) {
      return row[index]!.value.toString().trim();
    }
    return '';
  }

  void _showImportPreview(List<Map<String, String>> studentsData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معاينة البيانات المستوردة'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text('تم العثور على ${studentsData.length} طالب'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: studentsData.length,
                  itemBuilder: (context, index) {
                    final student = studentsData[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['studentName'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('ولي الأمر: ${student['parentName']}'),
                            Text('المدرسة: ${student['schoolName']}'),
                            Text('الصف: ${student['grade']}'),
                            Text('الخط: ${student['busRoute']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importStudents(studentsData);
            },
            child: const Text('استيراد الطلاب'),
          ),
        ],
      ),
    );
  }

  Future<void> _importStudents(List<Map<String, String>> studentsData) async {
    try {
      int successCount = 0;
      int errorCount = 0;

      for (final studentData in studentsData) {
        try {
          // إنشاء حساب ولي أمر مؤقت
          final parentId = 'parent_${DateTime.now().millisecondsSinceEpoch}_${successCount}';

          // إنشاء الطالب
          final student = StudentModel(
            id: '',
            name: studentData['studentName'] ?? '',
            parentId: parentId,
            parentName: studentData['parentName'] ?? '',
            parentPhone: studentData['parentPhone'] ?? '',
            parentEmail: studentData['parentEmail'] ?? '',
            qrCode: '',
            schoolName: studentData['schoolName'] ?? '',
            grade: studentData['grade'] ?? '',
            address: studentData['address'] ?? '',
            busRoute: studentData['busRoute'] ?? '',
            busId: '',
            photoUrl: null,
            currentStatus: StudentStatus.home,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _databaseService.addStudent(student);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Error importing student: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استيراد $successCount طالب بنجاح${errorCount > 0 ? '، فشل في استيراد $errorCount طالب' : ''}',
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استيراد الطلاب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExpandableFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded options with smooth animations
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isFABExpanded ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _isFABExpanded ? 1.0 : 0.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Staggered animation for each button
                _buildAnimatedFABOption(
                  delay: 0,
                  onPressed: () {
                    setState(() => _isFABExpanded = false);
                    context.push('/admin/parent-student-linking');
                  },
                  backgroundColor: const Color(0xFFFF9800),
                  icon: Icons.link,
                  label: 'ربط أولياء الأمور',
                ),
                const SizedBox(height: 8),
                _buildAnimatedFABOption(
                  delay: 25,
                  onPressed: () {
                    setState(() => _isFABExpanded = false);
                    context.push('/admin/parent-student-links-view');
                  },
                  backgroundColor: const Color(0xFF2196F3),
                  icon: Icons.visibility,
                  label: 'عرض الروابط',
                ),
                const SizedBox(height: 8),
                _buildAnimatedFABOption(
                  delay: 75,
                  onPressed: () {
                    setState(() => _isFABExpanded = false);
                    _showImportExcelDialog();
                  },
                  backgroundColor: const Color(0xFF4CAF50),
                  icon: Icons.upload_file,
                  label: 'استيراد Excel',
                ),
                const SizedBox(height: 8),
                _buildAnimatedFABOption(
                  delay: 100,
                  onPressed: () {
                    setState(() => _isFABExpanded = false);
                    _showAddStudentDialog();
                  },
                  backgroundColor: const Color(0xFF1E88E5),
                  icon: Icons.add,
                  label: 'إضافة طالب',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Main FAB with smooth rotation
        FloatingActionButton(
          onPressed: () {
            setState(() => _isFABExpanded = !_isFABExpanded);
          },
          backgroundColor: const Color(0xFF1E88E5),
          child: AnimatedRotation(
            turns: _isFABExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isFABExpanded ? Icons.close : Icons.add,
                key: ValueKey(_isFABExpanded),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedFABOption({
    required int delay,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String label,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.elasticOut,
      tween: Tween<double>(
        begin: _isFABExpanded ? 0.0 : 1.0,
        end: _isFABExpanded ? 1.0 : 0.0,
      ),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Opacity(
              opacity: value,
              child: FloatingActionButton.extended(
                onPressed: onPressed,
                backgroundColor: backgroundColor,
                heroTag: label,
                elevation: 4 * value,
                icon: Icon(icon, color: Colors.white, size: 20),
                label: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFABOption({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String label,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      heroTag: label,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}


