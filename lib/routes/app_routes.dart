import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/parent/parent_home_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/supervisor/supervisor_home_screen.dart';
import '../screens/test_responsive_screen.dart';
import '../screens/test_notifications_screen.dart';

import '../screens/common/notifications_screen.dart' as common_notifications;
import '../screens/common/error_screen.dart';
import '../screens/parent/student_activity_screen.dart';
import '../screens/parent/student_location_screen.dart';
import '../screens/parent/bus_info_screen.dart';
import '../screens/parent/complaints_screen.dart';
import '../screens/parent/add_complaint_screen.dart';
import '../screens/parent/notifications_screen.dart';
import '../screens/parent/parent_profile_screen.dart';
import '../screens/parent/report_absence_screen.dart';
import '../screens/parent/supervisor_info_screen.dart';
import '../screens/parent/add_student_screen.dart' as ParentAddStudent;
import '../screens/parent/surveys_screen.dart';
import '../screens/parent/take_survey_screen.dart';
import '../screens/parent/supervisor_evaluation_screen.dart';
import '../screens/parent/parent_settings_screen.dart';
import '../screens/parent/trip_history_screen.dart';
import '../screens/parent/evaluate_supervisor_screen.dart';
import '../screens/parent/complete_profile_screen.dart';
import '../screens/supervisor/qr_scanner_screen.dart';
import '../screens/supervisor/students_list_screen.dart';
import '../screens/supervisor/supervisor_profile_screen.dart';
import '../screens/supervisor/emergency_contact_screen.dart';
import '../screens/supervisor/route_statistics_screen.dart';
import '../screens/admin/student_management_screen.dart';
import '../screens/admin/add_student_screen.dart' as AdminAddStudent;
import '../screens/admin/edit_student_screen.dart';
import '../screens/admin/all_students_screen.dart';
import '../screens/admin/buses_management_screen.dart';
import '../screens/admin/supervisors_management_screen.dart';
import '../screens/admin/parents_management_screen.dart';
import '../screens/admin/complaints_management_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/system_settings_screen.dart';
import '../screens/admin/admin_notifications_screen.dart';
import '../screens/admin/surveys_reports_screen.dart';
import '../screens/admin/absence_management_screen.dart';
import '../screens/admin/supervisor_assignments_screen.dart';
import '../screens/admin/parent_student_linking_screen.dart';
import '../screens/admin/parent_student_links_view_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/notification_test_screen.dart';
import '../utils/app_constants.dart';
import '../models/student_model.dart';

class AppRoutes {
  // مفتاح التنقل الرئيسي
  static GlobalKey<NavigatorState>? _navigatorKey;

  // دالة للحصول على مفتاح التنقل
  static GlobalKey<NavigatorState> _getNavigatorKey() {
    _navigatorKey ??= GlobalKey<NavigatorState>();
    return _navigatorKey!;
  }

  // دالة للحصول على مفتاح التنقل من الخارج
  static GlobalKey<NavigatorState> get navigatorKey => _getNavigatorKey();

  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Parent Routes
  static const String parentHome = '/parent';
  static const String parentProfile = '/parent/profile';
  static const String parentCompleteProfile = '/parent/complete-profile';
  static const String parentNotifications = '/parent/notifications';
  static const String studentActivity = '/parent/student-activity';
  static const String busInfo = '/parent/bus-info';
  static const String complaints = '/parent/complaints';
  static const String addComplaint = '/parent/complaints/add';
  static const String reportAbsence = '/parent/report-absence';
  static const String supervisorInfo = '/parent/supervisor-info';
  
  // Supervisor Routes
  static const String supervisorHome = '/supervisor';
  static const String supervisorProfile = '/supervisor/profile';
  static const String qrScanner = '/supervisor/qr-scanner';
  static const String studentsList = '/supervisor/students-list';
  
