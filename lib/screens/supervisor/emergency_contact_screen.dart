import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isLoading = true;
  UserModel? _currentUser;
  Map<String, dynamic> _schoolInfo = {};
  String _adminPhone = '';

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      // Load school information for admin contact
      final schoolDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('school')
          .get();

      if (schoolDoc.exists) {
        _schoolInfo = schoolDoc.data() ?? {};
        _adminPhone = _schoolInfo['phone'] ?? '';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading emergency data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }





  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'اتصال الطوارئ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Alert Card
                  _buildEmergencyAlertCard(),
                  const SizedBox(height: 20),



                  // Administration Contact Card
                  _buildAdminContactCard(),
                  const SizedBox(height: 20),




                ],
              ),
            ),
    );
  }

  Widget _buildEmergencyAlertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'حالة طوارئ؟',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اتصل فوراً بالأرقام أدناه',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAdminContactCard() {
    return _buildInfoCard(
      title: 'رقم الإدارة',
      icon: Icons.admin_panel_settings,
      color: Colors.green,
      children: [
        _buildInfoRow(
          icon: Icons.phone,
          label: 'رقم الإدارة',
          value: _adminPhone.isNotEmpty ? _adminPhone : 'غير محدد',
          isClickable: _adminPhone.isNotEmpty,
          onTap: _adminPhone.isNotEmpty 
              ? () => _makePhoneCall(_adminPhone)
              : null,
        ),
        if (_schoolInfo['email'] != null && _schoolInfo['email'].isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email,
            label: 'البريد الإلكتروني',
            value: _schoolInfo['email'],
          ),
        ],
      ],
    );
  }







  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
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
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isClickable ? Colors.blue.withAlpha(13) : Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: isClickable ? Border.all(color: Colors.blue.withAlpha(76)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isClickable ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isClickable ? Colors.blue : const Color(0xFF2D3748),
                ),
              ),
            ),
            if (isClickable)
              Icon(
                Icons.phone,
                size: 16,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}
