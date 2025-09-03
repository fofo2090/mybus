import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'unified_notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUserData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  User? get currentUser => _auth.currentUser;
  UserModel? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => currentUser != null && _currentUserData != null;

  // التحقق من وجود تسجيل دخول محفوظ صالح
  Future<bool> get hasSavedLogin async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedUserId = prefs.getString('user_id');
      final loginTimestamp = prefs.getInt('login_timestamp') ?? 0;
      
      // التحقق من أن التسجيل ليس قديماً جداً (30 يوم)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      
      return isLoggedIn && 
             savedUserId != null && 
             loginDate.isAfter(thirtyDaysAgo) &&
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
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedEmail = prefs.getString('user_email');
      final savedUserId = prefs.getString('user_id');
      
      debugPrint('🔍 Checking saved login: isLoggedIn=$isLoggedIn, email=$savedEmail');
      
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
      
      debugPrint('✅ Login info cleared');
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

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🔐 Signing in user: $email (rememberMe: $rememberMe)');

      UserCredential result;
      try {
        result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
          debugPrint('🔄 Retrying login due to PigeonUserDetails error...');
          await Future.delayed(const Duration(milliseconds: 500));
          result = await _auth.signInWithEmailAndPassword(email: email, password: password);
        } else {
          rethrow;
        }
      }

      if (result.user != null) {
        debugPrint('✅ Login successful, loading user data...');
        await _loadUserData(result.user!.uid);
        if (_currentUserData != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', rememberMe);
          if (rememberMe) {
            await _saveAuthState(result.user!);
          }
          debugPrint('✅ User signed in: ${_currentUserData!.name} (${_currentUserData!.userType})');
          return _currentUserData;
        } else {
          throw Exception('Failed to load user data');
        }
      } else {
        throw Exception('Failed to sign in');
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleAuthException(e);
      _setError(errorMessage);
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = 'Login error: $e';
      _setError(errorMessage);
      throw Exception(errorMessage);
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

  Future<void> signOut({bool clearPersistedData = false}) async {
    try {
      _setLoading(true);
      debugPrint('🔓 Signing out user (clearPersistedData: $clearPersistedData)');

      await _auth.signOut();
      
      if (clearPersistedData) {
        await _clearPersistedAuth();
        debugPrint('✅ Persisted data cleared');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        debugPrint('✅ Signed out but kept some data for quick login');
      }
      
      _currentUserData = null;
      _setError(null);
      notifyListeners();

      debugPrint('✅ User signed out successfully');
    } catch (e) {
      final errorMessage = 'Logout error: $e';
      _setError(errorMessage);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveAuthState(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('remember_me', true);
      debugPrint('✅ Auth state saved for user: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error saving auth state: $e');
    }
  }

  Future<void> _clearPersistedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('login_timestamp');
      await prefs.remove('remember_me');
      debugPrint('✅ Persisted auth cleared');
    } catch (e) {
      debugPrint('❌ Error clearing persisted auth: $e');
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
