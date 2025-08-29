import 'package:flutter/material.dart';
import 'responsive_helper.dart';
import 'responsive_checker.dart';

/// أداة لاختبار التجاوب تلقائياً
class ResponsiveTestRunner {
  
  /// تشغيل اختبارات التجاوب على أحجام شاشات مختلفة
  static Future<ResponsiveTestResults> runTests(
    BuildContext context,
    Widget testWidget,
  ) async {
    List<ResponsiveTestCase> testCases = [];
    
    // أحجام الشاشات للاختبار
    final testSizes = [
      const Size(360, 640),   // موبايل صغير
      const Size(414, 896),   // موبايل كبير
      const Size(768, 1024),  // تابلت عمودي
      const Size(1024, 768),  // تابلت أفقي
      const Size(1366, 768),  // لابتوب
      const Size(1920, 1080), // سطح مكتب
      const Size(2560, 1440), // شاشة كبيرة
    ];
    
    for (final size in testSizes) {
      final testCase = await _runSingleTest(context, testWidget, size);
      testCases.add(testCase);
    }
    
    return ResponsiveTestResults(
      testCases: testCases,
      overallScore: _calculateOverallScore(testCases),
      recommendations: _generateRecommendations(testCases),
    );
  }
  
  /// تشغيل اختبار واحد على حجم شاشة محدد
  static Future<ResponsiveTestCase> _runSingleTest(
    BuildContext context,
    Widget testWidget,
    Size screenSize,
  ) async {
    // محاكاة حجم الشاشة
    final mediaQuery = MediaQuery.of(context).copyWith(
      size: screenSize,
    );
    
    // إنشاء context مؤقت للاختبار
    final testContext = _createTestContext(context, mediaQuery);
    
    // تحليل التجاوب
    final analysis = ResponsiveChecker.analyzeScreen(testContext);
    
    // اختبارات إضافية
    final additionalTests = _runAdditionalTests(testContext, testWidget);
    
    return ResponsiveTestCase(
      screenSize: screenSize,
      deviceType: ResponsiveHelper.getDeviceType(testContext),
      analysis: analysis,
      additionalTests: additionalTests,
      passed: analysis.score >= 70, // نجح إذا كانت النتيجة 70 أو أكثر
    );
  }
  
  /// إنشاء context للاختبار
  static BuildContext _createTestContext(BuildContext originalContext, MediaQueryData mediaQuery) {
    // هذا مبسط - في التطبيق الحقيقي نحتاج لإنشاء context كامل
    return originalContext;
  }
  
  /// اختبارات إضافية
  static List<AdditionalTest> _runAdditionalTests(BuildContext context, Widget widget) {
    List<AdditionalTest> tests = [];
    
    // اختبار حجم الخط
    tests.add(_testFontSizes(context));
    
    // اختبار المساحات
    tests.add(_testSpacing(context));
    
    // اختبار الأزرار
    tests.add(_testButtonSizes(context));
    
    // اختبار الأيقونات
    tests.add(_testIconSizes(context));
    
    return tests;
  }
  
  /// اختبار أحجام الخط
  static AdditionalTest _testFontSizes(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final fontSize = ResponsiveHelper.getFontSize(context);
    
    bool passed = true;
    String message = 'أحجام الخط مناسبة';
    
    // فحص الحد الأدنى والأقصى لحجم الخط
    if (deviceType == DeviceType.mobile && fontSize < 12) {
      passed = false;
      message = 'حجم الخط صغير جداً للموبايل ($fontSize px)';
    } else if (deviceType == DeviceType.desktop && fontSize < 14) {
      passed = false;
      message = 'حجم الخط صغير لسطح المكتب ($fontSize px)';
    } else if (fontSize > 24) {
      passed = false;
      message = 'حجم الخط كبير جداً ($fontSize px)';
    }
    
    return AdditionalTest(
      name: 'Font Size Test',
      passed: passed,
      message: message,
      value: fontSize,
    );
  }
  
  /// اختبار المساحات
  static AdditionalTest _testSpacing(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(context);
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    bool passed = true;
    String message = 'المساحات مناسبة';
    
    // فحص المساحات المناسبة لكل جهاز
    switch (deviceType) {
      case DeviceType.mobile:
        if (spacing < 4 || spacing > 16) {
          passed = false;
          message = 'المساحات غير مناسبة للموبايل ($spacing px)';
        }
        break;
      case DeviceType.tablet:
        if (spacing < 8 || spacing > 20) {
          passed = false;
          message = 'المساحات غير مناسبة للتابلت ($spacing px)';
        }
        break;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        if (spacing < 12 || spacing > 32) {
          passed = false;
          message = 'المساحات غير مناسبة لسطح المكتب ($spacing px)';
        }
        break;
    }
    
    return AdditionalTest(
      name: 'Spacing Test',
      passed: passed,
      message: message,
      value: spacing,
    );
  }
  
