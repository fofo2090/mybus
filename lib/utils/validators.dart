class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    
    return null;
  }

  // Password validation - تحسين أمان كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }

    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }

    if (value.length > 128) {
      return 'كلمة المرور طويلة جداً (الحد الأقصى 128 حرف)';
    }

    // التحقق من وجود حرف كبير
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
    }

    // التحقق من وجود حرف صغير
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل';
    }

    // التحقق من وجود رقم
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }

    // التحقق من عدم وجود مسافات
    if (value.contains(' ')) {
      return 'كلمة المرور لا يجب أن تحتوي على مسافات';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    
    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    
    if (value.length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    
    if (value.length > 50) {
      return 'الاسم يجب أن يكون أقل من 50 حرف';
    }
    
    // Check if name contains only letters and spaces
    final nameRegex = RegExp(r'^[a-zA-Zأ-ي\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'الاسم يجب أن يحتوي على أحرف فقط';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    
    // Remove any non-digit characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length < 10) {
      return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
    }
    
    if (cleanPhone.length > 15) {
      return 'رقم الهاتف يجب أن يكون أقل من 15 رقم';
    }
    
    // Check if phone starts with valid country/area codes
    final phoneRegex = RegExp(r'^(05|009665|9665|\+9665)[0-9]{8,12}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'يرجى إدخال رقم هاتف صحيح';
    }
    
    return null;
  }

  // Student name validation
  static String? validateStudentName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال اسم الطالب';
    }
    
    if (value.length < 2) {
      return 'اسم الطالب يجب أن يكون حرفين على الأقل';
    }
    
    if (value.length > 50) {
      return 'اسم الطالب يجب أن يكون أقل من 50 حرف';
    }
    
    return null;
  }

  // Grade validation
  static String? validateGrade(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الصف الدراسي';
    }
    
    if (value.length > 20) {
      return 'الصف الدراسي يجب أن يكون أقل من 20 حرف';
    }
    
    return null;
  }

  // School name validation
  static String? validateSchoolName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال اسم المدرسة';
    }
    
    if (value.length < 3) {
      return 'اسم المدرسة يجب أن يكون 3 أحرف على الأقل';
    }
    
    if (value.length > 100) {
      return 'اسم المدرسة يجب أن يكون أقل من 100 حرف';
    }
    
    return null;
  }

  // Bus route validation
  static String? validateBusRoute(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال خط الباص';
    }
    
    if (value.length > 50) {
      return 'خط الباص يجب أن يكون أقل من 50 حرف';
    }
    
    return null;
  }

  // QR Code validation
  static String? validateQRCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'رمز QR غير صحيح';
    }
    
    if (value.length < 10) {
      return 'رمز QR قصير جداً';
    }
    
    if (value.length > 100) {
      return 'رمز QR طويل جداً';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    if (value.length < minLength) {
      return '$fieldName يجب أن يكون $minLength أحرف على الأقل';
    }
    
    return null;
  }

  // Maximum length validation
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName يجب أن يكون أقل من $maxLength حرف';
    }
    
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(value)) {
      return '$fieldName يجب أن يحتوي على أرقام فقط';
    }
    
    return null;
  }

  // Arabic text validation
  static String? validateArabicText(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    final arabicRegex = RegExp(r'^[أ-ي\s]+$');
    if (!arabicRegex.hasMatch(value)) {
      return '$fieldName يجب أن يحتوي على أحرف عربية فقط';
    }
    
    return null;
  }

  // English text validation
  static String? validateEnglishText(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    final englishRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!englishRegex.hasMatch(value)) {
      return '$fieldName يجب أن يحتوي على أحرف إنجليزية فقط';
    }
    
    return null;
  }

  // URL validation
  static String? validateURL(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الرابط';
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'يرجى إدخال رابط صحيح';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال التاريخ';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'تاريخ غير صحيح';
    }
  }

  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال العمر';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'العمر يجب أن يكون رقم';
    }

    if (age < 3 || age > 18) {
      return 'العمر يجب أن يكون بين 3 و 18 سنة';
    }

    return null;
  }

  // Input sanitization - تنظيف المدخلات من الأكواد الضارة
  static String sanitizeInput(String? input) {
    if (input == null) return '';

    // إزالة HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // إزالة JavaScript
    sanitized = sanitized.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '');

    // إزالة SQL injection patterns
    sanitized = sanitized.replaceAll(RegExp(r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)', caseSensitive: false), '');

    // إزالة الأحرف الخطيرة
    sanitized = sanitized.replaceAll(RegExp(r'[<>"\']'), '');

    return sanitized.trim();
  }

  // XSS protection - حماية من هجمات XSS
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  // SQL injection protection
  static bool containsSqlInjection(String input) {
    final sqlPatterns = [
      r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b',
      r'(\-\-|\#|\/\*|\*\/)',
      r'(\bOR\b|\bAND\b).*(\=|\<|\>)',
      r'(\;|\||\&)',
    ];

    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  // File upload validation - التحقق من الملفات المرفوعة
  static String? validateFileUpload(String fileName, int fileSize) {
    // التحقق من امتداد الملف
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'نوع الملف غير مسموح. الأنواع المسموحة: ${allowedExtensions.join(', ')}';
    }

    // التحقق من حجم الملف (5MB max)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (fileSize > maxSize) {
      return 'حجم الملف كبير جداً. الحد الأقصى 5 ميجابايت';
    }

    // التحقق من اسم الملف
    if (fileName.contains('..') || fileName.contains('/') || fileName.contains('\\')) {
      return 'اسم الملف يحتوي على أحرف غير مسموحة';
    }

    return null;
  }

  // Rate limiting validation - التحقق من معدل الطلبات
  static bool isRateLimited(String userId, String action, Map<String, DateTime> lastRequests) {
    final key = '${userId}_$action';
    final lastRequest = lastRequests[key];

    if (lastRequest == null) {
      lastRequests[key] = DateTime.now();
      return false;
    }

    final timeDiff = DateTime.now().difference(lastRequest);
    const minInterval = Duration(seconds: 1); // حد أدنى ثانية واحدة بين الطلبات

    if (timeDiff < minInterval) {
      return true; // محدود
    }

    lastRequests[key] = DateTime.now();
    return false;
  }

  // Comprehensive input validation - تحقق شامل من المدخلات
  static String? validateSecureInput(String? value, String fieldName, {
    int? minLength,
    int? maxLength,
    bool allowNumbers = true,
    bool allowSpecialChars = false,
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'يرجى إدخال $fieldName' : null;
    }

    // تنظيف المدخل
    final sanitized = sanitizeInput(value);
    if (sanitized != value) {
      return '$fieldName يحتوي على أحرف غير مسموحة';
    }

    // التحقق من SQL injection
    if (containsSqlInjection(value)) {
      return '$fieldName يحتوي على أحرف خطيرة';
    }

    // التحقق من الطول
    if (minLength != null && value.length < minLength) {
      return '$fieldName يجب أن يكون $minLength أحرف على الأقل';
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName يجب أن يكون $maxLength حرف كحد أقصى';
    }

    // التحقق من الأرقام
    if (!allowNumbers && RegExp(r'[0-9]').hasMatch(value)) {
      return '$fieldName لا يجب أن يحتوي على أرقام';
    }

    // التحقق من الأحرف الخاصة
    if (!allowSpecialChars && RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return '$fieldName لا يجب أن يحتوي على أحرف خاصة';
    }

    return null;
  }
}
