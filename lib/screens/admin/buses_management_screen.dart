import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../services/enhanced_notification_service.dart';
import '../../models/bus_model.dart';
import '../../widgets/admin_bottom_navigation.dart';

class BusesManagementScreen extends StatefulWidget {
  const BusesManagementScreen({super.key});

  @override
  State<BusesManagementScreen> createState() => _BusesManagementScreenState();
}

class _BusesManagementScreenState extends State<BusesManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إدارة السيارات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBusDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'البحث عن سيارة...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Buses List
          Expanded(
            child: StreamBuilder<List<BusModel>>(
              stream: _databaseService.getAllBuses(),
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
                        Text('خطأ في تحميل السيارات: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final buses = snapshot.data ?? [];
                final filteredBuses = buses.where((bus) {
                  return bus.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         bus.driverName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         bus.route.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredBuses.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBuses.length,
                  itemBuilder: (context, index) {
                    final bus = filteredBuses[index];
                    return _buildBusCard(bus);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'لا توجد سيارات مسجلة' : 'لا توجد نتائج للبحث',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة سيارة جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusModel bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: !bus.isActive 
            ? Border.all(color: Colors.red.withAlpha(76), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bus.isActive 
                      ? const Color(0xFF4CAF50).withAlpha(25)
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: bus.isActive ? const Color(0xFF4CAF50) : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.plateNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bus.route,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bus.isActive 
                      ? const Color(0xFF4CAF50).withAlpha(25)
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bus.isActive ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    fontSize: 12,
                    color: bus.isActive ? const Color(0xFF4CAF50) : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bus Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.person,
                  label: 'السائق',
                  value: bus.driverName,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.phone,
                  label: 'الهاتف',
                  value: bus.driverPhone,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.badge,
                  label: 'الرقم القومي',
                  value: bus.driverNationalId.isNotEmpty ? bus.driverNationalId : 'غير محدد',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.people,
                  label: 'السعة',
                  value: '${bus.capacity} طالب',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.ac_unit,
                  label: 'التكييف',
                  value: bus.hasAirConditioning ? 'متوفر' : 'غير متوفر',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.directions_bus,
                  label: 'نوع الباص',
                  value: bus.description.isNotEmpty ? bus.description : 'لا يوجد',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditBusDialog(bus),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleBusStatus(bus),
                  icon: Icon(
                    bus.isActive ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(bus.isActive ? 'إيقاف' : 'تفعيل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bus.isActive ? Colors.orange : const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddBusDialog() {
    _showBusDialog();
  }

  void _showEditBusDialog(BusModel bus) {
    _showBusDialog(bus: bus);
  }

  void _showBusDialog({BusModel? bus}) {
    final isEditing = bus != null;
    final plateNumberController = TextEditingController(text: bus?.plateNumber ?? '');
    final descriptionController = TextEditingController(text: bus?.description ?? '');
    final driverNameController = TextEditingController(text: bus?.driverName ?? '');
    final driverPhoneController = TextEditingController(text: bus?.driverPhone ?? '');
    final driverNationalIdController = TextEditingController(text: bus?.driverNationalId ?? '');
    final routeController = TextEditingController(text: bus?.route ?? '');
    final capacityController = TextEditingController(text: bus?.capacity.toString() ?? '30');
    bool hasAirConditioning = bus?.hasAirConditioning ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'تعديل السيارة' : 'إضافة سيارة جديدة'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: plateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: Icon(Icons.confirmation_number),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: routeController,
                    decoration: const InputDecoration(
                      labelText: 'خط السير',
                      prefixIcon: Icon(Icons.route),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: driverNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم السائق',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: driverPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'هاتف السائق',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: driverNationalIdController,
                    decoration: const InputDecoration(
                      labelText: 'الرقم القومي للسائق',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: capacityController,
                    decoration: const InputDecoration(
                      labelText: 'سعة السيارة',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'نوع الباص (اختياري)',
                      prefixIcon: Icon(Icons.directions_bus),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('يوجد تكييف'),
                    value: hasAirConditioning,
                    onChanged: (value) {
                      setState(() {
                        hasAirConditioning = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveBus(
                  context: context,
                  isEditing: isEditing,
                  busId: bus?.id,
                  plateNumber: plateNumberController.text,
                  description: descriptionController.text,
                  driverName: driverNameController.text,
                  driverPhone: driverPhoneController.text,
                  driverNationalId: driverNationalIdController.text,
                  route: routeController.text,
                  capacity: int.tryParse(capacityController.text) ?? 30,
                  hasAirConditioning: hasAirConditioning,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة السيارة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBus({
    required BuildContext context,
    required bool isEditing,
    String? busId,
    required String plateNumber,
    required String description,
    required String driverName,
    required String driverPhone,
    required String driverNationalId,
    required String route,
    required int capacity,
    required bool hasAirConditioning,
  }) async {
    if (plateNumber.trim().isEmpty ||
        driverName.trim().isEmpty ||
        route.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى ملء جميع الحقول المطلوبة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (isEditing && busId != null) {
        // Update existing bus
        final existingBus = await _databaseService.getBus(busId);
        if (existingBus != null) {
          final updatedBus = existingBus.copyWith(
            plateNumber: plateNumber.trim(),
            description: description.trim(),
            driverName: driverName.trim(),
            driverPhone: driverPhone.trim(),
            driverNationalId: driverNationalId.trim(),
            route: route.trim(),
            capacity: capacity,
            hasAirConditioning: hasAirConditioning,
            updatedAt: DateTime.now(),
          );
          await _databaseService.updateBus(updatedBus);
        }
      } else {
        // Add new bus
        final newBus = BusModel(
          id: _databaseService.generateTripId(),
          plateNumber: plateNumber.trim(),
          description: description.trim(),
          driverName: driverName.trim(),
          driverPhone: driverPhone.trim(),
          driverNationalId: driverNationalId.trim(),
          route: route.trim(),
          capacity: capacity,
          hasAirConditioning: hasAirConditioning,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.addBus(newBus);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تحديث السيارة بنجاح' : 'تم إضافة السيارة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving bus: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog even on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ السيارة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleBusStatus(BusModel bus) async {
    // إظهار تأكيد قبل تغيير الحالة
    final confirmed = await _showBusStatusConfirmation(bus);
    if (!confirmed) return;

    try {
      // إظهار مؤشر التحميل
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحديث حالة السيارة...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final newStatus = !bus.isActive;

      // تحديث حالة الحافلة
      final updatedBus = bus.copyWith(
        isActive: newStatus,
        updatedAt: DateTime.now(),
      );
      await _databaseService.updateBus(updatedBus);

      // إجراءات إضافية حسب الحالة الجديدة
      if (newStatus) {
        // تفعيل الحافلة
        await _handleBusActivation(bus);
      } else {
        // إيقاف الحافلة
        await _handleBusDeactivation(bus);
      }

      // إغلاق مؤشر التحميل
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus ? Icons.check_circle : Icons.pause_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  newStatus ? 'تم تفعيل السيارة بنجاح' : 'تم إيقاف السيارة بنجاح',
                ),
              ],
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير حالة السيارة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// إظهار تأكيد تغيير حالة الحافلة
  Future<bool> _showBusStatusConfirmation(BusModel bus) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              bus.isActive ? Icons.pause_circle : Icons.play_circle,
              color: bus.isActive ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(bus.isActive ? 'إيقاف السيارة' : 'تفعيل السيارة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'السيارة: ${bus.plateNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'السائق: ${bus.driverName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (bus.isActive) ...[
              const Text(
                '⚠️ عند إيقاف السيارة سيتم:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 8),
              const Text('• منع تسكين طلاب جدد في هذه السيارة'),
              const Text('• إشعار المشرف المعين للسيارة'),
              const Text('• إشعار أولياء أمور الطلاب المسكنين'),
              const Text('• إيقاف عمليات المسح والرحلات'),
            ] else ...[
              const Text(
                '✅ عند تفعيل السيارة سيتم:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              const Text('• السماح بتسكين طلاب جدد'),
              const Text('• إشعار المشرف بإعادة التفعيل'),
              const Text('• تفعيل عمليات المسح والرحلات'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: bus.isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(bus.isActive ? 'إيقاف السيارة' : 'تفعيل السيارة'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// معالجة تفعيل الحافلة
  Future<void> _handleBusActivation(BusModel bus) async {
    try {
      // إرسال إشعارات التفعيل
      await _sendBusActivationNotifications(bus);
      debugPrint('✅ Bus activation notifications sent for: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error handling bus activation: $e');
    }
  }

  /// معالجة إيقاف الحافلة
  Future<void> _handleBusDeactivation(BusModel bus) async {
    try {
      // إرسال إشعارات الإيقاف
      await _sendBusDeactivationNotifications(bus);
      debugPrint('✅ Bus deactivation notifications sent for: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error handling bus deactivation: $e');
    }
  }

  /// إرسال إشعارات تفعيل الحافلة
  Future<void> _sendBusActivationNotifications(BusModel bus) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();
      final adminName = adminDoc.data()?['name'] ?? 'الإدارة';

      await _notificationService.notifyBusActivation(
        busId: bus.id,
        busPlateNumber: bus.plateNumber,
        driverName: bus.driverName,
        adminName: adminName,
        adminId: currentUser?.uid,
      );

      debugPrint('✅ Bus activation notifications sent for: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error sending bus activation notifications: $e');
    }
  }

  /// إرسال إشعارات إيقاف الحافلة
  Future<void> _sendBusDeactivationNotifications(BusModel bus) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();
      final adminName = adminDoc.data()?['name'] ?? 'الإدارة';

      await _notificationService.notifyBusDeactivation(
        busId: bus.id,
        busPlateNumber: bus.plateNumber,
        driverName: bus.driverName,
        adminName: adminName,
        adminId: currentUser?.uid,
      );

      debugPrint('✅ Bus deactivation notifications sent for: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error sending bus deactivation notifications: $e');
    }
  }
}
