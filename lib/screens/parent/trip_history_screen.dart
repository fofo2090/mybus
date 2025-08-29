import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/trip_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  List<StudentModel> _students = [];
  List<TripModel> _trips = [];
  StudentModel? _selectedStudent;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final students = await _databaseService.getStudentsByParent(currentUser.uid).first;
        setState(() {
          _students = students;
          if (students.isNotEmpty) {
            _selectedStudent = students.first;
            _loadTrips();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _loadTrips() async {
    if (_selectedStudent == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      final trips = await _databaseService.getStudentTrips(
        _selectedStudent!.id,
        _selectedDate,
      );
      
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الرحلات: $e')),
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
          'سجل الرحلات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildHeader(),
                    _buildFilters(),
                    Expanded(child: _buildTripsList()),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد طلاب مسجلين',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى إضافة طالب أولاً لعرض سجل الرحلات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل الرحلات التفصيلي',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تتبع جميع رحلات أطفالك',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الفلاتر',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          
          // Student Selection
          if (_students.length > 1) ...[
            const Text(
              'الطالب',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StudentModel>(
                  value: _selectedStudent,
                  isExpanded: true,
                  items: _students.map((student) {
                    return DropdownMenuItem(
                      value: student,
                      child: Text(student.name),
                    );
                  }).toList(),
                  onChanged: (student) {
                    setState(() {
                      _selectedStudent = student;
                    });
                    _loadTrips();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Date Selection
          const Text(
            'التاريخ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
                _loadTrips();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('yyyy/MM/dd').format(_selectedDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    if (_trips.isEmpty) {
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
              'لا توجد رحلات في هذا التاريخ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تاريخاً آخر',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return _buildTripCard(trip);
      },
    );
  }

  Widget _buildTripCard(TripModel trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: _getTripTypeColor(trip.tripType).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTripTypeIcon(trip.tripType),
                  color: _getTripTypeColor(trip.tripType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTripTypeText(trip.tripType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      _getDisplayTime(trip),
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
                  color: _getActionColor(trip.action).withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getActionText(trip.action),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getActionColor(trip.action),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // خط السير بتصميم مميز
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withAlpha(76)),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'خط السير: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Expanded(
                  child: Text(
                    trip.busRoute.isNotEmpty ? trip.busRoute : 'غير محدد',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (trip.supervisorName.isNotEmpty)
            _buildInfoRow(Icons.person, 'المشرف', trip.supervisorName),
          if (trip.notes != null && trip.notes!.isNotEmpty)
            _buildInfoRow(Icons.note, 'ملاحظات', trip.notes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  IconData _getTripTypeIcon(TripType type) {
    switch (type) {
      case TripType.toSchool:
        return Icons.school;
      case TripType.fromSchool:
        return Icons.home;
      default:
        return Icons.directions_bus;
    }
  }

  Color _getTripTypeColor(TripType type) {
    switch (type) {
      case TripType.toSchool:
        return Colors.blue;
      case TripType.fromSchool:
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getTripTypeText(TripType type) {
    switch (type) {
      case TripType.toSchool:
        return 'رحلة الذهاب للمدرسة';
      case TripType.fromSchool:
        return 'رحلة العودة للمنزل';
      default:
        return 'رحلة';
    }
  }

  Color _getActionColor(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
      case TripAction.boardBus:
        return Colors.orange;
      case TripAction.arriveAtSchool:
        return Colors.blue;
      case TripAction.boardBusToHome:
        return Colors.purple;
      case TripAction.arriveAtHome:
      case TripAction.leaveBus:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getActionText(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
      case TripAction.boardBus:
        return 'ركب الباص';
      case TripAction.arriveAtSchool:
        return 'وصل المدرسة';
      case TripAction.boardBusToHome:
        return 'ركب للعودة';
      case TripAction.arriveAtHome:
      case TripAction.leaveBus:
        return 'وصل المنزل';
      default:
        return 'غير محدد';
    }
  }

  String _getDisplayTime(TripModel trip) {
    // عرض الوقت مع تسمية مناسبة بناءً على نوع الحدث
    final timeString = DateFormat('HH:mm').format(trip.timestamp);
    
    switch (trip.action) {
      case TripAction.boardBusToSchool:
      case TripAction.boardBus:
        return 'وقت الركوب: $timeString';
      case TripAction.arriveAtSchool:
        return 'وقت الوصول للمدرسة: $timeString';
      case TripAction.boardBusToHome:
        return 'وقت ركوب العودة: $timeString';
      case TripAction.arriveAtHome:
      case TripAction.leaveBus:
        return 'وقت الوصول للمنزل: $timeString';
      default:
        return 'الوقت: $timeString';
    }
  }
}
