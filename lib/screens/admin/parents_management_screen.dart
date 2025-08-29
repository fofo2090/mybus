import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/email_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/responsive_grid_view.dart';
import '../../widgets/responsive_text.dart';
import '../../utils/responsive_helper.dart';

class ParentsManagementScreen extends StatefulWidget {
  const ParentsManagementScreen({super.key});

  @override
  State<ParentsManagementScreen> createState() => _ParentsManagementScreenState();
}

class _ParentsManagementScreenState extends State<ParentsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final EmailService _emailService = EmailService();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(
        title: 'إدارة أولياء الأمور',
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: Color(0xFF1E88E5),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إدارة أولياء الأمور',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إضافة وإدارة حسابات أولياء الأمور',
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
          
          // Parents List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('parent_profiles')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'خطأ في تحميل البيانات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E88E5),
                    ),
                  );
                }

                final parents = snapshot.data?.docs ?? [];

                if (parents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.family_restroom_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا يوجد أولياء أمور',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'انقر على + لإضافة ولي أمر جديد',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final parentData = parents[index].data() as Map<String, dynamic>;
                    final parentId = parents[index].id;

                    // Create a temporary UserModel for compatibility
                    final tempParent = UserModel(
                      id: parentId,
                      name: parentData['fullName'] ?? '',
                      email: parentData['email'] ?? '',
                      phone: parentData['phone'] ?? parentData['fatherPhone'] ?? '',
                      userType: UserType.parent,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: (parentData['phone'] ?? parentData['fatherPhone'] ?? '').isNotEmpty
                              ? Colors.green
                              : Colors.orange,
                          child: Text(
                            parentData['fullName']?.isNotEmpty == true
                                ? parentData['fullName'][0]
                                : 'و',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          parentData['fullName'] ?? parentData['email'] ?? 'غير محدد',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(parentData['email'] ?? 'غير محدد')),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(parentData['phone'] ?? parentData['fatherPhone'] ?? 'غير محدد'),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  (parentData['phone'] ?? parentData['fatherPhone'] ?? '').isNotEmpty
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  size: 16,
                                  color: (parentData['phone'] ?? parentData['fatherPhone'] ?? '').isNotEmpty
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (parentData['phone'] ?? parentData['fatherPhone'] ?? '').isNotEmpty
                                      ? 'معلومات الاتصال متوفرة'
                                      : 'معلومات الاتصال مفقودة',
                                  style: TextStyle(
                                    color: (parentData['phone'] ?? parentData['fatherPhone'] ?? '').isNotEmpty
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // عرض عدد الأطفال
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('students')
                                  .where('parentId', isEqualTo: parentId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final childrenCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                return Row(
                                  children: [
                                    const Icon(Icons.child_care, size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      'عدد الأطفال: $childrenCount',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'details',
                              child: const Row(
                                children: [
                                  Icon(Icons.info, size: 20, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('عرض التفاصيل'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'students',
                              child: const Row(
                                children: [
                                  Icon(Icons.school, size: 20, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('عرض الأطفال'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'notify',
                              child: const Row(
                                children: [
                                  Icon(Icons.notifications, size: 20, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('إرسال إشعار'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'test_notify',
                              child: const Row(
                                children: [
                                  Icon(Icons.bug_report, size: 20, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Text('إشعار تجريبي'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditParentDialog(tempParent);
                                break;
                              case 'details':
                                _showParentDetails(tempParent);
                                break;
                              case 'students':
                                _showParentStudents(tempParent);
                                break;
                              case 'notify':
                                _showNotificationDialog(tempParent);
                                break;
                              case 'test_notify':
                                _sendTestNotification(tempParent);
                                break;
                              case 'delete':
                                _showDeleteConfirmation(tempParent);
                                break;
                            }
                          },
                        ),
                        children: [
                          // عرض البيانات الإضافية للوالد
                          if ((parentData['phone'] ?? parentData['fatherPhone'] ?? '').isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'البيانات الشخصية:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('العنوان', parentData['address'] ?? 'غير محدد'),
                                  _buildDetailRow('الوظيفة', parentData['occupation'] ?? 'غير محدد'),
                                  _buildDetailRow('رقم الهاتف', parentData['phone'] ?? parentData['fatherPhone'] ?? 'غير محدد'),
                                  _buildDetailRow('هاتف الوالدة', parentData['motherPhone'] ?? 'غير محدد'),
                                  _buildDetailRow('تاريخ التسجيل',
                                    parentData['createdAt'] != null
                                        ? DateTime.parse(parentData['createdAt']).toString().split(' ')[0]
                                        : 'غير محدد'),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'البروفايل غير مكتمل - يحتاج الوالد لإكمال بياناته الشخصية',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // عرض الأطفال المرتبطين
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('students')
                                .where('parentId', isEqualTo: parentId)
                                .snapshots(),
                            builder: (context, studentSnapshot) {
                              if (!studentSnapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final students = studentSnapshot.data!.docs;
                              
                              if (students.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'لا يوجد أطفال مسجلين لهذا الولي',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return Column(
                                children: students.map((studentDoc) {
                                  final studentData = studentDoc.data() as Map<String, dynamic>;
                                  return ListTile(
                                    leading: const Icon(Icons.child_care, color: Colors.blue),
                                    title: Text(studentData['name'] ?? ''),
                                    subtitle: Text('${studentData['schoolName']} - ${studentData['grade']}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(studentData['currentStatus']) == Colors.green
                                            ? Colors.green.shade50
                                            : _getStatusColor(studentData['currentStatus']) == Colors.orange
                                            ? Colors.orange.shade50
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(studentData['currentStatus']),
                                        style: TextStyle(
                                          color: _getStatusColor(studentData['currentStatus']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddParentDialog,
        backgroundColor: const Color(0xFF1E88E5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة ولي أمر',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'home':
        return Colors.green;
      case 'onBus':
        return Colors.orange;
      case 'atSchool':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'home':
        return 'في المنزل';
      case 'onBus':
        return 'في الباص';
      case 'atSchool':
        return 'في المدرسة';
      default:
        return 'غير محدد';
    }
  }





  void _showEditParentDialog(UserModel parent) {
    final nameController = TextEditingController(text: parent.name);
    final phoneController = TextEditingController(text: parent.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل بيانات ولي الأمر'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _updateParent(
                  parent.id,
                  nameController.text.trim(),
                  phoneController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateParent(String id, String name, String phone) async {
    try {
      await _firestore.collection('users').doc(id).update({
        'name': name,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // تحديث الواجهة
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات ولي الأمر بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showParentStudents(UserModel parent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('أطفال ${parent.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('students')
                .where('parentId', isEqualTo: parent.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final students = snapshot.data!.docs;

              if (students.isEmpty) {
                return const Text('لا يوجد أطفال مسجلين لهذا الولي');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final studentData = students[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.child_care, color: Colors.blue),
                    title: Text(studentData['name'] ?? ''),
                    subtitle: Text('${studentData['schoolName']} - ${studentData['grade']}'),
                  );
                },
              );
            },
          ),
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

  void _showNotificationDialog(UserModel parent) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرسال إشعار إلى ${parent.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإشعار',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال عنوان الإشعار';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'نص الإشعار',
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال نص الإشعار';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _sendNotification(
                  parent,
                  titleController.text.trim(),
                  messageController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotification(UserModel parent, String title, String message) async {
    try {
      // إضافة الإشعار إلى قاعدة البيانات
      await _firestore.collection('notifications').add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'recipientId': parent.id,
        'title': title,
        'body': message,
        'type': 'general',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': _authService.currentUser?.uid,
        'data': {
          'source': 'admin',
          'parentId': parent.id,
        },
      });

      // إرسال إيميل
      await _emailService.sendParentNotification(
        parentEmail: parent.email,
        parentName: parent.name,
        title: title,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الإشعار بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الإشعار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification(UserModel parent) async {
    try {
      final testNotifications = [
        {
          'title': 'ركب ${parent.name} الباص',
          'body': 'ركب طفلك الباص بأمان في ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'type': 'studentBoarded',
        },
        {
          'title': 'وصل إلى المدرسة',
          'body': 'وصل طفلك إلى المدرسة بأمان',
          'type': 'studentLeft',
        },
        {
          'title': 'إشعار من الإدارة',
          'body': 'هذا إشعار تجريبي من إدارة المدرسة للتأكد من عمل النظام',
          'type': 'general',
        },
      ];

      for (var notification in testNotifications) {
        await _firestore.collection('notifications').add({
          'id': DateTime.now().millisecondsSinceEpoch.toString() + testNotifications.indexOf(notification).toString(),
          'recipientId': parent.id,
          'title': notification['title'],
          'body': notification['body'],
          'type': notification['type'],
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
          'createdBy': _authService.currentUser?.uid,
          'data': {
            'source': 'test',
            'parentId': parent.id,
          },
        });

        // تأخير بسيط بين الإشعارات
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال ${testNotifications.length} إشعارات تجريبية إلى ${parent.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الإشعارات التجريبية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(UserModel parent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف ولي الأمر "${parent.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteParent(parent.id);
              if (context.mounted) Navigator.pop(context);
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

  Future<void> _deleteParent(String id) async {
    try {
      // حذف ولي الأمر من قاعدة البيانات
      await _firestore.collection('users').doc(id).delete();

      if (mounted) {
        // تحديث الواجهة
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف ولي الأمر بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف ولي الأمر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddParentDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ولي أمر جديد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _addParent(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  phoneController.text.trim(),
                  passwordController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _addParent(String name, String email, String phone, String password) async {
    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        userType: UserType.parent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة ولي الأمر بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة ولي الأمر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showParentDetails(UserModel parent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تفاصيل ولي الأمر',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Information Section
                _buildDetailSection(
                  title: 'المعلومات الأساسية',
                  icon: Icons.info,
                  color: Colors.blue,
                  children: [
                    _buildDetailRow('الاسم الكامل', parent.name.isNotEmpty ? parent.name : 'غير محدد'),
                    _buildDetailRow('البريد الإلكتروني', parent.email),
                    _buildDetailRow('رقم الهاتف', parent.phone.isNotEmpty ? parent.phone : 'غير محدد'),
                    _buildDetailRow('تاريخ التسجيل', _formatDate(parent.createdAt)),
                    _buildDetailRow('آخر تحديث', _formatDate(parent.updatedAt)),
                  ],
                ),

                const SizedBox(height: 16),

                // Account Status Section
                _buildDetailSection(
                  title: 'حالة الحساب',
                  icon: parent.isActive ? Icons.check_circle : Icons.warning,
                  color: parent.isActive ? Colors.green : Colors.orange,
                  children: [
                    _buildDetailRow('نوع المستخدم', _getUserTypeDisplay(parent.userType)),
                    _buildDetailRow('حالة الحساب', parent.isActive ? 'نشط' : 'غير نشط'),
                  ],
                ),

                const SizedBox(height: 16),

                // Children Information Section
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('students')
                      .where('parentId', isEqualTo: parent.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final students = snapshot.data?.docs ?? [];

                    return _buildDetailSection(
                      title: 'الأطفال المسجلين (${students.length})',
                      icon: Icons.child_care,
                      color: Colors.purple,
                      children: students.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'لا يوجد أطفال مسجلين',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ]
                          : students.map((studentDoc) {
                              final studentData = studentDoc.data() as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.withAlpha(76)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentData['name'] ?? 'غير محدد',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'المدرسة: ${studentData['schoolName'] ?? 'غير محدد'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'الصف: ${studentData['grade'] ?? 'غير محدد'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (studentData['busRoute'] != null && studentData['busRoute'].toString().isNotEmpty)
                                      Text(
                                        'خط الباص: ${studentData['busRoute']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditParentDialog(parent);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getUserTypeDisplay(UserType userType) {
    switch (userType) {
      case UserType.parent:
        return 'ولي أمر';
      case UserType.supervisor:
        return 'مشرفة';
      case UserType.admin:
        return 'مدير';
    }
  }
}
