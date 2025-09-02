import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'unified_notification_service.dart';
// تم حذف الخدمات المتكررة واستبدالها بالخدمة الموحدة

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Private variables
  UserModel? _currentUserData;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _auth.currentUser;
  UserModel? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => currentUser != null;

  // التحقق من وجود تسجيل دخول محفوظ صالح
  Future<bool> get hasSavedLogin async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedUserId = prefs.getString('user_id');
      final loginTimestamp = prefs.getInt('login_timestamp') ?? 0;
      
      // التحقق من أن التسجيل ليس قديماً جداً (60 يوم)
      final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      
      return isLoggedIn && 
             savedUserId != null && 
             loginDate.isAfter(sixtyDaysAgo) &&
             _auth.currentUser?.uid == savedUserId;
    } catch (e) {
      debugPrint('❌ Error checking saved login: $e');
      return false;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Constructor
  AuthService() {
    _init();
  }

  // Initialize auth service
  void _init() {
    // تحقق من وجود تسجيل دخول محفوظ عند بدء التطبيق
    _checkSavedLogin();
    
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
        // حفظ معلومات تسجيل الدخول
        await _saveLoginInfo(user);
      } else {
        _currentUserData = null;
        // مسح معلومات تسجيل الدخول المحفوظة
        await _clearLoginInfo();
        notifyListeners();
      }
    });
  }

  // فحص وجود تسجيل دخول محفوظ
  Future<void> _checkSavedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (!rememberMe) {
        if (currentUser != null) {
          await signOut();
        }
        return;
      }

      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedEmail = prefs.getString('user_email');
      final savedUserId = prefs.getString('user_id');
      
      debugPrint('🔍 Checking saved login: isLoggedIn=$isLoggedIn, email=$savedEmail, rememberMe=$rememberMe');
      
      if (isLoggedIn && savedEmail != null && savedUserId != null) {
        // التحقق من أن المستخدم ما زال مسجل دخوله في Firebase
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == savedUserId) {
          debugPrint('✅ User already logged in from saved session');
          await _loadUserData(currentUser.uid);
        } else {
          debugPrint('⚠️ Saved login found but Firebase user not authenticated');
          await _clearLoginInfo();
        }
      } else if (rememberMe) {
        // This case should ideally not happen if everything is consistent,
        // but as a safeguard, if rememberMe is true but other details are missing,
        // we should probably clear everything to force a manual login.
        await _clearLoginInfo();
      }
    } catch (e) {
      debugPrint('❌ Error checking saved login: $e');
    }
  }

  // حفظ معلومات تسجيل الدخول
  Future<void> _saveLoginInfo(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_id', user.uid);
      await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('✅ Login info saved for user: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error saving login info: $e');
    }
  }

  // مسح معلومات تسجيل الدخول المحفوظة
  Future<void> _clearLoginInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('user_email');
      await prefs.remove('user_id');
      await prefs.remove('login_timestamp');
      await prefs.remove('remember_me');
      
      debugPrint('✅ All login info cleared');
    } catch (e) {
      debugPrint('❌ Error clearing login info: $e');
    }
  }

  // Load user data
  Future<void> _loadUserData(String uid) async {
    try {
      _currentUserData = await getUserData(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🔐 محاولة تسجيل الدخول للمستخدم: $email');

      // محاولة تسجيل الدخول مع معالجة خاصة لخطأ PigeonUserDetails
      UserCredential? result;

      try {
        result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // إذا كان الخطأ متعلق بـ PigeonUserDetails، نحاول مرة أخرى
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('List<Object?>')) {
          debugPrint('🔄 إعادة محاولة تسجيل الدخول بسبب خطأ PigeonUserDetails...');
          await Future.delayed(const Duration(milliseconds: 500));

          // محاولة ثانية
          result = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (result.user != null) {
        // Save the rememberMe choice
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);

        debugPrint('✅ تم تسجيل الدخول بنجاح، جلب بيانات المستخدم...');

        // انتظار قصير للتأكد من تحديث حالة المصادقة
        await Future.delayed(const Duration(milliseconds: 300));

        final userData = await getUserData(result.user!.uid);

        if (userData != null) {
          debugPrint('✅ تم جلب بيانات المستخدم: ${userData.name} (${userData.userType})');
          
          // إرسال إشعار ترحيب
          try {
            await UnifiedNotificationService().sendWelcomeNotification(userData.name);
          } catch (e) {
            debugPrint('⚠️ خطأ في إرسال إشعار الترحيب: $e');
          }
        } else {
          debugPrint('⚠️ لم يتم العثور على بيانات المستخدم في Firestore');

          // إذا لم نجد بيانات المستخدم، نحاول إنشاؤها
          if (email == 'admin@mybus.com') {
            debugPrint('🔧 إنشاء بيانات الأدمن المفقودة...');
            final adminUser = UserModel(
              id: result.user!.uid,
              email: email,
              name: 'مدير النظام',
              phone: '0501234567',
              userType: UserType.admin,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await _firestore
                .collection('users')
                .doc(result.user!.uid)
                .set(adminUser.toMap());

            return adminUser;
          } else if (email == 'supervisor@mybus.com') {
            debugPrint('🔧 إنشاء بيانات المشرف المفقودة...');
            final supervisorUser = UserModel(
              id: result.user!.uid,
              email: email,
              name: 'أحمد المشرف',
              phone: '0507654321',
              userType: UserType.supervisor,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await _firestore
                .collection('users')
                .doc(result.user!.uid)
                .set(supervisorUser.toMap());

            return supervisorUser;
          }
        }

        // تم استبدال خدمات الإشعارات بالخدمة الموحدة
        debugPrint('✅ User logged in successfully');

        return userData;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ خطأ في المصادقة: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ خطأ عام في تسجيل الدخول: $e');

      // إذا كان الخطأ متعلق بـ PigeonUserDetails، نعطي رسالة أوضح
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        _setError('خطأ في إعدادات Firebase. يرجى إعادة تشغيل التطبيق.');
        throw Exception('خطأ في إعدادات Firebase. يرجى إعادة تشغيل التطبيق.');
      }

      _setError('خطأ في تسجيل الدخول: $e');
      throw Exception('خطأ في تسجيل الدخول: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          phone: phone,
          userType: userType,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toMap());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return UserModel.fromMap(data);
        } else {
          debugPrint('❌ خطأ: بيانات المستخدم ليست من النوع المتوقع: ${data.runtimeType}');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المستخدم: $e');
      throw Exception('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المستخدم: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);

      // تم استبدال خدمات الإشعارات بالخدمة الموحدة
      debugPrint('✅ Stopping notification services before logout');

      await _auth.signOut();
      _currentUserData = null;
      _setError(null);
      
      // Always clear all login info on sign out
      await _clearLoginInfo();
      
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تسجيل الخروج: $e');
      throw Exception('خطأ في تسجيل الخروج: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send password reset email (alias for resetPassword)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('🔄 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error sending password reset email: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error sending password reset email: $e');
      throw Exception('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صحيحة أو منتهية الصلاحية';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح، حاول لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالشبكة';
      case 'operation-not-allowed':
        return 'العملية غير مسموحة';
      default:
        return 'حدث خطأ في المصادقة: ${e.code} - ${e.message}';
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final user = await getUserData(currentUser?.uid ?? '');
    return user?.userType == UserType.admin;
  }

  // Check if user is supervisor
  Future<bool> isSupervisor() async {
    final user = await getUserData(currentUser?.uid ?? '');
    return user?.userType == UserType.supervisor;
  }

  // Check if user is parent
  Future<bool> isParent() async {
    final user = await getUserData(currentUser?.uid ?? '');
    return user?.userType == UserType.parent;
  }

  // تم استبدال خدمات الإشعارات بالخدمة الموحدة
  // الخدمة الموحدة تعمل تلقائياً بعد تسجيل الدخول
}
