import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_sender_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/admin_bottom_navigation.dart';

/// صفحة إرسال الإشعارات الإدارية
class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final NotificationSenderService _notificationSender = NotificationSenderService();

  String _selectedUserType = 'all'; // all, admin, supervisor, parent
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إرسال إشعار إداري'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة معلومات
              Card(
                elevation: 2,
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
                          Icon(Icons.info, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'إرسال إشعار إداري',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'يمكنك إرسال إشعارات إدارية لجميع المستخدمين أو لفئة محددة. سيصل الإشعار كـ Push Notification خارج التطبيق.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // اختيار نوع المستخدمين
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المستهدفون',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // خيارات المستخدمين
                      _buildUserTypeOption('all', 'جميع المستخدمين', Icons.people, Colors.purple),
                      _buildUserTypeOption('admin', 'الإدارة فقط', Icons.admin_panel_settings, Colors.blue),
                      _buildUserTypeOption('supervisor', 'المشرفين فقط', Icons.supervisor_account, Colors.orange),
                      _buildUserTypeOption('parent', 'أولياء الأمور فقط', Icons.family_restroom, Colors.green),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // عنوان الإشعار
              CustomTextField(
                controller: _titleController,
                label: 'عنوان الإشعار',
                hint: 'أدخل عنوان الإشعار',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال عنوان الإشعار';
                  }
                  if (value.trim().length < 3) {
                    return 'العنوان يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // محتوى الإشعار
              CustomTextField(
                controller: _messageController,
                label: 'محتوى الإشعار',
                hint: 'أدخل محتوى الإشعار',
                prefixIcon: Icons.message,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال محتوى الإشعار';
                  }
                  if (value.trim().length < 10) {
                    return 'المحتوى يجب أن يكون 10 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // أزرار الإجراءات
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: _isLoading ? 'جاري الإرسال...' : 'إرسال الإشعار',
                      onPressed: _isLoading ? null : _sendNotification,
                      isLoading: _isLoading,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'إرسال إشعار طوارئ',
                      onPressed: _isLoading ? null : _sendEmergencyNotification,
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 0),
    );
  }

  /// بناء خيار نوع المستخدم
  Widget _buildUserTypeOption(String value, String title, IconData icon, Color color) {
    final isSelected = _selectedUserType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[700],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// إرسال الإشعار العادي
  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();

      if (_selectedUserType == 'all') {
        // إرسال لجميع المستخدمين
        await _notificationSender.sendAdminMessage(
          title: title,
          message: message,
        );
      } else {
        // إرسال لنوع محدد
        await _notificationSender.sendAdminMessage(
          title: title,
          message: message,
          targetUserType: _selectedUserType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال الإشعار بنجاح إلى ${_getUserTypeText(_selectedUserType)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // مسح النموذج
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedUserType = 'all';
        });
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// إرسال إشعار طوارئ
  Future<void> _sendEmergencyNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // تأكيد الإرسال
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد إرسال إشعار طوارئ'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إرسال هذا الإشعار كإشعار طوارئ؟ سيصل لجميع المستخدمين بأولوية عالية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();

      await _notificationSender.sendEmergencyNotification(
        title: title,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال إشعار الطوارئ بنجاح لجميع المستخدمين'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );

        // مسح النموذج
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedUserType = 'all';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال إشعار الطوارئ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// الحصول على نص نوع المستخدم
  String _getUserTypeText(String userType) {
    switch (userType) {
      case 'all':
        return 'جميع المستخدمين';
      case 'admin':
        return 'الإدارة';
      case 'supervisor':
        return 'المشرفين';
      case 'parent':
        return 'أولياء الأمور';
      default:
        return 'المستخدمين المحددين';
    }
  }
}
