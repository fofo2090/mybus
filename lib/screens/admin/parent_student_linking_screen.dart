import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/parent_student_link_service.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../models/parent_student_link_model.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_bottom_navigation.dart';

class ParentStudentLinkingScreen extends StatefulWidget {
  const ParentStudentLinkingScreen({super.key});

  @override
  State<ParentStudentLinkingScreen> createState() => _ParentStudentLinkingScreenState();
}

class _ParentStudentLinkingScreenState extends State<ParentStudentLinkingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ParentStudentLinkService _linkService = ParentStudentLinkService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // متغيرات جديدة لتحديد عدة طلاب
  final Set<String> _selectedStudentIds = {};
  bool _isMultiSelectMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'ربط الطلاب بأولياء الأمور المسجلين',
        actions: [
          // زر عرض الروابط الموجودة
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => context.push('/admin/parent-student-links-view'),
            tooltip: 'عرض الروابط الموجودة',
          ),
          // زر للتبديل بين وضع التحديد الفردي والمتعدد
          IconButton(
            icon: Icon(_isMultiSelectMode ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: () {
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
                _selectedStudentIds.clear();
              });
            },
            tooltip: _isMultiSelectMode ? 'إلغاء التحديد المتعدد' : 'تفعيل التحديد المتعدد',
          ),
          // زر للربط الجماعي (يظهر فقط في وضع التحديد المتعدد وعند تحديد طلاب)
          if (_isMultiSelectMode && _selectedStudentIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _showMultiLinkDialog,
              tooltip: 'ربط الطلاب المحددين',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Unlinked Students List
          Expanded(
            child: _buildUnlinkedStudentsList(),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث عن طالب غير مربوط...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildUnlinkedStudentsList() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('لا يوجد طلاب'),
          );
        }

        // فلترة الطلاب غير المربوطين
        final allStudents = snapshot.data!;
        final unlinkedStudents = allStudents.where((student) {
          final matchesSearch = _searchQuery.isEmpty ||
              student.name.toLowerCase().contains(_searchQuery) ||
              student.parentName.toLowerCase().contains(_searchQuery) ||
              student.parentEmail.toLowerCase().contains(_searchQuery);
          
          // هنا يمكن إضافة منطق للتحقق من الطلاب غير المربوطين
          final isUnlinked = student.parentId.isEmpty || student.parentId.startsWith('parent_');
          
          return matchesSearch && isUnlinked;
        }).toList();

        if (unlinkedStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'جميع الطلاب مربوطون بأولياء أمورهم',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: unlinkedStudents.length,
          itemBuilder: (context, index) {
            final student = unlinkedStudents[index];
            return _buildStudentCard(student);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    final isSelected = _selectedStudentIds.contains(student.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // إضافة خانة اختيار في وضع التحديد المتعدد
                if (_isMultiSelectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedStudentIds.add(student.id);
                        } else {
                          _selectedStudentIds.remove(student.id);
                        }
                      });
                    },
                  ),

                CircleAvatar(
                  backgroundColor: Colors.orange,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('ولي الأمر: ${student.parentName}'),
                      Text('الهاتف: ${student.parentPhone}'),
                      Text('البريد: ${student.parentEmail}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'غير مربوط',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // في وضع التحديد المتعدد، إظهار زر الإلغاء فقط
                if (_isMultiSelectMode)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedStudentIds.remove(student.id);
                        });
                      },
                      icon: const Icon(Icons.remove_circle, size: 18),
                      label: const Text('إلغاء التحديد'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  )
                else
                  // في وضع التحديد الفردي، إظهار زر الربط الفردي
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showLinkDialog(student),
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('اختيار ولي أمر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStudentDetails(student),
                    icon: const Icon(Icons.info, size: 18),
                    label: const Text('التفاصيل'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ربط الطالب: ${student.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر ولي الأمر من القائمة لربطه بالطالب',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildAvailableParentsList(student),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الطالب: ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الاسم', student.name),
            _buildDetailRow('ولي الأمر', student.parentName),
            _buildDetailRow('الهاتف', student.parentPhone),
            _buildDetailRow('البريد', student.parentEmail),
            _buildDetailRow('المدرسة', student.schoolName),
            _buildDetailRow('الصف', student.grade),
            _buildDetailRow('العنوان', student.address),
            _buildDetailRow('خط الحافلة', student.busRoute),
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
      padding: const EdgeInsets.only(bottom: 8),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAvailableParentsList(StudentModel student) {
    return StreamBuilder<List<UserModel>>(
<<<<<<< HEAD
      stream: _databaseService.getAvailableParents(),
=======
      stream: _getAllActiveParents(),
>>>>>>> 30d4977 (fix connect student)
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في تحميل أولياء الأمور: ${snapshot.error}'),
          );
        }

        final parents = snapshot.data ?? [];

        if (parents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا يوجد أولياء أمور متاحين للربط',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: parents.length,
          itemBuilder: (context, index) {
            final parent = parents[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E88E5),
                  child: Text(
                    parent.name.isNotEmpty ? parent.name[0] : 'و',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(parent.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parent.email),
                    Text(parent.phone),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _linkStudentToParent(student, parent);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ربط'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _linkStudentToParent(StudentModel student, UserModel parent) async {
    try {
      // ربط الطالب بولي الأمر باستخدام الخدمة المحسنة
      await _linkService.linkStudentToParent(student.id, parent.id);

      // إرسال إشعار لولي الأمر
      await _databaseService.sendNotificationToParent(
        parentId: parent.id,
        title: 'تم ربط طفل جديد',
        message: 'تم ربط الطالب ${student.name} بحسابك بنجاح',
        data: {
          'type': 'student_linked',
          'studentId': student.id,
          'studentName': student.name,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم ربط الطالب ${student.name} بولي الأمر ${parent.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في ربط الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة جديدة لعرض نافذة حوار الربط الجماعي
  void _showMultiLinkDialog() {
    if (_selectedStudentIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ربط ${_selectedStudentIds.length} طالب بولي الأمر'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر ولي الأمر من القائمة لربطه بـ ${_selectedStudentIds.length} طالب',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildAvailableParentsListForMultiLink(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  // دالة جديدة لبناء قائمة أولياء الأمور للربط الجماعي
  Widget _buildAvailableParentsListForMultiLink() {
    return StreamBuilder<List<UserModel>>(
<<<<<<< HEAD
      stream: _databaseService.getAvailableParents(),
=======
      stream: _getAllActiveParents(),
>>>>>>> 30d4977 (fix connect student)
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في تحميل أولياء الأمور: ${snapshot.error}'),
          );
        }

        final parents = snapshot.data ?? [];

        if (parents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا يوجد أولياء أمور متاحين للربط',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: parents.length,
          itemBuilder: (context, index) {
            final parent = parents[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E88E5),
                  child: Text(
                    parent.name.isNotEmpty ? parent.name[0] : 'و',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(parent.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parent.email),
                    Text(parent.phone),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _linkMultipleStudentsToParent(parent);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ربط الكل'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // دالة جديدة لربط عدة طلاب بولي الأمر واحد
  Future<void> _linkMultipleStudentsToParent(UserModel parent) async {
    if (_selectedStudentIds.isEmpty) return;

    final studentCount = _selectedStudentIds.length;

    try {
      // ربط جميع الطلاب المحددين بولي الأمر باستخدام الخدمة المحسنة
      await _linkService.linkMultipleStudentsToParent(_selectedStudentIds.toList(), parent.id);

      // إرسال إشعار لولي الأمر
      await _databaseService.sendNotificationToParent(
        parentId: parent.id,
        title: 'تم ربط أطفال جدد',
        message: 'تم ربط $studentCount طالب بحسابك بنجاح',
        data: {
          'type': 'multiple_students_linked',
          'studentCount': studentCount,
        },
      );

      // مسح قائمة الطلاب المحددين
      setState(() {
        _selectedStudentIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم ربط $studentCount طالب بولي الأمر ${parent.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في ربط الطلاب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
<<<<<<< HEAD
=======

  /// Get all active parents (allowing multiple students per parent)
  Stream<List<UserModel>> _getAllActiveParents() {
    return _databaseService.firestore
        .collection('users')
        .where('userType', isEqualTo: 'parent')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<UserModel> allParents = [];

          for (var doc in snapshot.docs) {
            try {
              final parent = UserModel.fromMap(doc.data());
              allParents.add(parent);
            } catch (e) {
              print('❌ Error parsing parent data: $e');
            }
          }

          // Sort by name
          allParents.sort((a, b) => a.name.compareTo(b.name));
          return allParents;
        });
  }
>>>>>>> 30d4977 (fix connect student)
}
