import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/parent_profile_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class CompleteProfileScreen extends StatefulWidget {
  final bool isEditing;

  const CompleteProfileScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherPhoneController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _databaseService.getParentProfile(currentUser.uid);
        if (profile != null && mounted) {
          _fullNameController.text = profile.fullName;
          _addressController.text = profile.address;
          _occupationController.text = profile.occupation;

          // إزالة +20 من أرقام الهواتف لعرضها في الحقول
          _fatherPhoneController.text = profile.fatherPhone.startsWith('+20')
              ? profile.fatherPhone.substring(3)
              : profile.fatherPhone;
          _motherPhoneController.text = profile.motherPhone.startsWith('+20')
              ? profile.motherPhone.substring(3)
              : profile.motherPhone;
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _fatherPhoneController.dispose();
    _motherPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل البيانات الشخصية' : 'إكمال البيانات الشخصية'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.isEditing, // السماح بالرجوع في حالة التعديل
      ),
      body: _isLoadingData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل البيانات...'),
                ],
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E88E5),
                      const Color(0xFF1E88E5).withAlpha(204),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isEditing ? 'تحديث البيانات' : 'مرحباً بك في كيدز باص',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isEditing
                          ? 'يمكنك تعديل بياناتك الشخصية هنا'
                          : 'يرجى إكمال بياناتك الشخصية للمتابعة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withAlpha(229),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Fields
              _buildTextField(
                controller: _fullNameController,
                label: 'الاسم الثلاثي',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال الاسم الثلاثي';
                  }
                  final names = value.trim().split(' ');
                  if (names.length < 3) {
                    return 'يرجى إدخال الاسم الثلاثي كاملاً';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: 'العنوان',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال العنوان';
                  }
                  if (value.trim().length < 10) {
                    return 'يرجى إدخال عنوان مفصل';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _occupationController,
                label: 'الوظيفة',
                icon: Icons.work,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال الوظيفة';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _fatherPhoneController,
                label: 'رقم هاتف الوالد',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                prefixText: '+20',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال رقم هاتف الوالد';
                  }
                  // التحقق من الرقم المصري (10 أو 11 رقم بعد +20)
                  final cleanNumber = value.trim().replaceAll(RegExp(r'[^\d]'), '');
                  if (!RegExp(r'^(10|11|12|15)\d{8}$').hasMatch(cleanNumber)) {
                    return 'يرجى إدخال رقم هاتف مصري صحيح (+20xxxxxxxxxx)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _motherPhoneController,
                label: 'رقم هاتف الوالدة',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                prefixText: '+20',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال رقم هاتف الوالدة';
                  }
                  // التحقق من الرقم المصري (10 أو 11 رقم بعد +20)
                  final cleanNumber = value.trim().replaceAll(RegExp(r'[^\d]'), '');
                  if (!RegExp(r'^(10|11|12|15)\d{8}$').hasMatch(cleanNumber)) {
                    return 'يرجى إدخال رقم هاتف مصري صحيح (+20xxxxxxxxxx)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: _isLoading
                    ? 'جاري الحفظ...'
                    : widget.isEditing
                        ? 'حفظ التعديلات'
                        : 'حفظ البيانات والمتابعة',
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading ? null : widget.isEditing ? Icons.update : Icons.save,
              ),

              // Cancel Button (only in edit mode)
              if (widget.isEditing) ...[
                const SizedBox(height: 12),
                CustomButton(
                  text: 'إلغاء',
                  onPressed: () {
                    context.pop(false); // العودة بدون حفظ
                  },
                  icon: Icons.cancel,
                  backgroundColor: Colors.grey[600],
                ),
              ],

              const SizedBox(height: 16),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withAlpha(76),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'هذه البيانات مطلوبة لضمان التواصل الآمن وإدارة حساب طفلك بشكل صحيح',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Color(0xFF1E88E5),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      // تنسيق أرقام الهواتف المصرية
      final fatherPhone = '+20${_fatherPhoneController.text.trim()}';
      final motherPhone = '+20${_motherPhoneController.text.trim()}';

      if (widget.isEditing) {
        // تحديث البيانات الموجودة
        await _databaseService.updateParentProfile(currentUser.uid, {
          'fullName': _fullNameController.text.trim(),
          'address': _addressController.text.trim(),
          'occupation': _occupationController.text.trim(),
          'fatherPhone': fatherPhone,
          'motherPhone': motherPhone,
          'isProfileComplete': true,
        });
      } else {
        // إنشاء بروفايل جديد
        final profile = ParentProfileModel(
          id: currentUser.uid,
          fullName: _fullNameController.text.trim(),
          address: _addressController.text.trim(),
          occupation: _occupationController.text.trim(),
          fatherPhone: fatherPhone,
          motherPhone: motherPhone,
          email: currentUser.email ?? '',
          isProfileComplete: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.saveParentProfile(profile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'تم تحديث البيانات بنجاح' : 'تم حفظ البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // العودة للصفحة السابقة أو الرئيسية
        if (widget.isEditing) {
          context.pop(true); // العودة للبروفايل مع إشارة النجاح
        } else {
          context.go('/parent'); // الانتقال للرئيسية
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
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
}


