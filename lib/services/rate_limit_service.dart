import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing rate limiting across the application
class RateLimitService {
  static final RateLimitService _instance = RateLimitService._internal();
  factory RateLimitService() => _instance;
  RateLimitService._internal();

  // Rate limiting configuration
  static const Map<String, RateLimitConfig> _operationLimits = {
    'getUserData': RateLimitConfig(perMinute: 30, perHour: 200),
    'updateUserData': RateLimitConfig(perMinute: 10, perHour: 50),
    'getStudent': RateLimitConfig(perMinute: 60, perHour: 400),
    'updateStudentStatus': RateLimitConfig(perMinute: 20, perHour: 100),
    'getBus': RateLimitConfig(perMinute: 30, perHour: 150),
    'recordTrip': RateLimitConfig(perMinute: 15, perHour: 80),
    'addComplaint': RateLimitConfig(perMinute: 5, perHour: 20),
    'sendNotification': RateLimitConfig(perMinute: 10, perHour: 60),
    'qrScan': RateLimitConfig(perMinute: 30, perHour: 200),
    'default': RateLimitConfig(perMinute: 20, perHour: 100),
  };

  // In-memory storage for rate limiting
  final Map<String, List<DateTime>> _requestHistory = {};
  final Map<String, List<DateTime>> _hourlyRequestHistory = {};

  /// Check if user can make a request for the given operation
  Future<bool> canMakeRequest(String userId, String operation) async {
    try {
      final config = _operationLimits[operation] ?? _operationLimits['default']!;
      final now = DateTime.now();
      final userKey = '${userId}_$operation';

      // Clean old requests
      _cleanOldRequests(userKey, now);

      // Initialize if not exists
      _requestHistory[userKey] ??= [];
      _hourlyRequestHistory[userKey] ??= [];

      // Check minute limit
      if (_requestHistory[userKey]!.length >= config.perMinute) {
        debugPrint('⚠️ Rate limit exceeded for $userId ($operation): ${_requestHistory[userKey]!.length}/${config.perMinute} per minute');
        await _logRateLimitViolation(userId, operation, 'minute', _requestHistory[userKey]!.length, config.perMinute);
        return false;
      }

      // Check hourly limit
      if (_hourlyRequestHistory[userKey]!.length >= config.perHour) {
        debugPrint('⚠️ Hourly rate limit exceeded for $userId ($operation): ${_hourlyRequestHistory[userKey]!.length}/${config.perHour} per hour');
        await _logRateLimitViolation(userId, operation, 'hour', _hourlyRequestHistory[userKey]!.length, config.perHour);
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error checking rate limit: $e');
      return true; // Allow request if rate limiting fails
    }
  }

  /// Record a request for rate limiting
  void recordRequest(String userId, String operation) {
    try {
      final now = DateTime.now();
      final userKey = '${userId}_$operation';

      _requestHistory[userKey] ??= [];
      _hourlyRequestHistory[userKey] ??= [];

      _requestHistory[userKey]!.add(now);
      _hourlyRequestHistory[userKey]!.add(now);

      debugPrint('📊 Request recorded for $userId ($operation). Minute: ${_requestHistory[userKey]!.length}, Hour: ${_hourlyRequestHistory[userKey]!.length}');
    } catch (e) {
      debugPrint('❌ Error recording request: $e');
    }
  }

  /// Clean old requests from memory
  void _cleanOldRequests(String userKey, DateTime now) {
    // Clean requests older than 1 minute
    _requestHistory[userKey]?.removeWhere(
      (timestamp) => now.difference(timestamp) > const Duration(minutes: 1),
    );

    // Clean requests older than 1 hour
    _hourlyRequestHistory[userKey]?.removeWhere(
      (timestamp) => now.difference(timestamp) > const Duration(hours: 1),
    );
  }

  /// Get current rate limit status for user and operation
  RateLimitStatus getRateLimitStatus(String userId, String operation) {
    final config = _operationLimits[operation] ?? _operationLimits['default']!;
    final userKey = '${userId}_$operation';
    final now = DateTime.now();

    // Clean old requests
    _cleanOldRequests(userKey, now);

    final minuteRequests = _requestHistory[userKey]?.length ?? 0;
    final hourlyRequests = _hourlyRequestHistory[userKey]?.length ?? 0;

    return RateLimitStatus(
      operation: operation,
      minuteRequests: minuteRequests,
      maxPerMinute: config.perMinute,
      hourlyRequests: hourlyRequests,
      maxPerHour: config.perHour,
      canMakeRequest: minuteRequests < config.perMinute && hourlyRequests < config.perHour,
      remainingMinute: config.perMinute - minuteRequests,
      remainingHour: config.perHour - hourlyRequests,
    );
  }

  /// Get rate limit status for all operations for a user
  Map<String, RateLimitStatus> getAllRateLimitStatus(String userId) {
    final result = <String, RateLimitStatus>{};
    
    for (final operation in _operationLimits.keys) {
      if (operation != 'default') {
        result[operation] = getRateLimitStatus(userId, operation);
      }
    }
    
    return result;
  }

  /// Log rate limit violation for monitoring
  Future<void> _logRateLimitViolation(String userId, String operation, String limitType, int currentCount, int maxAllowed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final violations = prefs.getStringList('rate_limit_violations') ?? [];
      
      final violation = {
        'userId': userId,
        'operation': operation,
        'limitType': limitType,
        'currentCount': currentCount,
        'maxAllowed': maxAllowed,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      violations.add(jsonEncode(violation));
      
      // Keep only last 100 violations
      if (violations.length > 100) {
        violations.removeRange(0, violations.length - 100);
      }
      
      await prefs.setStringList('rate_limit_violations', violations);
      debugPrint('📝 Rate limit violation logged for $userId ($operation)');
    } catch (e) {
      debugPrint('❌ Error logging rate limit violation: $e');
    }
  }

  /// Get rate limit violations for monitoring
  Future<List<Map<String, dynamic>>> getRateLimitViolations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final violations = prefs.getStringList('rate_limit_violations') ?? [];
      
      return violations.map((violation) => jsonDecode(violation) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('❌ Error getting rate limit violations: $e');
      return [];
    }
  }

