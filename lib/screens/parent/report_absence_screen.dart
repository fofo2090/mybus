import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/absence_model.dart';
import '../../models/student_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/curved_app_bar.dart';

class ReportAbsenceScreen extends StatefulWidget {
  final StudentModel student;

  const ReportAbsenceScreen({
    super.key,
    required this.student,
  });

  @override
  State<ReportAbsenceScreen> createState() => _ReportAbsenceScreenState();
}

class _ReportAbsenceScreenState extends State<ReportAbsenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _databaseService = DatabaseService();
  final _notificationService = NotificationService();

  AbsenceType _selectedType = AbsenceType.sick;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isMultipleDays = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const EnhancedCurvedAppBar(
        title: 'إبلاغ غياب',
        subtitle: Text('إشعار المدرسة بغياب الطالب'),
        backgroundColor: Color(0xFF1E88E5),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Student Info Card
            _buildStudentInfoCard(),
            const SizedBox(height: 20),

            // Absence Type Selection
            _buildAbsenceTypeCard(),
            const SizedBox(height: 20),

            // Date Selection
            _buildDateSelectionCard(),
            const SizedBox(height: 20),

            // Reason Input
            _buildReasonCard(),
            const SizedBox(height: 20),

            // Notes Input
            _buildNotesCard(),
            const SizedBox(height: 30),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الصف: ${widget.student.grade} - الخط: ${widget.student.busRoute}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceTypeCard() {
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
          const Row(
            children: [
              Icon(Icons.category, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'نوع الغياب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AbsenceType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAbsenceTypeIcon(type),
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getAbsenceTypeText(type),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionCard() {
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
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'تاريخ الغياب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Multiple days toggle
          Row(
            children: [
              Checkbox(
                value: _isMultipleDays,
                onChanged: (value) {
                  setState(() {
                    _isMultipleDays = value ?? false;
                    if (!_isMultipleDays) {
                      _endDate = null;
                    }
                  });
                },
              ),
              const Text('غياب لعدة أيام'),
            ],
          ),
          const SizedBox(height: 12),
          
          // Start date
          InkWell(
            onTap: _selectStartDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _isMultipleDays ? 'من تاريخ: ' : 'تاريخ الغياب: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                ],
              ),
            ),
          ),
          
          // End date (if multiple days)
          if (_isMultipleDays) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectEndDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'إلى تاريخ: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(_endDate != null 
                        ? DateFormat('yyyy/MM/dd').format(_endDate!) 
                        : 'اختر التاريخ'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
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
          const Row(
            children: [
              Icon(Icons.description, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'سبب الغياب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'اكتب سبب الغياب بالتفصيل...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى كتابة سبب الغياب';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
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
          const Row(
            children: [
              Icon(Icons.note_add, color: Colors.teal, size: 20),
              SizedBox(width: 8),
              Text(
                'ملاحظات إضافية (اختياري)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'أي ملاحظات إضافية...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitAbsenceReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'إبلاغ عن الغياب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Helper methods
  IconData _getAbsenceTypeIcon(AbsenceType type) {
    switch (type) {
      case AbsenceType.sick:
        return Icons.local_hospital;
      case AbsenceType.family:
        return Icons.family_restroom;
      case AbsenceType.travel:
        return Icons.flight;
      case AbsenceType.emergency:
        return Icons.emergency;
      case AbsenceType.other:
        return Icons.more_horiz;
    }
  }

  String _getAbsenceTypeText(AbsenceType type) {
    switch (type) {
      case AbsenceType.sick:
        return 'مرض';
      case AbsenceType.family:
        return 'ظروف عائلية';
      case AbsenceType.travel:
        return 'سفر';
      case AbsenceType.emergency:
        return 'طوارئ';
      case AbsenceType.other:
        return 'أخرى';
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _submitAbsenceReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isMultipleDays && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تاريخ النهاية'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final absenceId = DateTime.now().millisecondsSinceEpoch.toString();
      final absence = AbsenceModel(
        id: absenceId,
        studentId: widget.student.id,
        studentName: widget.student.name,
        parentId: widget.student.parentId,
        type: _selectedType,
        status: AbsenceStatus.approved, // إشعار مقبول تلقائياً
        source: AbsenceSource.parent,
        date: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        approvedBy: 'ولي الأمر', // تم الإبلاغ من قبل ولي الأمر
        approvedAt: DateTime.now(), // وقت الإبلاغ
      );

      debugPrint('ًں”„ Parent creating absence request:');
      debugPrint('   ID: $absenceId');
      debugPrint('   Student: ${widget.student.name} (${widget.student.id})');
      debugPrint('   Parent: ${widget.student.parentId}');
      debugPrint('   Status: ${absence.status.toString().split('.').last}');
      debugPrint('   Date: ${absence.date}');
      debugPrint('   Reason: ${absence.reason}');

      await _databaseService.createAbsence(absence);

      debugPrint('âœ… Absence notification created successfully!');

      // إرسال إشعار للمشرفين والإدارة مع الصوت
      await _sendNotificationsToStaffWithSound(absence);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إبلاغ المدرسة عن الغياب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الطلب: $e'),
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

  // إرسال إشعارات للمشرفين والإدارة مع الصوت
  Future<void> _sendNotificationsToStaffWithSound(AbsenceModel absence) async {
    try {
      // الحصول على جميع المشرفين والإدارة
      final supervisors = await _databaseService.getAllSupervisors();
      final admins = await _databaseService.getAllAdmins();

      // إرسال إشعار للمشرفين
      for (final supervisor in supervisors) {
        await _notificationService.notifyAbsenceRequestWithSound(
          studentId: absence.studentId,
          studentName: absence.studentName,
          parentId: absence.parentId,
          parentName: 'ولي الأمر', // يمكن الحصول عليه من بيانات المستخدم
          supervisorId: supervisor.id,
          busId: widget.student.busRoute,
          absenceDate: absence.date,
          reason: absence.reason,
        );
      }

      // إرسال إشعار للإدارة
      for (final admin in admins) {
        await _notificationService.notifyAbsenceRequestWithSound(
          studentId: absence.studentId,
          studentName: absence.studentName,
          parentId: absence.parentId,
          parentName: 'ولي الأمر', // يمكن الحصول عليه من بيانات المستخدم
          supervisorId: admin.id, // استخدام معرف الإدمن كمشرف
          busId: widget.student.busRoute,
          absenceDate: absence.date,
          reason: absence.reason,
        );
      }

      debugPrint('✅ Enhanced notifications sent to ${supervisors.length} supervisors and ${admins.length} admins');
    } catch (e) {
      debugPrint('❌ Error sending enhanced notifications to staff: $e');
      // الرجوع للطريقة القديمة في حالة الفشل
      await _sendNotificationsToStaff(absence);
    }
  }

  // إرسال إشعارات للمشرفين والإدارة
  Future<void> _sendNotificationsToStaff(AbsenceModel absence) async {
    try {
      final dateText = absence.endDate != null
          ? 'من ${_formatDate(absence.date)} إلى ${_formatDate(absence.endDate!)}'
          : _formatDate(absence.date);

      final notificationTitle = 'إشعار غياب - ${absence.studentName}';
      final notificationBody = 'أبلغ ولي الأمر عن غياب ${absence.studentName} يوم $dateText\nالسبب: ${absence.reason}';

      // الحصول على جميع المشرفين والإدارة
      final supervisors = await _databaseService.getAllSupervisors();
      final admins = await _databaseService.getAllAdmins();

      // إرسال إشعار لكل مشرف
      for (final supervisor in supervisors) {
        await _notificationService.sendGeneralNotification(
          title: notificationTitle,
          body: notificationBody,
          recipientId: supervisor.id,
          data: {
            'type': 'absence_notification',
            'studentId': absence.studentId,
            'studentName': absence.studentName,
            'parentId': absence.parentId,
            'absenceId': absence.id,
            'date': absence.date.toIso8601String(),
            'endDate': absence.endDate?.toIso8601String(),
            'reason': absence.reason,
          },
        );
      }

      // إرسال إشعار لكل أدمن
      for (final admin in admins) {
        await _notificationService.sendGeneralNotification(
          title: notificationTitle,
          body: notificationBody,
          recipientId: admin.id,
          data: {
            'type': 'absence_notification',
            'studentId': absence.studentId,
            'studentName': absence.studentName,
            'parentId': absence.parentId,
            'absenceId': absence.id,
            'date': absence.date.toIso8601String(),
            'endDate': absence.endDate?.toIso8601String(),
            'reason': absence.reason,
          },
        );
      }

      debugPrint('âœ… Notifications sent to ${supervisors.length} supervisors and ${admins.length} admins');
    } catch (e) {
      debugPrint('â‌Œ Error sending notifications to staff: $e');
      // لا نريد أن يفشل إنشاء الغياب بسبب فشل الإشعارات
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }
}