  // Admin Routes
  static const String adminHome = '/admin';
  static const String studentManagement = '/admin/students';
  static const String addStudent = '/admin/students/add';
  static const String editStudent = '/admin/students/edit';
  static const String allStudents = '/admin/students/all';
  static const String busesManagement = '/admin/buses';
  static const String supervisorsManagement = '/admin/supervisors';
  static const String parentsManagement = '/admin/parents';
  static const String complaintsManagement = '/admin/complaints';
  static const String reports = '/admin/reports';
  static const String systemSettings = '/admin/settings';
  static const String adminNotifications = '/admin/notifications';
  static const String surveysReports = '/admin/surveys-reports';
  static const String absenceManagement = '/admin/absence-management';
  static const String busesManagementRoute = '/admin/buses-management';
  static const String supervisorAssignments = '/admin/supervisor-assignments';
  static const String parentStudentLinking = '/admin/parent-student-linking';

  // Test Routes
  static const String testResponsive = '/test/responsive';
  static const String testNotifications = '/test/notifications';
  static const String testNotificationSystem = '/test/notification-system';


  // Common Routes
  static const String notifications = '/notifications';

  // Router Configuration
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    navigatorKey: _getNavigatorKey(),
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Parent Routes
      GoRoute(
        path: parentHome,
        name: 'parent-home',
        builder: (context, state) => const ParentHomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: 'parent-profile',
            builder: (context, state) => const ParentProfileScreen(),
          ),
          GoRoute(
            path: 'complete-profile',
            name: 'parent-complete-profile',
            builder: (context, state) {
              final isEditing = state.uri.queryParameters['edit'] == 'true';
              return CompleteProfileScreen(isEditing: isEditing);
            },
          ),
          GoRoute(
            path: 'notifications',
            name: 'parent-notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'student-activity/:studentId',
            name: 'student-activity',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId']!;
              return StudentActivityScreen(studentId: studentId);
            },
            routes: [
              GoRoute(
                path: 'location',
                name: 'student-location',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId']!;
                  return StudentLocationScreen(studentId: studentId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'bus-info/:studentId',
            name: 'bus-info',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId']!;
              return BusInfoScreen(studentId: studentId);
            },
          ),
          GoRoute(
            path: 'complaints',
            name: 'complaints',
            builder: (context, state) => const ComplaintsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-complaint',
                builder: (context, state) => const AddComplaintScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'report-absence/:studentId',
            name: 'report-absence',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId']!;
              // For now, we'll create a dummy student. In real app, fetch from database
              final student = StudentModel(
                id: studentId,
                name: 'طالب',
                parentId: '',
                parentName: 'ولي الأمر',
                parentPhone: '1234567890',
                parentEmail: 'parent@example.com',
                qrCode: '',
                schoolName: 'المدرسة',
                grade: 'الصف الأول',
                busRoute: 'الطريق الأول',
                busId: '',
                address: 'العنوان',
                notes: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isActive: true,
              );
              return ReportAbsenceScreen(student: student);
            },
          ),
          GoRoute(
            path: 'supervisor-info',
            name: 'supervisor-info',
            builder: (context, state) => const SupervisorInfoScreen(),
          ),
          GoRoute(
            path: 'add-student',
            name: 'parent-add-student',
            builder: (context, state) => const ParentAddStudent.AddStudentScreen(),
          ),
          GoRoute(
            path: 'surveys',
            name: 'parent-surveys',
            builder: (context, state) => const SurveysScreen(),
            routes: [
              GoRoute(
                path: 'take/:surveyId',
                name: 'take-survey',
                builder: (context, state) {
                  final surveyId = state.pathParameters['surveyId']!;
                  return TakeSurveyScreen(surveyId: surveyId);
                },
              ),
              GoRoute(
                path: 'supervisor-evaluation',
                name: 'supervisor-evaluation',
                builder: (context, state) => const SupervisorEvaluationScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            name: 'parent-settings',
            builder: (context, state) => const ParentSettingsScreen(),
          ),
          GoRoute(
            path: 'trip-history',
            name: 'trip-history',
            builder: (context, state) => const TripHistoryScreen(),
          ),
        ],
      ),
      
