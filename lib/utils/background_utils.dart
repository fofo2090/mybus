import 'package:flutter/material.dart';

/// فئة لإدارة الخلفيات المختلفة للتطبيق
class BackgroundUtils {

  // School Bus Theme Colors
  static const Color busYellow = Color(0xFFFFD700);
  static const Color busOrange = Color(0xFFFF8C00);
  static const Color schoolBlue = Color(0xFF1E88E5);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color roadGray = Color(0xFF696969);
  static const Color grassGreen = Color(0xFF32CD32);
  static const Color sunYellow = Color(0xFFFFA500);
  static const Color cloudWhite = Color(0xFFF0F8FF);
  
  /// خلفية متدرجة للشاشات الرئيسية - تصميم النقل المدرسي
  static BoxDecoration get primaryGradientBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        skyBlue, // أزرق سماوي
        Color(0xFF4A90E2), // أزرق فاتح
        schoolBlue, // أزرق المدرسة
        Color(0xFF1565C0), // أزرق داكن
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
  );

  /// خلفية الحافلة المدرسية المحسنة - تصميم أنيق ومتناسق
  static BoxDecoration get schoolBusBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF8FAFC), // خلفية فاتحة نظيفة
        Color(0xFFE2E8F0), // رمادي فاتح أنيق
        Color(0xFFCBD5E1), // رمادي متوسط
        Color(0xFFE8F4FD), // أزرق فاتح جداً
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
  );

  /// خلفية الباص المدرسي مع عناصر بصرية جميلة
  static Widget buildSchoolBusBackgroundWithElements({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF87CEEB), // سماء زرقاء فاتحة
            Color(0xFFB0E0E6), // سماء متوسطة
            Color(0xFFE0F6FF), // أفق بعيد
            Color(0xFFF0F8FF), // أفق قريب
            Color(0xFF98FB98), // مروج خضراء
            Color(0xFF90EE90), // أشجار
            Color(0xFF808080), // طريق أسفلت
          ],
          stops: [0.0, 0.2, 0.4, 0.6, 0.75, 0.85, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // عناصر الخلفية الزخرفية
          _buildBackgroundElements(),
          // المحتوى الرئيسي
          child,
        ],
      ),
    );
  }

  /// بناء العناصر الزخرفية للخلفية
  static Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // الشمس
        Positioned(
          top: 50,
          right: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  sunYellow.withOpacity(0.3),
                  sunYellow.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // سحب
        Positioned(
          top: 80,
          left: 50,
          child: Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: cloudWhite.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        Positioned(
          top: 120,
          right: 100,
          child: Container(
            width: 60,
            height: 25,
            decoration: BoxDecoration(
              color: cloudWhite.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // أشجار
        Positioned(
          bottom: 150,
          left: 20,
          child: Container(
            width: 40,
            height: 60,
            decoration: BoxDecoration(
              color: grassGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 140,
          right: 40,
          child: Container(
            width: 35,
            height: 50,
            decoration: BoxDecoration(
              color: grassGreen.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
          ),
        ),

        // باص مدرسي صغير كعنصر زخرفي
        Positioned(
          bottom: 200,
          right: 20,
          child: Container(
            width: 50,
            height: 25,
            decoration: BoxDecoration(
              color: busYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: busYellow.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.directions_bus,
                size: 16,
                color: busYellow.withOpacity(0.3),
              ),
            ),
          ),
        ),

        // مبنى المدرسة
        Positioned(
          bottom: 180,
          left: 60,
          child: Container(
            width: 45,
            height: 40,
            decoration: BoxDecoration(
              color: schoolBlue.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.school,
                size: 20,
                color: schoolBlue.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// خلفية شاشة البداية المحسنة
  static BoxDecoration get enhancedSplashBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF87CEEB), // سماء صافية
        Color(0xFF4A90E2), // أزرق فاتح
        Color(0xFFFFD700), // أصفر الحافلة
        Color(0xFFFF8C00), // برتقالي دافئ
        Color(0xFF1E88E5), // أزرق المدرسة
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
  );

  /// خلفية متدرجة للشاشات الثانوية
  static BoxDecoration get secondaryGradientBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF667EEA), // بنفسجي فاتح
        Color(0xFF764BA2), // بنفسجي متوسط
        Color(0xFF1E88E5), // أزرق
      ],
      stops: [0.0, 0.6, 1.0],
    ),
  );

  /// خلفية متدرجة لشاشات المشرف
  static BoxDecoration get supervisorGradientBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF43A047), // أخضر فاتح
        Color(0xFF388E3C), // أخضر متوسط
        Color(0xFF2E7D32), // أخضر داكن
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  /// خلفية متدرجة لشاشات الإدارة
  static BoxDecoration get adminGradientBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF7043), // برتقالي فاتح
        Color(0xFFFF5722), // برتقالي متوسط
        Color(0xFFE64A19), // برتقالي داكن
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  /// خلفية متدرجة لشاشات تسجيل الدخول
  static BoxDecoration get authGradientBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF667EEA),
        Color(0xFF764BA2),
        Color(0xFF1E88E5),
        Color(0xFF4A90E2),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
  );

  /// خلفية بنمط الحافلة المدرسية
  static BoxDecoration get busPatternBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF4A90E2),
        Color(0xFF1E88E5),
      ],
    ),
  );

  /// خلفية مع نمط الطرق
  static BoxDecoration get roadPatternBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF87CEEB), // أزرق سماوي
        Color(0xFF4A90E2), // أزرق متوسط
      ],
    ),
  );

  /// خلفية بنمط المدرسة
  static BoxDecoration get schoolPatternBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF43A047),
        Color(0xFF388E3C),
      ],
    ),
  );

  /// خلفية فاتحة للوضع النهاري
  static BoxDecoration get lightBackground => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.grey[50]!,
        Colors.grey[100]!,
        Colors.grey[200]!,
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
  );

  /// خلفية داكنة للوضع الليلي
  static BoxDecoration get darkBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF121212),
        Color(0xFF1F1F1F),
        Color(0xFF2C2C2C),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  /// خلفية مع تأثير الفقاعات
  static BoxDecoration getBubbleBackground(Color primaryColor) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withOpacity(0.8),
        primaryColor,
        primaryColor.withOpacity(0.9),
      ],
    ),
  );

  /// خلفية مع تأثير الموجات
  static BoxDecoration getWaveBackground(Color primaryColor, Color secondaryColor) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor,
        secondaryColor,
        primaryColor.withOpacity(0.8),
      ],
      stops: const [0.0, 0.6, 1.0],
    ),
  );

  /// الحصول على خلفية حسب نوع المستخدم
  static BoxDecoration getBackgroundByUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'parent':
        return primaryGradientBackground;
      case 'supervisor':
        return supervisorGradientBackground;
      case 'admin':
        return adminGradientBackground;
      default:
        return primaryGradientBackground;
    }
  }

  /// الحصول على خلفية حسب السياق
  static BoxDecoration getBackgroundByContext(String context) {
    switch (context.toLowerCase()) {
      case 'auth':
        return authGradientBackground;
      case 'splash':
        return authGradientBackground;
      case 'home':
        return primaryGradientBackground;
      case 'profile':
        return secondaryGradientBackground;
      case 'settings':
        return lightBackground;
      default:
        return primaryGradientBackground;
    }
  }

  /// إضافة تأثير الظل للحاويات
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// تأثير ظل قوي
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];

  /// تأثير ظل ناعم
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// خلفية مع نمط الحافلة والأطفال
  static BoxDecoration get kidsOnBusBackground => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Color(0xFFFFD700), // أصفر الحافلة في المركز
        Color(0xFF87CEEB), // أزرق السماء
        Color(0xFF4A90E2), // أزرق أعمق
        Color(0xFF1E88E5), // أزرق المدرسة
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
  );

  /// خلفية الطريق إلى المدرسة
  static BoxDecoration get roadToSchoolBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF87CEEB), // سماء الصباح
        Color(0xFFFFD700), // شمس ذهبية
        Color(0xFF32CD32), // أشجار خضراء
        Color(0xFF696969), // طريق رمادي
        Color(0xFF2F4F4F), // ظل الطريق
      ],
      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
    ),
  );

  /// خلفية المدرسة السعيدة
  static BoxDecoration get happySchoolBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFA500), // برتقالي مشرق
        Color(0xFFFFD700), // أصفر مشمس
        Color(0xFF32CD32), // أخضر طبيعي
        Color(0xFF87CEEB), // أزرق هادئ
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
    ),
  );

  /// خلفية الأمان والحماية
  static BoxDecoration get safetyBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF4CAF50), // أخضر الأمان
        Color(0xFF8BC34A), // أخضر فاتح
        Color(0xFFFFEB3B), // أصفر التحذير
        Color(0xFFFF9800), // برتقالي الانتباه
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
  );

  /// خلفية مع تأثير الحركة
  static BoxDecoration getMovingBackground(double animationValue) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment(-1.0 + animationValue, -1.0 + animationValue),
      end: Alignment(1.0 + animationValue, 1.0 + animationValue),
      colors: const [
        Color(0xFF87CEEB),
        Color(0xFFFFD700),
        Color(0xFF32CD32),
        Color(0xFF4A90E2),
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    ),
  );

  /// خلفية الاحتفال والنجاح
  static BoxDecoration get celebrationBackground => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [
        Color(0xFFFFD700), // ذهبي مشرق
        Color(0xFFFFA500), // برتقالي احتفالي
        Color(0xFFFF69B4), // وردي مرح
        Color(0xFF9370DB), // بنفسجي جميل
        Color(0xFF4169E1), // أزرق ملكي
      ],
      stops: [0.0, 0.2, 0.4, 0.7, 1.0],
    ),
  );
}
