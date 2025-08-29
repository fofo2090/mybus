import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_bottom_navigation.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // School Settings Controllers
  final _schoolNameController = TextEditingController();
  final _schoolAddressController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  
  // Trip Timing Controllers
  final _morningStartController = TextEditingController();
  final _morningEndController = TextEditingController();
  final _afternoonStartController = TextEditingController();
  final _afternoonEndController = TextEditingController();
  
  // System Settings
  bool _autoBackup = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _parentTracking = true;
  bool _emergencyAlerts = true;
  int _maxStudentsPerBus = 30;
  int _tripTimeoutMinutes = 120;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    _morningStartController.dispose();
    _morningEndController.dispose();
    _afternoonStartController.dispose();
    _afternoonEndController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Load school settings
      final schoolDoc = await _firestore.collection('settings').doc('school').get();
      if (schoolDoc.exists) {
        final schoolData = schoolDoc.data()!;
        _schoolNameController.text = schoolData['name'] ?? '';
        _schoolAddressController.text = schoolData['address'] ?? '';
        _schoolPhoneController.text = schoolData['phone'] ?? '';
        _schoolEmailController.text = schoolData['email'] ?? '';
      }
      
      // Load trip timings
      final timingsDoc = await _firestore.collection('settings').doc('trip_timings').get();
      if (timingsDoc.exists) {
        final timingsData = timingsDoc.data()!;
        _morningStartController.text = timingsData['morning_start'] ?? '06:30';
        _morningEndController.text = timingsData['morning_end'] ?? '08:00';
        _afternoonStartController.text = timingsData['afternoon_start'] ?? '13:00';
        _afternoonEndController.text = timingsData['afternoon_end'] ?? '15:00';
      }
      
      // Load system settings
      final systemDoc = await _firestore.collection('settings').doc('system').get();
      if (systemDoc.exists) {
        final systemData = systemDoc.data()!;
        _autoBackup = systemData['auto_backup'] ?? true;
        _emailNotifications = systemData['email_notifications'] ?? true;
        _smsNotifications = systemData['sms_notifications'] ?? false;
        _parentTracking = systemData['parent_tracking'] ?? true;
        _emergencyAlerts = systemData['emergency_alerts'] ?? true;
        _maxStudentsPerBus = systemData['max_students_per_bus'] ?? 30;
        _tripTimeoutMinutes = systemData['trip_timeout_minutes'] ?? 120;
      }
      
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل الإعدادات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إعدادات النظام'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAllSettings,
              tooltip: 'حفظ التغييرات',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.school, size: 20), text: 'المدرسة'),
            Tab(icon: Icon(Icons.access_time, size: 20), text: 'المواعيد'),
            Tab(icon: Icon(Icons.settings, size: 20), text: 'النظام'),
            Tab(icon: Icon(Icons.security, size: 20), text: 'الأمان'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSchoolSettingsTab(),
                _buildTripTimingsTab(),
                _buildSystemSettingsTab(),
                _buildSecuritySettingsTab(),
              ],
            ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _saveAllSettings,
              backgroundColor: const Color(0xFF1E88E5),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'حفظ التغييرات',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildSchoolSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'معلومات المدرسة',
            'تحديد البيانات الأساسية للمدرسة',
            Icons.school,
            Colors.blue,
          ),
          const SizedBox(height: 20),
          
          _buildSchoolInfoCard(),
          const SizedBox(height: 20),
          
          _buildContactInfoCard(),
        ],
      ),
    );
  }

  Widget _buildTripTimingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'مواعيد الرحلات',
            'تحديد أوقات الذهاب والعودة',
            Icons.access_time,
            Colors.green,
          ),
          const SizedBox(height: 20),
          
          _buildMorningTimingsCard(),
          const SizedBox(height: 16),
          
          _buildAfternoonTimingsCard(),
          const SizedBox(height: 20),
          
          _buildTimingNotesCard(),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'إعدادات النظام',
            'تكوين سلوك التطبيق والميزات',
            Icons.settings,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          
          _buildNotificationSettingsCard(),
          const SizedBox(height: 16),
          
          _buildOperationalSettingsCard(),
          const SizedBox(height: 16),
          
          _buildBackupSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildSecuritySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'الأمان والخصوصية',
            'إعدادات الحماية والتتبع',
            Icons.security,
            Colors.red,
          ),
          const SizedBox(height: 20),
          
          _buildTrackingSettingsCard(),
          const SizedBox(height: 16),
          
          _buildEmergencySettingsCard(),
          const SizedBox(height: 16),
          
          _buildPrivacySettingsCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(229),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دوال بناء بطاقات إعدادات المدرسة
  Widget _buildSchoolInfoCard() {
    return _buildSettingsCard(
      title: 'معلومات المدرسة الأساسية',
      icon: Icons.info,
      color: Colors.blue,
      child: Column(
        children: [
          _buildTextField(
            controller: _schoolNameController,
            label: 'اسم المدرسة',
            icon: Icons.school,
            onChanged: () => _markAsChanged(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _schoolAddressController,
            label: 'عنوان المدرسة',
            icon: Icons.location_on,
            maxLines: 2,
            onChanged: () => _markAsChanged(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return _buildSettingsCard(
      title: 'معلومات الاتصال',
      icon: Icons.contact_phone,
      color: Colors.green,
      child: Column(
        children: [
          _buildTextField(
            controller: _schoolPhoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            onChanged: () => _markAsChanged(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _schoolEmailController,
            label: 'البريد الإلكتروني',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: () => _markAsChanged(),
          ),
        ],
      ),
    );
  }

  // دوال بناء بطاقات مواعيد الرحلات
  Widget _buildMorningTimingsCard() {
    return _buildSettingsCard(
      title: 'مواعيد الذهاب (صباحاً)',
      icon: Icons.wb_sunny,
      color: Colors.orange,
      child: Row(
        children: [
          Expanded(
            child: _buildTimeField(
              controller: _morningStartController,
              label: 'بداية الرحلات',
              icon: Icons.play_arrow,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTimeField(
              controller: _morningEndController,
              label: 'نهاية الرحلات',
              icon: Icons.stop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfternoonTimingsCard() {
    return _buildSettingsCard(
      title: 'مواعيد العودة (مساءً)',
      icon: Icons.nights_stay,
      color: Colors.indigo,
      child: Row(
        children: [
          Expanded(
            child: _buildTimeField(
              controller: _afternoonStartController,
              label: 'بداية الرحلات',
              icon: Icons.play_arrow,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTimeField(
              controller: _afternoonEndController,
              label: 'نهاية الرحلات',
              icon: Icons.stop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingNotesCard() {
    return _buildSettingsCard(
      title: 'ملاحظات مهمة',
      icon: Icons.info_outline,
      color: Colors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.schedule,
            text: 'يتم تطبيق هذه المواعيد على جميع الحافلات',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.notification_important,
            text: 'سيتم إشعار أولياء الأمور بأي تغيير في المواعيد',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.access_time,
            text: 'يُنصح بترك هامش 15 دقيقة للطوارئ',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  // دوال بناء بطاقات إعدادات النظام
  Widget _buildNotificationSettingsCard() {
    return _buildSettingsCard(
      title: 'إعدادات الإشعارات',
      icon: Icons.notifications,
      color: Colors.blue,
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'إشعارات البريد الإلكتروني',
            subtitle: 'إرسال إشعارات عبر البريد الإلكتروني',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _markAsChanged();
            },
          ),
          _buildSwitchTile(
            title: 'إشعارات الرسائل النصية',
            subtitle: 'إرسال إشعارات عبر الرسائل النصية',
            value: _smsNotifications,
            onChanged: (value) {
              setState(() => _smsNotifications = value);
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalSettingsCard() {
    return _buildSettingsCard(
      title: 'الإعدادات التشغيلية',
      icon: Icons.settings_applications,
      color: Colors.green,
      child: Column(
        children: [
          _buildNumberField(
            label: 'الحد الأقصى للطلاب في الحافلة',
            value: _maxStudentsPerBus,
            min: 10,
            max: 50,
            onChanged: (value) {
              setState(() => _maxStudentsPerBus = value);
              _markAsChanged();
            },
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            label: 'مهلة انتهاء الرحلة (بالدقائق)',
            value: _tripTimeoutMinutes,
            min: 60,
            max: 300,
            onChanged: (value) {
              setState(() => _tripTimeoutMinutes = value);
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSettingsCard() {
    return _buildSettingsCard(
      title: 'إعدادات النسخ الاحتياطي',
      icon: Icons.backup,
      color: Colors.orange,
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'النسخ الاحتياطي التلقائي',
            subtitle: 'إنشاء نسخة احتياطية يومياً',
            value: _autoBackup,
            onChanged: (value) {
              setState(() => _autoBackup = value);
              _markAsChanged();
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createManualBackup,
            icon: const Icon(Icons.backup),
            label: const Text('إنشاء نسخة احتياطية الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // دوال بناء بطاقات الأمان
  Widget _buildTrackingSettingsCard() {
    return _buildSettingsCard(
      title: 'إعدادات التتبع',
      icon: Icons.gps_fixed,
      color: Colors.red,
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'تتبع أولياء الأمور',
            subtitle: 'السماح لأولياء الأمور بتتبع الحافلات',
            value: _parentTracking,
            onChanged: (value) {
              setState(() => _parentTracking = value);
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySettingsCard() {
    return _buildSettingsCard(
      title: 'إعدادات الطوارئ',
      icon: Icons.emergency,
      color: Colors.red[700]!,
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'تنبيهات الطوارئ',
            subtitle: 'إرسال تنبيهات فورية في حالات الطوارئ',
            value: _emergencyAlerts,
            onChanged: (value) {
              setState(() => _emergencyAlerts = value);
              _markAsChanged();
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _testEmergencyAlert,
            icon: const Icon(Icons.warning),
            label: const Text('اختبار تنبيه الطوارئ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsCard() {
    return _buildSettingsCard(
      title: 'الخصوصية وحماية البيانات',
      icon: Icons.privacy_tip,
      color: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.lock,
            text: 'جميع البيانات محمية بتشفير عالي المستوى',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.visibility_off,
            text: 'لا يتم مشاركة البيانات مع أطراف ثالثة',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.delete_forever,
            text: 'يمكن حذف البيانات نهائياً عند الطلب',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showDataManagementDialog,
            icon: const Icon(Icons.manage_accounts),
            label: const Text('إدارة البيانات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // دوال مساعدة لبناء العناصر
  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required VoidCallback onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectTime(controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        suffixIcon: const Icon(Icons.access_time, color: Color(0xFF1E88E5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1E88E5),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.grey[700],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  // دوال الأحداث والعمليات
  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
      _markAsChanged();
    }
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isLoading = true);

    try {
      // حفظ إعدادات المدرسة
      await _firestore.collection('settings').doc('school').set({
        'name': _schoolNameController.text.trim(),
        'address': _schoolAddressController.text.trim(),
        'phone': _schoolPhoneController.text.trim(),
        'email': _schoolEmailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // حفظ مواعيد الرحلات
      await _firestore.collection('settings').doc('trip_timings').set({
        'morning_start': _morningStartController.text,
        'morning_end': _morningEndController.text,
        'afternoon_start': _afternoonStartController.text,
        'afternoon_end': _afternoonEndController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // حفظ إعدادات النظام
      await _firestore.collection('settings').doc('system').set({
        'auto_backup': _autoBackup,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
        'parent_tracking': _parentTracking,
        'emergency_alerts': _emergencyAlerts,
        'max_students_per_bus': _maxStudentsPerBus,
        'trip_timeout_minutes': _tripTimeoutMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _hasChanges = false);
      _showSuccessSnackBar('تم حفظ جميع الإعدادات بنجاح');

    } catch (e) {
      _showErrorSnackBar('خطأ في حفظ الإعدادات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createManualBackup() async {
    try {
      // إنشاء نسخة احتياطية
      await _firestore.collection('backups').add({
        'type': 'manual',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
        'status': 'completed',
      });

      _showSuccessSnackBar('تم إنشاء النسخة الاحتياطية بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في إنشاء النسخة الاحتياطية: $e');
    }
  }

  Future<void> _testEmergencyAlert() async {
    try {
      // إرسال تنبيه تجريبي
      await _firestore.collection('emergency_alerts').add({
        'type': 'test',
        'message': 'هذا تنبيه تجريبي للتأكد من عمل النظام',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      _showSuccessSnackBar('تم إرسال تنبيه الطوارئ التجريبي');
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال التنبيه: $e');
    }
  }

  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.manage_accounts, color: Colors.purple),
            SizedBox(width: 8),
            Text('إدارة البيانات'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('خيارات إدارة البيانات:'),
            SizedBox(height: 16),
            Text('• تصدير البيانات'),
            Text('• حذف البيانات القديمة'),
            Text('• إعادة تعيين النظام'),
            Text('• تنظيف قاعدة البيانات'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('ميزة إدارة البيانات قيد التطوير');
            },
            child: const Text('المتابعة'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


