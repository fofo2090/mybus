import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../services/database_service.dart';
import '../../services/enhanced_notification_service.dart';
import '../../utils/app_constants.dart';


class EditStudentScreen extends StatefulWidget {
  final String studentId;

  const EditStudentScreen({super.key, required this.studentId});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  StudentModel? _student;
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedStatus = 'home';
  String? _selectedBusId;
  List<BusModel> _availableBuses = [];



  final List<String> _busRoutes = [
    'خط العواميه',
    'خط التليفزيون',
    'خط البياضية',
    'خط شرق السكة',
    'خط الشمال',
    'خط الجنوب',
    'خط الشرق',
    'خط الغرب',
    'خط الوسط',
  ];

  final List<String> _schoolNames = [
    'النيل الدوليه بطيبه',
    'المستقبل بطيبه',
    'المستقبل الدوليه بالطود',
    'المدرسه التجريبى بطيبه',
    'أخرى',
  ];

  final List<String> _statuses = [
    'home',
    'onBus',
    'atSchool'
  ];

  @override
  void initState() {
    super.initState();
    _loadStudent();
    _loadAvailableBuses();
  }

  Future<void> _loadAvailableBuses() async {
    try {
      final buses = await _databaseService.getAllBuses().first;
      setState(() {
        _availableBuses = buses;
      });
    } catch (e) {
      debugPrint('Error loading buses: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolNameController.dispose();
    _gradeController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    try {
      final doc = await _firestore.collection('students').doc(widget.studentId).get();
      
      if (doc.exists) {
        final studentData = doc.data()!;
        _student = StudentModel.fromMap(studentData);
        
        // Fill form fields
        _nameController.text = _student!.name;
        _schoolNameController.text = _student!.schoolName;
        _gradeController.text = _student!.grade;
        _selectedBusId = _student!.busId.isNotEmpty ? _student!.busId : null;
        _parentNameController.text = _student!.parentName;
        _parentPhoneController.text = _student!.parentPhone;
        _addressController.text = _student!.address;
        _notesController.text = _student!.notes;
        _selectedStatus = _student!.currentStatus.toString().split('.').last;
        
        setState(() {
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الطالب غير موجود'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('تعديل بيانات الطالب'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E88E5),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Student Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF1E88E5),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'بيانات الطالب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Student Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'اسم الطالب',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم الطالب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // School Name Dropdown
                          DropdownButtonFormField<String>(
                            value: _schoolNames.contains(_schoolNameController.text) ? _schoolNameController.text : null,
                            decoration: InputDecoration(
                              labelText: 'اسم المدرسة',
                              prefixIcon: const Icon(Icons.school),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            hint: const Text('اختر المدرسة'),
                            items: _schoolNames.map((school) {
                              return DropdownMenuItem(
                                value: school,
                                child: Text(school),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _schoolNameController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى اختيار المدرسة';
                              }
                              return null;
                            },
                          ),

                          // Custom school name field (if "أخرى" is selected)
                          if (_schoolNameController.text == 'أخرى') ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'اسم المدرسة (مخصص)',
                                prefixIcon: const Icon(Icons.edit),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onChanged: (value) {
                                // Update the controller with custom school name
                                _schoolNameController.text = value;
                              },
                              validator: (value) {
                                if (_schoolNameController.text == 'أخرى' && (value == null || value.isEmpty)) {
                                  return 'يرجى إدخال اسم المدرسة';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          
                          // Grade Dropdown
                          DropdownButtonFormField<String>(
                            value: AppConstants.studentGrades.contains(_gradeController.text) ? _gradeController.text : null,
                            decoration: InputDecoration(
                              labelText: 'الصف الدراسي',
                              prefixIcon: const Icon(Icons.class_),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: AppConstants.studentGrades.map((grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(grade),
                              );
                            }).toList(),
                            onChanged: (value) {
                              _gradeController.text = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى اختيار الصف الدراسي';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Bus Selection
                          DropdownButtonFormField<String>(
                            value: _selectedBusId,
                            decoration: InputDecoration(
                              labelText: 'السيارة',
                              prefixIcon: const Icon(Icons.directions_bus),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            hint: const Text('اختر السيارة'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('بدون سيارة'),
                              ),
                              ..._availableBuses.map((bus) {
                                return DropdownMenuItem<String>(
                                  value: bus.id,
                                  child: Text('${bus.plateNumber} - ${bus.driverName}'),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedBusId = value;
                              });
                            },
                            validator: (value) {
                              // Bus assignment is optional
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Parent Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.family_restroom,
                                  color: Color(0xFFFF9800),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'بيانات ولي الأمر',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Parent Name
                          TextFormField(
                            controller: _parentNameController,
                            decoration: InputDecoration(
                              labelText: 'اسم ولي الأمر',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم ولي الأمر';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Parent Phone
                          TextFormField(
                            controller: _parentPhoneController,
                            decoration: InputDecoration(
                              labelText: 'رقم هاتف ولي الأمر',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.phone,
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
                    
                    const SizedBox(height: 20),

                    // Student Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'تفاصيل الطالب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Address Field
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'عنوان الطالب',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال عنوان الطالب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Notes Field
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'ملاحظات إضافية (اختياري)',
                              prefixIcon: const Icon(Icons.note),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF4CAF50),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'حالة الطالب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Status Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'الحالة الحالية',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _statuses.map((status) {
                              String displayText;
                              switch (status) {
                                case 'home':
                                  displayText = 'في المنزل';
                                  break;
                                case 'onBus':
                                  displayText = 'في الباص';
                                  break;
                                case 'atSchool':
                                  displayText = 'في المدرسة';
                                  break;
                                default:
                                  displayText = status;
                              }
                              return DropdownMenuItem(
                                value: status,
                                child: Text(displayText),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'حفظ التعديلات',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse status
      StudentStatus status;
      switch (_selectedStatus) {
        case 'home':
          status = StudentStatus.home;
          break;
        case 'onBus':
          status = StudentStatus.onBus;
          break;
        case 'atSchool':
          status = StudentStatus.atSchool;
          break;
        default:
          status = StudentStatus.home;
      }

      // تتبع التغييرات
      final updatedFields = <String, dynamic>{};

      if (_student!.name != _nameController.text.trim()) {
        updatedFields['name'] = {
          'old': _student!.name,
          'new': _nameController.text.trim(),
        };
      }

      if (_student!.schoolName != _schoolNameController.text.trim()) {
        updatedFields['schoolName'] = {
          'old': _student!.schoolName,
          'new': _schoolNameController.text.trim(),
        };
      }

      if (_student!.grade != _gradeController.text.trim()) {
        updatedFields['grade'] = {
          'old': _student!.grade,
          'new': _gradeController.text.trim(),
        };
      }

      if (_student!.busId != (_selectedBusId ?? '')) {
        // الحصول على اسم الباص للعرض
        String oldBusName = 'غير محدد';
        String newBusName = 'غير محدد';

        if (_student!.busId.isNotEmpty) {
          final oldBus = _availableBuses.firstWhere(
            (bus) => bus.id == _student!.busId,
            orElse: () => BusModel(
              id: '',
              plateNumber: 'غير محدد',
              description: '',
              driverName: '',
              driverPhone: '',
              route: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          oldBusName = oldBus.plateNumber;
        }

        if (_selectedBusId != null && _selectedBusId!.isNotEmpty) {
          final newBus = _availableBuses.firstWhere(
            (bus) => bus.id == _selectedBusId,
            orElse: () => BusModel(
              id: '',
              plateNumber: 'غير محدد',
              description: '',
              driverName: '',
              driverPhone: '',
              route: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          newBusName = newBus.plateNumber;
        }

        updatedFields['busId'] = {
          'old': oldBusName,
          'new': newBusName,
        };
      }

      if (_student!.parentName != _parentNameController.text.trim()) {
        updatedFields['parentName'] = {
          'old': _student!.parentName,
          'new': _parentNameController.text.trim(),
        };
      }

      if (_student!.parentPhone != _parentPhoneController.text.trim()) {
        updatedFields['parentPhone'] = {
          'old': _student!.parentPhone,
          'new': _parentPhoneController.text.trim(),
        };
      }

      if (_student!.address != _addressController.text.trim()) {
        updatedFields['address'] = {
          'old': _student!.address,
          'new': _addressController.text.trim(),
        };
      }

      if (_student!.notes != _notesController.text.trim()) {
        updatedFields['notes'] = {
          'old': _student!.notes,
          'new': _notesController.text.trim(),
        };
      }

      if (_student!.currentStatus != status) {
        updatedFields['currentStatus'] = {
          'old': _student!.statusDisplayText,
          'new': _getStatusDisplayText(status),
        };
      }

      // Update student data
      final updatedStudent = _student!.copyWith(
        name: _nameController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
        grade: _gradeController.text.trim(),
        busRoute: '', // Deprecated field, keeping for compatibility
        busId: _selectedBusId ?? '',
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        currentStatus: status,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('students').doc(widget.studentId).update(updatedStudent.toMap());

      // إرسال الإشعارات إذا كان هناك تغييرات
      if (updatedFields.isNotEmpty) {
        await _sendUpdateNotifications(updatedStudent, updatedFields);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ التعديلات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الطالب "${_student?.name}"؟\n\nسيتم حذف جميع البيانات المرتبطة به نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStudent();
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

  Future<void> _deleteStudent() async {
    try {
      await _firestore.collection('students').doc(widget.studentId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الطالب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
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

  /// إرسال إشعارات التحديث لولي الأمر والمشرف
  Future<void> _sendUpdateNotifications(
    StudentModel updatedStudent,
    Map<String, dynamic> updatedFields,
  ) async {
    try {
      // الحصول على معلومات الإدمن الحالي
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final adminDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final adminName = adminDoc.data()?['name'] ?? 'الإدارة';

      // إرسال الإشعارات (باستثناء الإدمن الحالي)
      await _notificationService.notifyStudentDataUpdate(
        studentId: updatedStudent.id,
        studentName: updatedStudent.name,
        parentId: updatedStudent.parentId,
        busId: updatedStudent.busId,
        updatedFields: updatedFields,
        adminName: adminName,
        adminId: currentUser.uid, // استبعاد الإدمن الحالي من الإشعارات
      );

      debugPrint('✅ Update notifications sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending update notifications: $e');
    }
  }

  /// الحصول على نص عرض الحالة
  String _getStatusDisplayText(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return 'في المنزل';
      case StudentStatus.onBus:
        return 'في الباص';
      case StudentStatus.atSchool:
        return 'في المدرسة';
    }
  }
}
