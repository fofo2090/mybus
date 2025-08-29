import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/unified_notification_service.dart';
import 'services/notification_dialog_service.dart';
import 'services/fcm_service.dart';
import 'services/fcm_background_handler.dart';
import 'services/theme_service.dart';
import 'services/persistent_auth_service.dart';
import 'services/enhanced_push_notification_service.dart';
import 'services/enhanced_background_handler.dart';
import 'utils/app_constants.dart';
import 'utils/app_validator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تهيئة Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Firebase Auth يحفظ تسجيل الدخول تلقائياً في Flutter
    print('✅ Firebase Auth persistence is enabled by default');

    // تسجيل معالج الرسائل المحسن في الخلفية
    FirebaseMessaging.onBackgroundMessage(EnhancedBackgroundHandler.handleBackgroundMessage);
    print('✅ Enhanced background message handler registered');

    // تهيئة خدمة الإشعارات المحسنة
    await EnhancedPushNotificationService().initialize();
    print('✅ Enhanced push notification service initialized');

    // تهيئة خدمة المصادقة المستمرة
    await PersistentAuthService().initialize();
    print('✅ Persistent auth service initialized');

    // تهيئة خدمة FCM المتكاملة فقط (لتجنب التضارب)
    await FCMService().initialize();
    print('✅ FCM service initialized');

    // تهيئة الخدمة الموحدة للإشعارات فقط
    await UnifiedNotificationService().initialize();
    print('✅ Unified notification service initialized');

    // طباعة معلومات التطبيق
    AppValidator.printAppInfo();

    // فحص سريع للتطبيق
    final healthCheck = await AppValidator.quickHealthCheck();
    if (healthCheck) {
      print('✅ App health check passed');
    } else {
      print('⚠️ App health check failed');
    }

  } catch (e) {
    print('❌ Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // تسجيل جميع الخدمات كـ Providers
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: PersistentAuthService()),
        Provider(create: (_) => DatabaseService()),
        Provider(create: (_) => UnifiedNotificationService()),
        Provider(create: (_) => EnhancedPushNotificationService()),
        Provider(create: (_) => FCMService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // دعم اللغة العربية (RTL)
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'), // العربية
              Locale('en', 'US'), // الإنجليزية
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // تطبيق الثيم
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeService.themeMode,

            // نظام التوجيه
            routerConfig: AppRoutes.router,

            // Builder لتهيئة خدمة dialog الإشعارات
            builder: (context, child) {
              // تهيئة خدمة dialog الإشعارات مع مفتاح التنقل
              NotificationDialogService.setNavigatorKey(AppRoutes.navigatorKey);
              return child!;
            },
          );
        },
      ),
    );
  }

  // بناء الثيم الفاتح
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: AppConstants.primaryColor,

      // ألوان التطبيق
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.light,
      ),

      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),

      // خلفية الشاشات
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),

      // الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // البطاقات
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // حقول النص
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // بناء الثيم الداكن
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: AppConstants.primaryColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
        color: const Color(0xFF1E1E1E),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}



// Widget للخلفية المشتركة
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2), // أزرق فاتح
            Color(0xFF1E88E5), // أزرق متوسط
            Color(0xFF1565C0), // أزرق غامق
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
