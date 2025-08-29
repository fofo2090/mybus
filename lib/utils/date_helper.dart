import 'package:intl/intl.dart';

class DateHelper {
  // Arabic date formatter
  static final DateFormat _arabicDateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
  static final DateFormat _arabicTimeFormat = DateFormat('HH:mm', 'ar');
  static final DateFormat _arabicDateTimeFormat = DateFormat('EEEE، d MMMM yyyy - HH:mm', 'ar');
  
  // English date formatter (for debugging/logs)
  static final DateFormat _englishDateFormat = DateFormat('EEEE, MMMM d, yyyy', 'en');
  static final DateFormat _englishTimeFormat = DateFormat('HH:mm', 'en');
  static final DateFormat _englishDateTimeFormat = DateFormat('EEEE, MMMM d, yyyy - HH:mm', 'en');

  // Format date in Arabic
  static String formatDateArabic(DateTime date) {
    return _arabicDateFormat.format(date);
  }

  // Format time in Arabic
  static String formatTimeArabic(DateTime date) {
    return _arabicTimeFormat.format(date);
  }

  // Format date and time in Arabic
  static String formatDateTimeArabic(DateTime date) {
    return _arabicDateTimeFormat.format(date);
  }

  // Format date in English
  static String formatDateEnglish(DateTime date) {
    return _englishDateFormat.format(date);
  }

  // Format time in English
  static String formatTimeEnglish(DateTime date) {
    return _englishTimeFormat.format(date);
  }

  // Format date and time in English
  static String formatDateTimeEnglish(DateTime date) {
    return _englishDateTimeFormat.format(date);
  }

  // Get formatted time (24-hour format)
  static String getFormattedTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted date (dd/MM/yyyy)
  static String getFormattedDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Get time ago string in Arabic
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'منذ سنة' : 'منذ $years سنوات';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'منذ شهر' : 'منذ $months أشهر';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'منذ يوم' : 'منذ ${difference.inDays} أيام';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? 'منذ ساعة' : 'منذ ${difference.inHours} ساعات';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? 'منذ دقيقة' : 'منذ ${difference.inMinutes} دقائق';
    } else {
      return 'الآن';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  // Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of week (Monday)
  static DateTime getStartOfWeek(DateTime date) {
    final startOfDay = getStartOfDay(date);
    return startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
  }

  // Get end of week (Sunday)
  static DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    return getEndOfDay(startOfWeek.add(const Duration(days: 6)));
  }

  // Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    final nextMonth = date.month == 12 
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  // Get day name in Arabic
  static String getDayNameArabic(DateTime date) {
    const dayNames = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return dayNames[date.weekday - 1];
  }

  // Get month name in Arabic
  static String getMonthNameArabic(DateTime date) {
    const monthNames = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return monthNames[date.month - 1];
  }

  // Check if time is morning (6 AM - 12 PM)
  static bool isMorning(DateTime time) {
    return time.hour >= 6 && time.hour < 12;
  }

  // Check if time is afternoon (12 PM - 6 PM)
  static bool isAfternoon(DateTime time) {
    return time.hour >= 12 && time.hour < 18;
  }

  // Check if time is evening (6 PM - 10 PM)
  static bool isEvening(DateTime time) {
    return time.hour >= 18 && time.hour < 22;
  }

  // Check if time is night (10 PM - 6 AM)
  static bool isNight(DateTime time) {
    return time.hour >= 22 || time.hour < 6;
  }

  // Get time period in Arabic
  static String getTimePeriodArabic(DateTime time) {
    if (isMorning(time)) {
      return 'صباحاً';
    } else if (isAfternoon(time)) {
      return 'ظهراً';
    } else if (isEvening(time)) {
      return 'مساءً';
    } else {
      return 'ليلاً';
    }
  }

  // Calculate age from birth date
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // Get relative date string
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'اليوم';
    } else if (isYesterday(date)) {
      return 'أمس';
    } else if (isThisWeek(date)) {
      return getDayNameArabic(date);
    } else if (isThisMonth(date)) {
      return '${date.day} ${getMonthNameArabic(date)}';
    } else {
      return getFormattedDate(date);
    }
  }

  // Parse date string
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Convert to UTC
  static DateTime toUTC(DateTime dateTime) {
    return dateTime.toUtc();
  }

  // Convert from UTC to local
  static DateTime fromUTC(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  // Add business days (excluding weekends)
  static DateTime addBusinessDays(DateTime date, int days) {
    DateTime result = date;
    int addedDays = 0;
    
    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      // Skip weekends (Friday = 5, Saturday = 6 in Dart)
      if (result.weekday != DateTime.friday && result.weekday != DateTime.saturday) {
        addedDays++;
      }
    }
    
    return result;
  }

  // Check if date is weekend (Friday or Saturday in Saudi Arabia)
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
  }

  // Get next business day
  static DateTime getNextBusinessDay(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (isWeekend(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }
}
