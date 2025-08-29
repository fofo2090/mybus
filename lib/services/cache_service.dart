import 'package:flutter/foundation.dart';
import 'dart:convert';

/// أولوية التخزين المؤقت
enum CachePriority {
  low(1),
  normal(2),
  high(3),
  critical(4);

  const CachePriority(this.value);
  final int value;
}

/// عنصر التخزين المؤقت
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiration;
  final int accessCount;
  final DateTime lastAccessed;
  final CachePriority priority;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiration,
    this.accessCount = 1,
    DateTime? lastAccessed,
    this.priority = CachePriority.normal,
  }) : lastAccessed = lastAccessed ?? DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > expiration;
  
  CacheEntry copyWithAccess() {
    return CacheEntry(
      data: data,
      timestamp: timestamp,
      expiration: expiration,
      accessCount: accessCount + 1,
      lastAccessed: DateTime.now(),
      priority: priority,
    );
  }
}

/// خدمة التخزين المؤقت البسيطة
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // التخزين المؤقت في الذاكرة
  final Map<String, CacheEntry> _memoryCache = {};
  
  // إحصائيات الأداء
  int _hits = 0;
  int _misses = 0;

  /// الحصول على البيانات من التخزين المؤقت
  Future<T?> get<T>(String key) async {
    try {
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        
        if (!entry.isExpired) {
          _hits++;
          _memoryCache[key] = entry.copyWithAccess();
          return entry.data as T?;
        } else {
          _memoryCache.remove(key);
        }
      }

      _misses++;
      return null;
    } catch (e) {
      debugPrint('❌ Cache get error: $e');
      return null;
    }
  }

  /// حفظ البيانات في التخزين المؤقت
  Future<void> set<T>(
    String key,
    T data, {
    Duration? expiration,
    CachePriority priority = CachePriority.normal,
  }) async {
    try {
      expiration ??= const Duration(minutes: 5);
      
      final entry = CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        expiration: expiration,
        priority: priority,
      );

      _memoryCache[key] = entry;
      
      // تنظيف الذاكرة إذا لزم الأمر
      if (_memoryCache.length > 100) {
        _cleanupMemoryCache();
      }
    } catch (e) {
      debugPrint('❌ Cache set error: $e');
    }
  }

  /// إزالة عنصر من التخزين المؤقت
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
  }

  /// مسح جميع البيانات المؤقتة
  Future<void> clear() async {
    _memoryCache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// تنظيف الذاكرة
  void _cleanupMemoryCache() {
    // إزالة العناصر المنتهية الصلاحية
    final expiredKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    // إزالة العناصر الأقل استخداماً إذا لزم الأمر
    if (_memoryCache.length > 50) {
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final keysToRemove = sortedEntries
          .take(_memoryCache.length - 50)
          .map((entry) => entry.key)
          .toList();

      for (final key in keysToRemove) {
        _memoryCache.remove(key);
      }
    }
  }

  /// إحصائيات الأداء
  Map<String, dynamic> getStats() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? (_hits / totalRequests) * 100 : 0.0;
    
    return {
      'hits': _hits,
      'misses': _misses,
      'hitRate': hitRate,
      'cacheSize': _memoryCache.length,
      'totalRequests': totalRequests,
    };
  }
}
