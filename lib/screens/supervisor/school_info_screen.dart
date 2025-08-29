import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SupervisorSchoolInfoScreen extends StatefulWidget {
  const SupervisorSchoolInfoScreen({super.key});

  @override
  State<SupervisorSchoolInfoScreen> createState() => _SupervisorSchoolInfoScreenState();
}

class _SupervisorSchoolInfoScreenState extends State<SupervisorSchoolInfoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic> _schoolInfo = {};
  Map<String, dynamic> _tripTimings = {};
  Map<String, dynamic> _systemSettings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }

  Future<void> _loadSchoolInfo() async {
    setState(() => _isLoading = true);
    
    try {
      // تحميل معلومات المدرسة
      final schoolDoc = await _firestore.collection('settings').doc('school').get();
      if (schoolDoc.exists) {
        _schoolInfo = schoolDoc.data() ?? {};
      }

      // تحميل مواعيد الرحلات
      final timingsDoc = await _firestore.collection('settings').doc('trip_timings').get();
      if (timingsDoc.exists) {
        _tripTimings = timingsDoc.data() ?? {};
      }

      // تحميل إعدادات النظام
      final systemDoc = await _firestore.collection('settings').doc('system').get();
      if (systemDoc.exists) {
        _systemSettings = systemDoc.data() ?? {};
      }

    } catch (e) {
      debugPrint('خطأ في تحميل معلومات المدرسة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('معلومات المدرسة والنظام'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchoolInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات المدرسة الأساسية
                    _buildSchoolInfoCard(),
                    const SizedBox(height: 16),

                    // معلومات الاتصال
                    _buildContactInfoCard(),
                    const SizedBox(height: 16),

                    // مواعيد الرحلات
                    _buildTripTimingsCard(),
                    const SizedBox(height: 16),

                    // إعدادات النظام للمشرف
                    _buildSystemSettingsCard(),
                    const SizedBox(height: 16),

                    // ملاحظات للمشرفين
                    _buildSupervisorNotesCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSchoolInfoCard() {
    final schoolName = _schoolInfo['name'] ?? 'اسم المدرسة غير محدد';
    final schoolAddress = _schoolInfo['address'] ?? 'العنوان غير محدد';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                child: Text(
                  'معلومات المدرسة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'مشرف',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Text(
            schoolName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schoolAddress,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(229),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    final schoolPhone = _schoolInfo['phone'] ?? '';
    final schoolEmail = _schoolInfo['email'] ?? '';

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
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.contact_phone,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'معلومات الاتصال',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (schoolPhone.isNotEmpty) ...[
            _buildContactItem(
              icon: Icons.phone,
              label: 'رقم الهاتف',
              value: schoolPhone,
              color: Colors.green,
              onTap: () => _makePhoneCall(schoolPhone),
            ),
            const SizedBox(height: 16),
          ],
          
          if (schoolEmail.isNotEmpty) ...[
            _buildContactItem(
              icon: Icons.email,
              label: 'البريد الإلكتروني',
              value: schoolEmail,
              color: Colors.blue,
              onTap: () => _sendEmail(schoolEmail),
            ),
          ],
          
          if (schoolPhone.isEmpty && schoolEmail.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد معلومات اتصال متاحة',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTimingsCard() {
    final morningStart = _tripTimings['morning_start'] ?? '06:30';
    final morningEnd = _tripTimings['morning_end'] ?? '08:00';
    final afternoonStart = _tripTimings['afternoon_start'] ?? '13:00';
    final afternoonEnd = _tripTimings['afternoon_end'] ?? '15:00';

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
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'مواعيد الرحلات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // رحلات الذهاب
          _buildTimingSection(
            title: 'رحلات الذهاب (صباحاً)',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            startTime: morningStart,
            endTime: morningEnd,
          ),

          const SizedBox(height: 20),

          // رحلات العودة
          _buildTimingSection(
            title: 'رحلات العودة (مساءً)',
            icon: Icons.nights_stay,
            color: Colors.indigo,
            startTime: afternoonStart,
            endTime: afternoonEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection({
    required String title,
    required IconData icon,
    required Color color,
    required String startTime,
    required String endTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
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

          Row(
            children: [
              Expanded(
                child: _buildTimeDisplay(
                  label: 'بداية الرحلات',
                  time: startTime,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeDisplay(
                  label: 'نهاية الرحلات',
                  time: endTime,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay({
    required String label,
    required String time,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSettingsCard() {
    final maxStudents = _systemSettings['max_students_per_bus'] ?? 30;
    final tripTimeout = _systemSettings['trip_timeout_minutes'] ?? 120;
    final emailNotifications = _systemSettings['email_notifications'] ?? true;
    final parentTracking = _systemSettings['parent_tracking'] ?? true;

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
                  color: Colors.purple.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'إعدادات النظام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildSystemSettingItem(
                  icon: Icons.people,
                  label: 'الحد الأقصى للطلاب',
                  value: '$maxStudents طالب',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSystemSettingItem(
                  icon: Icons.timer,
                  label: 'مهلة الرحلة',
                  value: '$tripTimeout دقيقة',
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSystemSettingItem(
                  icon: emailNotifications ? Icons.email : Icons.email_outlined,
                  label: 'إشعارات البريد',
                  value: emailNotifications ? 'مفعل' : 'معطل',
                  color: emailNotifications ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSystemSettingItem(
                  icon: parentTracking ? Icons.gps_fixed : Icons.gps_off,
                  label: 'تتبع أولياء الأمور',
                  value: parentTracking ? 'مفعل' : 'معطل',
                  color: parentTracking ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorNotesCard() {
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
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.supervisor_account,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ملاحظات للمشرفين',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildNoteItem(
            icon: Icons.schedule,
            text: 'تأكد من وصول الحافلة في الوقت المحدد وإبلاغ الإدارة عن أي تأخير',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildNoteItem(
            icon: Icons.security,
            text: 'تحقق من هوية الطلاب قبل السماح لهم بالصعود للحافلة',
            color: Colors.red,
          ),
          const SizedBox(height: 12),

          _buildNoteItem(
            icon: Icons.phone,
            text: 'في حالة الطوارئ، اتصل بإدارة المدرسة فوراً وأبلغ أولياء الأمور',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),

          _buildNoteItem(
            icon: Icons.people,
            text: 'راقب سلوك الطلاب وتأكد من التزامهم بقواعد السلامة',
            color: Colors.green,
          ),
          const SizedBox(height: 12),

          _buildNoteItem(
            icon: Icons.report,
            text: 'سجل أي ملاحظات أو مشاكل في التطبيق لمتابعتها مع الإدارة',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('لا يمكن إجراء المكالمة');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في إجراء المكالمة');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=استفسار من مشرف الحافلة المدرسية',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('لا يمكن إرسال البريد الإلكتروني');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال البريد الإلكتروني');
    }
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


