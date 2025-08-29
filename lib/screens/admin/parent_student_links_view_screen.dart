import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/parent_student_link_service.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../models/parent_student_link_model.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_bottom_navigation.dart';

class ParentStudentLinksViewScreen extends StatefulWidget {
  const ParentStudentLinksViewScreen({super.key});

  @override
  State<ParentStudentLinksViewScreen> createState() => _ParentStudentLinksViewScreenState();
}

class _ParentStudentLinksViewScreenState extends State<ParentStudentLinksViewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ParentStudentLinkService _linkService = ParentStudentLinkService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'عرض روابط أولياء الأمور والطلاب',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: () => context.push('/admin/parent-student-linking'),
            tooltip: 'إضافة روابط جديدة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Links List
          Expanded(
            child: _buildLinksList(),
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
          hintText: 'البحث عن ولي أمر أو طالب...',
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

  Widget _buildLinksList() {
    return StreamBuilder<List<ParentStudentLinkModel>>(
      stream: _linkService.getAllParentStudentLinks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد روابط بين أولياء الأمور والطلاب',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final links = snapshot.data!;
        final filteredLinks = links.where((link) {
          if (_searchQuery.isEmpty) return true;
          
          return link.parentEmail.toLowerCase().contains(_searchQuery) ||
                 link.parentPhone.contains(_searchQuery);
        }).toList();

        if (filteredLinks.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد نتائج للبحث',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredLinks.length,
          itemBuilder: (context, index) {
            final link = filteredLinks[index];
            return _buildLinkCard(link);
          },
        );
      },
    );
  }

  Widget _buildLinkCard(ParentStudentLinkModel link) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          child: Text(
            link.parentEmail.isNotEmpty ? link.parentEmail[0].toUpperCase() : 'و',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'ولي الأمر',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('البريد: ${link.parentEmail}'),
            Text('الهاتف: ${link.parentPhone}'),
            Text('عدد الطلاب: ${link.studentIds.length}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'مربوط',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          _buildStudentsList(link.studentIds),
        ],
      ),
    );
  }

  Widget _buildStudentsList(List<String> studentIds) {
    if (studentIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'لا توجد طلاب مربوطين',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('خطأ في تحميل بيانات الطلاب'),
          );
        }

        final allStudents = snapshot.data!;
        final linkedStudents = allStudents
            .where((student) => studentIds.contains(student.id))
            .toList();

        return Column(
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.school, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'الطلاب المربوطين (${linkedStudents.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...linkedStudents.map((student) => _buildStudentTile(student)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildStudentTile(StudentModel student) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange,
        radius: 20,
        child: Text(
          student.name.isNotEmpty ? student.name[0] : 'ط',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(student.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المدرسة: ${student.schoolName}'),
          Text('الصف: ${student.grade}'),
          Text('خط الحافلة: ${student.busRoute}'),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'unlink') {
            _showUnlinkConfirmation(student);
          } else if (value == 'details') {
            _showStudentDetails(student);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.info, size: 20),
                SizedBox(width: 8),
                Text('التفاصيل'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'unlink',
            child: Row(
              children: [
                Icon(Icons.link_off, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('إلغاء الربط', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlinkConfirmation(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إلغاء الربط'),
        content: Text('هل أنت متأكد من إلغاء ربط الطالب "${student.name}" من ولي الأمر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unlinkStudent(student);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('إلغاء الربط'),
          ),
        ],
      ),
    );
  }

  Future<void> _unlinkStudent(StudentModel student) async {
    try {
      await _linkService.unlinkStudentFromParent(student.id, student.parentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إلغاء ربط الطالب ${student.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إلغاء ربط الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            _buildDetailRow('الحالة', student.statusDisplayText),
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
          Expanded(child: Text(value.isEmpty ? 'غير محدد' : value)),
        ],
      ),
    );
  }
}