  /// Clear rate limit violations log
  Future<void> clearRateLimitViolations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rate_limit_violations');
      debugPrint('🗑️ Rate limit violations cleared');
    } catch (e) {
      debugPrint('❌ Error clearing rate limit violations: $e');
    }
  }

  /// Reset rate limits for a user (admin function)
  void resetUserRateLimits(String userId) {
    final keysToRemove = <String>[];
    
    for (final key in _requestHistory.keys) {
      if (key.startsWith(userId)) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _requestHistory.remove(key);
      _hourlyRequestHistory.remove(key);
    }
    
    debugPrint('🔄 Rate limits reset for user: $userId');
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    int totalMinuteEntries = 0;
    int totalHourlyEntries = 0;
    
    for (final entries in _requestHistory.values) {
      totalMinuteEntries += entries.length;
    }
    
    for (final entries in _hourlyRequestHistory.values) {
      totalHourlyEntries += entries.length;
    }
    
    return {
      'uniqueUserOperations': _requestHistory.length,
      'totalMinuteEntries': totalMinuteEntries,
      'totalHourlyEntries': totalHourlyEntries,
      'memoryUsageKB': ((totalMinuteEntries + totalHourlyEntries) * 24) / 1024, // Rough estimate
    };
  }
}

/// Configuration for rate limiting per operation
class RateLimitConfig {
  final int perMinute;
  final int perHour;
  
  const RateLimitConfig({
    required this.perMinute,
    required this.perHour,
  });
}

/// Status of rate limiting for a specific operation
class RateLimitStatus {
  final String operation;
  final int minuteRequests;
  final int maxPerMinute;
  final int hourlyRequests;
  final int maxPerHour;
  final bool canMakeRequest;
  final int remainingMinute;
  final int remainingHour;
  
  const RateLimitStatus({
    required this.operation,
    required this.minuteRequests,
    required this.maxPerMinute,
    required this.hourlyRequests,
    required this.maxPerHour,
    required this.canMakeRequest,
    required this.remainingMinute,
    required this.remainingHour,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'minuteRequests': minuteRequests,
      'maxPerMinute': maxPerMinute,
      'hourlyRequests': hourlyRequests,
      'maxPerHour': maxPerHour,
      'canMakeRequest': canMakeRequest,
      'remainingMinute': remainingMinute,
      'remainingHour': remainingHour,
    };
  }
}
