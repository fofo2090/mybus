import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/persistent_auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/ui_helper.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserType _selectedUserType = UserType.parent;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<PersistentAuthService>(context, listen: false);

    try {
      final UserModel? user = await authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: _selectedUserType,
      );

      if (user != null && mounted) {
        // Navigate to home screen after successful registration
        NavigationHelper.navigateToHome(context, user.userType);
      }
    } catch (e) {
      if (mounted) {
        NavigationHelper.showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        showChildren: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'املأ البيانات التالية للانضمام إلينا',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Name Field
                  CustomTextField(
                    controller: _nameController,
                    label: 'الاسم الكامل',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                        if (value == null || value.isEmpty) {
                            return 'يرجى إدخال الاسم';
                        }
                        return null;
                    }
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                        if (value == null || value.isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'يرجى إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                    }
                  ),
                  const SizedBox(height: 20),

                  // Phone Field
                  CustomTextField(
                    controller: _phoneController,
                    label: 'رقم الجوال',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (value) {
                        if (value == null || value.isEmpty) {
                            return 'يرجى إدخال رقم الهاتف';
                        }
                        return null;
                    }
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                        if (value == null || value.isEmpty) {
                            return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                    }
                  ),
                   const SizedBox(height: 16),
                        
                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى تأكيد كلمة المرور';
                            }
                            if (value != _passwordController.text) {
                              return 'كلمة المرور غير متطابقة';
                            }
                            return null;
                          },
                        ),

                  const SizedBox(height: 20),

                  // User Type Selection
                  _buildUserTypeSelector(),
                  const SizedBox(height: 30),

                  // Register Button
                  Consumer<PersistentAuthService>(
                    builder: (context, authService, child) {
                      return UIHelper.buildActionButton(
                        label: 'إنشاء حساب',
                        onPressed: _register,
                        icon: Icons.person_add,
                        isLoading: authService.isLoading,
                        isEnabled: !authService.isLoading,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'لديك حساب بالفعل؟ ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserType>(
          value: _selectedUserType,
          isExpanded: true,
          dropdownColor: const Color(0xFF3A6EA5),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: [
            DropdownMenuItem(
              value: UserType.parent,
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('ولي أمر', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: UserType.supervisor,
              child: Row(
                children: [
                  const Icon(Icons.supervisor_account, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('مشرف', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
          onChanged: (UserType? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedUserType = newValue;
              });
            }
          },
        ),
      ),
    );
  }
}
