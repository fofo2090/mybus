import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/supervisor_profile_model.dart';
import '../../models/user_model.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../models/bus_model.dart';
import '../../widgets/responsive_widgets.dart';

class SupervisorProfileScreen extends StatefulWidget {
  const SupervisorProfileScreen({super.key});

  @override
  State<SupervisorProfileScreen> createState() => _SupervisorProfileScreenState();
}

class _SupervisorProfileScreenState extends State<SupervisorProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _emailController = TextEditingController();
  
  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String _selectedQualification = '';
  String _busAssignment = '';
  SupervisorProfileModel? _profile;
  UserModel? _currentUser;
  List<SupervisorAssignmentModel> _assignments = [];
  BusModel? _assignedBus;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تحميل البيانات عند العودة للصفحة
    if (mounted) {
      _loadSupervisorAssignments();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        _currentUser = UserModel.fromMap(userDoc.data()!);
        _emailController.text = _currentUser!.email;
        _phoneController.text = _currentUser!.phone;
      }

      // Load supervisor profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('supervisor_profiles')
          .doc(currentUser.uid)
          .get();

      if (profileDoc.exists) {
        _profile = SupervisorProfileModel.fromMap(profileDoc.data()!);
        _fillFormFields();
      } else {
        // Create default profile
        _profile = SupervisorProfileModel(
          id: currentUser.uid,
          fullName: _currentUser?.name ?? '',
          address: '',
          phone: _currentUser?.phone ?? '',
          nationalId: '',
          qualification: '',
          busAssignment: '',
          email: _currentUser?.email ?? '',
          isProfileComplete: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Load supervisor assignments
      await _loadSupervisorAssignments();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSupervisorAssignments() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      debugPrint('🔄 Loading supervisor assignments for: ${currentUser.uid}');

      // جلب تسكينات المشرف
      final assignments = await _databaseService.getSupervisorAssignmentsSimple(currentUser.uid);

      if (assignments.isNotEmpty) {
        _assignments = assignments;
        final assignment = assignments.first;

        debugPrint('✅ Found assignment: ${assignment.busRoute}');

        // جلب بيانات الباص
        if (assignment.busId.isNotEmpty) {
          final bus = await _databaseService.getBusById(assignment.busId);
          if (bus != null) {
            _assignedBus = bus;
            debugPrint('✅ Found bus: ${bus.plateNumber} - ${bus.route}');
          }
        }

        // تحديث نص التسكين
        _busAssignment = _buildAssignmentText(assignment);
      } else {
        debugPrint('⚠️ No assignments found');
        _busAssignment = 'لم يتم التعيين بعد';
      }
    } catch (e) {
      debugPrint('❌ Error loading supervisor assignments: $e');
      _busAssignment = 'خطأ في تحميل البيانات';
    }
  }

  String _buildAssignmentText(SupervisorAssignmentModel assignment) {
    final busInfo = _assignedBus != null
        ? '${_assignedBus!.plateNumber} - ${_assignedBus!.route}'
        : assignment.busRoute.isNotEmpty
            ? assignment.busRoute
            : 'باص غير محدد';

    return '$busInfo\nالاتجاه: ${assignment.directionDisplayName}\nالحالة: ${assignment.statusDisplayName}';
  }

  void _fillFormFields() {
    if (_profile != null) {
      _fullNameController.text = _profile!.fullName;
      _addressController.text = _profile!.address;
      _phoneController.text = _profile!.phone;
      _nationalIdController.text = _profile!.nationalId;
      _selectedQualification = _profile!.qualification;
      _busAssignment = _profile!.busAssignment;
      _emailController.text = _profile!.email;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final updatedProfile = SupervisorProfileModel(
        id: currentUser.uid,
        fullName: _fullNameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        qualification: _selectedQualification,
        busAssignment: _busAssignment,
        email: _emailController.text.trim(),
        isProfileComplete: _hasRequiredData(),
        createdAt: _profile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('supervisor_profiles')
          .doc(currentUser.uid)
          .set(updatedProfile.toMap());

      // Update user data if needed
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          name: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update(updatedUser.toMap());
      }

      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasRequiredData() {
    return _fullNameController.text.trim().isNotEmpty &&
           _addressController.text.trim().isNotEmpty &&
           _phoneController.text.trim().isNotEmpty &&
           _nationalIdController.text.trim().isNotEmpty &&
           _selectedQualification.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadSupervisorAssignments();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث بيانات التسكين'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            tooltip: 'تحديث بيانات التسكين',
          ),
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ResponsiveHelper.getPadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    const SizedBox(height: 24),

                    // Personal Information Card
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 20),

                    // Contact Information Card
                    _buildContactInfoCard(),
                    const SizedBox(height: 20),

                    // Professional Information Card
                    _buildProfessionalInfoCard(),
                    const SizedBox(height: 20),

                    // Bus Assignment Card
                    _buildBusAssignmentCard(),
                    const SizedBox(height: 32),

                    // Action Buttons
                    if (_isEditing) _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E88E5), const Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              _profile?.initials ?? 'م',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile?.displayName ?? 'المشرفة',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _profile?.isProfileComplete == true ? 'الملف مكتمل' : 'الملف غير مكتمل',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildInfoCard(
      title: 'المعلومات الشخصية',
      icon: Icons.person,
      children: [
        _buildTextField(
          controller: _fullNameController,
          label: 'الاسم الكامل',
          icon: Icons.badge,
          enabled: _isEditing,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال الاسم الكامل';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'العنوان',
          icon: Icons.location_on,
          enabled: _isEditing,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال العنوان';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nationalIdController,
          label: 'رقم البطاقة الشخصية',
          icon: Icons.credit_card,
          enabled: _isEditing,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال رقم البطاقة';
            }
            if (value.trim().length < 10) {
              return 'رقم البطاقة يجب أن يكون 10 أرقام على الأقل';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return _buildInfoCard(
      title: 'معلومات الاتصال',
      icon: Icons.contact_phone,
      children: [
        _buildTextField(
          controller: _phoneController,
          label: 'رقم الهاتف',
          icon: Icons.phone,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال رقم الهاتف';
            }
            if (value.trim().length < 10) {
              return 'رقم الهاتف غير صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'البريد الإلكتروني',
          icon: Icons.email,
          enabled: false, // Email cannot be changed
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoCard() {
    return _buildInfoCard(
      title: 'المعلومات المهنية',
      icon: Icons.work,
      children: [
        _buildDropdownField(
          value: _selectedQualification.isNotEmpty ? _selectedQualification : null,
          label: 'المؤهل العلمي',
          icon: Icons.school,
          items: SupervisorQualifications.qualifications,
          enabled: _isEditing,
          onChanged: (value) {
            setState(() {
              _selectedQualification = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى اختيار المؤهل العلمي';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBusAssignmentCard() {
    return _buildInfoCard(
      title: 'تسكين الباص',
      icon: Icons.directions_bus,
      children: [
        if (_assignments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(76)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'حالة التسكين',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'لم يتم التعيين بعد',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم تحديد تسكين الباص من قبل الإدارة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          ..._assignments.map((assignment) => _buildAssignmentCard(assignment)).toList(),
      ],
    );
  }

  Widget _buildAssignmentCard(SupervisorAssignmentModel assignment) {
    final isActive = assignment.status == AssignmentStatus.active;
    final direction = assignment.directionDisplayName;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.withAlpha(76) : Colors.grey.withAlpha(76),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.pause_circle,
                color: isActive ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تسكين ${assignment.statusDisplayName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green[700] : Colors.grey[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withAlpha(51) : Colors.grey.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  direction,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bus information
          if (_assignedBus != null) ...[
            _buildInfoRow(Icons.directions_bus, 'رقم الباص', _assignedBus!.plateNumber),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.route, 'خط السير', _assignedBus!.route),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.airline_seat_recline_normal, 'عدد المقاعد', '${_assignedBus!.capacity}'),
          ] else if (assignment.busRoute.isNotEmpty) ...[
            _buildInfoRow(Icons.route, 'خط السير', assignment.busRoute),
          ],

          const SizedBox(height: 8),

          // Assignment details
          if (assignment.assignedByName.isNotEmpty) ...[
            _buildInfoRow(Icons.person, 'تم التعيين بواسطة', assignment.assignedByName),
            const SizedBox(height: 8),
          ],

          _buildInfoRow(
            Icons.access_time,
            'تاريخ التعيين',
            '${assignment.assignedAt.day}/${assignment.assignedAt.month}/${assignment.assignedAt.year}'
          ),

          if (assignment.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.note, 'ملاحظات', assignment.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _fillFormFields(); // Reset form
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'حفظ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
                  color: const Color(0xFF1E88E5).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1E88E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    bool enabled = true,
    void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
