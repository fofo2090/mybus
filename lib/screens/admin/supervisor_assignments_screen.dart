import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../models/user_model.dart';
import '../../models/bus_model.dart';
import '../../widgets/admin_bottom_navigation.dart';

// Statistics model for assignments
class AssignmentStatistics {
  final int totalAssignments;
  final int activeAssignments;
  final int emergencyAssignments;
  final int unassignedBuses;
  final int totalSupervisors;
  final int availableSupervisors;

  const AssignmentStatistics({
    required this.totalAssignments,
    required this.activeAssignments,
    required this.emergencyAssignments,
    required this.unassignedBuses,
    required this.totalSupervisors,
    required this.availableSupervisors,
  });

  factory AssignmentStatistics.empty() {
    return const AssignmentStatistics(
      totalAssignments: 0,
      activeAssignments: 0,
      emergencyAssignments: 0,
      unassignedBuses: 0,
      totalSupervisors: 0,
      availableSupervisors: 0,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }










}

class SupervisorAssignmentsScreen extends StatefulWidget {
  const SupervisorAssignmentsScreen({super.key});

  @override
  State<SupervisorAssignmentsScreen> createState() => _SupervisorAssignmentsScreenState();
}

class _SupervisorAssignmentsScreenState extends State<SupervisorAssignmentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  String _selectedFilter = 'all'; // all, active, emergency
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            _currentUser = UserModel.fromMap(userData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إدارة تعيينات المشرفين',
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
            icon: const Icon(Icons.add),
            onPressed: _showCreateAssignmentDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(),
          
          // Filter Tabs
          _buildFilterTabs(),
          
          // Assignments List
          Expanded(
            child: _buildAssignmentsList(),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1), // أو index مناسب
    );
  }

  Widget _buildStatisticsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _databaseService.getAssignmentStatistics(),
      builder: (context, snapshot) {
        final statsData = snapshot.data ?? {};
        final stats = AssignmentStatistics(
          totalAssignments: statsData['totalAssignments'] ?? 0,
          activeAssignments: statsData['activeAssignments'] ?? 0,
          emergencyAssignments: statsData['emergencyAssignments'] ?? 0,
          unassignedBuses: statsData['unassignedBuses'] ?? 0,
          totalSupervisors: statsData['totalSupervisors'] ?? 0,
          availableSupervisors: statsData['availableSupervisors'] ?? 0,
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1E88E5), const Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withAlpha(51),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إحصائيات التعيينات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    Icons.analytics,
                    color: Colors.white.withAlpha(204),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatItem('النشطة', stats.activeAssignments.toString(), Icons.check_circle),
                  ),
                  Container(width: 1, height: 30, color: Colors.white.withAlpha(76)),
                  Expanded(
                    child: _buildCompactStatItem('الإجمالي', stats.totalAssignments.toString(), Icons.assignment),
                  ),
                  Container(width: 1, height: 30, color: Colors.white.withAlpha(76)),
                  Expanded(
                    child: _buildCompactStatItem('غير مُعينة', (stats.unassignedBuses < 0 ? 0 : stats.unassignedBuses).toString(), Icons.directions_bus),
                  ),
                  Container(width: 1, height: 30, color: Colors.white.withAlpha(76)),
                  Expanded(
                    child: _buildCompactStatItem('متاحين', stats.availableSupervisors.toString(), Icons.person_add),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(204),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withAlpha(204),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab('all', 'الكل', Icons.list),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab('active', 'النشطة', Icons.check_circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab('emergency', 'الطوارئ', Icons.emergency),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF1E88E5).withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return StreamBuilder<List<SupervisorAssignmentModel>>(
      stream: _getFilteredAssignments(),
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
                Text('خطأ في تحميل التعيينات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final assignments = snapshot.data ?? [];

        if (assignments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return _buildAssignmentCard(assignment);
          },
        );
      },
    );
  }

  Stream<List<SupervisorAssignmentModel>> _getFilteredAssignments() {
    switch (_selectedFilter) {
      case 'active':
        return _databaseService.getActiveSupervisorAssignments();
      case 'emergency':
        return _databaseService.getAllSupervisorAssignments()
            .map((assignments) => assignments.where((a) => a.isEmergency).toList());
      default:
        return _databaseService.getAllSupervisorAssignments();
    }
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'active':
        message = 'لا توجد تعيينات نشطة حالياً';
        icon = Icons.check_circle_outline;
        break;
      case 'emergency':
        message = 'لا توجد تعيينات طوارئ حالياً';
        icon = Icons.emergency_outlined;
        break;
      default:
        message = 'لا توجد تعيينات مشرفين حالياً';
        icon = Icons.assignment_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة تعيين جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(SupervisorAssignmentModel assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: assignment.isEmergencyAssignment
            ? Border.all(color: Colors.red, width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Modern Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                colors: assignment.isEmergencyAssignment
                    ? [Colors.red[400]!, Colors.red[600]!]
                    : [const Color(0xFF1E88E5), const Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    assignment.isEmergencyAssignment ? Icons.emergency : Icons.assignment_turned_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.isEmergencyAssignment ? 'تعيين طوارئ' : 'تعيين عادي',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تم في ${_formatDate(assignment.assignedAt)}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    assignment.status == 'active' ? 'نشط' : 'غير نشط',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Bus and Supervisor Info Row
                Row(
                  children: [
                    // Bus Info
                    Expanded(
                      child: _buildModernInfoCard(
                        title: 'معلومات الحافلة',
                        icon: Icons.directions_bus,
                        color: const Color(0xFF2196F3),
                        child: FutureBuilder<BusModel?>(
                          future: _databaseService.getBusById(assignment.busId),
                          builder: (context, snapshot) {
                            final bus = snapshot.data;
                            return Column(
                              children: [
                                _buildModernInfoRow(
                                  icon: Icons.directions_bus,
                                  label: 'نوع الباص',
                                  value: bus?.description ?? 'غير محدد',
                                ),
                                _buildModernInfoRow(
                                  icon: Icons.confirmation_number,
                                  label: 'رقم اللوحة',
                                  value: bus?.plateNumber ?? 'غير محدد',
                                ),
                                _buildModernInfoRow(
                                  icon: Icons.route,
                                  label: 'خط السير',
                                  value: _getBusRoute(assignment, bus),
                                ),
                                _buildModernInfoRow(
                                  icon: Icons.people,
                                  label: 'السعة',
                                  value: bus != null ? '${bus.capacity} راكب' : 'غير محدد',
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Supervisor Info
                    Expanded(
                      child: _buildModernInfoCard(
                        title: 'معلومات المشرف',
                        icon: Icons.supervisor_account,
                        color: const Color(0xFF4CAF50),
                        child: FutureBuilder<UserModel?>(
                          future: _databaseService.getUserById(assignment.supervisorId),
                          builder: (context, snapshot) {
                            final supervisor = snapshot.data;
                            return Column(
                              children: [
                                _buildModernInfoRow(
                                  icon: Icons.person,
                                  label: 'الاسم',
                                  value: supervisor?.name ?? 'غير محدد',
                                ),
                                _buildModernInfoRow(
                                  icon: Icons.phone,
                                  label: 'الهاتف',
                                  value: supervisor?.phone ?? 'غير محدد',
                                ),
                                _buildModernInfoRow(
                                  icon: Icons.email,
                                  label: 'الإيميل',
                                  value: supervisor?.email ?? 'غير محدد',
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Assignment Details
                _buildModernInfoCard(
                  title: 'تفاصيل التعيين',
                  icon: Icons.assignment,
                  color: const Color(0xFFFF9800),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernInfoRow(
                              icon: Icons.compare_arrows,
                              label: 'الاتجاه',
                              value: _getDirectionText(assignment.direction),
                            ),
                          ),
                          Expanded(
                            child: _buildModernInfoRow(
                              icon: Icons.calendar_today,
                              label: 'تاريخ التعيين',
                              value: _formatDate(assignment.assignedAt),
                            ),
                          ),
                        ],
                      ),
                      _buildModernInfoRow(
                        icon: Icons.admin_panel_settings,
                        label: 'تم التعيين بواسطة',
                        value: _getAssignedByName(assignment),
                      ),
                      if (assignment.notes?.isNotEmpty == true)
                        _buildModernInfoRow(
                          icon: Icons.note,
                          label: 'ملاحظات',
                          value: assignment.notes!,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        onPressed: () => _editAssignment(assignment),
                        icon: Icons.edit,
                        label: 'تعديل',
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        onPressed: () => _viewAssignmentDetails(assignment),
                        icon: Icons.visibility,
                        label: 'تفاصيل',
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        onPressed: () => _deleteAssignment(assignment),
                        icon: Icons.delete,
                        label: 'حذف',
                        color: const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isEmergency) {
    return isEmergency ? Colors.red : Colors.green;
  }

  IconData _getStatusIcon(bool isEmergency) {
    return isEmergency ? Icons.emergency : Icons.check_circle;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  String _getBusRoute(SupervisorAssignmentModel assignment, BusModel? bus) {
    // First try to get route from assignment
    if (assignment.busRoute.isNotEmpty && assignment.busRoute != 'غير محدد') {
      return assignment.busRoute;
    }

    // Then try to get route from bus
    if (bus?.route != null && bus!.route.isNotEmpty && bus.route != 'غير محدد') {
      return bus.route;
    }

    // Default fallback
    return 'غير محدد';
  }

  String _getAssignedByName(SupervisorAssignmentModel assignment) {
    // Check if assignedByName is available and not empty
    if (assignment.assignedByName != null &&
        assignment.assignedByName!.isNotEmpty &&
        assignment.assignedByName != 'غير محدد') {
      return assignment.assignedByName!;
    }

    // Fallback to a default admin name
    return 'الإدارة';
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: Colors.blue[700]),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Value text - full width, no truncation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    );
  }

  void _editAssignment(SupervisorAssignmentModel assignment) {
    _showEditAssignmentDialog(assignment);
  }

  void _deleteAssignment(SupervisorAssignmentModel assignment) {
    _showDeleteConfirmationDialog(assignment);
  }

  void _viewAssignmentDetails(SupervisorAssignmentModel assignment) {
    _showAssignmentDetailsDialog(assignment);
  }

  void _showCreateAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateAssignmentDialog(
        databaseService: _databaseService,
        currentUser: _currentUser,
      ),
    );
  }

  void _showEditRouteDialog(SupervisorAssignmentModel assignment, BusModel? bus) {
    final TextEditingController routeController = TextEditingController(
      text: _getBusRoute(assignment, bus),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.route, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text('تعديل خط السير'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تعديل خط السير للباص ${assignment.busPlateNumber}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: routeController,
              decoration: const InputDecoration(
                labelText: 'خط السير الجديد',
                border: OutlineInputBorder(),
                hintText: 'مثال: الحي الأول - المدرسة - الحي الثاني',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRoute = routeController.text.trim();
              if (newRoute.isNotEmpty) {
                try {
                  // Update bus route
                  await _databaseService.updateBusRoute(assignment.busId, newRoute);

                  // Update assignment route
                  await _databaseService.updateAssignmentRoute(assignment.id, newRoute);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث خط السير بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {}); // Refresh the UI
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في تحديث خط السير: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyChangeDialog(SupervisorAssignmentModel assignment) {
    // Implementation for emergency supervisor change
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير مشرف الطوارئ'),
        content: const Text('سيتم تطوير هذه الميزة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateAssignment(SupervisorAssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إنهاء التعيين'),
        content: Text('هل أنت متأكد من إنهاء تعيين ${assignment.supervisorName} على باص ${assignment.busPlateNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إنهاء التعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deactivateSupervisorAssignment(assignment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنهاء التعيين بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إنهاء التعيين: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getDirectionText(TripDirection direction) {
    switch (direction) {
      case TripDirection.toSchool:
        return 'الذهاب';
      case TripDirection.fromSchool:
        return 'العودة';
      case TripDirection.both:
        return 'الذهاب والعودة';
    }
  }

  void _showEditAssignmentDialog(SupervisorAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => _EditAssignmentDialog(
        assignment: assignment,
        databaseService: _databaseService,
        onAssignmentUpdated: () {
          setState(() {}); // Refresh the list
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(SupervisorAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف تعيين ${assignment.supervisorName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseService.deleteSupervisorAssignment(assignment.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف التعيين بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف التعيين: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetailsDialog(SupervisorAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'تفاصيل التعيين',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('المشرف', assignment.supervisorName),
              _buildDetailRow('الباص', assignment.busPlateNumber),
              FutureBuilder<BusModel?>(
                future: _databaseService.getBusById(assignment.busId),
                builder: (context, snapshot) {
                  final bus = snapshot.data;
                  return _buildDetailRowWithEdit(
                    'خط السير',
                    _getBusRoute(assignment, bus),
                    onEdit: () => _showEditRouteDialog(assignment, bus),
                  );
                },
              ),
              _buildDetailRow('الاتجاه', _getDirectionText(assignment.direction)),
              _buildDetailRow('تاريخ التعيين', _formatDate(assignment.assignedAt)),
              _buildDetailRow('تم التعيين بواسطة', _getAssignedByName(assignment)),
              if (assignment.notes?.isNotEmpty == true)
                _buildDetailRow('ملاحظات', assignment.notes!),
              _buildDetailRow('نوع التعيين', assignment.isEmergencyAssignment ? 'طوارئ' : 'عادي'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithEdit(String label, String value, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit,
                size: 18,
                color: Color(0xFF1E88E5),
              ),
              tooltip: 'تعديل $label',
            ),
        ],
      ),
    );
  }
}

class _CreateAssignmentDialog extends StatefulWidget {
  final DatabaseService databaseService;
  final UserModel? currentUser;

  const _CreateAssignmentDialog({
    required this.databaseService,
    this.currentUser,
  });

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  String? _selectedSupervisorId;
  String? _selectedBusId;
  TripDirection _selectedDirection = TripDirection.both;
  String _notes = '';
  bool _isLoading = false;

  List<UserModel> _supervisors = [];
  List<BusModel> _buses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load supervisors
      _supervisors = await widget.databaseService.getAllSupervisors();

      // Load buses
      _buses = await widget.databaseService.getAllBuses().first;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.assignment_add, color: Color(0xFF1E88E5)),
          SizedBox(width: 8),
          Text('إضافة تعيين جديد'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Supervisor selection with add button
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSupervisorId,
                          decoration: const InputDecoration(
                            labelText: 'اختر المشرف',
                            border: OutlineInputBorder(),
                          ),
                          items: _supervisors.map((supervisor) {
                            return DropdownMenuItem(
                              value: supervisor.id,
                              child: Text(supervisor.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSupervisorId = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showAddSupervisorDialog(),
                        icon: const Icon(Icons.person_add),
                        tooltip: 'إضافة مشرف جديد',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[50],
                          foregroundColor: Colors.green[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bus selection
                  DropdownButtonFormField<String>(
                    value: _selectedBusId,
                    decoration: const InputDecoration(
                      labelText: 'اختر الباص',
                      border: OutlineInputBorder(),
                    ),
                    items: _buses.map((bus) {
                      return DropdownMenuItem(
                        value: bus.id,
                        child: Text('${bus.plateNumber} - ${bus.route}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedBusId = value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Direction selection
                  DropdownButtonFormField<TripDirection>(
                    value: _selectedDirection,
                    decoration: const InputDecoration(
                      labelText: 'اتجاه الرحلة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TripDirection.toSchool,
                        child: Text('الذهاب للمدرسة'),
                      ),
                      DropdownMenuItem(
                        value: TripDirection.fromSchool,
                        child: Text('العودة من المدرسة'),
                      ),
                      DropdownMenuItem(
                        value: TripDirection.both,
                        child: Text('كلا الاتجاهين'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedDirection = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => _notes = value,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _canSubmit() ? _createAssignment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
          child: const Text('إنشاء التعيين'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedSupervisorId != null &&
           _selectedBusId != null &&
           !_isLoading;
  }

  Future<void> _createAssignment() async {
    if (!_canSubmit()) return;

    try {
      setState(() => _isLoading = true);

      final supervisor = _supervisors.firstWhere((s) => s.id == _selectedSupervisorId);
      final bus = _buses.firstWhere((b) => b.id == _selectedBusId);

      final assignmentId = widget.databaseService.generateTripId();
      final assignment = SupervisorAssignmentModel(
        id: assignmentId,
        supervisorId: _selectedSupervisorId!,
        supervisorName: supervisor.name,
        busId: _selectedBusId!,
        busPlateNumber: bus.plateNumber,
        busRoute: bus.route,
        direction: _selectedDirection,
        assignedAt: DateTime.now(),
        assignedBy: widget.currentUser?.id ?? '',
        assignedByName: widget.currentUser?.name ?? 'مدير',
        notes: _notes.isNotEmpty ? _notes : null,
      );

      await widget.databaseService.createSupervisorAssignment(assignment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء التعيين بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التعيين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddSupervisorDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddSupervisorDialog(
        databaseService: widget.databaseService,
        onSupervisorAdded: () {
          _loadData(); // Reload supervisors list
        },
      ),
    );
  }
}

// Edit Assignment Dialog
class _EditAssignmentDialog extends StatefulWidget {
  final SupervisorAssignmentModel assignment;
  final DatabaseService databaseService;
  final VoidCallback onAssignmentUpdated;

  const _EditAssignmentDialog({
    required this.assignment,
    required this.databaseService,
    required this.onAssignmentUpdated,
  });

  @override
  State<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<_EditAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  TripDirection? _selectedDirection;
  bool _isEmergency = false;
  bool _isLoading = false;
  String? _selectedBusId;
  List<BusModel> _availableBuses = [];
  BusModel? _currentBus;

  @override
  void initState() {
    super.initState();
    _selectedDirection = widget.assignment.direction;
    _isEmergency = widget.assignment.isEmergencyAssignment;
    _notesController.text = widget.assignment.notes ?? '';
    _selectedBusId = widget.assignment.busId;
    _loadAvailableBuses();
    _loadCurrentBus();
  }

  Future<void> _loadAvailableBuses() async {
    try {
      final buses = await widget.databaseService.getAllBuses().first;
      setState(() {
        _availableBuses = buses;
      });
    } catch (e) {
      debugPrint('Error loading buses: $e');
    }
  }

  Future<void> _loadCurrentBus() async {
    try {
      final bus = await widget.databaseService.getBusById(widget.assignment.busId);
      setState(() {
        _currentBus = bus;
      });
    } catch (e) {
      debugPrint('Error loading current bus: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل التعيين'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Assignment Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات التعيين',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('المشرف: ${widget.assignment.supervisorName}'),
                    Text('الحافلة الحالية: ${_currentBus?.plateNumber ?? 'جاري التحميل...'} (${_currentBus?.description ?? ''})',),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bus Selection
              DropdownButtonFormField<String>(
                value: _selectedBusId,
                decoration: const InputDecoration(
                  labelText: 'اختيار الحافلة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_bus),
                ),
                items: _availableBuses.map((bus) {
                  return DropdownMenuItem(
                    value: bus.id,
                    child: Text('${bus.plateNumber} - ${bus.description}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى اختيار الحافلة';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Direction Selection
              DropdownButtonFormField<TripDirection>(
                value: _selectedDirection,
                decoration: const InputDecoration(
                  labelText: 'الاتجاه',
                  border: OutlineInputBorder(),
                ),
                items: TripDirection.values.map((direction) {
                  return DropdownMenuItem(
                    value: direction,
                    child: Text(_getDirectionText(direction)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDirection = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'يرجى اختيار الاتجاه';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Emergency Assignment
              CheckboxListTile(
                title: const Text('تعيين طوارئ'),
                subtitle: const Text('هل هذا تعيين طوارئ؟'),
                value: _isEmergency,
                onChanged: (value) {
                  setState(() {
                    _isEmergency = value ?? false;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateAssignment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ التعديلات'),
        ),
      ],
    );
  }

  String _getDirectionText(TripDirection direction) {
    switch (direction) {
      case TripDirection.toSchool:
        return 'الذهاب للمدرسة';
      case TripDirection.fromSchool:
        return 'العودة من المدرسة';
      case TripDirection.both:
        return 'الذهاب والعودة';
    }
  }

  Future<void> _updateAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the selected bus details
      final selectedBus = _availableBuses.firstWhere((bus) => bus.id == _selectedBusId);

      final updatedAssignment = widget.assignment.copyWith(
        busId: _selectedBusId!,
        busPlateNumber: selectedBus.plateNumber,
        busRoute: selectedBus.route,
        direction: _selectedDirection!,
        isEmergencyAssignment: _isEmergency,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // تحديث التعيين
      await widget.databaseService.updateSupervisorAssignment(updatedAssignment);

      // تحديث معرف المشرف في الباص إذا تم تغيير الباص
      if (_selectedBusId != widget.assignment.busId) {
        await widget.databaseService.updateBusSupervisor(
          _selectedBusId!,
          widget.assignment.supervisorId,
        );

        // إزالة المشرف من الباص القديم إذا لم يعد مُعيّن له
        final oldBusAssignments = await widget.databaseService
            .getSupervisorAssignmentsByBusId(widget.assignment.busId);
        if (oldBusAssignments.where((a) => a.id != widget.assignment.id).isEmpty) {
          await widget.databaseService.updateBusSupervisor(
            widget.assignment.busId,
            null, // إزالة المشرف
          );
        }
      }

      debugPrint('✅ Assignment updated successfully: ${updatedAssignment.id}');

      if (mounted) {
        Navigator.pop(context);
        widget.onAssignmentUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث التعيين بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث التعيين: $e'),
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

  void _showAddSupervisorDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddSupervisorDialog(
        databaseService: widget.databaseService,
        onSupervisorAdded: () {
          _loadAvailableBuses(); // Reload buses list
        },
      ),
    );
  }
}

// Add Supervisor Dialog
class _AddSupervisorDialog extends StatefulWidget {
  final DatabaseService databaseService;
  final VoidCallback onSupervisorAdded;

  const _AddSupervisorDialog({
    required this.databaseService,
    required this.onSupervisorAdded,
  });

  @override
  State<_AddSupervisorDialog> createState() => _AddSupervisorDialogState();
}

class _AddSupervisorDialogState extends State<_AddSupervisorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Color(0xFF4CAF50)),
          SizedBox(width: 8),
          Text('إضافة مشرف جديد'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المشرف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم المشرف';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@')) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addSupervisor,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إضافة المشرف'),
        ),
      ],
    );
  }

  Future<void> _addSupervisor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create supervisor user
      await widget.databaseService.createSupervisor(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSupervisorAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المشرف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المشرف: $e'),
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