      // Supervisor Routes
      GoRoute(
        path: supervisorHome,
        name: 'supervisor-home',
        builder: (context, state) => const SupervisorHomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: 'supervisor-profile',
            builder: (context, state) => const SupervisorProfileScreen(),
          ),
          GoRoute(
            path: 'qr-scanner',
            name: 'qr-scanner',
            builder: (context, state) => const QRScannerScreen(),
          ),
          GoRoute(
            path: 'students-list',
            name: 'students-list',
            builder: (context, state) => const StudentsListScreen(),
          ),
          GoRoute(
            path: 'emergency-contact',
            name: 'supervisor-emergency-contact',
            builder: (context, state) => const EmergencyContactScreen(),
          ),
          GoRoute(
            path: 'route-statistics',
            name: 'supervisor-route-statistics',
            builder: (context, state) => const RouteStatisticsScreen(),
          ),
        ],
      ),
      
      // Admin Routes
      GoRoute(
        path: adminHome,
        name: 'admin-home',
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'students',
            name: 'student-management',
            builder: (context, state) => const StudentManagementScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-student',
                builder: (context, state) => const AdminAddStudent.AddStudentScreen(),
              ),
              GoRoute(
                path: 'edit/:studentId',
                name: 'edit-student',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId']!;
                  return EditStudentScreen(studentId: studentId);
                },
              ),
              GoRoute(
                path: 'all',
                name: 'all-students',
                builder: (context, state) => const AllStudentsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'buses',
            name: 'buses-management',
            builder: (context, state) => const BusesManagementScreen(),
          ),
          GoRoute(
            path: 'supervisors',
            name: 'supervisors-management',
            builder: (context, state) => const SupervisorsManagementScreen(),
          ),
          GoRoute(
            path: 'parents',
            name: 'parents-management',
            builder: (context, state) => const ParentsManagementScreen(),
          ),
          GoRoute(
            path: 'complaints',
            name: 'complaints-management',
            builder: (context, state) => const ComplaintsManagementScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'system-settings',
            builder: (context, state) => const SystemSettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'admin-notifications',
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: 'surveys-reports',
            name: 'surveys-reports',
            builder: (context, state) => const SurveysReportsScreen(),
          ),
          GoRoute(
            path: 'absence-management',
            name: 'absence-management',
            builder: (context, state) => const AbsenceManagementScreen(),
          ),
          GoRoute(
            path: 'buses-management',
            name: 'buses-management-route',
            builder: (context, state) => const BusesManagementScreen(),
          ),
          GoRoute(
            path: 'supervisor-assignments',
            name: 'supervisor-assignments',
            builder: (context, state) => const SupervisorAssignmentsScreen(),
          ),
          GoRoute(
            path: 'parent-student-linking',
            name: 'parent-student-linking',
            builder: (context, state) => const ParentStudentLinkingScreen(),
          ),
          GoRoute(
            path: 'parent-student-links-view',
            name: 'parent-student-links-view',
            builder: (context, state) => const ParentStudentLinksViewScreen(),
          ),
          GoRoute(
            path: 'profile',
            name: 'admin-profile',
            builder: (context, state) => const AdminProfileScreen(),
          ),
          GoRoute(
            path: 'notification-test',
            name: 'notification-test',
            builder: (context, state) => const NotificationTestScreen(),
          ),
        ],
      ),
      // Test Routes
      GoRoute(
        path: testResponsive,
        name: 'test-responsive',
        builder: (context, state) => const TestResponsiveScreen(),
      ),
      GoRoute(
        path: testNotifications,
        name: 'test-notifications',
        builder: (context, state) => const TestNotificationsScreen(),
      ),



      // Common Routes
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const common_notifications.NotificationsScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => const ErrorScreen(),
  );
}