  /// اختبار أحجام الأزرار
  static AdditionalTest _testButtonSizes(BuildContext context) {
    final buttonHeight = ResponsiveHelper.getButtonHeight(context);
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    bool passed = true;
    String message = 'أحجام الأزرار مناسبة';
    
    // الحد الأدنى لحجم الأزرار للمس
    final minTouchSize = deviceType == DeviceType.mobile ? 44.0 : 36.0;
    
    if (buttonHeight < minTouchSize) {
      passed = false;
      message = 'الأزرار صغيرة جداً للمس ($buttonHeight px)';
    } else if (buttonHeight > 80) {
      passed = false;
      message = 'الأزرار كبيرة جداً ($buttonHeight px)';
    }
    
    return AdditionalTest(
      name: 'Button Size Test',
      passed: passed,
      message: message,
      value: buttonHeight,
    );
  }
  
  /// اختبار أحجام الأيقونات
  static AdditionalTest _testIconSizes(BuildContext context) {
    final iconSize = ResponsiveHelper.getIconSize(context);
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    bool passed = true;
    String message = 'أحجام الأيقونات مناسبة';
    
    // فحص أحجام الأيقونات المناسبة
    if (deviceType == DeviceType.mobile && iconSize < 16) {
      passed = false;
      message = 'الأيقونات صغيرة للموبايل ($iconSize px)';
    } else if (deviceType == DeviceType.desktop && iconSize < 20) {
      passed = false;
      message = 'الأيقونات صغيرة لسطح المكتب ($iconSize px)';
    } else if (iconSize > 48) {
      passed = false;
      message = 'الأيقونات كبيرة جداً ($iconSize px)';
    }
    
    return AdditionalTest(
      name: 'Icon Size Test',
      passed: passed,
      message: message,
      value: iconSize,
    );
  }
  
  /// حساب النتيجة الإجمالية
  static int _calculateOverallScore(List<ResponsiveTestCase> testCases) {
    if (testCases.isEmpty) return 0;
    
    int totalScore = 0;
    for (final testCase in testCases) {
      totalScore += testCase.analysis.score;
    }
    
    return (totalScore / testCases.length).round();
  }
  
  /// إنتاج توصيات عامة
  static List<String> _generateRecommendations(List<ResponsiveTestCase> testCases) {
    List<String> recommendations = [];
    
    // فحص الأجهزة التي فشلت
    final failedCases = testCases.where((c) => !c.passed).toList();
    
    if (failedCases.isNotEmpty) {
      recommendations.add('هناك ${failedCases.length} أحجام شاشة تحتاج تحسين');
      
      // توصيات محددة لكل نوع جهاز
      final failedMobile = failedCases.where((c) => c.deviceType == DeviceType.mobile);
      if (failedMobile.isNotEmpty) {
        recommendations.add('تحسين التخطيط للموبايل مطلوب');
      }
      
      final failedDesktop = failedCases.where((c) => c.deviceType == DeviceType.desktop || c.deviceType == DeviceType.largeDesktop);
      if (failedDesktop.isNotEmpty) {
        recommendations.add('تحسين التخطيط لسطح المكتب مطلوب');
      }
    }
    
    // فحص النتائج المنخفضة
    final lowScoreCases = testCases.where((c) => c.analysis.score < 80).toList();
    if (lowScoreCases.isNotEmpty) {
      recommendations.add('${lowScoreCases.length} أحجام شاشة تحتاج تحسينات إضافية');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('التطبيق متجاوب بشكل ممتاز على جميع الشاشات! 🎉');
    }
    
    return recommendations;
  }
}

/// نتائج اختبارات التجاوب
class ResponsiveTestResults {
  final List<ResponsiveTestCase> testCases;
  final int overallScore;
  final List<String> recommendations;
  
  ResponsiveTestResults({
    required this.testCases,
    required this.overallScore,
    required this.recommendations,
  });
  
  /// عدد الاختبارات التي نجحت
  int get passedCount => testCases.where((c) => c.passed).length;
  
  /// عدد الاختبارات التي فشلت
  int get failedCount => testCases.where((c) => !c.passed).length;
  
  /// نسبة النجاح
  double get successRate => passedCount / testCases.length;
  
  /// هل النتيجة الإجمالية جيدة؟
  bool get isGood => overallScore >= 80;
  
  /// طباعة تقرير مفصل
  void printDetailedReport() {
    print('=== تقرير اختبار التجاوب ===');
    print('النتيجة الإجمالية: $overallScore/100');
    print('الاختبارات الناجحة: $passedCount/${testCases.length}');
    print('نسبة النجاح: ${(successRate * 100).toStringAsFixed(1)}%');
    print('');
    
    print('=== تفاصيل الاختبارات ===');
    for (final testCase in testCases) {
      print('${testCase.screenSize.width}x${testCase.screenSize.height} (${testCase.deviceType.name}): ${testCase.passed ? "✅" : "❌"} ${testCase.analysis.score}/100');
    }
    print('');
    
    print('=== التوصيات ===');
    for (final recommendation in recommendations) {
      print('• $recommendation');
    }
  }
}

/// حالة اختبار واحدة
class ResponsiveTestCase {
  final Size screenSize;
  final DeviceType deviceType;
  final ResponsiveAnalysis analysis;
  final List<AdditionalTest> additionalTests;
  final bool passed;
  
  ResponsiveTestCase({
    required this.screenSize,
    required this.deviceType,
    required this.analysis,
    required this.additionalTests,
    required this.passed,
  });
}

/// اختبار إضافي
class AdditionalTest {
  final String name;
  final bool passed;
  final String message;
  final double value;
  
  AdditionalTest({
    required this.name,
    required this.passed,
    required this.message,
    required this.value,
  });
}