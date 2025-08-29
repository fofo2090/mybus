import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/responsive_widgets.dart';
import '../../utils/constants.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  // Controllers
  final _nameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedBusId;
  String? _selectedGrade;
  String? _selectedSchool;
  bool _isLoading = false;
  List<BusModel> _availableBuses = [];

  @override
  void initState() {
    super.initState();
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
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _schoolNameController.dispose();
    _gradeController.dispose();
    _addressController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إضافة طالب جديد'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getPadding(context,
            mobilePadding: const EdgeInsets.all(12),
            tabletPadding: const EdgeInsets.all(16),
            desktopPadding: const EdgeInsets.all(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: ResponsiveHelper.getPadding(context,
                  mobilePadding: const EdgeInsets.all(16),
                  tabletPadding: const EdgeInsets.all(20),
                  desktopPadding: const EdgeInsets.all(24),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(25),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 48,
                      color: Color(0xFF1E88E5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'بيانات الطالب الجديد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يرجى ملء جميع البيانات المطلوبة',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Student Information Section
              _buildSectionCard(
                title: 'بيانات الطالب',
                icon: Icons.school,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: 'اسم الطالب',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم الطالب';
                      }
                      if (value.length < 2) {
                        return 'الاسم يجب أن يكون حرفين على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: InputDecoration(
                      labelText: 'الصف الدراسي',
                      prefixIcon: const Icon(Icons.class_),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5)),
                      ),
                    ),
                    hint: const Text('اختر الصف الدراسي'),
                    items: AppConstants.studentGrades.map((grade) {
                      return DropdownMenuItem<String>(
                        value: grade,
                        child: Text(grade),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGrade = value;
                        _gradeController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى اختيار الصف الدراسي';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSchool,
                    decoration: InputDecoration(
                      labelText: 'اسم المدرسة',
                      prefixIcon: const Icon(Icons.school),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5)),
                      ),
                    ),
                    hint: const Text('اختر المدرسة'),
                    items: [
                      ...AppConstants.schoolNames.map((school) {
                        return DropdownMenuItem<String>(
                          value: school,
                          child: Text(school),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: 'أخرى',
                        child: Text('أخرى'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSchool = value;
                        if (value != 'أخرى') {
                          _schoolNameController.text = value ?? '';
                        } else {
                          _schoolNameController.clear();
                        }
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
                  if (_selectedSchool == 'أخرى') ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _schoolNameController,
                      label: 'اسم المدرسة (مخصص)',
                      prefixIcon: Icons.edit,
                      validator: (value) {
                        if (_selectedSchool == 'أخرى' && (value == null || value.isEmpty)) {
                          return 'يرجى إدخال اسم المدرسة';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Student Details Section
              _buildStudentDetailsSection(),

              const SizedBox(height: 20),

              // Parent Information Section
              _buildSectionCard(
                title: 'بيانات ولي الأمر',
                icon: Icons.family_restroom,
                children: [
                  CustomTextField(
                    controller: _parentNameController,
                    label: 'اسم ولي الأمر',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم ولي الأمر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _parentPhoneController,
                    label: 'رقم هاتف ولي الأمر',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال رقم الهاتف';
                      }
                      if (value.length < 10) {
                        return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Transportation Information Section
              _buildSectionCard(
                title: 'بيانات النقل',
                icon: Icons.directions_bus,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBusId,
                    decoration: InputDecoration(
                      labelText: 'السيارة',
                      prefixIcon: const Icon(Icons.directions_bus),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5)),
                      ),
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

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'إلغاء',
                      onPressed: _isLoading ? null : () => context.pop(),
                      backgroundColor: Colors.grey[100],
                      textColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'إضافة الطالب',
                      onPressed: _isLoading ? null : _addStudent,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1E88E5), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate unique ID and QR code
      final studentId = _databaseService.generateTripId(); // Using same UUID generator
      final qrCode = await _databaseService.generateQRCode();

      // Create student model
      final student = StudentModel(
        id: studentId,
        name: _nameController.text.trim(),
        parentId: '', // Will be set when parent registers
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        parentEmail: '', // Will be set when parent registers
        qrCode: qrCode,
        schoolName: _schoolNameController.text.trim(),
        grade: _gradeController.text.trim(),
        busRoute: '', // Deprecated field, keeping for compatibility
        busId: _selectedBusId ?? '',
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        currentStatus: StudentStatus.home,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add student to database
      await _databaseService.addStudent(student);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة الطالب ${student.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الطالب: $e'),
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

  Widget _buildStudentDetailsSection() {
    return _buildSectionCard(
      title: 'تفاصيل الطالب',
      icon: Icons.info_outline,
      children: [
        CustomTextField(
          controller: _addressController,
          label: 'عنوان الطالب',
          prefixIcon: Icons.location_on,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال عنوان الطالب';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _notesController,
          label: 'ملاحظات إضافية (اختياري)',
          prefixIcon: Icons.note,
          maxLines: 3,
          validator: null, // Optional field
        ),
      ],
    );
  }
}


