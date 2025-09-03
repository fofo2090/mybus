import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/trip_model.dart';
import '../models/bus_model.dart';
import '../models/complaint_model.dart';
import '../models/parent_profile_model.dart';
import '../models/absence_model.dart';
import '../models/user_model.dart';
import '../models/survey_model.dart';
import '../models/supervisor_assignment_model.dart';
import '../models/student_behavior_model.dart';
import '../models/notification_model.dart';
import '../models/supervisor_evaluation_model.dart';
import '../models/parent_student_link_model.dart';
import 'rate_limit_service.dart';
import 'cache_service.dart';
import 'notification_service.dart';
import 'enhanced_notification_service.dart';


class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  final RateLimitService _rateLimitService = RateLimitService();
  final CacheService _cacheService = CacheService();

  // Getter للوصول إلى Firestore من خارج الكلاس
  FirebaseFirestore get firestore => _firestore;

  // Initialize Firestore settings for better performance
  DatabaseService() {
    _initializeFirestore();
  }

  void _initializeFirestore() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('✅ Firestore settings initialized for better performance');
    } catch (e) {
      debugPrint('⚠️ Could not set Firestore settings: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check rate limit and record request
  Future<bool> _checkAndRecordRateLimit(String userId, String operation) async {
    final canMakeRequest = await _rateLimitService.canMakeRequest(userId, operation);
    if (canMakeRequest) {
      _rateLimitService.recordRequest(userId, operation);
    }
    return canMakeRequest;
  }

  /// Get current user ID safely
  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  }

  /// Get cache statistics (delegated to cache service)
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }

  /// Get rate limit status (delegated to rate limit service)
  Map<String, dynamic> getRateLimitStatus(String userId, String operation) {
    return _rateLimitService.getRateLimitStatus(userId, operation).toMap();
  }

  /// Clear all caches
  Future<void> clearCache() async {
    await _cacheService.clear();
  }

  // User Data Methods
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      // Check rate limit
      if (!await _checkAndRecordRateLimit(userId, 'getUserData')) {
        throw Exception('تم تجاوز الحد المسموح من الطلبات. يرجى المحاولة لاحقاً.');
      }

      // Check cache first
      final cacheKey = 'user_data_$userId';
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>?;

        // Store in cache with high priority for user data
        if (userData != null) {
          await _cacheService.set(
            cacheKey,
            userData,
            priority: CachePriority.high,
          );
        }

        return userData;
      }
      return null;
    } catch (e) {
      throw Exception('فشل في الحصول على بيانات المستخدم: $e');
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      // Check rate limit
      if (!await _checkAndRecordRateLimit(userId, 'updateUserData')) {
        throw Exception('تم تجاوز الحد المسموح من الطلبات. يرجى المحاولة لاحقاً.');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache for this user
      final cacheKey = 'user_data_$userId';
      await _cacheService.remove(cacheKey);
      debugPrint('🗑️ Invalidated cache for user: $userId');

    } catch (e) {
      throw Exception('فشل في تحديث بيانات المستخدم: $e');
    }
  }

  // Parent-Student Relationship Methods

  /// Add a child to parent using a simpler approach
  Future<void> addChildToParent(String parentId, Map<String, dynamic> childData) async {
    try {
      debugPrint('➕ Adding child to parent: $parentId');

      // Create a clean child data object
      final cleanChildData = Map<String, dynamic>.from(childData);
      cleanChildData['addedAt'] = DateTime.now().toIso8601String();
      cleanChildData['updatedAt'] = DateTime.now().toIso8601String();

      // Get current parent data
      final parentDoc = await _firestore.collection('users').doc(parentId).get();

      if (parentDoc.exists) {
        final parentData = parentDoc.data() as Map<String, dynamic>;
        final List<dynamic> currentChildren = List.from(parentData['children'] ?? []);

        // Add new child to the list
        currentChildren.add(cleanChildData);

        // Update parent document
        await _firestore.collection('users').doc(parentId).update({
          'children': currentChildren,
          'childrenCount': currentChildren.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Child added to parent children list successfully');
      } else {
        // Create new parent document with first child
        await _firestore.collection('users').doc(parentId).set({
          'children': [cleanChildData],
          'childrenCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Created new parent document with first child');
      }
    } catch (e) {
      debugPrint('❌ Failed to add child to parent: $e');
      throw Exception('فشل في إضافة الطفل لقائمة ولي الأمر: $e');
    }
  }

  /// Get parent's children from users collection
  Future<List<Map<String, dynamic>>> getParentChildren(String parentId) async {
    try {
      final parentDoc = await _firestore.collection('users').doc(parentId).get();

      if (parentDoc.exists) {
        final parentData = parentDoc.data() as Map<String, dynamic>;
        final List<dynamic> children = parentData['children'] ?? [];

        return children.map((child) => child as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      throw Exception('فشل في جلب أطفال ولي الأمر: $e');
    }
  }

  /// Alternative approach: Create a separate parent-child relationship document
  Future<void> syncStudentWithParent(String parentId, StudentModel student) async {
    try {
      debugPrint('🔄 Creating parent-child relationship for ${student.name}');

      // Instead of using arrays, create a separate document for the relationship
      final relationshipId = '${parentId}_${student.id}';

      await _firestore.collection('parent_children').doc(relationshipId).set({
        'parentId': parentId,
        'studentId': student.id,
        'studentName': student.name,
        'studentGrade': student.grade,
        'studentSchool': student.schoolName,
        'studentRoute': student.busRoute,
        'studentPhoto': student.photoUrl,
        'studentQR': student.qrCode,
        'studentStatus': student.currentStatus.toString().split('.').last,
        'isActive': student.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update parent's simple counter
      await _firestore.collection('users').doc(parentId).update({
        'hasChildren': true,
        'lastChildAdded': student.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Parent-child relationship created successfully');
    } catch (e) {
      debugPrint('❌ Failed to create parent-child relationship: $e');
      throw Exception('فشل في ربط الطالب بولي الأمر: $e');
    }
  }

  /// Get parent's children using the relationship collection
  Future<List<Map<String, dynamic>>> getParentChildrenFromRelationships(String parentId) async {
    try {
      final snapshot = await _firestore
          .collection('parent_children')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['studentId'],
          'name': data['studentName'],
          'grade': data['studentGrade'],
          'schoolName': data['studentSchool'],
          'busRoute': data['studentRoute'],
          'photoUrl': data['studentPhoto'],
          'qrCode': data['studentQR'],
          'currentStatus': data['studentStatus'],
          'isActive': data['isActive'],
          'relationshipId': doc.id,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get parent children from relationships: $e');
      return [];
    }
  }

  // Students Collection Methods

  // Add new student with enhanced parent relationship
  Future<String> addStudent(StudentModel student) async {
    try {
      // Generate ID if not provided
      final studentId = student.id.isEmpty ? _uuid.v4() : student.id;

      // Generate QR code if not provided
      final qrCode = student.qrCode.isEmpty ? await generateQRCode() : student.qrCode;

      // Create student with generated values
      final studentWithId = student.copyWith(
        id: studentId,
        qrCode: qrCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to students collection
      await _firestore
          .collection('students')
          .doc(studentId)
          .set(studentWithId.toMap());

      // Sync with parent's children list (with fallback)
      try {
        await syncStudentWithParent(student.parentId, studentWithId);
      } catch (syncError) {
        debugPrint('⚠️ Failed to sync with parent, but student was created: $syncError');
        // Continue anyway - student is created, sync can be done later
      }

      debugPrint('✅ Student added successfully: ${student.name} with QR: $qrCode');
      return studentId;
    } catch (e) {
      throw Exception('خطأ في إضافة الطالب: $e');
    }
  }

  // Get student by ID
  Future<StudentModel?> getStudent(String studentId) async {
    try {
      // Check rate limit
      final currentUserId = _getCurrentUserId();
      if (!await _checkAndRecordRateLimit(currentUserId, 'getStudent')) {
        throw Exception('تم تجاوز الحد المسموح من الطلبات. يرجى المحاولة لاحقاً.');
      }

      // Check cache first
      final cacheKey = 'student_$studentId';
      final cachedStudent = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedStudent != null) {
        return StudentModel.fromMap(cachedStudent);
      }

      final doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        final studentData = doc.data()!;

        // Store in cache with normal priority
        await _cacheService.set(
          cacheKey,
          studentData,
          priority: CachePriority.normal,
        );

        return StudentModel.fromMap(studentData);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات الطالب: $e');
    }
  }

  // Get student by QR code
  Future<StudentModel?> getStudentByQRCode(String qrCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('qrCode', isEqualTo: qrCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return StudentModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في البحث عن الطالب: $e');
    }
  }

  // Get students by parent ID
  Stream<List<StudentModel>> getStudentsByParent(String parentId) {
    return _firestore
        .collection('students')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Get all students (for admin)
  Stream<List<StudentModel>> getAllStudents() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Get all active students (Future version for better error handling)
  Future<List<StudentModel>> getAllActiveStudents() async {
    try {
      debugPrint('🔍 Getting all active students...');

      final snapshot = await _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint('📊 Found ${snapshot.docs.length} active students in database');

      final students = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return StudentModel.fromMap(data);
          })
          .toList();

      // Sort manually by name
      students.sort((a, b) => a.name.compareTo(b.name));

      return students;
    } catch (e) {
      debugPrint('❌ Error getting all active students: $e');
      return [];
    }
  }

  // Get all students (active and inactive) - Future version
  Future<List<StudentModel>> getAllStudentsFuture() async {
    try {
      debugPrint('🔍 Getting all students (active and inactive)...');

      final snapshot = await _firestore
          .collection('students')
          .get();

      debugPrint('📊 Found ${snapshot.docs.length} total students in database');

      final students = snapshot.docs
          .map((doc) {
            final data = doc.data();
            debugPrint('👤 Student: ${data['name']} - Route: "${data['busRoute']}" - BusId: "${data['busId']}" - Active: ${data['isActive']}');
            return StudentModel.fromMap(data);
          })
          .toList();

      // Sort manually by name
      students.sort((a, b) => a.name.compareTo(b.name));

      return students;
    } catch (e) {
      debugPrint('❌ Error getting all students: $e');
      return [];
    }
  }

  // Get only assigned students (students who have busRoute or busId)
  Future<List<StudentModel>> getAssignedStudents() async {
    try {
      debugPrint('🔍 Getting only assigned students...');

      final allStudents = await getAllStudentsFuture();

      final assignedStudents = allStudents.where((student) {
        final isAssigned = student.busRoute.isNotEmpty || student.busId.isNotEmpty;
        return isAssigned;
      }).toList();

      debugPrint('📊 Found ${assignedStudents.length} assigned students out of ${allStudents.length} total');

      return assignedStudents;
    } catch (e) {
      debugPrint('❌ Error getting assigned students: $e');
      return [];
    }
  }

  // Get students by bus ID (simplified to avoid index issues)
  Stream<List<StudentModel>> getStudentsByBusId(String busId) {
    return _firestore
        .collection('students')
        .where('busId', isEqualTo: busId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final students = snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList();

          // Sort manually to avoid index requirement
          students.sort((a, b) => a.name.compareTo(b.name));
          return students;
        });
  }

  // Update student with notifications
  Future<void> updateStudent(StudentModel student) async {
    try {
      // Get current student data for comparison
      final currentDoc = await _firestore.collection('students').doc(student.id).get();
      Map<String, dynamic>? currentData;

      if (currentDoc.exists) {
        currentData = currentDoc.data()!;
      }

      await _firestore
          .collection('students')
          .doc(student.id)
          .update(student.copyWith(updatedAt: DateTime.now()).toMap());

      // Send notifications for important changes if we have previous data
      if (currentData != null) {
        await _sendStudentUpdateNotifications(student.id, currentData, student.toMap());
      }
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات الطالب: $e');
    }
  }

  // Send notifications for student information updates
  Future<void> _sendStudentUpdateNotifications(
    String studentId,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData
  ) async {
    try {
      final studentName = oldData['name'] ?? 'طالب';
      final parentId = oldData['parentId'] ?? '';

      if (parentId.isEmpty) return;

      List<String> changes = [];

      // Check for important field changes
      if (newData['name'] != oldData['name']) {
        changes.add('الاسم: من "${oldData['name']}" إلى "${newData['name']}"');
      }

      if (newData['grade'] != oldData['grade']) {
        changes.add('الصف: من "${oldData['grade']}" إلى "${newData['grade']}"');
      }

      if (newData['busRoute'] != oldData['busRoute']) {
        changes.add('خط السير: من "${oldData['busRoute'] ?? 'غير محدد'}" إلى "${newData['busRoute'] ?? 'غير محدد'}"');
      }

      if (newData['address'] != oldData['address']) {
        changes.add('العنوان: تم تحديثه');
      }

      if (newData['emergencyContact'] != oldData['emergencyContact']) {
        changes.add('جهة اتصال الطوارئ: تم تحديثها');
      }

      if (newData['medicalInfo'] != oldData['medicalInfo']) {
        changes.add('المعلومات الطبية: تم تحديثها');
      }

      if (changes.isNotEmpty) {
        // إرسال إشعار لولي الأمر فقط (بدون إشعار الأدمن)
        final notificationService = EnhancedNotificationService();
        await notificationService.sendNotificationToUser(
          userId: parentId,
          title: 'تم تحديث معلومات $studentName',
          body: 'تم تحديث المعلومات التالية:\n• ${changes.join('\n• ')}',
          type: 'student',
          data: {
            'type': 'student_info_update',
            'changes': changes,
            'studentId': studentId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        debugPrint('✅ Parent notification sent for student info update (no admin notification)');
      }

    } catch (e) {
      debugPrint('❌ Error sending student update notifications: $e');
    }
  }

  // Update student status with enhanced logging and sync
  Future<void> updateStudentStatus(String studentId, StudentStatus status) async {
    try {
      // Check rate limit
      final currentUserId = _getCurrentUserId();
      if (!await _checkAndRecordRateLimit(currentUserId, 'updateStudentStatus')) {
        throw Exception('تم تجاوز الحد المسموح من الطلبات. يرجى المحاولة لاحقاً.');
      }

      debugPrint('🔄 Updating student status: $studentId to ${status.toString().split('.').last}');

      // Get student data first
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) {
        throw Exception('الطالب غير موجود');
      }

      final studentData = studentDoc.data()!;
      final oldStatus = studentData['currentStatus'] ?? 'unknown';
      final newStatus = status.toString().split('.').last;

      await _firestore.collection('students').doc(studentId).update({
        'currentStatus': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('✅ Student status updated successfully: $studentId');

      // إرسال إشعار تغيير الحالة
      if (currentUserId.isNotEmpty) {
        final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
        final supervisorName = currentUserDoc.exists ?
          (currentUserDoc.data()?['name'] ?? 'مشرف') : 'مشرف';

        await NotificationService().sendStudentStatusChangeNotification(
          studentId: studentId,
          studentName: studentData['name'] ?? 'طالب',
          parentId: studentData['parentId'] ?? '',
          oldStatus: oldStatus,
          newStatus: newStatus,
          supervisorName: supervisorName,
        );
      }

      // Invalidate cache for this student
      final cacheKey = 'student_$studentId';
      await _cacheService.remove(cacheKey);
      debugPrint('🗑️ Invalidated cache for student: $studentId');

      // Force refresh any cached data by updating a timestamp
      await _firestore.collection('system_updates').doc('last_student_update').set({
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'studentId': studentId,
        'newStatus': newStatus,
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('❌ Error updating student status: $e');
      throw Exception('خطأ في تحديث حالة الطالب: $e');
    }
  }

  // Delete student (soft delete)
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('خطأ في حذف الطالب: $e');
    }
  }

  // Trip Collection Methods

  // Record trip action with enhanced logging
  Future<void> recordTrip(TripModel trip) async {
    try {
      // Ensure all required fields are present
      final tripData = trip.toMap();

      // Add additional metadata for better tracking
      tripData['createdAt'] = Timestamp.fromDate(DateTime.now());
      tripData['source'] = 'mobile_app';

      // Log the trip data for debugging
      debugPrint('🚌 Recording trip: ${trip.studentName} - ${trip.actionDisplayText}');
      debugPrint('📍 Trip data: $tripData');

      await _firestore.collection('trips').doc(trip.id).set(tripData);

      debugPrint('✅ Trip recorded successfully');
    } catch (e) {
      debugPrint('❌ Error recording trip: $e');
      throw Exception('خطأ في تسجيل الرحلة: $e');
    }
  }

  // Get trips by student ID
  Stream<List<TripModel>> getTripsByStudent(String studentId) {
    return _firestore
        .collection('trips')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.data()))
            .toList());
  }

  // Get trips by date range
  Stream<List<TripModel>> getTripsByDateRange(DateTime startDate, DateTime endDate) {
    try {
      debugPrint('🔍 Getting trips from ${startDate.toString()} to ${endDate.toString()}');

      return _firestore
          .collection('trips')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('❌ Error in getTripsByDateRange: $error');
            // If compound index is missing, try simpler query
            if (error.toString().contains('index')) {
              debugPrint('🔄 Trying simpler query without orderBy...');
              return _firestore
                  .collection('trips')
                  .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
                  .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
                  .snapshots();
            }
            throw error;
          })
          .map((snapshot) {
            debugPrint('📊 Found ${snapshot.docs.length} trips in date range');
            return snapshot.docs
                .map((doc) {
                  try {
                    return TripModel.fromMap(doc.data());
                  } catch (e) {
                    debugPrint('❌ Error parsing trip ${doc.id}: $e');
                    return null;
                  }
                })
                .where((trip) => trip != null)
                .cast<TripModel>()
                .toList();
          });
    } catch (e) {
      debugPrint('❌ Error setting up getTripsByDateRange: $e');
      // Return empty stream on error
      return Stream.value(<TripModel>[]);
    }
  }

  // Get trips by student ID and date (simpler query)
  Stream<List<TripModel>> getTripsByStudentAndDate(String studentId, DateTime date) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('🔍 Getting trips for student $studentId on ${date.toString()}');

      return _firestore
          .collection('trips')
          .where('studentId', isEqualTo: studentId)
          .snapshots()
          .map((snapshot) {
            final allTrips = snapshot.docs
                .map((doc) {
                  try {
                    return TripModel.fromMap(doc.data());
                  } catch (e) {
                    debugPrint('❌ Error parsing trip ${doc.id}: $e');
                    return null;
                  }
                })
                .where((trip) => trip != null)
                .cast<TripModel>()
                .toList();

            // Filter by date locally
            final filteredTrips = allTrips.where((trip) {
              return trip.timestamp.isAfter(startOfDay) &&
                     trip.timestamp.isBefore(endOfDay);
            }).toList();

            // Sort by timestamp descending
            filteredTrips.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            debugPrint('📊 Found ${filteredTrips.length} trips for student on date');
            return filteredTrips;
          });
    } catch (e) {
      debugPrint('❌ Error in getTripsByStudentAndDate: $e');
      return Stream.value(<TripModel>[]);
    }
  }

  // Generate unique QR code for student (sequential starting from 1000)
  Future<String> generateQRCode() async {
    try {
      // Get the current counter from Firestore
      final counterDoc = await _firestore
          .collection('counters')
          .doc('student_qr_code')
          .get();

      int nextNumber = 1000; // Start from 1000

      if (counterDoc.exists) {
        final currentValue = counterDoc.data()?['value'] ?? 999;
        nextNumber = currentValue + 1;
      }

      // Update the counter
      await _firestore
          .collection('counters')
          .doc('student_qr_code')
          .set({'value': nextNumber});

      // Return the QR code as string
      final qrCode = nextNumber.toString();
      debugPrint('✅ Generated QR code: $qrCode');
      return qrCode;
    } catch (e) {
      debugPrint('❌ Error generating QR code: $e');
      // Fallback to timestamp-based code if counter fails
      final fallbackCode = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
      debugPrint('🔄 Using fallback QR code: $fallbackCode');
      return fallbackCode;
    }
  }

  // Generate unique QR code synchronously (for compatibility)
  String generateQRCodeSync() {
    // Generate a simple sequential number based on timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrCode = (1000 + (timestamp % 9000)).toString();
    return qrCode;
  }

  // Generate unique trip ID
  String generateTripId() {
    return _uuid.v4();
  }

  // Bus Collection Methods

  // Add new bus
  Future<void> addBus(BusModel bus) async {
    try {
      await _firestore
          .collection('buses')
          .doc(bus.id)
          .set(bus.toMap());
      debugPrint('✅ Bus added successfully: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error adding bus: $e');
      throw Exception('خطأ في إضافة السيارة: $e');
    }
  }

  // Get bus by ID
  Future<BusModel?> getBus(String busId) async {
    try {
      // Check rate limit
      final currentUserId = _getCurrentUserId();
      if (!await _checkAndRecordRateLimit(currentUserId, 'getBus')) {
        throw Exception('تم تجاوز الحد المسموح من الطلبات. يرجى المحاولة لاحقاً.');
      }

      // Check cache first
      final cacheKey = 'bus_$busId';
      final cachedBus = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedBus != null) {
        return BusModel.fromMap(cachedBus);
      }

      final doc = await _firestore.collection('buses').doc(busId).get();
      if (doc.exists) {
        final busData = doc.data()!;

        // Store in cache with longer expiration for buses (they change less frequently)
        await _cacheService.set(
          cacheKey,
          busData,
          expiration: const Duration(minutes: 15),
          priority: CachePriority.normal,
        );

        return BusModel.fromMap(busData);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting bus: $e');
      throw Exception('خطأ في جلب بيانات السيارة: $e');
    }
  }

  // Get bus by route
  Future<BusModel?> getBusByRoute(String route) async {
    try {
      final querySnapshot = await _firestore
          .collection('buses')
          .where('route', isEqualTo: route)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return BusModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting bus by route: $e');
      throw Exception('خطأ في البحث عن السيارة: $e');
    }
  }

  // Get all buses (for admin) - simplified query to avoid index issues
  Stream<List<BusModel>> getAllBuses() {
    return _firestore
        .collection('buses')
        .snapshots()
        .map((snapshot) {
          try {
            final buses = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    // Add document ID if missing
                    if (!data.containsKey('id') || data['id'] == null || data['id'] == '') {
                      data['id'] = doc.id;
                    }
                    return BusModel.fromMap(data);
                  } catch (e) {
                    debugPrint('❌ Error parsing bus document ${doc.id}: $e');
                    debugPrint('📝 Document data: ${doc.data()}');
                    return null;
                  }
                })
                .where((bus) => bus != null)
                .cast<BusModel>()
                .toList();

            // Sort locally to avoid compound index requirement
            // Sort by active status first (active buses first), then by plate number
            buses.sort((a, b) {
              if (a.isActive && !b.isActive) return -1;
              if (!a.isActive && b.isActive) return 1;
              return a.plateNumber.compareTo(b.plateNumber);
            });

            debugPrint('✅ Loaded ${buses.length} buses from ${snapshot.docs.length} total documents');

            // Debug: print all buses found
            for (var bus in buses) {
              debugPrint('🚌 Bus: ${bus.plateNumber} - ${bus.driverName} - Active: ${bus.isActive}');
            }

            return buses;
          } catch (e) {
            debugPrint('❌ Error processing buses snapshot: $e');
            return <BusModel>[];
          }
        })
        .handleError((error) {
          debugPrint('❌ Error in getAllBuses stream: $error');
          return <BusModel>[];
        });
  }

  // Update bus
  Future<void> updateBus(BusModel bus) async {
    try {
      await _firestore
          .collection('buses')
          .doc(bus.id)
          .update(bus.copyWith(updatedAt: DateTime.now()).toMap());
      debugPrint('✅ Bus updated successfully: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error updating bus: $e');
      throw Exception('خطأ في تحديث بيانات السيارة: $e');
    }
  }

  // Update bus route only
  Future<void> updateBusRoute(String busId, String newRoute) async {
    try {
      await _firestore
          .collection('buses')
          .doc(busId)
          .update({
            'route': newRoute,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      debugPrint('✅ Bus route updated successfully: $newRoute');
    } catch (e) {
      debugPrint('❌ Error updating bus route: $e');
      throw Exception('خطأ في تحديث خط السير: $e');
    }
  }

  // Update bus supervisor
  Future<void> updateBusSupervisor(String busId, String? supervisorId) async {
    try {
      await _firestore
          .collection('buses')
          .doc(busId)
          .update({
            'supervisorId': supervisorId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      debugPrint('✅ Bus supervisor updated successfully: $supervisorId');
    } catch (e) {
      debugPrint('❌ Error updating bus supervisor: $e');
      throw Exception('خطأ في تحديث مشرف الباص: $e');
    }
  }

  // Update assignment route
  Future<void> updateAssignmentRoute(String assignmentId, String newRoute) async {
    try {
      await _firestore
          .collection('supervisor_assignments')
          .doc(assignmentId)
          .update({
            'busRoute': newRoute,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      debugPrint('✅ Assignment route updated successfully: $newRoute');
    } catch (e) {
      debugPrint('❌ Error updating assignment route: $e');
      throw Exception('خطأ في تحديث خط السير في التعيين: $e');
    }
  }

  // Debug function to check all buses in database
  Future<void> debugAllBuses() async {
    try {
      final snapshot = await _firestore.collection('buses').get();
      debugPrint('🔍 Total buses in database: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('📄 Bus Document ID: ${doc.id}');
        debugPrint('📝 Bus Data: $data');
        debugPrint('✅ isActive: ${data['isActive']}');
        debugPrint('🚌 plateNumber: ${data['plateNumber']}');
        debugPrint('👨‍✈️ driverName: ${data['driverName']}');
        debugPrint('---');
      }
    } catch (e) {
      debugPrint('❌ Error debugging buses: $e');
    }
  }

  // Delete bus (soft delete)
  Future<void> deleteBus(String busId) async {
    try {
      await _firestore.collection('buses').doc(busId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('✅ Bus deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting bus: $e');
      throw Exception('خطأ في حذف السيارة: $e');
    }
  }

  // Get available routes
  Future<List<String>> getAvailableRoutes() async {
    try {
      final querySnapshot = await _firestore
          .collection('buses')
          .where('isActive', isEqualTo: true)
          .get();

      final routes = querySnapshot.docs
          .map((doc) => doc.data()['route'] as String)
          .where((route) => route.isNotEmpty)
          .toSet()
          .toList();

      routes.sort();
      return routes;
    } catch (e) {
      debugPrint('❌ Error getting routes: $e');
      return [];
    }
  }

  // Generate unique bus ID
  String generateBusId() {
    return _uuid.v4();
  }

  // Get bus information for a student
  Future<BusModel?> getBusForStudent(String studentId) async {
    try {
      // First get the student to find their busId
      final student = await getStudent(studentId);
      if (student == null || student.busId.isEmpty) {
        return null;
      }

      // Then get the bus information
      return await getBus(student.busId);
    } catch (e) {
      debugPrint('❌ Error getting bus for student: $e');
      return null;
    }
  }

  // Assign bus to student
  Future<void> assignBusToStudent(String studentId, String busId) async {
    try {
      // Get student and bus data
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      final busDoc = await _firestore.collection('buses').doc(busId).get();

      if (!studentDoc.exists || !busDoc.exists) {
        throw Exception('الطالب أو الباص غير موجود');
      }

      final studentData = studentDoc.data()!;
      final busData = busDoc.data()!;

      await _firestore.collection('students').doc(studentId).update({
        'busId': busId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // إرسال إشعار تسكين الطالب
      final currentUserId = _getCurrentUserId();
      if (currentUserId.isNotEmpty) {
        final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
        final adminName = currentUserDoc.exists ?
          (currentUserDoc.data()?['name'] ?? 'إدمن') : 'إدمن';

        // إرسال إشعار محسن مع الصوت (باستثناء الإدمن الحالي)
        await NotificationService().notifyStudentAssignmentWithSound(
          studentId: studentId,
          studentName: studentData['name'] ?? 'طالب',
          busId: busId,
          busRoute: busData['route'] ?? 'غير محدد',
          parentId: studentData['parentId'] ?? '',
          supervisorId: busData['supervisorId'] ?? '',
          parentName: studentData['parentName'] ?? 'ولي الأمر',
          parentPhone: studentData['parentPhone'] ?? 'غير محدد',
          excludeAdminId: currentUserId, // استبعاد الإدمن الحالي
        );
      }

      debugPrint('✅ Bus assigned to student successfully');
    } catch (e) {
      debugPrint('❌ Error assigning bus to student: $e');
      throw Exception('خطأ في تعيين السيارة للطالب: $e');
    }
  }

  // Get students assigned to a specific bus
  Stream<List<StudentModel>> getStudentsByBus(String busId) {
    return _firestore
        .collection('students')
        .where('busId', isEqualTo: busId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Get all students currently on buses (based on current status from QR scanner)
  Stream<List<StudentModel>> getStudentsOnBus() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .where('currentStatus', isEqualTo: 'onBus')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Get students currently on bus for specific supervisor
  Stream<List<StudentModel>> getStudentsOnBusForSupervisor(String supervisorId) {
    debugPrint('🔍 Getting students on bus for supervisor: $supervisorId');

    return _firestore
        .collection('supervisor_assignments')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((assignmentSnapshot) async {
          debugPrint('📋 Found ${assignmentSnapshot.docs.length} active assignments for supervisor $supervisorId');

          if (assignmentSnapshot.docs.isEmpty) {
            debugPrint('⚠️ No active assignments found for supervisor $supervisorId');
            return <StudentModel>[];
          }

          // Get bus routes for this supervisor
          final busRoutes = assignmentSnapshot.docs
              .map((doc) {
                final data = doc.data();
                final busRoute = data['busRoute'] as String? ?? '';
                final busPlateNumber = data['busPlateNumber'] as String? ?? '';
                debugPrint('🚌 Supervisor assigned to route: $busRoute (Bus: $busPlateNumber)');
                return busRoute;
              })
              .where((route) => route.isNotEmpty)
              .toSet()
              .toList();

          if (busRoutes.isEmpty) {
            debugPrint('⚠️ No bus routes found for supervisor $supervisorId');
            return <StudentModel>[];
          }

          debugPrint('🔍 Looking for students on routes: $busRoutes');

          // Get students currently on these routes
          final studentsSnapshot = await _firestore
              .collection('students')
              .where('isActive', isEqualTo: true)
              .where('currentStatus', isEqualTo: 'onBus')
              .where('busRoute', whereIn: busRoutes)
              .get();

          final students = studentsSnapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList();

          debugPrint('👥 Found ${students.length} students currently on supervisor routes');
          for (final student in students) {
            debugPrint('   - ${student.name} (Route: ${student.busRoute})');
          }

          // Sort by name for consistent display
          students.sort((a, b) => a.name.compareTo(b.name));

          return students;
        });
  }

  // Get supervisor's assigned buses
  Future<List<String>> getSupervisorAssignedBuses(String supervisorId) async {
    try {
      debugPrint('🔍 Getting assigned buses for supervisor: $supervisorId');

      final assignmentSnapshot = await _firestore
          .collection('supervisor_assignments')
          .where('supervisorId', isEqualTo: supervisorId)
          .where('status', isEqualTo: 'active')
          .get();

      final busIds = assignmentSnapshot.docs
          .map((doc) {
            final data = doc.data();
            final busId = data['busId'] as String;
            final busPlate = data['busPlateNumber'] as String;
            debugPrint('🚌 Found assignment: Bus $busPlate (ID: $busId)');
            return busId;
          })
          .toList();

      debugPrint('📊 Total assigned buses: ${busIds.length}');
      return busIds;
    } catch (e) {
      debugPrint('❌ Error getting supervisor assigned buses: $e');
      return [];
    }
  }

  // Check if supervisor has any active assignments
  Future<bool> hasSupervisorAssignments(String supervisorId) async {
    try {
      final assignmentSnapshot = await _firestore
          .collection('supervisor_assignments')
          .where('supervisorId', isEqualTo: supervisorId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      final hasAssignments = assignmentSnapshot.docs.isNotEmpty;
      debugPrint('🔍 Supervisor $supervisorId has assignments: $hasAssignments');
      return hasAssignments;
    } catch (e) {
      debugPrint('❌ Error checking supervisor assignments: $e');
      return false;
    }
  }

  // Complaints Collection Methods

  /// Add new complaint
  Future<String> addComplaint(ComplaintModel complaint) async {
    try {
      // Generate ID if not provided
      final complaintId = complaint.id.isEmpty ? _uuid.v4() : complaint.id;

      // Create complaint with generated ID
      final complaintWithId = complaint.copyWith(
        id: complaintId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to complaints collection
      await _firestore
          .collection('complaints')
          .doc(complaintId)
          .set(complaintWithId.toMap());

      debugPrint('✅ Complaint added successfully: ${complaint.title}');
      return complaintId;
    } catch (e) {
      debugPrint('❌ Error adding complaint: $e');
      throw Exception('خطأ في إضافة الشكوى: $e');
    }
  }

  /// Get complaint by ID
  Future<ComplaintModel?> getComplaint(String complaintId) async {
    try {
      final doc = await _firestore.collection('complaints').doc(complaintId).get();
      if (doc.exists) {
        return ComplaintModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting complaint: $e');
      throw Exception('خطأ في جلب بيانات الشكوى: $e');
    }
  }

  /// Get complaints by parent ID (simplified query to avoid index issues)
  Stream<List<ComplaintModel>> getComplaintsByParent(String parentId) {
    return _firestore
        .collection('complaints')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid compound index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Get all complaints (for admin) - simplified query
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Get complaints by status - simplified query
  Stream<List<ComplaintModel>> getComplaintsByStatus(ComplaintStatus status) {
    return _firestore
        .collection('complaints')
        .where('status', isEqualTo: status.toString().split('.').last)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Get complaints by priority - simplified query
  Stream<List<ComplaintModel>> getComplaintsByPriority(ComplaintPriority priority) {
    return _firestore
        .collection('complaints')
        .where('priority', isEqualTo: priority.toString().split('.').last)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Update complaint
  Future<void> updateComplaint(ComplaintModel complaint) async {
    try {
      await _firestore
          .collection('complaints')
          .doc(complaint.id)
          .update(complaint.copyWith(updatedAt: DateTime.now()).toMap());
      debugPrint('✅ Complaint updated successfully: ${complaint.title}');
    } catch (e) {
      debugPrint('❌ Error updating complaint: $e');
      throw Exception('خطأ في تحديث الشكوى: $e');
    }
  }

  /// Update complaint status
  Future<void> updateComplaintStatus(String complaintId, ComplaintStatus status) async {
    try {
      // Get complaint data first
      final complaintDoc = await _firestore.collection('complaints').doc(complaintId).get();
      if (!complaintDoc.exists) {
        throw Exception('الشكوى غير موجودة');
      }

      final complaintData = complaintDoc.data()!;

      await _firestore.collection('complaints').doc(complaintId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // إرسال إشعار تحديث حالة الشكوى
      await NotificationService().sendComplaintNotification(
        complaintId: complaintId,
        title: complaintData['title'] ?? 'شكوى',
        description: complaintData['description'] ?? '',
        parentId: complaintData['parentId'] ?? '',
        parentName: complaintData['parentName'] ?? 'ولي أمر',
        status: status.toString().split('.').last,
      );

      debugPrint('✅ Complaint status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating complaint status: $e');
      throw Exception('خطأ في تحديث حالة الشكوى: $e');
    }
  }

  /// Add admin response to complaint
  Future<void> addComplaintResponse(String complaintId, String response, String adminId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'adminResponse': response,
        'responseDate': FieldValue.serverTimestamp(),
        'assignedTo': adminId,
        'status': ComplaintStatus.resolved.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Admin response added successfully');
    } catch (e) {
      debugPrint('❌ Error adding admin response: $e');
      throw Exception('خطأ في إضافة رد الإدارة: $e');
    }
  }

  /// Delete complaint (soft delete)
  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Complaint deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting complaint: $e');
      throw Exception('خطأ في حذف الشكوى: $e');
    }
  }

  /// Get complaints statistics
  Future<Map<String, int>> getComplaintsStats() async {
    try {
      final snapshot = await _firestore
          .collection('complaints')
          .where('isActive', isEqualTo: true)
          .get();

      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data()))
          .toList();

      return {
        'total': complaints.length,
        'pending': complaints.where((c) => c.status == ComplaintStatus.pending).length,
        'inProgress': complaints.where((c) => c.status == ComplaintStatus.inProgress).length,
        'resolved': complaints.where((c) => c.status == ComplaintStatus.resolved).length,
        'closed': complaints.where((c) => c.status == ComplaintStatus.closed).length,
        'urgent': complaints.where((c) => c.priority == ComplaintPriority.urgent).length,
        'high': complaints.where((c) => c.priority == ComplaintPriority.high).length,
      };
    } catch (e) {
      debugPrint('❌ Error getting complaints stats: $e');
      return {};
    }
  }

  /// Get pending complaints for admin review
  Stream<List<ComplaintModel>> getPendingComplaints() {
    return _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'pending')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Generate unique complaint ID
  String generateComplaintId() {
    return _uuid.v4();
  }

  /// Test Firebase connection
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing Firebase connection...');

      // Try to read from a simple collection
      await _firestore
          .collection('test')
          .doc('connection')
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('✅ Firebase connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase connection test failed: $e');
      return false;
    }
  }

  /// Get buses with fallback
  Future<List<BusModel>> getBusesWithFallback() async {
    try {
      debugPrint('🔍 Getting buses with fallback...');

      final snapshot = await _firestore
          .collection('buses')
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 15));

      final buses = snapshot.docs
          .map((doc) {
            try {
              return BusModel.fromMap(doc.data());
            } catch (e) {
              debugPrint('❌ Error parsing bus document ${doc.id}: $e');
              return null;
            }
          })
          .where((bus) => bus != null)
          .cast<BusModel>()
          .toList();

      buses.sort((a, b) => a.plateNumber.compareTo(b.plateNumber));
      debugPrint('✅ Loaded ${buses.length} buses with fallback');
      return buses;
    } catch (e) {
      debugPrint('❌ Error getting buses with fallback: $e');
      // Return mock data for testing
      debugPrint('📝 Returning mock buses for testing...');
      return _getMockBuses();
    }
  }

  /// Get mock buses for testing/fallback
  List<BusModel> _getMockBuses() {
    return [
      BusModel(
        id: 'mock_bus_1',
        plateNumber: 'أ ب ج 123',
        description: 'سيارة نقل طلاب - خط الشمال',
        driverName: 'أحمد محمد',
        driverPhone: '0501234567',
        route: 'خط الشمال',
        capacity: 30,
        hasAirConditioning: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      BusModel(
        id: 'mock_bus_2',
        plateNumber: 'د هـ و 456',
        description: 'سيارة نقل طلاب - خط الجنوب',
        driverName: 'محمد علي',
        driverPhone: '0507654321',
        route: 'خط الجنوب',
        capacity: 25,
        hasAirConditioning: false,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      BusModel(
        id: 'mock_bus_3',
        plateNumber: 'ز ح ط 789',
        description: 'سيارة نقل طلاب - خط الشرق',
        driverName: 'عبدالله سالم',
        driverPhone: '0509876543',
        route: 'خط الشرق',
        capacity: 35,
        hasAirConditioning: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Trip Management Methods
  Future<void> addTrip(Map<String, dynamic> tripData) async {
    try {
      await _firestore.collection('trips').add({
        ...tripData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Trip added to database');
    } catch (e) {
      debugPrint('❌ Error adding trip: $e');
      throw Exception('فشل في إضافة الرحلة: $e');
    }
  }

  Future<void> updateSupervisorTripStatus(String supervisorId, Map<String, dynamic> tripData) async {
    try {
      // Check if supervisor document exists first
      final docRef = _firestore.collection('supervisors').doc(supervisorId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update existing document
        await docRef.update({
          'currentTrip': tripData,
          'lastTripUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Supervisor trip status updated');
      } else {
        // Create new supervisor document
        await docRef.set({
          'id': supervisorId,
          'currentTrip': tripData,
          'lastTripUpdate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Supervisor document created with trip status');
      }
    } catch (e) {
      debugPrint('❌ Error updating supervisor trip status: $e');
      throw Exception('فشل في تحديث حالة رحلة المشرف: $e');
    }
  }

  // Get current trip status for supervisor
  Future<Map<String, dynamic>?> getSupervisorTripStatus(String supervisorId) async {
    try {
      final doc = await _firestore.collection('supervisors').doc(supervisorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['currentTrip'] as Map<String, dynamic>?;
      } else {
        // Create supervisor document if it doesn't exist
        await createSupervisorIfNotExists(supervisorId);
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting supervisor trip status: $e');
      return null;
    }
  }

  // Create supervisor document if it doesn't exist
  Future<void> createSupervisorIfNotExists(String supervisorId) async {
    try {
      final docRef = _firestore.collection('supervisors').doc(supervisorId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({
          'id': supervisorId,
          'currentTrip': null,
          'lastTripUpdate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        debugPrint('✅ Supervisor document created: $supervisorId');
      }
    } catch (e) {
      debugPrint('❌ Error creating supervisor document: $e');
    }
  }

  // Get all trips for supervisor
  Stream<List<Map<String, dynamic>>> getSupervisorTrips(String supervisorId) {
    return _firestore
        .collection('trips')
        .where('supervisorId', isEqualTo: supervisorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // Parent Profile Management Methods
  Future<void> saveParentProfile(ParentProfileModel profile) async {
    try {
      await _firestore.collection('parent_profiles').doc(profile.id).set(profile.toMap());
      debugPrint('✅ Parent profile saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving parent profile: $e');
      throw Exception('فشل في حفظ بيانات الوالد: $e');
    }
  }

  Future<ParentProfileModel?> getParentProfile(String parentId) async {
    try {
      final doc = await _firestore.collection('parent_profiles').doc(parentId).get();
      if (doc.exists) {
        return ParentProfileModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting parent profile: $e');
      return null;
    }
  }

  Future<void> updateParentProfile(String parentId, Map<String, dynamic> updates) async {
    try {
      // Update parent profile
      await _firestore.collection('parent_profiles').doc(parentId).update({
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Parent profile updated successfully');

      // Update related student records if name or address changed
      if (updates.containsKey('fullName') || updates.containsKey('address')) {
        await _updateStudentParentInfo(parentId, updates);
      }
    } catch (e) {
      debugPrint('❌ Error updating parent profile: $e');
      throw Exception('فشل في تحديث بيانات الوالد: $e');
    }
  }

  // Update student records when parent info changes
  Future<void> _updateStudentParentInfo(String parentId, Map<String, dynamic> updates) async {
    try {
      // Get all students for this parent
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .get();

      if (studentsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in studentsSnapshot.docs) {
          final studentRef = _firestore.collection('students').doc(doc.id);
          final updateData = <String, dynamic>{
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Update parent name if changed
          if (updates.containsKey('fullName')) {
            updateData['parentName'] = updates['fullName'];
          }

          // Update address if changed
          if (updates.containsKey('address')) {
            updateData['address'] = updates['address'];
          }

          batch.update(studentRef, updateData);
        }

        await batch.commit();
        debugPrint('✅ Updated ${studentsSnapshot.docs.length} student records with new parent info');
      }
    } catch (e) {
      debugPrint('❌ Error updating student parent info: $e');
      // Don't throw here to avoid breaking the main profile update
    }
  }

  Stream<List<ParentProfileModel>> getAllParentProfiles() {
    return _firestore
        .collection('parent_profiles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) =>
            ParentProfileModel.fromMap({
              'id': doc.id,
              ...doc.data(),
            })
        ).toList());
  }

  Future<bool> isParentProfileComplete(String parentId) async {
    try {
      final profile = await getParentProfile(parentId);
      return profile?.isProfileComplete ?? false;
    } catch (e) {
      debugPrint('❌ Error checking profile completion: $e');
      return false;
    }
  }

  // ==================== ABSENCE MANAGEMENT ====================

  // Create absence report
  Future<void> createAbsence(AbsenceModel absence) async {
    try {
      final absenceData = absence.toMap();
      debugPrint('📝 Creating absence: ${absence.studentName} - Status: ${absence.status.toString().split('.').last}');
      debugPrint('📊 Absence data: $absenceData');

      await _firestore.collection('absences').doc(absence.id).set(absenceData);
      debugPrint('✅ Absence created successfully with ID: ${absence.id}');
    } catch (e) {
      debugPrint('❌ Error creating absence: $e');
      throw Exception('فشل في إنشاء تقرير الغياب: $e');
    }
  }

  // Update absence
  Future<void> updateAbsence(AbsenceModel absence) async {
    try {
      await _firestore.collection('absences').doc(absence.id).update(absence.toMap());
      debugPrint('✅ Absence updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating absence: $e');
      throw Exception('فشل في تحديث تقرير الغياب: $e');
    }
  }

  // Delete absence
  Future<void> deleteAbsence(String absenceId) async {
    try {
      await _firestore.collection('absences').doc(absenceId).delete();
      debugPrint('✅ Absence deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting absence: $e');
      throw Exception('فشل في حذف تقرير الغياب: $e');
    }
  }

  // Get absence by ID
  Future<AbsenceModel?> getAbsenceById(String absenceId) async {
    try {
      final doc = await _firestore.collection('absences').doc(absenceId).get();
      if (doc.exists) {
        return AbsenceModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting absence: $e');
      return null;
    }
  }

  // Get all absences
  Stream<List<AbsenceModel>> getAllAbsences() {
    return _firestore
        .collection('absences')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsenceModel.fromMap(doc.data()))
            .toList());
  }

  // Get absences by student
  Stream<List<AbsenceModel>> getAbsencesByStudent(String studentId) {
    return _firestore
        .collection('absences')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsenceModel.fromMap(doc.data()))
            .toList());
  }

  // Get absences by parent
  Stream<List<AbsenceModel>> getAbsencesByParent(String parentId) {
    return _firestore
        .collection('absences')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return absences;
        });
  }

  // Get pending absences for admin approval
  Stream<List<AbsenceModel>> getPendingAbsences() {
    debugPrint('🔍 Setting up pending absences stream...');

    return _firestore
        .collection('absences')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .handleError((error) {
          debugPrint('❌ Error in getPendingAbsences stream: $error');
        })
        .map((snapshot) {
          debugPrint('📡 Received snapshot with ${snapshot.docs.length} documents');

          final absences = <AbsenceModel>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              debugPrint('📋 Processing document ${doc.id}:');
              debugPrint('   Student: ${data['studentName']}');
              debugPrint('   Status: ${data['status']}');
              debugPrint('   Parent: ${data['parentId']}');
              debugPrint('   Created: ${data['createdAt']}');

              final absence = AbsenceModel.fromMap(data);
              absences.add(absence);
              debugPrint('✅ Successfully parsed absence for ${absence.studentName}');
            } catch (e) {
              debugPrint('❌ Error parsing document ${doc.id}: $e');
            }
          }

          debugPrint('📊 Final pending absences count: ${absences.length}');
          return absences;
        });
  }

  // Get pending absences for specific supervisor (index-safe approach)
  Stream<List<AbsenceModel>> getPendingAbsencesForSupervisor(String supervisorId) {
    return _firestore
        .collection('supervisor_assignments')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((assignmentSnapshot) async {
          debugPrint('🔍 Getting pending absences for supervisor: $supervisorId');

          if (assignmentSnapshot.docs.isEmpty) {
            debugPrint('⚠️ No assignments found for supervisor');
            return <AbsenceModel>[];
          }

          // Get bus routes for this supervisor (with fallback to busId)
          final List<String> busRoutes = [];

          for (final doc in assignmentSnapshot.docs) {
            final data = doc.data();
            var busRoute = data['busRoute'] as String? ?? '';

            // إذا كان busRoute فارغ، احصل عليه من بيانات الباص
            if (busRoute.isEmpty) {
              final busId = data['busId'] as String? ?? '';
              if (busId.isNotEmpty) {
                try {
                  final bus = await getBusById(busId);
                  if (bus != null) {
                    busRoute = bus.route;
                    debugPrint('✅ Got busRoute from bus $busId: "$busRoute"');
                  }
                } catch (e) {
                  debugPrint('❌ Error getting bus data for $busId: $e');
                }
              }
            }

            if (busRoute.isNotEmpty) {
              busRoutes.add(busRoute);
            }
          }

          if (busRoutes.isEmpty) {
            debugPrint('⚠️ No bus routes found for supervisor');
            return <AbsenceModel>[];
          }

          debugPrint('🚌 Supervisor routes: $busRoutes');

          // Get students on these routes (avoid whereIn with multiple conditions)
          final List<String> allStudentIds = [];

          for (final route in busRoutes) {
            try {
              final studentsSnapshot = await _firestore
                  .collection('students')
                  .where('isActive', isEqualTo: true)
                  .where('busRoute', isEqualTo: route)
                  .get();

              final routeStudentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();
              allStudentIds.addAll(routeStudentIds);
              debugPrint('📍 Route $route: Found ${routeStudentIds.length} students');
            } catch (e) {
              debugPrint('❌ Error getting students for route $route: $e');
            }
          }

          if (allStudentIds.isEmpty) {
            debugPrint('⚠️ No students found for supervisor routes');
            return <AbsenceModel>[];
          }

          // Get pending absences with simple query
          final absencesSnapshot = await _firestore
              .collection('absences')
              .where('status', isEqualTo: 'pending')
              .get();

          debugPrint('📊 Found ${absencesSnapshot.docs.length} total pending absences');

          // Filter by student IDs locally
          final absences = absencesSnapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .where((absence) => allStudentIds.contains(absence.studentId))
              .toList();

          debugPrint('📊 Found ${absences.length} pending absences for supervisor students');
          debugPrint('👥 Student IDs: $allStudentIds');
          return absences;
        });
  }

  // Get today's absences for specific supervisor (index-safe approach)
  Stream<List<AbsenceModel>> getTodayAbsencesForSupervisor(String supervisorId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _firestore
        .collection('supervisor_assignments')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((assignmentSnapshot) async {
          debugPrint('🔍 Getting today absences for supervisor: $supervisorId');

          if (assignmentSnapshot.docs.isEmpty) {
            debugPrint('⚠️ No assignments found for supervisor');
            return <AbsenceModel>[];
          }

          // Get bus routes for this supervisor (with fallback to busId)
          final List<String> busRoutes = [];

          for (final doc in assignmentSnapshot.docs) {
            final data = doc.data();
            var busRoute = data['busRoute'] as String? ?? '';

            // إذا كان busRoute فارغ، احصل عليه من بيانات الباص
            if (busRoute.isEmpty) {
              final busId = data['busId'] as String? ?? '';
              if (busId.isNotEmpty) {
                try {
                  final bus = await getBusById(busId);
                  if (bus != null) {
                    busRoute = bus.route;
                    debugPrint('✅ Got busRoute from bus $busId: "$busRoute"');
                  }
                } catch (e) {
                  debugPrint('❌ Error getting bus data for $busId: $e');
                }
              }
            }

            if (busRoute.isNotEmpty) {
              busRoutes.add(busRoute);
            }
          }

          if (busRoutes.isEmpty) {
            debugPrint('⚠️ No bus routes found for supervisor');
            return <AbsenceModel>[];
          }

          debugPrint('🚌 Supervisor routes: $busRoutes');

          // Get students on these routes (avoid whereIn with multiple conditions)
          final List<String> allStudentIds = [];

          for (final route in busRoutes) {
            try {
              final studentsSnapshot = await _firestore
                  .collection('students')
                  .where('isActive', isEqualTo: true)
                  .where('busRoute', isEqualTo: route)
                  .get();

              final routeStudentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();
              allStudentIds.addAll(routeStudentIds);
              debugPrint('📍 Route $route: Found ${routeStudentIds.length} students');
            } catch (e) {
              debugPrint('❌ Error getting students for route $route: $e');
            }
          }

          if (allStudentIds.isEmpty) {
            debugPrint('⚠️ No students found for supervisor routes');
            return <AbsenceModel>[];
          }

          // Get today's absences with simple queries
          debugPrint('📅 Searching for absences between ${today.toIso8601String()} and ${tomorrow.toIso8601String()}');
          final absencesSnapshot = await _firestore
              .collection('absences')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
              .where('date', isLessThan: Timestamp.fromDate(tomorrow))
              .where('status', isEqualTo: 'approved')
              .get();

          debugPrint('📊 Found ${absencesSnapshot.docs.length} total today absences');

          // Filter by student IDs locally
          final absences = absencesSnapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .where((absence) => allStudentIds.contains(absence.studentId))
              .toList();

          debugPrint('📊 Found ${absences.length} today absences for supervisor students');
          debugPrint('👥 Student IDs: $allStudentIds');

          // Sort locally
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return absences;
        });
  }

  // Get today's absences
  Stream<List<AbsenceModel>> getTodayAbsences() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _firestore
        .collection('absences')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .snapshots()
        .map((snapshot) {
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .where((absence) => absence.status == AbsenceStatus.approved)
              .toList();

          // Sort locally
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return absences;
        });
  }

  // Get recent absence notifications (last 24 hours)
  Stream<List<AbsenceModel>> getRecentAbsenceNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('absences')
        .where('source', isEqualTo: 'parent')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .map((snapshot) {
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .toList();

          // Sort by creation date (newest first)
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return absences;
        });
  }

  // Get recent general notifications (last 24 hours)
  Stream<List<Map<String, dynamic>>> getRecentGeneralNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('notifications')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
        });
  }

  // Get combined recent notifications count
  Stream<int> getRecentNotificationsCount() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    // For now, let's just use absence notifications as they are more reliable
    // We can expand this later when we have more notification data
    return _firestore
        .collection('absences')
        .where('source', isEqualTo: 'parent')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .map((snapshot) {
          debugPrint('🔔 Recent absence notifications count: ${snapshot.docs.length}');
          return snapshot.docs.length;
        });
  }

  // Alternative method to get all recent notifications count
  Stream<int> getAllRecentNotificationsCount() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('absences')
        .where('source', isEqualTo: 'parent')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .asyncMap((absenceSnapshot) async {
          try {
            // Get general notifications count
            final notificationSnapshot = await _firestore
                .collection('notifications')
                .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
                .get();

            final totalCount = absenceSnapshot.docs.length + notificationSnapshot.docs.length;
            debugPrint('🔔 Total notifications count: $totalCount (Absences: ${absenceSnapshot.docs.length}, General: ${notificationSnapshot.docs.length})');
            return totalCount;
          } catch (e) {
            debugPrint('❌ Error getting notifications count: $e');
            return absenceSnapshot.docs.length; // Fallback to just absence count
          }
        });
  }

  // Get parent notifications count (for parent home screen)
  Stream<int> getParentNotificationsCount(String parentId) {
    if (parentId.isEmpty) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: parentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.length;
          debugPrint('🔔 Parent notifications count for $parentId: $count');
          return count;
        });
  }

  // Get admin notifications count (for admin home screen)
  Stream<int> getAdminNotificationsCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    // دمج عدة أنواع من الإشعارات للإدمن
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      try {
        int totalCount = 0;

        // 1. الإشعارات العامة
        final notificationsSnapshot = await _firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false)
            .get();
        totalCount += notificationsSnapshot.docs.length;

        // 2. طلبات الغياب المعلقة
        final absencesSnapshot = await _firestore
            .collection('absences')
            .where('status', isEqualTo: 'pending')
            .get();
        totalCount += absencesSnapshot.docs.length;

        // 3. الشكاوى الجديدة
        final complaintsSnapshot = await _firestore
            .collection('complaints')
            .where('status', isEqualTo: 'pending')
            .get();
        totalCount += complaintsSnapshot.docs.length;

        debugPrint('🔔 Total admin notifications count for ${currentUser.uid}: $totalCount');
        debugPrint('   - General notifications: ${notificationsSnapshot.docs.length}');
        debugPrint('   - Pending absences: ${absencesSnapshot.docs.length}');
        debugPrint('   - Pending complaints: ${complaintsSnapshot.docs.length}');

        return totalCount;
      } catch (e) {
        debugPrint('❌ Error getting admin notifications count: $e');
        return 0;
      }
    });
  }

  // Get supervisor notifications count (for supervisor home screen)
  Stream<int> getSupervisorNotificationsCount(String supervisorId) {
    if (supervisorId.isEmpty) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: supervisorId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.length;
          debugPrint('🔔 Supervisor notifications count for $supervisorId: $count');
          return count;
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      debugPrint('🔄 Attempting to mark notification as read: $notificationId');

      // التحقق من وجود الإشعار أولاً
      final docRef = _firestore.collection('notifications').doc(notificationId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('⚠️ Notification document does not exist: $notificationId');
        return;
      }

      // تحديث حالة القراءة
      await docRef.update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification marked as read successfully: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      throw Exception('فشل في تحديث حالة الإشعار: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  // Mark all system notifications as read (for admin)
  Future<void> markAllSystemNotificationsAsRead() async {
    try {
      debugPrint('🔄 Marking all system notifications as read...');

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      debugPrint('📊 Found ${snapshot.docs.length} unread notifications to mark as read');

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ All system notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all system notifications as read: $e');
      throw Exception('فشل في تحديث جميع الإشعارات: $e');
    }
  }

  // Mark all parent notifications as read (alias for markAllNotificationsAsRead)
  Future<void> markAllParentNotificationsAsRead(String parentId) async {
    return markAllNotificationsAsRead(parentId);
  }

  // Get supervisor notifications
  Stream<List<NotificationModel>> getSupervisorNotifications(String supervisorId) {
    if (supervisorId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: supervisorId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final notifications = <NotificationModel>[];
          for (final doc in snapshot.docs) {
            try {
              final notification = NotificationModel.fromMap(doc.data());
              notifications.add(notification);
            } catch (e) {
              debugPrint('❌ Error parsing notification ${doc.id}: $e');
            }
          }
          debugPrint('📱 Supervisor notifications loaded: ${notifications.length}');
          return notifications;
        });
  }

  // Get parent notifications
  Stream<List<NotificationModel>> getParentNotifications(String parentId) {
    if (parentId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: parentId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return NotificationModel.fromMap(doc.data());
            } catch (e) {
              debugPrint('❌ Error parsing notification ${doc.id}: $e');
              // Return null for documents that fail to parse
              return null;
            }
          }).where((notification) => notification != null).cast<NotificationModel>().toList();
        });
  }

  // Get current supervisor assignment for a bus and direction
  Future<SupervisorAssignmentModel?> getCurrentSupervisorAssignment(String busId, TripDirection direction) async {
    try {
      debugPrint('🔍 Getting supervisor assignment for bus: $busId, direction: $direction');

      // Simplified query to avoid index issues
      final query = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('📊 Found ${query.docs.length} active assignments for bus $busId');

      if (query.docs.isNotEmpty) {
        // Filter by direction and get the most recent
        SupervisorAssignmentModel? bestMatch;
        DateTime? latestDate;

        for (final doc in query.docs) {
          try {
            final assignment = SupervisorAssignmentModel.fromMap(doc.data());
            debugPrint('📋 Assignment: ${assignment.supervisorName}, direction: ${assignment.direction}, date: ${assignment.assignedAt}');

            // Check if direction matches
            if (assignment.direction == direction || assignment.direction == TripDirection.both) {
              if (latestDate == null || assignment.assignedAt.isAfter(latestDate)) {
                bestMatch = assignment;
                latestDate = assignment.assignedAt;
              }
            }
          } catch (e) {
            debugPrint('❌ Error parsing assignment document: $e');
          }
        }

        if (bestMatch != null) {
          debugPrint('✅ Found matching assignment: ${bestMatch.supervisorName}');
          return bestMatch;
        }
      }

      debugPrint('⚠️ No matching supervisor assignment found');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current supervisor assignment: $e');
      return null;
    }
  }

  // Get supervisor info for parent based on bus and current time
  Future<Map<String, String>> getSupervisorInfoForParent(String busId) async {
    try {
      debugPrint('🚌 Getting supervisor info for bus: $busId');

      // Determine current direction based on time
      final currentTime = DateTime.now();
      final currentHour = currentTime.hour;

      TripDirection currentDirection;
      if (currentHour >= 6 && currentHour <= 10) {
        currentDirection = TripDirection.toSchool;
      } else if (currentHour >= 12 && currentHour <= 18) {
        currentDirection = TripDirection.fromSchool;
      } else {
        currentDirection = TripDirection.both;
      }

      debugPrint('⏰ Current time: $currentHour:00, Direction: $currentDirection');

      // Get supervisor assignment
      final assignment = await getCurrentSupervisorAssignment(busId, currentDirection);

      if (assignment != null) {
        debugPrint('📋 Found assignment: ${assignment.supervisorName} (ID: ${assignment.supervisorId})');

        // Get supervisor details
        final supervisor = await getUserById(assignment.supervisorId);

        if (supervisor != null) {
          debugPrint('👤 Found supervisor: ${supervisor.name}, Phone: ${supervisor.phone}');
          return {
            'name': supervisor.name,
            'phone': supervisor.phone,
            'direction': assignment.directionDisplayName,
          };
        } else {
          debugPrint('❌ Supervisor user not found for ID: ${assignment.supervisorId}');
        }
      } else {
        debugPrint('⚠️ No supervisor assignment found for bus $busId with direction $currentDirection');

        // Try to get any active assignment for this bus (fallback)
        final fallbackQuery = await _firestore
            .collection('supervisor_assignments')
            .where('busId', isEqualTo: busId)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (fallbackQuery.docs.isNotEmpty) {
          final fallbackAssignment = SupervisorAssignmentModel.fromMap(fallbackQuery.docs.first.data());
          final supervisor = await getUserById(fallbackAssignment.supervisorId);

          if (supervisor != null) {
            debugPrint('🔄 Using fallback assignment: ${supervisor.name}');
            return {
              'name': supervisor.name,
              'phone': supervisor.phone,
              'direction': fallbackAssignment.directionDisplayName,
            };
          }
        }
      }

      debugPrint('❌ No supervisor info found, returning default values');
      return {
        'name': 'غير محدد',
        'phone': '',
        'direction': 'غير محدد',
      };
    } catch (e) {
      debugPrint('❌ Error getting supervisor info for parent: $e');
      return {
        'name': 'خطأ في التحميل',
        'phone': '',
        'direction': 'خطأ في التحميل',
      };
    }
  }

  // Debug function to check supervisor assignments
  Future<void> debugSupervisorAssignments(String busId) async {
    try {
      debugPrint('🔍 DEBUG: Checking all assignments for bus: $busId');

      final allAssignments = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .get();

      debugPrint('📊 Total assignments found: ${allAssignments.docs.length}');

      for (final doc in allAssignments.docs) {
        final data = doc.data();
        debugPrint('📋 Assignment: ${doc.id}');
        debugPrint('   - Supervisor: ${data['supervisorName']}');
        debugPrint('   - Direction: ${data['direction']}');
        debugPrint('   - Status: ${data['status']}');
        debugPrint('   - Assigned At: ${data['assignedAt']}');
      }

      // Check if there are any active assignments
      final activeAssignments = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('✅ Active assignments: ${activeAssignments.docs.length}');

    } catch (e) {
      debugPrint('❌ Error in debug function: $e');
    }
  }

  // Get parent complaints
  Stream<List<ComplaintModel>> getParentComplaints(String parentId) {
    if (parentId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('complaints')
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final complaints = <ComplaintModel>[];
          for (final doc in snapshot.docs) {
            try {
              final complaint = ComplaintModel.fromMap(doc.data());
              complaints.add(complaint);
            } catch (e) {
              debugPrint('❌ Error parsing complaint ${doc.id}: $e');
            }
          }
          debugPrint('📝 Parent complaints loaded: ${complaints.length}');
          return complaints;
        });
  }

  // Get supervisors assigned to parent's student buses with proper assignment validation
  Future<List<UserModel>> getSupervisorsForParent(String parentId) async {
    try {
      debugPrint('🔍 Getting supervisors for parent: $parentId');

      // Get parent's students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        debugPrint('⚠️ No students found for parent $parentId');
        return [];
      }

      final busIds = <String>{};
      for (final doc in studentsSnapshot.docs) {
        final busId = doc.data()['busId'] as String?;
        if (busId != null && busId.isNotEmpty) {
          busIds.add(busId);
          debugPrint('📍 Student ${doc.data()['name']} assigned to bus: $busId');
        }
      }

      if (busIds.isEmpty) {
        debugPrint('⚠️ No bus assignments found for parent students');
        return [];
      }

      // Get all active supervisor assignments for these buses
      final supervisorIds = <String>{};
      for (final busId in busIds) {
        final assignmentsSnapshot = await _firestore
            .collection('supervisor_assignments')
            .where('busId', isEqualTo: busId)
            .where('status', isEqualTo: 'active')
            .get();

        for (final assignmentDoc in assignmentsSnapshot.docs) {
          final supervisorId = assignmentDoc.data()['supervisorId'] as String?;
          if (supervisorId != null && supervisorId.isNotEmpty) {
            supervisorIds.add(supervisorId);
            debugPrint('👨‍🏫 Found supervisor $supervisorId for bus $busId');
          }
        }
      }

      if (supervisorIds.isEmpty) {
        debugPrint('⚠️ No supervisor assignments found for buses');
        return [];
      }

      // Get supervisor user details
      final supervisors = <UserModel>[];
      for (final supervisorId in supervisorIds) {
        final supervisorDoc = await _firestore
            .collection('users')
            .doc(supervisorId)
            .get();

        if (supervisorDoc.exists) {
          final supervisorData = supervisorDoc.data()!;
          if (supervisorData['userType'] == 'supervisor') {
            final supervisor = UserModel.fromMap(supervisorData);
            supervisors.add(supervisor);
            debugPrint('✅ Added supervisor: ${supervisor.name}');
          }
        }
      }

      debugPrint('📋 Total supervisors found: ${supervisors.length}');
      return supervisors;
    } catch (e) {
      debugPrint('❌ Error getting supervisors for parent: $e');
      return [];
    }
  }

  // Get detailed supervisor info for each student assignment
  Future<Map<String, Map<String, String>>> getSupervisorInfoForStudents(String parentId) async {
    try {
      debugPrint('🔍 Getting detailed supervisor info for parent: $parentId');

      final result = <String, Map<String, String>>{};

      // Get parent's students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final studentId = studentData['id'] as String;
        final busId = studentData['busId'] as String?;

        if (busId == null || busId.isEmpty) {
          result[studentId] = {
            'supervisorName': 'غير محدد',
            'supervisorPhone': '',
            'direction': 'غير محدد',
          };
          continue;
        }

        // Get supervisor info for this bus
        final supervisorInfo = await getSupervisorInfoForParent(busId);
        result[studentId] = supervisorInfo;
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error getting supervisor info for students: $e');
      return {};
    }
  }

  // Create supervisor evaluation
  Future<void> createSupervisorEvaluation(SupervisorEvaluationModel evaluation) async {
    try {
      await _firestore
          .collection('supervisor_evaluations')
          .doc(evaluation.id)
          .set(evaluation.toMap());

      debugPrint('✅ Supervisor evaluation created successfully: ${evaluation.id}');
    } catch (e) {
      debugPrint('❌ Error creating supervisor evaluation: $e');
      throw Exception('خطأ في حفظ التقييم: $e');
    }
  }

  // Get supervisor evaluations
  Future<List<SupervisorEvaluationModel>> getSupervisorEvaluations(String supervisorId) async {
    try {
      final snapshot = await _firestore
          .collection('supervisor_evaluations')
          .where('supervisorId', isEqualTo: supervisorId)
          .orderBy('evaluatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SupervisorEvaluationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting supervisor evaluations: $e');
      return [];
    }
  }

  // Get supervisor evaluations for a parent
  Stream<List<SupervisorEvaluationModel>> getParentSupervisorEvaluations(String parentId) {
    return _firestore
        .collection('supervisor_evaluations')
        .where('parentId', isEqualTo: parentId)
        .orderBy('evaluatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final evaluations = <SupervisorEvaluationModel>[];
          for (final doc in snapshot.docs) {
            try {
              final evaluation = SupervisorEvaluationModel.fromMap(doc.data());
              evaluations.add(evaluation);
            } catch (e) {
              debugPrint('❌ Error parsing evaluation ${doc.id}: $e');
            }
          }
          debugPrint('📊 Parent evaluations loaded: ${evaluations.length}');
          return evaluations;
        });
  }

  // Check if parent has already evaluated supervisor this month
  Future<bool> hasEvaluatedSupervisorThisMonth(
    String parentId,
    String supervisorId,
    int month,
    int year,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('supervisor_evaluations')
          .where('parentId', isEqualTo: parentId)
          .where('supervisorId', isEqualTo: supervisorId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking evaluation status: $e');
      return false;
    }
  }

  // Get students by parent ID (Future version for one-time queries)
  Future<List<StudentModel>> getStudentsByParentOnce(String parentId) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .get();

      final students = <StudentModel>[];
      for (final doc in snapshot.docs) {
        try {
          final student = StudentModel.fromMap(doc.data());
          students.add(student);
        } catch (e) {
          debugPrint('❌ Error parsing student ${doc.id}: $e');
        }
      }

      debugPrint('👨‍👩‍👧‍👦 Found ${students.length} students for parent $parentId');
      return students;
    } catch (e) {
      debugPrint('❌ Error getting students by parent: $e');
      return [];
    }
  }

  // Get supervisor evaluations by month for admin reports
  Future<List<SupervisorEvaluationModel>> getSupervisorEvaluationsByMonth(int month, int year) async {
    try {
      final snapshot = await _firestore
          .collection('supervisor_evaluations')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      final evaluations = <SupervisorEvaluationModel>[];
      for (final doc in snapshot.docs) {
        try {
          final evaluation = SupervisorEvaluationModel.fromMap(doc.data());
          evaluations.add(evaluation);
        } catch (e) {
          debugPrint('❌ Error parsing supervisor evaluation ${doc.id}: $e');
        }
      }

      debugPrint('📊 Supervisor evaluations for $month/$year: ${evaluations.length}');
      return evaluations;
    } catch (e) {
      debugPrint('❌ Error getting supervisor evaluations by month: $e');
      return [];
    }
  }

  // Get behavior evaluations by month for admin reports
  Future<List<StudentBehaviorEvaluation>> getBehaviorEvaluationsByMonth(int month, int year) async {
    try {
      final snapshot = await _firestore
          .collection('behavior_evaluations')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      final evaluations = <StudentBehaviorEvaluation>[];
      for (final doc in snapshot.docs) {
        try {
          final evaluation = StudentBehaviorEvaluation.fromMap(doc.data());
          evaluations.add(evaluation);
        } catch (e) {
          debugPrint('❌ Error parsing behavior evaluation ${doc.id}: $e');
        }
      }

      debugPrint('📊 Behavior evaluations for $month/$year: ${evaluations.length}');
      return evaluations;
    } catch (e) {
      debugPrint('❌ Error getting behavior evaluations by month: $e');
      return [];
    }
  }

  // Get assignment statistics for admin dashboard
  Future<Map<String, dynamic>> getAssignmentStatistics() async {
    try {
      // Get all assignments
      final assignmentsSnapshot = await _firestore
          .collection('supervisor_assignments')
          .get();

      // Get all buses
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('isActive', isEqualTo: true)
          .get();

      // Get all active supervisors only
      final supervisorsSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'supervisor')
          .where('isActive', isEqualTo: true)
          .get();

      final totalAssignments = assignmentsSnapshot.docs.length;
      final totalBuses = busesSnapshot.docs.length;
      final totalSupervisors = supervisorsSnapshot.docs.length;

      // Count assigned buses
      final assignedBusIds = <String>{};
      int emergencyAssignments = 0;

      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        final busId = data['busId'] as String?;
        final isEmergency = data['isEmergency'] as bool? ?? false;

        if (busId != null) {
          assignedBusIds.add(busId);
        }

        if (isEmergency) {
          emergencyAssignments++;
        }
      }

      final unassignedBuses = totalBuses - assignedBusIds.length;

      return {
        'totalAssignments': totalAssignments,
        'activeAssignments': totalAssignments, // For now, all are considered active
        'emergencyAssignments': emergencyAssignments,
        'unassignedBuses': unassignedBuses,
        'totalSupervisors': totalSupervisors,
        'availableSupervisors': totalSupervisors, // For now, all are considered available
      };
    } catch (e) {
      debugPrint('❌ Error getting assignment statistics: $e');
      return {
        'totalAssignments': 0,
        'activeAssignments': 0,
        'emergencyAssignments': 0,
        'unassignedBuses': 0,
        'totalSupervisors': 0,
        'availableSupervisors': 0,
      };
    }
  }

  // Get all absences stream (for debugging)
  Stream<List<AbsenceModel>> getAllAbsencesStream() {
    return _firestore
        .collection('absences')
        .snapshots()
        .map((snapshot) {
          debugPrint('📊 All absences snapshot: ${snapshot.docs.length} documents');

          final absences = <AbsenceModel>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final absence = AbsenceModel.fromMap(data);
              absences.add(absence);
              debugPrint('📋 Found absence: ${absence.studentName} - ${absence.status.toString().split('.').last}');
            } catch (e) {
              debugPrint('❌ Error parsing absence ${doc.id}: $e');
            }
          }

          // Sort by creation date
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          debugPrint('✅ Returning ${absences.length} absences');
          return absences;
        });
  }

  // Debug function to check absences statistics
  Future<void> debugAllAbsences() async {
    try {
      debugPrint('🔍 === Absence Statistics ===');

      final snapshot = await _firestore.collection('absences').get();
      debugPrint('📊 Total absences: ${snapshot.docs.length}');

      // Count by status
      final pendingCount = snapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
      final approvedCount = snapshot.docs.where((doc) => doc.data()['status'] == 'approved').length;
      final rejectedCount = snapshot.docs.where((doc) => doc.data()['status'] == 'rejected').length;

      debugPrint('⏳ Pending: $pendingCount');
      debugPrint('✅ Approved: $approvedCount');
      debugPrint('❌ Rejected: $rejectedCount');

    } catch (e) {
      debugPrint('❌ Error getting absence statistics: $e');
    }
  }

  // Approve absence
  Future<void> approveAbsence(String absenceId, String approvedBy) async {
    try {
      debugPrint('🔄 Approving absence: $absenceId by $approvedBy');

      await _firestore.collection('absences').doc(absenceId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Absence approved successfully: $absenceId');
    } catch (e) {
      debugPrint('❌ Error approving absence: $e');
      throw Exception('فشل في الموافقة على الغياب: $e');
    }
  }

  // Reject absence
  Future<void> rejectAbsence(String absenceId, String rejectedBy, String reason) async {
    try {
      await _firestore.collection('absences').doc(absenceId).update({
        'status': 'rejected',
        'approvedBy': rejectedBy,
        'approvedAt': Timestamp.now(),
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });
      debugPrint('✅ Absence rejected successfully');
    } catch (e) {
      debugPrint('❌ Error rejecting absence: $e');
      throw Exception('فشل في رفض الغياب: $e');
    }
  }

  // Update absence status (generic method)
  Future<void> updateAbsenceStatus(String absenceId, AbsenceStatus status, String userId) async {
    try {
      debugPrint('🔄 Updating absence status: $absenceId to ${status.toString().split('.').last}');

      // Get absence data first
      final absenceDoc = await _firestore.collection('absences').doc(absenceId).get();
      if (!absenceDoc.exists) {
        throw Exception('طلب الغياب غير موجود');
      }

      final absenceData = absenceDoc.data()!;

      await _firestore.collection('absences').doc(absenceId).update({
        'status': status.toString().split('.').last,
        'approvedBy': userId,
        'approvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // إرسال إشعار تحديث حالة الغياب
      await NotificationService().sendStudentAbsenceNotification(
        studentId: absenceData['studentId'] ?? '',
        studentName: absenceData['studentName'] ?? 'طالب',
        parentId: absenceData['parentId'] ?? '',
        reason: absenceData['reason'] ?? 'غير محدد',
        date: (absenceData['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: status.toString().split('.').last,
      );

      debugPrint('✅ Absence status updated successfully: $absenceId');
    } catch (e) {
      debugPrint('❌ Error updating absence status: $e');
      throw Exception('فشل في تحديث حالة الغياب: $e');
    }
  }

  // Get absence statistics
  Future<Map<String, int>> getAbsenceStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection('absences');

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final absences = snapshot.docs.map((doc) => AbsenceModel.fromMap(doc.data() as Map<String, dynamic>)).toList();

      return {
        'total': absences.length,
        'pending': absences.where((a) => a.status == AbsenceStatus.pending).length,
        'approved': absences.where((a) => a.status == AbsenceStatus.approved).length,
        'rejected': absences.where((a) => a.status == AbsenceStatus.rejected).length,
        'sick': absences.where((a) => a.type == AbsenceType.sick).length,
        'family': absences.where((a) => a.type == AbsenceType.family).length,
        'travel': absences.where((a) => a.type == AbsenceType.travel).length,
        'emergency': absences.where((a) => a.type == AbsenceType.emergency).length,
        'other': absences.where((a) => a.type == AbsenceType.other).length,
      };
    } catch (e) {
      debugPrint('❌ Error getting absence statistics: $e');
      return {};
    }
  }



  // ==================== USER MANAGEMENT ====================

  // Get all supervisors
  Future<List<UserModel>> getAllSupervisors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'supervisor')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting supervisors: $e');
      return [];
    }
  }

  // Create new supervisor
  Future<void> createSupervisor({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      final userModel = UserModel(
        id: userId,
        name: name,
        email: email,
        phone: phone,
        userType: UserType.supervisor,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(userModel.toMap());

      debugPrint('✅ Supervisor created successfully: $name');
    } catch (e) {
      debugPrint('❌ Error creating supervisor: $e');
      throw Exception('خطأ في إنشاء المشرف: $e');
    }
  }

  // Get all admins
  Future<List<UserModel>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting admins: $e');
      return [];
    }
  }

  // Survey Collection Methods

  /// Create new survey
  Future<String> createSurvey(SurveyModel survey) async {
    try {
      final surveyId = survey.id.isNotEmpty ? survey.id : _uuid.v4();
      final surveyWithId = survey.copyWith(id: surveyId);

      await _firestore
          .collection('surveys')
          .doc(surveyId)
          .set(surveyWithId.toMap());

      debugPrint('✅ Survey created successfully: $surveyId');
      return surveyId;
    } catch (e) {
      debugPrint('❌ Error creating survey: $e');
      rethrow;
    }
  }

  /// Get all surveys
  Stream<List<SurveyModel>> getAllSurveys() {
    return _firestore
        .collection('surveys')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyModel.fromMap(doc.data()))
            .toList());
  }

  /// Get surveys by type
  Stream<List<SurveyModel>> getSurveysByType(SurveyType type) {
    return _firestore
        .collection('surveys')
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyModel.fromMap(doc.data()))
            .toList());
  }

  /// Get active surveys for user type
  Stream<List<SurveyModel>> getActiveSurveysForUser(String userType) {
    SurveyType? targetType;
    switch (userType) {
      case 'parent':
        targetType = SurveyType.parentFeedback;
        break;
      case 'supervisor':
        targetType = SurveyType.supervisorMonthly;
        break;
      default:
        return Stream.value([]);
    }

    // Simplified query to avoid index requirements
    return _firestore
        .collection('surveys')
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: targetType.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
          final surveys = snapshot.docs
              .map((doc) => SurveyModel.fromMap(doc.data()))
              .where((survey) =>
                  survey.status == SurveyStatus.active &&
                  !survey.isExpired)
              .toList();

          // Sort manually to avoid compound index requirement
          surveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return surveys;
        });
  }

  /// Submit survey response
  Future<String> submitSurveyResponse(SurveyResponse response) async {
    try {
      final responseId = response.id.isNotEmpty ? response.id : _uuid.v4();
      final responseWithId = SurveyResponse(
        id: responseId,
        surveyId: response.surveyId,
        respondentId: response.respondentId,
        respondentName: response.respondentName,
        respondentType: response.respondentType,
        answers: response.answers,
        submittedAt: response.submittedAt,
        isComplete: response.isComplete,
      );

      await _firestore
          .collection('survey_responses')
          .doc(responseId)
          .set(responseWithId.toMap());

      debugPrint('✅ Survey response submitted successfully: $responseId');
      return responseId;
    } catch (e) {
      debugPrint('❌ Error submitting survey response: $e');
      rethrow;
    }
  }

  /// Get survey responses
  Stream<List<SurveyResponse>> getSurveyResponses(String surveyId) {
    return _firestore
        .collection('survey_responses')
        .where('surveyId', isEqualTo: surveyId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyResponse.fromMap(doc.data()))
            .toList());
  }

  /// Get student trips for a specific date
  Future<List<TripModel>> getStudentTrips(String studentId, DateTime date) async {
    try {
      // Get start and end of the selected date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('trips')
          .where('studentId', isEqualTo: studentId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TripModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting student trips: $e');
      return [];
    }
  }

  /// Check if user has responded to survey
  Future<bool> hasUserRespondedToSurvey(String surveyId, String userId) async {
    try {
      final response = await _firestore
          .collection('survey_responses')
          .where('surveyId', isEqualTo: surveyId)
          .where('respondentId', isEqualTo: userId)
          .limit(1)
          .get();

      return response.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking survey response: $e');
      return false;
    }
  }

  /// Update survey status
  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status) async {
    try {
      await _firestore
          .collection('surveys')
          .doc(surveyId)
          .update({
            'status': status.toString().split('.').last,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Survey status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating survey status: $e');
      rethrow;
    }
  }

  /// Get survey statistics
  Future<Map<String, dynamic>> getSurveyStatistics(String surveyId) async {
    try {
      final responses = await _firestore
          .collection('survey_responses')
          .where('surveyId', isEqualTo: surveyId)
          .get();

      final totalResponses = responses.docs.length;
      final responsesByType = <String, int>{};

      for (final doc in responses.docs) {
        final data = doc.data();
        final type = data['respondentType'] ?? 'unknown';
        responsesByType[type] = (responsesByType[type] ?? 0) + 1;
      }

      return {
        'totalResponses': totalResponses,
        'responsesByType': responsesByType,
        'lastResponseDate': responses.docs.isNotEmpty
            ? responses.docs.first.data()['submittedAt']
            : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting survey statistics: $e');
      return {
        'totalResponses': 0,
        'responsesByType': <String, int>{},
        'lastResponseDate': null,
      };
    }
  }

  // Supervisor Assignment Methods

  /// Create new supervisor assignment
  Future<String> createSupervisorAssignment(SupervisorAssignmentModel assignment) async {
    try {
      final assignmentId = assignment.id.isNotEmpty ? assignment.id : _uuid.v4();
      final assignmentWithId = assignment.copyWith(id: assignmentId);

      await _firestore
          .collection('supervisor_assignments')
          .doc(assignmentId)
          .set(assignmentWithId.toMap());

      debugPrint('✅ Supervisor assignment created successfully: $assignmentId');
      return assignmentId;
    } catch (e) {
      debugPrint('❌ Error creating supervisor assignment: $e');
      rethrow;
    }
  }

  /// Get all supervisor assignments
  Stream<List<SupervisorAssignmentModel>> getAllSupervisorAssignments() {
    return _firestore
        .collection('supervisor_assignments')
        .snapshots()
        .map((snapshot) {
          final assignments = snapshot.docs
              .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
              .toList();

          // Sort manually to avoid index requirements
          assignments.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
          return assignments;
        });
  }

  /// Get active supervisor assignments
  Stream<List<SupervisorAssignmentModel>> getActiveSupervisorAssignments() {
    return _firestore
        .collection('supervisor_assignments')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final assignments = snapshot.docs
              .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
              .toList();

          // Sort manually to avoid index requirements
          assignments.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
          return assignments;
        });
  }

  /// Get assignments for specific supervisor
  Stream<List<SupervisorAssignmentModel>> getSupervisorAssignments(String supervisorId) {
    return _firestore
        .collection('supervisor_assignments')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'active')
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
            .toList());
  }

  /// Get assignments for specific supervisor (simple version without orderBy to avoid index issues)
  Future<List<SupervisorAssignmentModel>> getSupervisorAssignmentsSimple(String supervisorId) async {
    try {
      debugPrint('🔍 Getting simple assignments for supervisor: $supervisorId');

      // الطريقة الأولى: البحث بـ supervisorId و status = active
      var snapshot = await _firestore
          .collection('supervisor_assignments')
          .where('supervisorId', isEqualTo: supervisorId)
          .where('status', isEqualTo: 'active')
          .get();

      var assignments = snapshot.docs
          .map((doc) {
            final data = doc.data();
            debugPrint('📄 Assignment data: $data');
            return SupervisorAssignmentModel.fromMap(data);
          })
          .toList();

      debugPrint('📋 Found ${assignments.length} active assignments for supervisor $supervisorId');

      // إذا لم نجد تعيينات نشطة، جرب البحث بدون قيد status
      if (assignments.isEmpty) {
        debugPrint('🔍 No active assignments found, trying without status filter...');
        snapshot = await _firestore
            .collection('supervisor_assignments')
            .where('supervisorId', isEqualTo: supervisorId)
            .get();

        assignments = snapshot.docs
            .map((doc) {
              final data = doc.data();
              debugPrint('📄 Assignment data (any status): $data');
              return SupervisorAssignmentModel.fromMap(data);
            })
            .toList();

        debugPrint('📋 Found ${assignments.length} total assignments for supervisor $supervisorId');
      }

      // إذا لم نجد أي تعيينات، جرب البحث في جميع التعيينات
      if (assignments.isEmpty) {
        debugPrint('🔍 No assignments found by supervisorId, checking all assignments...');
        snapshot = await _firestore
            .collection('supervisor_assignments')
            .get();

        final allAssignments = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return SupervisorAssignmentModel.fromMap(data);
            })
            .toList();

        debugPrint('📊 Total assignments in database: ${allAssignments.length}');
        for (final assignment in allAssignments) {
          debugPrint('   - Assignment: supervisorId=${assignment.supervisorId}, busRoute="${assignment.busRoute}", status=${assignment.status}');
        }

        // فلترة بناءً على supervisorId مع مرونة أكثر
        assignments = allAssignments.where((assignment) {
          return assignment.supervisorId == supervisorId;
        }).toList();

        debugPrint('📋 Found ${assignments.length} assignments after manual filtering');
      }

      // Sort manually to avoid index requirement
      if (assignments.isNotEmpty) {
        assignments.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      }

      debugPrint('📋 Final result: ${assignments.length} assignments for supervisor $supervisorId');
      for (final assignment in assignments) {
        debugPrint('   - Assignment: busId="${assignment.busId}", busRoute="${assignment.busRoute}", busPlate="${assignment.busPlateNumber}", status="${assignment.status}"');
      }

      return assignments;
    } catch (e) {
      debugPrint('❌ Error getting supervisor assignments: $e');
      return [];
    }
  }

  /// Get assignments for specific bus
  Stream<List<SupervisorAssignmentModel>> getBusAssignments(String busId) {
    return _firestore
        .collection('supervisor_assignments')
        .where('busId', isEqualTo: busId)
        .where('status', isEqualTo: 'active')
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
            .toList());
  }

  /// Get supervisor assignments by bus route
  Stream<List<SupervisorAssignmentModel>> getSupervisorAssignmentsByRoute(String busRoute) {
    return _firestore
        .collection('supervisor_assignments')
        .where('busRoute', isEqualTo: busRoute)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final assignments = snapshot.docs
              .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
              .toList();

          // Sort manually to avoid index requirements
          assignments.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
          return assignments;
        });
  }

  /// Get supervisor assignments by bus ID
  Future<List<SupervisorAssignmentModel>> getSupervisorAssignmentsByBusId(String busId) async {
    try {
      final snapshot = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting supervisor assignments by bus ID: $e');
      return [];
    }
  }

  /// Get active supervisor for a specific bus route and direction
  Future<SupervisorAssignmentModel?> getActiveSupervisorForRoute(
    String busRoute, {
    TripDirection? direction,
  }) async {
    try {
      debugPrint('🔍 Looking for supervisor for route: $busRoute, direction: $direction');

      // Get all active supervisor assignments
      final querySnapshot = await _firestore
          .collection('supervisor_assignments')
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('📋 Found ${querySnapshot.docs.length} active assignments');

      for (final doc in querySnapshot.docs) {
        final assignment = SupervisorAssignmentModel.fromMap(doc.data());
        debugPrint('🔍 Checking assignment: ${assignment.supervisorName} - Route: ${assignment.busRoute} - Direction: ${assignment.direction}');

        // Check if route matches
        bool routeMatches = assignment.busRoute == busRoute;

        // If route doesn't match directly, try to get bus by ID and check route
        if (!routeMatches && assignment.busId.isNotEmpty) {
          try {
            final busDoc = await _firestore.collection('buses').doc(assignment.busId).get();
            if (busDoc.exists) {
              final busData = busDoc.data()!;
              final busRouteFromBus = busData['route'] ?? '';
              routeMatches = busRouteFromBus == busRoute;
              debugPrint('🚌 Bus route from bus doc: $busRouteFromBus, matches: $routeMatches');
            }
          } catch (e) {
            debugPrint('⚠️ Error getting bus data: $e');
          }
        }

        if (routeMatches) {
          // Check direction compatibility
          if (direction == null) {
            // If no specific direction requested, return any supervisor for this route
            debugPrint('✅ Found supervisor (any direction): ${assignment.supervisorName}');
            return assignment;
          } else {
            // Check if supervisor handles this direction
            bool directionMatches = assignment.direction == direction || assignment.direction == TripDirection.both;
            debugPrint('🧭 Direction check - Assignment: ${assignment.direction}, Requested: $direction, Matches: $directionMatches');

            if (directionMatches) {
              debugPrint('✅ Found supervisor for route and direction: ${assignment.supervisorName}');
              return assignment;
            }
          }
        }
      }

      debugPrint('⚠️ No active supervisor found for route: $busRoute, direction: $direction');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting active supervisor for route: $e');
      return null;
    }
  }

  /// Get supervisor for parent's student route and direction
  Future<SupervisorAssignmentModel?> getSupervisorForParentStudent(
    String parentId, {
    TripDirection? direction,
  }) async {
    try {
      debugPrint('🔍 Looking for supervisor for parent: $parentId, direction: $direction');

      // Get parent's students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        debugPrint('⚠️ No active students found for parent: $parentId');
        return null;
      }

      // Try each student until we find a supervisor
      for (final studentDoc in studentsSnapshot.docs) {
        final student = StudentModel.fromMap(studentDoc.data());
        debugPrint('👨‍👩‍👧‍👦 Checking student: ${student.name}, route: ${student.busRoute}, busId: ${student.busId}');

        // Try to get supervisor by route first
        var supervisor = await getActiveSupervisorForRoute(student.busRoute, direction: direction);

        if (supervisor != null) {
          debugPrint('✅ Found supervisor via route for student: ${student.name}');
          return supervisor;
        }

        // If not found by route, try by busId
        if (student.busId.isNotEmpty) {
          final assignmentsSnapshot = await _firestore
              .collection('supervisor_assignments')
              .where('busId', isEqualTo: student.busId)
              .where('status', isEqualTo: 'active')
              .get();

          for (final assignmentDoc in assignmentsSnapshot.docs) {
            final assignment = SupervisorAssignmentModel.fromMap(assignmentDoc.data());

            // Check direction compatibility
            if (direction == null || assignment.direction == direction || assignment.direction == TripDirection.both) {
              debugPrint('✅ Found supervisor via busId for student: ${student.name}');
              return assignment;
            }
          }
        }
      }

      debugPrint('⚠️ No supervisor found for any student of parent: $parentId');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting supervisor for parent student: $e');
      return null;
    }
  }

  /// Get active supervisor for a specific bus ID and direction
  Future<SupervisorAssignmentModel?> getActiveSupervisorForBus(
    String busId, {
    TripDirection? direction,
  }) async {
    try {
      debugPrint('🔍 Looking for supervisor for busId: $busId, direction: $direction');

      final querySnapshot = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('📋 Found ${querySnapshot.docs.length} active assignments for bus: $busId');

      for (final doc in querySnapshot.docs) {
        final assignment = SupervisorAssignmentModel.fromMap(doc.data());
        debugPrint('🔍 Checking assignment: ${assignment.supervisorName} - Direction: ${assignment.direction}');

        // Check direction compatibility
        if (direction == null) {
          // If no specific direction requested, return any supervisor for this bus
          debugPrint('✅ Found supervisor (any direction): ${assignment.supervisorName}');
          return assignment;
        } else {
          // Check if supervisor handles this direction
          bool directionMatches = assignment.direction == direction || assignment.direction == TripDirection.both;
          debugPrint('🧭 Direction check - Assignment: ${assignment.direction}, Requested: $direction, Matches: $directionMatches');

          if (directionMatches) {
            debugPrint('✅ Found supervisor for bus and direction: ${assignment.supervisorName}');
            return assignment;
          }
        }
      }

      debugPrint('⚠️ No active supervisor found for busId: $busId, direction: $direction');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting active supervisor for bus: $e');
      return null;
    }
  }

  /// Get students by bus route
  Stream<List<StudentModel>> getStudentsByRoute(String busRoute) {
    return _firestore
        .collection('students')
        .where('busRoute', isEqualTo: busRoute)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final students = snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList();

          // Sort manually by name
          students.sort((a, b) => a.name.compareTo(b.name));
          return students;
        });
  }

  /// Get students by bus route (simple version to avoid index issues)
  /// Returns only students who are assigned to a bus (have busRoute or busId)
  Future<List<StudentModel>> getStudentsByRouteSimple(String busRoute) async {
    try {
      debugPrint('🔍 Getting assigned students for route: "$busRoute"');

      if (busRoute.isEmpty) {
        debugPrint('⚠️ Bus route is empty');
        return [];
      }

      // البحث الأساسي باستخدام busRoute (فقط الطلاب المسكنين)
      final snapshot = await _firestore
          .collection('students')
          .where('busRoute', isEqualTo: busRoute)
          .get();

      debugPrint('📊 Query result: ${snapshot.docs.length} documents found');

      final students = snapshot.docs
          .map((doc) {
            final data = doc.data();
            debugPrint('👤 Student: ${data['name']} - busRoute: "${data['busRoute']}" - busId: "${data['busId']}" - isActive: ${data['isActive']}');
            return StudentModel.fromMap(data);
          })
          .where((student) {
            // فقط الطلاب المسكنين في خط سير (لديهم busRoute أو busId)
            final isAssigned = student.busRoute.isNotEmpty || student.busId.isNotEmpty;
            if (!isAssigned) {
              debugPrint('⚠️ Student ${student.name} is not assigned to any bus');
            }
            return isAssigned;
          })
          .toList();

      // Sort manually by name
      students.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('👥 Found ${students.length} assigned students for route "$busRoute"');

      // إذا لم نجد طلاب، جرب البحث باستخدام busId
      if (students.isEmpty) {
        debugPrint('🔍 No students found by route, trying to find by busId...');
        return await getStudentsByBusIdSimple(busRoute); // قد يكون busRoute هو في الواقع busId
      }

      return students;
    } catch (e) {
      debugPrint('❌ Error getting students for route: $e');
      return [];
    }
  }

  /// Get students by bus ID (Future version)
  /// Returns only students who are assigned to a bus (have busRoute or busId)
  Future<List<StudentModel>> getStudentsByBusIdSimple(String busId) async {
    try {
      debugPrint('🔍 Getting assigned students for busId: "$busId"');

      if (busId.isEmpty) {
        debugPrint('⚠️ Bus ID is empty');
        return [];
      }

      final snapshot = await _firestore
          .collection('students')
          .where('busId', isEqualTo: busId)
          .get();

      debugPrint('📊 Query result for busId: ${snapshot.docs.length} documents found');

      final students = snapshot.docs
          .map((doc) {
            final data = doc.data();
            debugPrint('👤 Student: ${data['name']} - busRoute: "${data['busRoute']}" - busId: "${data['busId']}" - isActive: ${data['isActive']}');
            return StudentModel.fromMap(data);
          })
          .where((student) {
            // فقط الطلاب المسكنين في خط سير (لديهم busRoute أو busId)
            final isAssigned = student.busRoute.isNotEmpty || student.busId.isNotEmpty;
            if (!isAssigned) {
              debugPrint('⚠️ Student ${student.name} is not assigned to any bus');
            }
            return isAssigned;
          })
          .toList();

      // Sort manually by name
      students.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('👥 Found ${students.length} assigned students for busId "$busId"');
      return students;
    } catch (e) {
      debugPrint('❌ Error getting students for busId: $e');
      return [];
    }
  }

  /// Get today absences for supervisor (simple version)
  Future<List<AbsenceModel>> getTodayAbsencesForSupervisorSimple(String supervisorId) async {
    try {
      debugPrint('📅 Getting today absences for supervisor: $supervisorId');

      // Get supervisor assignments first
      final assignments = await getSupervisorAssignmentsSimple(supervisorId);
      if (assignments.isEmpty) {
        debugPrint('⚠️ No assignments found for supervisor');
        return [];
      }

      final assignment = assignments.first;
      var busRoute = assignment.busRoute;

      // Get busRoute from bus if empty
      if (busRoute.isEmpty) {
        final bus = await getBusById(assignment.busId);
        if (bus != null) {
          busRoute = bus.route;
        }
      }

      if (busRoute.isEmpty) {
        debugPrint('❌ No valid busRoute found');
        return [];
      }

      // Get students for this route
      final students = await getStudentsByRouteSimple(busRoute);
      final studentIds = students.map((s) => s.id).toList();

      if (studentIds.isEmpty) {
        return [];
      }

      // Get today's date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get absences for today
      final snapshot = await _firestore
          .collection('absences')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final absences = snapshot.docs
          .map((doc) => AbsenceModel.fromMap(doc.data()))
          .where((absence) => studentIds.contains(absence.studentId))
          .toList();

      debugPrint('📅 Found ${absences.length} today absences');
      return absences;
    } catch (e) {
      debugPrint('❌ Error getting today absences: $e');
      return [];
    }
  }

  /// Get absences in date range for supervisor (simple version)
  Future<List<AbsenceModel>> getAbsencesInDateRangeSimple(
    String supervisorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint('📅 Getting absences for supervisor $supervisorId from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // Get supervisor assignments first
      final assignments = await getSupervisorAssignmentsSimple(supervisorId);
      if (assignments.isEmpty) {
        debugPrint('⚠️ No assignments found for supervisor');
        return [];
      }

      final assignment = assignments.first;
      var busRoute = assignment.busRoute;

      // Get busRoute from bus if empty
      if (busRoute.isEmpty) {
        final bus = await getBusById(assignment.busId);
        if (bus != null) {
          busRoute = bus.route;
        }
      }

      if (busRoute.isEmpty) {
        debugPrint('❌ No valid busRoute found');
        return [];
      }

      // Get students for this route
      final students = await getStudentsByRouteSimple(busRoute);
      final studentIds = students.map((s) => s.id).toList();

      if (studentIds.isEmpty) {
        return [];
      }

      // Get absences in date range
      final snapshot = await _firestore
          .collection('absences')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final absences = snapshot.docs
          .map((doc) => AbsenceModel.fromMap(doc.data()))
          .where((absence) => studentIds.contains(absence.studentId))
          .toList();

      debugPrint('📅 Found ${absences.length} absences in date range');
      return absences;
    } catch (e) {
      debugPrint('❌ Error getting absences in date range: $e');
      return [];
    }
  }

  /// Get students for supervisor based on their assignments (index-safe approach)
  Stream<List<StudentModel>> getStudentsForSupervisor(String supervisorId) {
    debugPrint('🔍 Getting students for supervisor: $supervisorId');

    return _firestore
        .collection('supervisor_assignments')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((assignmentSnapshot) async {
          debugPrint('📋 Found ${assignmentSnapshot.docs.length} assignments for supervisor $supervisorId');

          if (assignmentSnapshot.docs.isEmpty) {
            debugPrint('⚠️ No assignments found for supervisor $supervisorId');
            return <StudentModel>[];
          }

          // Get bus routes for this supervisor
          final busRoutes = assignmentSnapshot.docs
              .map((doc) {
                final data = doc.data();
                final busRoute = data['busRoute'] as String? ?? '';
                final busPlateNumber = data['busPlateNumber'] as String? ?? '';
                debugPrint('🚌 Supervisor assigned to route: $busRoute (Bus: $busPlateNumber)');
                return busRoute;
              })
              .where((route) => route.isNotEmpty)
              .toSet()
              .toList();

          if (busRoutes.isEmpty) {
            debugPrint('⚠️ No bus routes found for supervisor $supervisorId');
            return <StudentModel>[];
          }

          debugPrint('🔍 Looking for students on routes: $busRoutes');

          // Get students for each route separately to avoid index requirements
          final List<StudentModel> allStudents = [];

          for (final route in busRoutes) {
            try {
              final routeStudentsSnapshot = await _firestore
                  .collection('students')
                  .where('isActive', isEqualTo: true)
                  .where('busRoute', isEqualTo: route)
                  .get();

              final routeStudents = routeStudentsSnapshot.docs
                  .map((doc) => StudentModel.fromMap(doc.data()))
                  .toList();

              debugPrint('📍 Route $route: Found ${routeStudents.length} students');
              allStudents.addAll(routeStudents);
            } catch (e) {
              debugPrint('❌ Error getting students for route $route: $e');
            }
          }

          // Remove duplicates based on student ID
          final uniqueStudents = <String, StudentModel>{};
          for (final student in allStudents) {
            uniqueStudents[student.id] = student;
          }

          final students = uniqueStudents.values.toList();
          students.sort((a, b) => a.name.compareTo(b.name));

          debugPrint('👥 Found ${students.length} unique students on supervisor routes');
          for (final student in students) {
            debugPrint('   - ${student.name} (Route: ${student.busRoute}, Status: ${student.currentStatus})');
          }

          return students;
        });
  }

  /// Get absences in date range for supervisor (index-safe approach)
  Future<List<AbsenceModel>> getAbsencesInDateRange(
    String supervisorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint('🔍 Getting absences for supervisor $supervisorId from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // First get all absences for this supervisor (simple query)
      final querySnapshot = await _firestore
          .collection('absences')
          .where('supervisorId', isEqualTo: supervisorId)
          .get();

      // Filter by date range locally to avoid compound index requirement
      final absences = querySnapshot.docs
          .map((doc) => AbsenceModel.fromMap(doc.data()))
          .where((absence) {
            final absenceDate = absence.date;
            return absenceDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                   absenceDate.isBefore(endDate.add(const Duration(days: 1)));
          })
          .toList();

      debugPrint('📊 Found ${absences.length} absences in date range');
      return absences;
    } catch (e) {
      debugPrint('❌ Error getting absences in date range: $e');
      return [];
    }
  }

  /// Update supervisor assignment
  Future<void> updateSupervisorAssignment(SupervisorAssignmentModel assignment) async {
    try {
      await _firestore
          .collection('supervisor_assignments')
          .doc(assignment.id)
          .update({
            'busId': assignment.busId,
            'busPlateNumber': assignment.busPlateNumber,
            'busRoute': assignment.busRoute,
            'direction': assignment.direction.toString().split('.').last,
            'isEmergencyAssignment': assignment.isEmergencyAssignment,
            'notes': assignment.notes,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Supervisor assignment updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating supervisor assignment: $e');
      rethrow;
    }
  }

  /// Deactivate supervisor assignment
  Future<void> deactivateSupervisorAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection('supervisor_assignments')
          .doc(assignmentId)
          .update({
            'status': 'inactive',
            'unassignedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Supervisor assignment deactivated successfully');
    } catch (e) {
      debugPrint('❌ Error deactivating supervisor assignment: $e');
      rethrow;
    }
  }

  /// Create emergency assignment (temporary supervisor change)
  Future<String> createEmergencyAssignment({
    required String busId,
    required String newSupervisorId,
    required String newSupervisorName,
    required String busPlateNumber,
    required TripDirection direction,
    required String assignedBy,
    required String assignedByName,
    String? notes,
  }) async {
    try {
      // First, deactivate current assignment for this bus
      final currentAssignments = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .get();

      String? originalSupervisorId;
      for (final doc in currentAssignments.docs) {
        final data = doc.data();
        originalSupervisorId = data['supervisorId'];
        await doc.reference.update({
          'status': 'inactive',
          'unassignedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create new emergency assignment
      // Get bus route for the assignment
      final bus = await getBusById(busId);
      final busRoute = bus?.route ?? '';

      final emergencyAssignment = SupervisorAssignmentModel(
        id: _uuid.v4(),
        supervisorId: newSupervisorId,
        supervisorName: newSupervisorName,
        busId: busId,
        busPlateNumber: busPlateNumber,
        busRoute: busRoute,
        direction: direction,
        status: AssignmentStatus.emergency,
        assignedAt: DateTime.now(),
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        notes: notes,
        isEmergencyAssignment: true,
        originalSupervisorId: originalSupervisorId,
      );

      return await createSupervisorAssignment(emergencyAssignment);
    } catch (e) {
      debugPrint('❌ Error creating emergency assignment: $e');
      rethrow;
    }
  }

  // Get bus by ID
  Future<BusModel?> getBusById(String busId) async {
    try {
      final doc = await _firestore.collection('buses').doc(busId).get();
      if (doc.exists) {
        return BusModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting bus by ID: $e');
      return null;
    }
  }

  // Get bus stream for real-time updates
  Stream<BusModel?> getBusStream(String busId) {
    return _firestore
        .collection('buses')
        .doc(busId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            try {
              return BusModel.fromMap(doc.data()!);
            } catch (e) {
              debugPrint('❌ Error parsing bus data: $e');
              return null;
            }
          }
          return null;
        });
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user by ID: $e');
      return null;
    }
  }

  // Delete supervisor assignment
  Future<void> deleteSupervisorAssignment(String assignmentId) async {
    try {
      await _firestore.collection('supervisor_assignments').doc(assignmentId).delete();
      debugPrint('✅ Supervisor assignment deleted: $assignmentId');
    } catch (e) {
      debugPrint('❌ Error deleting supervisor assignment: $e');
      throw Exception('خطأ في حذف التعيين: $e');
    }
  }



  /// Get all students with their absence data for comprehensive report
  Stream<List<Map<String, dynamic>>> getAllStudentsWithAbsenceData() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((studentsSnapshot) async {
      List<Map<String, dynamic>> studentsWithAbsences = [];

      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();

        // Get absences for this student
        final absencesSnapshot = await _firestore
            .collection('absences')
            .where('studentId', isEqualTo: studentDoc.id)
            .where('source', isEqualTo: 'parent')
            .orderBy('date', descending: true)
            .get();

        final absences = absencesSnapshot.docs
            .map((doc) => AbsenceModel.fromMap(doc.data()))
            .toList();

        studentsWithAbsences.add({
          'student': studentData,
          'absences': absences,
        });
      }

      // Sort by number of absences (descending)
      studentsWithAbsences.sort((a, b) {
        final aAbsences = (a['absences'] as List).length;
        final bAbsences = (b['absences'] as List).length;
        return bAbsences.compareTo(aAbsences);
      });

      return studentsWithAbsences;
    });
  }

  // Student Behavior Evaluation Methods

  /// Create or update behavior evaluation
  Future<void> saveBehaviorEvaluation(StudentBehaviorEvaluation evaluation) async {
    try {
      final evaluationId = evaluation.id.isEmpty
          ? _uuid.v4()
          : evaluation.id;

      final updatedEvaluation = evaluation.copyWith(
        id: evaluationId,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('behavior_evaluations')
          .doc(evaluationId)
          .set(updatedEvaluation.toMap());

      debugPrint('✅ Behavior evaluation saved successfully: ${evaluation.studentName}');
    } catch (e) {
      debugPrint('❌ Error saving behavior evaluation: $e');
      throw Exception('فشل في حفظ التقييم السلوكي: $e');
    }
  }

  /// Get behavior evaluations for a supervisor in a specific month/year
  Future<List<StudentBehaviorEvaluation>> getBehaviorEvaluations({
    required String supervisorId,
    required int month,
    required int year,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('behavior_evaluations')
          .where('supervisorId', isEqualTo: supervisorId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      return snapshot.docs
          .map((doc) => StudentBehaviorEvaluation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting behavior evaluations: $e');
      return [];
    }
  }

  /// Get behavior evaluations for a specific student
  Future<List<StudentBehaviorEvaluation>> getStudentBehaviorEvaluations(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('behavior_evaluations')
          .where('studentId', isEqualTo: studentId)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudentBehaviorEvaluation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting student behavior evaluations: $e');
      return [];
    }
  }

  /// Get all behavior evaluations (for admin)
  Stream<List<StudentBehaviorEvaluation>> getAllBehaviorEvaluationsStream() {
    return _firestore
        .collection('behavior_evaluations')
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .orderBy('studentName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentBehaviorEvaluation.fromMap(doc.data()))
            .toList());
  }

  /// Delete behavior evaluation
  Future<void> deleteBehaviorEvaluation(String evaluationId) async {
    try {
      await _firestore
          .collection('behavior_evaluations')
          .doc(evaluationId)
          .delete();

      debugPrint('✅ Behavior evaluation deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting behavior evaluation: $e');
      throw Exception('فشل في حذف التقييم السلوكي: $e');
    }
  }

  // Create supervisor evaluation survey for parents
  Future<String> createSupervisorEvaluationSurvey({
    required String supervisorId,
    required String supervisorName,
    required String parentId,
    required String parentName,
  }) async {
    try {
      final surveyId = _uuid.v4();
      final now = DateTime.now();

      final survey = SurveyModel(
        id: surveyId,
        title: 'تقييم المشرف: $supervisorName',
        description: 'استبيان تقييم أداء المشرف من قبل ولي الأمر',
        type: SurveyType.supervisorEvaluation,
        status: SurveyStatus.active,
        createdBy: 'system',
        createdByName: 'النظام',
        questions: _getSupervisorEvaluationQuestions(),
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 30)), // Valid for 30 days
        isActive: true,
      );

      await _firestore
          .collection('surveys')
          .doc(surveyId)
          .set(survey.toMap());

      debugPrint('✅ Supervisor evaluation survey created: $surveyId');
      return surveyId;
    } catch (e) {
      debugPrint('❌ Error creating supervisor evaluation survey: $e');
      throw Exception('فشل في إنشاء استبيان تقييم المشرف: $e');
    }
  }

  // Get supervisor evaluation questions
  List<SurveyQuestion> _getSupervisorEvaluationQuestions() {
    return [
      const SurveyQuestion(
        id: 'communication',
        question: 'كيف تقيم مستوى التواصل مع المشرف؟',
        type: QuestionType.rating,
        options: [],
        isRequired: true,
        order: 1,
      ),
      const SurveyQuestion(
        id: 'punctuality',
        question: 'كيف تقيم التزام المشرف بالمواعيد؟',
        type: QuestionType.rating,
        options: [],
        isRequired: true,
        order: 2,
      ),
      const SurveyQuestion(
        id: 'safety',
        question: 'كيف تقيم اهتمام المشرف بسلامة الطلاب؟',
        type: QuestionType.rating,
        options: [],
        isRequired: true,
        order: 3,
      ),
      const SurveyQuestion(
        id: 'professionalism',
        question: 'كيف تقيم مستوى المهنية لدى المشرف؟',
        type: QuestionType.rating,
        options: [],
        isRequired: true,
        order: 4,
      ),
      const SurveyQuestion(
        id: 'student_care',
        question: 'كيف تقيم مستوى العناية بالطلاب؟',
        type: QuestionType.rating,
        options: [],
        isRequired: true,
        order: 5,
      ),
      const SurveyQuestion(
        id: 'overall_satisfaction',
        question: 'ما هو مستوى رضاك العام عن أداء المشرف؟',
        type: QuestionType.rating,
        options: [],
        isRequired: true,
        order: 6,
      ),
      const SurveyQuestion(
        id: 'recommend_supervisor',
        question: 'هل تنصح بهذا المشرف لأولياء أمور آخرين؟',
        type: QuestionType.yesNo,
        options: ['نعم', 'لا'],
        isRequired: true,
        order: 7,
      ),
      const SurveyQuestion(
        id: 'positive_feedback',
        question: 'ما هي الجوانب الإيجابية في أداء المشرف؟',
        type: QuestionType.text,
        options: [],
        isRequired: false,
        order: 8,
      ),
      const SurveyQuestion(
        id: 'improvement_suggestions',
        question: 'ما هي اقتراحاتك لتحسين أداء المشرف؟',
        type: QuestionType.text,
        options: [],
        isRequired: false,
        order: 9,
      ),
      const SurveyQuestion(
        id: 'additional_comments',
        question: 'أي تعليقات إضافية؟',
        type: QuestionType.text,
        options: [],
        isRequired: false,
        order: 10,
      ),
    ];
  }

  // Get supervisor evaluation surveys for admin reports
  Stream<List<Map<String, dynamic>>> getSupervisorEvaluationReports() {
    return _firestore
        .collection('survey_responses')
        .where('surveyType', isEqualTo: 'supervisorEvaluation')
        .snapshots()
        .map((snapshot) {
          final responses = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();

          responses.sort((a, b) =>
              (b['submittedAt'] as Timestamp).compareTo(a['submittedAt'] as Timestamp));
          return responses;
        });
  }

  // Get supervisor evaluation statistics
  Future<Map<String, dynamic>> getSupervisorEvaluationStats(String supervisorId) async {
    try {
      final snapshot = await _firestore
          .collection('survey_responses')
          .where('surveyType', isEqualTo: 'supervisorEvaluation')
          .where('supervisorId', isEqualTo: supervisorId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalResponses': 0,
          'averageRating': 0.0,
          'categoryAverages': {},
          'recommendationRate': 0.0,
        };
      }

      final responses = snapshot.docs.map((doc) => doc.data()).toList();
      final totalResponses = responses.length;

      // Calculate averages for each category
      final categoryTotals = <String, double>{};
      final categoryCounts = <String, int>{};
      int recommendCount = 0;

      for (final response in responses) {
        final answers = response['answers'] as Map<String, dynamic>? ?? {};

        // Process rating questions
        for (final entry in answers.entries) {
          if (entry.key.contains('communication') ||
              entry.key.contains('punctuality') ||
              entry.key.contains('safety') ||
              entry.key.contains('professionalism') ||
              entry.key.contains('student_care') ||
              entry.key.contains('overall_satisfaction')) {

            final rating = double.tryParse(entry.value.toString()) ?? 0.0;
            categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0.0) + rating;
            categoryCounts[entry.key] = (categoryCounts[entry.key] ?? 0) + 1;
          }
        }

        // Process recommendation
        if (answers['recommend_supervisor'] == 'نعم') {
          recommendCount++;
        }
      }

      // Calculate averages
      final categoryAverages = <String, double>{};
      double totalRating = 0.0;
      int ratingCount = 0;

      for (final entry in categoryTotals.entries) {
        final average = entry.value / (categoryCounts[entry.key] ?? 1);
        categoryAverages[entry.key] = average;
        totalRating += average;
        ratingCount++;
      }

      final averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;
      final recommendationRate = totalResponses > 0 ? (recommendCount / totalResponses) * 100 : 0.0;

      return {
        'totalResponses': totalResponses,
        'averageRating': averageRating,
        'categoryAverages': categoryAverages,
        'recommendationRate': recommendationRate,
      };
    } catch (e) {
      debugPrint('❌ Error getting supervisor evaluation stats: $e');
      return {
        'totalResponses': 0,
        'averageRating': 0.0,
        'categoryAverages': {},
        'recommendationRate': 0.0,
      };
    }
  }

  // Submit supervisor evaluation survey response
  Future<void> submitSupervisorEvaluationResponse({
    required String surveyId,
    required String supervisorId,
    required String supervisorName,
    required String parentId,
    required String parentName,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final responseId = _uuid.v4();

      await _firestore
          .collection('survey_responses')
          .doc(responseId)
          .set({
            'id': responseId,
            'surveyId': surveyId,
            'surveyType': 'supervisorEvaluation',
            'supervisorId': supervisorId,
            'supervisorName': supervisorName,
            'respondentId': parentId,
            'respondentName': parentName,
            'respondentType': 'parent',
            'answers': answers,
            'submittedAt': FieldValue.serverTimestamp(),
            'isComplete': true,
          });

      debugPrint('✅ Supervisor evaluation response submitted successfully');
    } catch (e) {
      debugPrint('❌ Error submitting supervisor evaluation response: $e');
      throw Exception('فشل في إرسال تقييم المشرف: $e');
    }
  }

  // Parent-Student Linking Functions
  Future<void> createParentStudentLink(ParentStudentLinkModel link) async {
    try {
      await _firestore.collection('parent_student_links').doc(link.id).set(link.toMap());
      debugPrint('✅ Parent-student link created successfully');
    } catch (e) {
      debugPrint('❌ Error creating parent-student link: $e');
      throw Exception('فشل في إنشاء رابط ولي الأمر: $e');
    }
  }

  Stream<List<ParentStudentLinkModel>> getParentStudentLinks() {
    return _firestore
        .collection('parent_student_links')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParentStudentLinkModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> activateParentStudentLink(String linkId, String parentId) async {
    try {
      await _firestore.collection('parent_student_links').doc(linkId).update({
        'parentId': parentId,
        'isLinked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Parent-student link activated successfully');
    } catch (e) {
      debugPrint('❌ Error activating parent-student link: $e');
      throw Exception('فشل في تفعيل رابط ولي الأمر: $e');
    }
  }

  // Bus Assignment Functions
  Future<void> assignSupervisorToBus(String supervisorId, String busId) async {
    try {
      // Get supervisor and bus data
      final supervisorDoc = await _firestore.collection('users').doc(supervisorId).get();
      final busDoc = await _firestore.collection('buses').doc(busId).get();

      if (!supervisorDoc.exists || !busDoc.exists) {
        throw Exception('المشرف أو الباص غير موجود');
      }

      final supervisorData = supervisorDoc.data()!;
      final busData = busDoc.data()!;

      final batch = _firestore.batch();

      // Update bus with supervisor info
      final busRef = _firestore.collection('buses').doc(busId);
      batch.update(busRef, {
        'supervisorId': supervisorId,
        'supervisorName': supervisorData['name'] ?? 'غير محدد',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update supervisor with bus info
      final supervisorRef = _firestore.collection('users').doc(supervisorId);
      batch.update(supervisorRef, {
        'assignedBusId': busId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // إرسال إشعار تسكين المشرف
      final currentUserId = _getCurrentUserId();
      if (currentUserId.isNotEmpty) {
        final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
        final adminName = currentUserDoc.exists ?
          (currentUserDoc.data()?['name'] ?? 'إدمن') : 'إدمن';

        await NotificationService().sendSupervisorAssignmentNotification(
          supervisorId: supervisorId,
          supervisorName: supervisorData['name'] ?? 'مشرف',
          busId: busId,
          busPlateNumber: busData['plateNumber'] ?? 'غير محدد',
          adminName: adminName,
          adminId: currentUserId, // استبعاد الإدمن الحالي
        );
      }

      debugPrint('✅ Supervisor assigned to bus successfully');
    } catch (e) {
      debugPrint('❌ Error assigning supervisor to bus: $e');
      throw Exception('فشل في تسكين المشرف في الحافلة: $e');
    }
  }

  Future<void> removeSupervisorFromBus(String supervisorId, String busId) async {
    try {
      final batch = _firestore.batch();

      // Remove supervisor from bus
      final busRef = _firestore.collection('buses').doc(busId);
      batch.update(busRef, {
        'supervisorId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove bus assignment from supervisor
      final supervisorRef = _firestore.collection('users').doc(supervisorId);
      batch.update(supervisorRef, {
        'assignedBusId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('✅ Supervisor removed from bus successfully');
    } catch (e) {
      debugPrint('❌ Error removing supervisor from bus: $e');
      throw Exception('فشل في إزالة المشرف من الحافلة: $e');
    }
  }

  // Parent-Student Linking Functions (New System)

  /// Get available parents (parents without linked children)
  Stream<List<UserModel>> getAvailableParents() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'parent')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<UserModel> availableParents = [];

          for (var doc in snapshot.docs) {
            try {
              final parent = UserModel.fromMap(doc.data());

              // Check if parent has any linked children
              final linkedStudents = await _firestore
                  .collection('students')
                  .where('parentId', isEqualTo: parent.id)
                  .where('isActive', isEqualTo: true)
                  .get();

              // If no linked children, add to available list
              if (linkedStudents.docs.isEmpty) {
                availableParents.add(parent);
              }
            } catch (e) {
              debugPrint('❌ Error parsing parent data: $e');
            }
          }

          // Sort by name
          availableParents.sort((a, b) => a.name.compareTo(b.name));
          return availableParents;
        });
  }

  /// Link student to parent directly
  Future<void> linkStudentToParent(String studentId, String parentId) async {
    try {
      // Get student and parent data
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      final parentDoc = await _firestore.collection('users').doc(parentId).get();

      if (!studentDoc.exists || !parentDoc.exists) {
        throw Exception('الطالب أو ولي الأمر غير موجود');
      }

      final studentData = studentDoc.data()!;
      final parentData = parentDoc.data()!;

      // Update student with parent info
      await _firestore.collection('students').doc(studentId).update({
        'parentId': parentId,
        'parentName': parentData['name'] ?? '',
        'parentEmail': parentData['email'] ?? '',
        'parentPhone': parentData['phone'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Student linked to parent successfully');
    } catch (e) {
      debugPrint('❌ Error linking student to parent: $e');
      throw Exception('فشل في ربط الطالب بولي الأمر: $e');
    }
  }

  /// Send notification to specific parent only
  Future<void> sendNotificationToParent({
    required String parentId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // إرسال إشعار لولي الأمر المحدد فقط
      await _firestore.collection('notifications').add({
        'id': _uuid.v4(),
        'recipientId': parentId, // إرسال لولي الأمر المحدد فقط
        'title': title,
        'body': message,
        'type': 'student_linked',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': _getCurrentUserId(),
        'data': data ?? {},
      });

      debugPrint('✅ Notification sent to parent $parentId successfully');
    } catch (e) {
      debugPrint('❌ Error sending notification to parent: $e');
      throw Exception('فشل في إرسال الإشعار لولي الأمر: $e');
    }
  }

  /// Get admin notifications (admin-specific notifications only)
  Stream<List<NotificationModel>> getAdminNotifications(String adminId) {
    if (adminId.isEmpty) return Stream.value([]);

    // الإدمن يرى الإشعارات المخصصة له فقط لتجنب التكرار
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: adminId)
        .orderBy('timestamp', descending: true)
        .limit(50) // تقليل العدد لتحسين الأداء
        .snapshots()
        .map((snapshot) {
          final notifications = <NotificationModel>[];
          final seenIds = <String>{};
          final seenContent = <String>{};

          for (final doc in snapshot.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              // إضافة معرف الوثيقة للتأكد من التحديث الصحيح
              data['id'] = doc.id;

              // التحقق من عدم التكرار
              final contentKey = '${data['title']}_${data['body']}';
              if (seenIds.contains(doc.id) || seenContent.contains(contentKey)) {
                debugPrint('⚠️ Skipping duplicate notification: ${data['title']}');
                continue;
              }

              final notification = NotificationModel.fromMap(data);
              notifications.add(notification);
              seenIds.add(doc.id);
              seenContent.add(contentKey);

            } catch (e) {
              debugPrint('❌ Error parsing admin notification ${doc.id}: $e');
            }
          }
          debugPrint('📱 Admin notifications loaded: ${notifications.length}');
          return notifications;
        });
  }

  /// Get all system notifications for admin monitoring (separate from personal notifications)
  Stream<List<NotificationModel>> getAllSystemNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final notifications = <NotificationModel>[];
          final seenIds = <String>{};

          for (final doc in snapshot.docs) {
            try {
              // تجنب المكررات
              if (seenIds.contains(doc.id)) continue;

              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;

              final notification = NotificationModel.fromMap(data);
              notifications.add(notification);
              seenIds.add(doc.id);

            } catch (e) {
              debugPrint('❌ Error parsing system notification ${doc.id}: $e');
            }
          }
          debugPrint('📱 System notifications loaded: ${notifications.length}');
          return notifications;
        });
  }

  /// Get total users count
  Stream<int> getTotalUsersCount() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get active students count
  Stream<int> getActiveStudentsCount() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get total parents count
  Stream<int> getTotalParentsCount() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'parent')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get total supervisors count
  Stream<int> getTotalSupervisorsCount() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'supervisor')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get total buses count
  Stream<int> getTotalBusesCount() {
    return _firestore
        .collection('buses')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get active trip count
  Stream<int> getActiveTripCount() {
    return _firestore
        .collection('trips')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get today trips count
  Stream<int> getTodayTripsCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('trips')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get assigned students count
  Stream<int> getAssignedStudentsCount() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final assignedStudents = snapshot.docs.where((doc) {
            final data = doc.data();
            final busRoute = data['busRoute'] as String? ?? '';
            final busId = data['busId'] as String? ?? '';
            return busRoute.isNotEmpty || busId.isNotEmpty;
          }).length;
          return assignedStudents;
        });
  }

  /// إصلاح الإشعارات الموجودة لضمان وجود النص في حقل body
  Future<void> fixExistingNotifications() async {
    try {
      debugPrint('🔧 Starting to fix existing notifications...');

      final snapshot = await _firestore
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      int fixedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final currentBody = data['body'] ?? '';
        final message = data['message'] ?? '';

        // إذا كان body فارغ ولكن message موجود
        if (currentBody.isEmpty && message.isNotEmpty) {
          batch.update(doc.reference, {
            'body': message,
          });
          fixedCount++;
          debugPrint('🔧 Fixed notification ${doc.id}: moved message to body');
        }
        // إذا كان body موجود ولكن message أيضاً موجود ومختلف
        else if (currentBody.isNotEmpty && message.isNotEmpty && currentBody != message) {
          // نحتفظ بـ body الحالي ونحذف message لتجنب التضارب
          batch.update(doc.reference, {
            'message': FieldValue.delete(),
          });
          debugPrint('🔧 Cleaned notification ${doc.id}: removed duplicate message field');
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        debugPrint('✅ Fixed $fixedCount notifications successfully');
      } else {
        debugPrint('✅ No notifications needed fixing');
      }
    } catch (e) {
      debugPrint('❌ Error fixing notifications: $e');
    }
  }

}
