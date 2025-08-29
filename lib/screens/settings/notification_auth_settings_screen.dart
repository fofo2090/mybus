import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/persistent_auth_service.dart';
import '../../services/enhanced_push_notification_service.dart';
import '../../widgets/responsive_widgets.dart';

/// شاشة إعدادات الإشعارات والمصادقة
class NotificationAuthSettingsScreen extends StatefulWidget {
  const NotificationAuthSettingsScreen({super.key});

  @override
  State<NotificationAuthSettingsScreen> createState() => _NotificationAuthSettingsScreenState();
}

class _NotificationAuthSettingsScreenState extends State<NotificationAuthSettingsScreen> {
  bool _autoLoginEnabled = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = false;
  Map<String, dynamic> _sessionInfo = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<PersistentAuthService>(context, listen: false);
      
      // تحميل إعدادات المصادقة
      _autoLoginEnabled = authService.autoLoginEnabled;
      _sessionInfo = await authService.getSessionInfo();
      
      // تحميل إعدادات الإشعارات (يمكن إضافة المزيد حسب الحاجة)
      _notificationsEnabled = true; // افتراضي
      _soundEnabled = true; // افتراضي
      _vibrationEnabled = true; // افتراضي
      
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutoLogin(bool value) async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<PersistentAuthService>(context, listen: false);
      await authService.setAutoLoginEnabled(value);
      
      setState(() => _autoLoginEnabled = value);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'تم تفعيل تسجيل الدخول التلقائي' : 'تم إلغاء تسجيل الدخول التلقائي'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الإعدادات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل خروج كامل'),
        content: const Text('هل تريد تسجيل الخروج ومسح جميع البيانات المحفوظة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل خروج كامل'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<PersistentAuthService>(context, listen: false);
        await authService.signOut(clearPersistedData: true);
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _validateSession() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<PersistentAuthService>(context, listen: false);
      final isValid = await authService.validateCurrentSession();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid ? 'الجلسة صحيحة ✅' : 'الجلسة غير صحيحة ❌'),
          backgroundColor: isValid ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فحص الجلسة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات والمصادقة'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ResponsivePageContainer(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveVerticalSpace(),
        
        // قسم إعدادات المصادقة
        _buildAuthSection(),
        
        const ResponsiveVerticalSpace(multiplier: 2),
        
        // قسم إعدادات الإشعارات
        _buildNotificationSection(),
        
        const ResponsiveVerticalSpace(multiplier: 2),
        
        // قسم معلومات الجلسة
        _buildSessionInfoSection(),
        
        const ResponsiveVerticalSpace(multiplier: 2),
        
        // قسم الإجراءات
        _buildActionsSection(),
      ],
    );
  }

  Widget _buildAuthSection() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubtitle('إعدادات المصادقة'),
          const ResponsiveVerticalSpace(),
          
          SwitchListTile(
            title: const ResponsiveBody('تسجيل الدخول التلقائي'),
            subtitle: const ResponsiveSmall('الحفاظ على تسجيل الدخول عند إغلاق التطبيق'),
            value: _autoLoginEnabled,
            onChanged: _toggleAutoLogin,
            activeColor: Theme.of(context).primaryColor,
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const ResponsiveBody('حالة تسجيل الدخول'),
            subtitle: ResponsiveSmall(
              _sessionInfo['isLoggedIn'] == true 
                ? 'مسجل دخول ✅' 
                : 'غير مسجل دخول ❌'
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _validateSession,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubtitle('إعدادات الإشعارات'),
          const ResponsiveVerticalSpace(),
          
          SwitchListTile(
            title: const ResponsiveBody('تفعيل الإشعارات'),
            subtitle: const ResponsiveSmall('استقبال إشعارات التطبيق'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          
          SwitchListTile(
            title: const ResponsiveBody('الصوت'),
            subtitle: const ResponsiveSmall('تشغيل صوت عند وصول الإشعارات'),
            value: _soundEnabled,
            onChanged: _notificationsEnabled ? (value) {
              setState(() => _soundEnabled = value);
            } : null,
            activeColor: Theme.of(context).primaryColor,
          ),
          
          SwitchListTile(
            title: const ResponsiveBody('الاهتزاز'),
            subtitle: const ResponsiveSmall('اهتزاز الجهاز عند وصول الإشعارات'),
            value: _vibrationEnabled,
            onChanged: _notificationsEnabled ? (value) {
              setState(() => _vibrationEnabled = value);
            } : null,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoSection() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubtitle('معلومات الجلسة'),
          const ResponsiveVerticalSpace(),
          
          _buildInfoRow('البريد الإلكتروني', _sessionInfo['userEmail'] ?? 'غير محدد'),
          _buildInfoRow('معرف المستخدم', _sessionInfo['userId'] ?? 'غير محدد'),
          _buildInfoRow('تذكرني', _sessionInfo['rememberMe'] == true ? 'مفعل' : 'غير مفعل'),
          _buildInfoRow('تسجيل الدخول التلقائي', _sessionInfo['autoLoginEnabled'] == true ? 'مفعل' : 'غير مفعل'),
          
          if (_sessionInfo['loginTimestamp'] != null)
            _buildInfoRow(
              'آخر تسجيل دخول',
              _formatTimestamp(_sessionInfo['loginTimestamp']),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: ResponsiveSmall(label, color: Colors.grey[600]),
          ),
          Expanded(
            flex: 3,
            child: ResponsiveSmall(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubtitle('الإجراءات'),
          const ResponsiveVerticalSpace(),
          
          ResponsiveButtonEnhanced(
            onPressed: _validateSession,
            fullWidth: true,
            buttonType: ButtonType.outlined,
            child: const ResponsiveBody('فحص صحة الجلسة'),
          ),
          
          const ResponsiveVerticalSpace(),
          
          ResponsiveButtonEnhanced(
            onPressed: _forceLogout,
            fullWidth: true,
            backgroundColor: Colors.red,
            child: const ResponsiveBody('تسجيل خروج كامل', color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// مساحة عمودية متجاوبة
class ResponsiveVerticalSpace extends StatelessWidget {
  final double multiplier;
  
  const ResponsiveVerticalSpace({
    super.key,
    this.multiplier = 1.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(context) * multiplier;
    return SizedBox(height: spacing);
  }
}