import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'enhanced_push_notification_service.dart';

/// خدمة المصادقة المستمرة - تحافظ على تسجيل الدخول
class PersistentAuthService extends ChangeNotifier {
  static final PersistentAuthService _instance = PersistentAuthService._internal();
  factory PersistentAuthService() => _instance;
  PersistentAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EnhancedPushNotificationService _notificationService = 
      EnhancedPushNotificationService();

  // Private variables
  UserModel? _currentUserData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _autoLoginEnabled = true;

  // Getters
  User? get currentUser => _auth.currentUser;
  UserModel? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => currentUser != null && _currentUserData != null;
  bool get autoLoginEnabled => _autoLoginEnabled;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 Initializing Persistent Auth Service...');

      // تحميل إعدادات تسجيل الدخول التلقائي
      await _loadAutoLoginSettings();

      // فحص تسجيل الدخول المحفوظ
      await _checkPersistedAuth();

      // الاستماع لتغييرات حالة المصادقة
      _setupAuthStateListener();

      _isInitialized = true;
      debugPrint('✅ Persistent Auth Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Persistent Auth Service: $e');
    }
  }

  /// تحميل إعدادات تسجيل الدخول التلقائي
  Future<void> _loadAutoLoginSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoLoginEnabled = prefs.getBool('auto_login_enabled') ?? true;
      debugPrint('📱 Auto login enabled: $_autoLoginEnabled');
    } catch (e) {
      debugPrint('❌ Error loading auto login settings: $e');
    }
  }

  /// فحص تسجيل الدخول المحفوظ
  Future<void> _checkPersistedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // فحص إعدادات تسجيل الدخول المحفوظة
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedUserId = prefs.getString('user_id');
      final loginTimestamp = prefs.getInt('login_timestamp') ?? 0;
      final rememberMe = prefs.getBool('remember_me') ?? false;
      
      debugPrint('🔍 Checking persisted auth:');
      debugPrint('  - isLoggedIn: $isLoggedIn');
      debugPrint('  - savedUserId: $savedUserId');
      debugPrint('  - rememberMe: $rememberMe');
      debugPrint('  - autoLoginEnabled: $_autoLoginEnabled');

      // التحقق من صحة البيانات المحفوظة
      if (!_autoLoginEnabled || !isLoggedIn || !rememberMe || savedUserId == null) {
        debugPrint('⚠️ Auto login disabled or no valid saved session');
        return;
      }

      // التحقق من أن التسجيل ليس قديماً جداً (30 يوم)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      
      if (loginDate.isBefore(thirtyDaysAgo)) {
        debugPrint('⚠️ Saved login is too old, clearing...');
        await _clearPersistedAuth();
        return;
      }

      // التحقق من أن المستخدم ما زال مسجل دخوله في Firebase
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == savedUserId) {
        debugPrint('✅ Valid persisted session found, loading user data...');
        await _loadUserData(currentUser.uid);
        await _updateNotificationService();
      } else {
        // We will not clear the persisted auth here.
        // The authStateChanges listener will handle the case where the user is truly signed out.
        // This prevents a race condition on app startup.
        debugPrint('⚠️ Firebase user not authenticated at this moment. Waiting for authStateChanges listener.');
      }
    } catch (e) {
      debugPrint('❌ Error checking persisted auth: $e');
      await _clearPersistedAuth();
    }
  }

  /// إعداد مستمع تغييرات حالة المصادقة
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) async {
      debugPrint('🔄 Auth state changed: ${user?.uid}');
      
      if (user != null) {
        // المستخدم مسجل دخوله
        await _loadUserData(user.uid);
        await _updateNotificationService();
        
        // حفظ معلومات تسجيل الدخول إذا كان مفعلاً
        if (_autoLoginEnabled) {
          await _saveAuthState(user);
        }
      } else {
        // المستخدم خرج من التطبيق
        _currentUserData = null;
        await _notificationService.cleanup();
        notifyListeners();
      }
    });
  }

  /// تحميل بيانات المستخدم
  Future<void> _loadUserData(String uid) async {
    try {
      _setLoading(true);
      
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        _currentUserData = UserModel.fromMap(userDoc.data()!);
        debugPrint('✅ User data loaded: ${_currentUserData?.name}');
      } else {
        debugPrint('⚠️ User document not found for uid: $uid');
        _currentUserData = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      _setError('خطأ في تحميل بيانات المستخدم');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث خدمة الإشعارات
  Future<void> _updateNotificationService() async {
    try {
      await _notificationService.updateCurrentUser(_currentUserData?.id);
      debugPrint('✅ Notification service updated for user: ${_currentUserData?.id}');
    } catch (e) {
      debugPrint('❌ Error updating notification service: $e');
    }
  }

  /// حفظ حالة المصادقة
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

  /// مسح حالة المصادقة المحفوظة
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

  /// تسجيل الدخول مع خيار "تذكرني"
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🔐 Signing in user: $email (rememberMe: $rememberMe)');

      // محاولة تسجيل الدخول
      UserCredential result;
      
      try {
        result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // معالجة خطأ PigeonUserDetails
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('List<Object?>')) {
          debugPrint('🔄 Retrying login due to PigeonUserDetails error...');
          await Future.delayed(const Duration(milliseconds: 500));
          
          result = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (result.user != null) {
        debugPrint('✅ Login successful, loading user data...');
        
        // انتظار قصير للتأكد من تحديث حالة المصادقة
        await Future.delayed(const Duration(milliseconds: 300));
        
        // تحميل بيانات المستخدم
        await _loadUserData(result.user!.uid);
        
        if (_currentUserData != null) {
          // حفظ إعدادات "تذكرني"
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', rememberMe);
          
          if (rememberMe && _autoLoginEnabled) {
            await _saveAuthState(result.user!);
          }
          
          debugPrint('✅ User signed in: ${_currentUserData!.name} (${_currentUserData!.userType})');
          return _currentUserData;
        } else {
          throw Exception('فشل في تحميل بيانات المستخدم');
        }
      } else {
        throw Exception('فشل في تسجيل الدخول');
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleAuthException(e);
      _setError(errorMessage);
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = 'خطأ في تسجيل الدخول: $e';
      _setError(errorMessage);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// تسجيل الخروج (مع خيار الحفاظ على البيانات)
  Future<void> signOut({bool clearPersistedData = false}) async {
    try {
      _setLoading(true);
      
      debugPrint('🔓 Signing out user (clearPersistedData: $clearPersistedData)');

      // تنظيف خدمة الإشعارات
      await _notificationService.cleanup();

      // تسجيل الخروج من Firebase
      await _auth.signOut();
      
      // مسح البيانات المحفوظة إذا طُلب ذلك
      if (clearPersistedData) {
        await _clearPersistedAuth();
        debugPrint('✅ Persisted data cleared');
      } else {
        // الحفاظ على بعض البيانات للدخول السريع
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        debugPrint('✅ Signed out but kept some data for quick login');
      }
      
      _currentUserData = null;
      _setError(null);
      notifyListeners();
      
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      final errorMessage = 'خطأ في تسجيل الخروج: $e';
      _setError(errorMessage);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// تفعيل/إلغاء تفعيل تسجيل الدخول التلقائي
  Future<void> setAutoLoginEnabled(bool enabled) async {
    try {
      _autoLoginEnabled = enabled;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_login_enabled', enabled);
      
      if (!enabled) {
        // إذا تم إلغاء التفعيل، امسح البيانات المحفوظة
        await _clearPersistedAuth();
      }
      
      notifyListeners();
      debugPrint('✅ Auto login ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Error setting auto login: $e');
    }
  }

  /// فحص صحة الجلسة الحالية
  Future<bool> validateCurrentSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // إعادة تحميل بيانات المستخدم للتأكد من صحتها
      await user.reload();
      
      // التحقق من وجود بيانات المستخدم في قاعدة البيانات
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      return userDoc.exists;
    } catch (e) {
      debugPrint('❌ Error validating session: $e');
      return false;
    }
  }

  /// تحديث آخر نشاط للمستخدم
  Future<void> updateLastActivity() async {
    try {
      if (_currentUserData != null) {
        await _firestore.collection('users').doc(_currentUserData!.id).update({
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating last activity: $e');
    }
  }

  /// الحصول على معلومات الجلسة
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'isLoggedIn': prefs.getBool('is_logged_in') ?? false,
        'userId': prefs.getString('user_id'),
        'userEmail': prefs.getString('user_email'),
        'loginTimestamp': prefs.getInt('login_timestamp'),
        'rememberMe': prefs.getBool('remember_me') ?? false,
        'autoLoginEnabled': _autoLoginEnabled,
        'currentUser': _currentUserData?.toMap(),
      };
    } catch (e) {
      debugPrint('❌ Error getting session info: $e');
      return {};
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح. حاول مرة أخرى لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      default:
        return 'حدث خطأ في تسجيل الدخول: ${e.message}';
    }
  }
}