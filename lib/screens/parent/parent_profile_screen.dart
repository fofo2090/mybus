import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/parent_profile_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_widgets.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  late Future<ParentProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<ParentProfileModel?> _loadProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        return await _databaseService.getParentProfile(currentUser.uid);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('البروفايل الشخصي'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<ParentProfileModel?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _buildNoProfileState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshProfile();
            },
            child: _buildProfileContent(profile),
          );
        },
      ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.person_add,
                size: 64,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'البروفايل غير مكتمل',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى إكمال بياناتك الشخصية\nللحصول على تجربة أفضل',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'إكمال البيانات',
              onPressed: () {
                context.push('/parent/complete-profile');
              },
              icon: Icons.edit,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(ParentProfileModel profile) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getPadding(context),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(profile),
          const SizedBox(height: 24),

          // Profile Details
          _buildProfileDetails(profile),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ParentProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withAlpha(51),
            child: Text(
              profile.initials,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withAlpha(76)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green[100],
                ),
                const SizedBox(width: 4),
                Text(
                  'البروفايل مكتمل',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[100],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(ParentProfileModel profile) {
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
          ResponsiveSubheading(
            'البيانات الشخصية',
            color: const Color(0xFF2D3748),
          ),
          const ResponsiveVerticalSpace(),
          
          _buildDetailItem(
            icon: Icons.location_on,
            label: 'العنوان',
            value: profile.address,
            color: Colors.red,
          ),

          _buildDetailItem(
            icon: Icons.work,
            label: 'الوظيفة',
            value: profile.occupation,
            color: Colors.blue,
          ),

          _buildDetailItem(
            icon: Icons.phone,
            label: 'هاتف الوالد',
            value: profile.fatherPhone,
            color: Colors.green,
          ),

          _buildDetailItem(
            icon: Icons.phone,
            label: 'هاتف الوالدة',
            value: profile.motherPhone,
            color: Colors.purple,
          ),

          _buildDetailItem(
            icon: Icons.email,
            label: 'البريد الإلكتروني',
            value: profile.email,
            color: Colors.orange,
          ),

          _buildDetailItem(
            icon: Icons.calendar_today,
            label: 'تاريخ التسجيل',
            value: _formatDate(profile.createdAt),
            color: Colors.teal,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLast = false,
  }) {
    return Column(
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'تعديل البيانات',
          onPressed: () async {
            final result = await context.push('/parent/complete-profile?edit=true');
            // إعادة تحميل البيانات بعد العودة من التعديل
            if (result == true) {
              _refreshProfile();
            }
          },
          icon: Icons.edit,
          backgroundColor: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'العودة للرئيسية',
          onPressed: () {
            context.pop();
          },
          icon: Icons.home,
          backgroundColor: Colors.grey[600],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


