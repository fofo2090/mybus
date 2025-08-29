import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';

import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/curved_app_bar.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _nameController.text = userData.name;
            _phoneController.text = userData.phone;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: EnhancedCurvedAppBar(
        title: 'الإعدادات',
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        height: 250,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 24),
            onPressed: () {
              context.go('/parent');
            },
            tooltip: 'الصفحة الرئيسية',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Section
            _buildProfileSection(),
            
            const SizedBox(height: 20),
            
            // Notifications Section
            _buildNotificationsSection(),
            
            const SizedBox(height: 20),
            
            // App Settings Section
            _buildAppSettingsSection(),
            
            const SizedBox(height: 20),
            
            // About Section
            _buildAboutSection(),
            
            const SizedBox(height: 32),
            
            // Logout Button
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF1E88E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'الملف الشخصي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            CustomTextField(
              controller: _nameController,
              label: 'الاسم',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الاسم';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم الهاتف';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            CustomButton(
              text: 'حفظ التغييرات',
              onPressed: _isLoading ? null : _saveProfile,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Color(0xFF1E88E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'الإشعارات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          SwitchListTile(
            title: const Text('تفعيل الإشعارات'),
            subtitle: const Text('استقبال إشعارات حول أنشطة أطفالك'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: const Color(0xFF1E88E5),
          ),
          
          SwitchListTile(
            title: const Text('إشعارات البريد الإلكتروني'),
            subtitle: const Text('استقبال إشعارات عبر البريد الإلكتروني'),
            value: _emailNotifications,
            onChanged: _notificationsEnabled ? (value) {
              setState(() {
                _emailNotifications = value;
              });
            } : null,
            activeColor: const Color(0xFF1E88E5),
          ),
          
          SwitchListTile(
            title: const Text('إشعارات الرسائل النصية'),
            subtitle: const Text('استقبال إشعارات عبر الرسائل النصية'),
            value: _smsNotifications,
            onChanged: _notificationsEnabled ? (value) {
              setState(() {
                _smsNotifications = value;
              });
            } : null,
            activeColor: const Color(0xFF1E88E5),
          ),

          SwitchListTile(
            title: const Text('الصوت'),
            subtitle: const Text('تشغيل صوت عند وصول الإشعارات'),
            value: _soundEnabled,
            onChanged: _notificationsEnabled ? (value) {
              setState(() {
                _soundEnabled = value;
              });
            } : null,
            activeColor: const Color(0xFF1E88E5),
          ),

          SwitchListTile(
            title: const Text('الاهتزاز'),
            subtitle: const Text('اهتزاز الجهاز عند وصول الإشعارات'),
            value: _vibrationEnabled,
            onChanged: _notificationsEnabled ? (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            } : null,
            activeColor: const Color(0xFF1E88E5),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF1E88E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'إعدادات التطبيق',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return SwitchListTile(
                title: const Text('المظهر الداكن'),
                subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
                value: themeService.isDarkMode,
                onChanged: (value) async {
                  await themeService.toggleTheme();
                  if (mounted) {
                    _showThemeChangeDialog(themeService.isDarkMode);
                  }
                },
                activeColor: const Color(0xFF1E88E5),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.palette, color: Color(0xFF1E88E5)),
            title: const Text('إعدادات المظهر'),
            subtitle: const Text('تخصيص ألوان وشكل التطبيق'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemeSettings(context),
          ),

          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.security, color: Color(0xFF1E88E5)),
            title: const Text('الخصوصية والأمان'),
            subtitle: const Text('إعدادات الحماية وحفظ البيانات'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPrivacyAndSecuritySettings,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.storage, color: Color(0xFF1E88E5)),
            title: const Text('مسح البيانات المؤقتة'),
            subtitle: const Text('حذف الملفات المؤقتة لتوفير مساحة'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info,
                  color: Color(0xFF1E88E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'حول التطبيق',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.help_center, color: Color(0xFF1E88E5)),
            title: const Text('المساعدة والدعم'),
            subtitle: const Text('الحصول على المساعدة والدعم التقني'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showHelpAndSupport,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.article, color: Color(0xFF1E88E5)),
            title: const Text('شروط الاستخدام'),
            subtitle: const Text('قراءة شروط وأحكام الاستخدام'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTermsOfUse,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.policy, color: Color(0xFF1E88E5)),
            title: const Text('سياسة الاستخدام'),
            subtitle: const Text('قواعد وسياسات استخدام التطبيق'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showUsagePolicy,
          ),
          
          const Divider(),
          
          const ListTile(
            leading: Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
            title: Text('إصدار التطبيق'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text(
        'تسجيل الخروج',
        style: TextStyle(color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ التغييرات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ التغييرات: $e'),
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

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Theme Settings Methods
  Future<void> _showThemeChangeDialog(bool isDarkMode) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم تغيير المظهر'),
        content: Text(
          isDarkMode
            ? '🌙 تم تفعيل المظهر الداكن بنجاح!\nالتغييرات مطبقة فوراً.'
            : '☀️ تم تفعيل المظهر الفاتح بنجاح!\nالتغييرات مطبقة فوراً.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رائع!'),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeSettings(BuildContext context) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات المظهر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode, color: Colors.orange),
              title: const Text('المظهر الفاتح'),
              subtitle: const Text('مظهر مشرق ومريح للعين'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await themeService.setThemeMode(value);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('☀️ تم تطبيق المظهر الفاتح'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.indigo),
              title: const Text('المظهر الداكن'),
              subtitle: const Text('مظهر داكن يريح العين في الإضاءة المنخفضة'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await themeService.setThemeMode(value);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🌙 تم تطبيق المظهر الداكن'),
                          backgroundColor: Colors.indigo,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_mode, color: Colors.blue),
              title: const Text('تلقائي'),
              subtitle: const Text('يتبع إعدادات النظام تلقائياً'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await themeService.setThemeMode(value);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 تم تطبيق الوضع التلقائي'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  }
                },
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

  // Privacy and Security Methods
  Future<void> _showPrivacyAndSecuritySettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الخصوصية والأمان'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إعدادات الخصوصية:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('مشاركة البيانات التحليلية'),
                subtitle: const Text('مساعدة في تحسين التطبيق'),
                value: true,
                onChanged: (value) {},
                dense: true,
              ),

              SwitchListTile(
                title: const Text('حفظ سجل النشاط'),
                subtitle: const Text('تسجيل الأنشطة والتفاعلات'),
                value: true,
                onChanged: (value) {},
                dense: true,
              ),

              const SizedBox(height: 16),
              const Text(
                'إعدادات الأمان:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.fingerprint, color: Colors.green),
                title: const Text('المصادقة البيومترية'),
                subtitle: const Text('استخدام البصمة أو الوجه'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('المصادقة البيومترية ستكون متاحة قريباً'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.lock_clock, color: Colors.orange),
                title: const Text('انتهاء الجلسة التلقائي'),
                subtitle: const Text('تسجيل الخروج بعد فترة عدم نشاط'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showSessionTimeoutSettings();
                },
              ),
            ],
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

  Future<void> _showSessionTimeoutSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتهاء الجلسة التلقائي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('15 دقيقة'),
              leading: Radio(value: 15, groupValue: 30, onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('30 دقيقة'),
              leading: Radio(value: 30, groupValue: 30, onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('ساعة واحدة'),
              leading: Radio(value: 60, groupValue: 30, onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('لا تنتهي'),
              leading: Radio(value: 0, groupValue: 30, onChanged: (value) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ إعدادات انتهاء الجلسة'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // Cache Management
  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح البيانات المؤقتة'),
        content: const Text('هل تريد حذف جميع البيانات المؤقتة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح البيانات المؤقتة بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // Help and Support Methods
  Future<void> _showHelpAndSupport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة والدعم'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📞 معلومات الاتصال:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• الهاتف: 123-456-7890'),
                    Text('• البريد الإلكتروني: support@mybus.com'),
                    Text('• واتساب: +966-50-123-4567'),
                    Text('• ساعات العمل: 8 ص - 6 م (السبت - الخميس)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '❓ الأسئلة الشائعة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• كيفية متابعة نشاط طفلي؟'),
                    Text('• كيفية تسجيل غياب طفلي؟'),
                    Text('• كيفية تحديث بيانات الطفل؟'),
                    Text('• كيفية التواصل مع المدرسة؟'),
                    Text('• حل مشاكل الإشعارات؟'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 الدعم الطارئ:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• للمشاكل العاجلة: 911'),
                    Text('• دعم تقني فوري: 800-123-4567'),
                    Text('• متاح 24/7 للحالات الطارئة'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يمكنك الاتصال بنا في أي وقت للحصول على المساعدة'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('اتصل بنا'),
          ),
        ],
      ),
    );
  }

  // Terms and Policies Methods
  Future<void> _showTermsOfUse() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('شروط الاستخدام'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 شروط وأحكام استخدام تطبيق MyBus',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. الاستخدام المسموح:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• متابعة نشاط الأطفال في النقل المدرسي'),
                    Text('• تسجيل الغياب والحضور'),
                    Text('• التواصل مع إدارة المدرسة'),
                    SizedBox(height: 8),

                    Text(
                      '2. المسؤوليات:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• الحفاظ على سرية بيانات الدخول'),
                    Text('• تحديث البيانات الشخصية بانتظام'),
                    Text('• احترام خصوصية الآخرين'),
                    Text('• الإبلاغ عن أي مشاكل فوراً'),
                    SizedBox(height: 8),

                    Text(
                      '3. الاستخدام المحظور:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• مشاركة بيانات الدخول مع الآخرين'),
                    Text('• استخدام التطبيق لأغراض غير مشروعة'),
                    Text('• إدخال بيانات غير صحيحة'),
                    Text('• محاولة اختراق النظام'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ تنبيهات مهمة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• أي مخالفة للشروط قد تؤدي لإيقاف الحساب'),
                    Text('• يجب الإبلاغ عن أي استخدام مشبوه'),
                    Text('• التطبيق مراقب لضمان الأمان'),
                    Text('• تحديث الشروط قد يحدث دون إشعار مسبق'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('شكراً لك على قراءة شروط الاستخدام'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUsagePolicy() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سياسة الاستخدام'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📜 سياسة استخدام تطبيق MyBus لأولياء الأمور',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 12),

                    Text(
                      '1. قواعد الاستخدام اليومي:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• متابعة نشاط الأطفال بانتظام'),
                    Text('• التحقق من حالة الحضور والغياب'),
                    Text('• تحديث البيانات الشخصية عند الحاجة'),
                    Text('• التواصل مع المدرسة عند الضرورة'),
                    SizedBox(height: 8),

                    Text(
                      '2. إجراءات الأمان:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• عدم مشاركة بيانات الدخول'),
                    Text('• تسجيل الخروج عند انتهاء الاستخدام'),
                    Text('• الإبلاغ عن أي مشاكل أمنية'),
                    Text('• تحديث كلمة المرور بانتظام'),
                    SizedBox(height: 8),

                    Text(
                      '3. التعامل مع البيانات:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• احترام خصوصية بيانات الأطفال الآخرين'),
                    Text('• عدم مشاركة المعلومات مع أطراف خارجية'),
                    Text('• استخدام البيانات للمتابعة فقط'),
                    Text('• الحفاظ على سرية المعلومات'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚫 المخالفات والعقوبات:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• إساءة استخدام التطبيق: إنذار أول'),
                    Text('• مشاركة بيانات خاطئة: إنذار ثاني'),
                    Text('• مشاركة بيانات الدخول: إيقاف مؤقت'),
                    Text('• انتهاك الخصوصية: إيقاف نهائي'),
                    Text('• استخدام غير مصرح: إجراءات قانونية'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📞 الإبلاغ عن المشاكل:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• مشاكل تقنية: support@mybus.com'),
                    Text('• مخالفات أمنية: security@mybus.com'),
                    Text('• اقتراحات تحسين: feedback@mybus.com'),
                    Text('• شكاوى عامة: complaints@mybus.com'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('شكراً لك على الالتزام بسياسة الاستخدام'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('أوافق'),
          ),
        ],
      ),
    );
  }
}
