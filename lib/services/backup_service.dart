import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/backup_config.dart';

/// خدمة النسخ الاحتياطي التلقائي والمجدول
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _autoBackupTimer;
  bool _isAutoBackupEnabled = false;
  
  // استخدام إعدادات من ملف التكوين
  static const String _autoBackupKey = BackupConfig.autoBackupEnabledKey;
  static const String _lastBackupKey = BackupConfig.lastBackupDateKey;
  static const String _backupIntervalKey = BackupConfig.backupIntervalKey;

  // الفترة الافتراضية للنسخ الاحتياطي
  static const int _defaultBackupIntervalHours = BackupConfig.defaultBackupIntervalHours;

  /// تهيئة خدمة النسخ الاحتياطي
  Future<void> initialize() async {
    try {
      debugPrint('🔧 تهيئة خدمة النسخ الاحتياطي...');
      
      final prefs = await SharedPreferences.getInstance();
      _isAutoBackupEnabled = prefs.getBool(_autoBackupKey) ?? false;
      
      if (_isAutoBackupEnabled) {
        await _startAutoBackup();
        debugPrint('✅ تم تفعيل النسخ الاحتياطي التلقائي');
      }
      
      debugPrint('✅ تم تهيئة خدمة النسخ الاحتياطي');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة النسخ الاحتياطي: $e');
    }
  }

  /// تفعيل أو إلغاء تفعيل النسخ الاحتياطي التلقائي
  Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBackupKey, enabled);
      _isAutoBackupEnabled = enabled;
      
      if (enabled) {
        await _startAutoBackup();
        debugPrint('✅ تم تفعيل النسخ الاحتياطي التلقائي');
      } else {
        _stopAutoBackup();
        debugPrint('⏹️ تم إيقاف النسخ الاحتياطي التلقائي');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تعديل إعدادات النسخ الاحتياطي: $e');
    }
  }

  /// الحصول على حالة النسخ الاحتياطي التلقائي
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;

  /// بدء النسخ الاحتياطي التلقائي
  Future<void> _startAutoBackup() async {
    _stopAutoBackup(); // إيقاف أي مؤقت سابق
    
    final prefs = await SharedPreferences.getInstance();
    final intervalHours = prefs.getInt(_backupIntervalKey) ?? _defaultBackupIntervalHours;
    
    // التحقق من آخر نسخة احتياطية
    final lastBackupString = prefs.getString(_lastBackupKey);
    DateTime? lastBackup;
    
    if (lastBackupString != null) {
      lastBackup = DateTime.tryParse(lastBackupString);
    }
    
    // حساب الوقت المتبقي للنسخة التالية
    Duration nextBackupDelay;
    if (lastBackup != null) {
      final timeSinceLastBackup = DateTime.now().difference(lastBackup);
      final intervalDuration = Duration(hours: intervalHours);
      
      if (timeSinceLastBackup >= intervalDuration) {
        // حان وقت النسخة الاحتياطية
        nextBackupDelay = const Duration(minutes: 1);
      } else {
        // حساب الوقت المتبقي
        nextBackupDelay = intervalDuration - timeSinceLastBackup;
      }
    } else {
      // لا توجد نسخة سابقة، إنشاء نسخة فوراً
      nextBackupDelay = const Duration(minutes: 1);
    }
    
    debugPrint('⏰ النسخة الاحتياطية التالية خلال: ${nextBackupDelay.inMinutes} دقيقة');
    
    _autoBackupTimer = Timer.periodic(
      Duration(hours: intervalHours),
      (timer) => _performScheduledBackup(),
    );
    
    // إنشاء النسخة الأولى إذا لزم الأمر
    if (nextBackupDelay.inMinutes <= 1) {
      Timer(nextBackupDelay, () => _performScheduledBackup());
    }
  }

  /// إيقاف النسخ الاحتياطي التلقائي
  void _stopAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
  }

  /// تنفيذ النسخ الاحتياطي المجدول
  Future<void> _performScheduledBackup() async {
    try {
      debugPrint('🔄 بدء النسخ الاحتياطي المجدول...');
      
      final result = await createSystemBackup();
      
      if (result['success'] == true) {
        // حفظ تاريخ آخر نسخة احتياطية
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
        
        debugPrint('✅ تم إنشاء النسخة الاحتياطية المجدولة بنجاح: ${result['backupId']}');
        
        // تنظيف النسخ القديمة
        await _cleanupOldBackups();
      } else {
        debugPrint('❌ فشل في النسخ الاحتياطي المجدول: ${result['error']}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في النسخ الاحتياطي المجدول: $e');
    }
  }

  /// إنشاء نسخة احتياطية شاملة للنظام
  Future<Map<String, dynamic>> createSystemBackup() async {
    try {
      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = <String, dynamic>{};
      int totalRecords = 0;

      // قائمة المجموعات المراد نسخها من ملف التكوين
      final collections = BackupConfig.collectionsToBackup;

      // نسخ كل مجموعة
      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).get();
          final collectionData = <Map<String, dynamic>>[];
          
          for (final doc in snapshot.docs) {
            collectionData.add({
              'id': doc.id,
              ...doc.data(),
            });
          }
          
          backupData[collection] = collectionData;
          totalRecords += collectionData.length;
          
          debugPrint('✅ نسخ مجموعة $collection: ${collectionData.length} سجل');
        } catch (e) {
          debugPrint('❌ خطأ في نسخ مجموعة $collection: $e');
          backupData[collection] = [];
        }
      }

      // معلومات النسخة الاحتياطية
      final backupInfo = {
        'id': backupId,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': 'system',
        'type': 'auto',
        'version': '1.0',
        'totalRecords': totalRecords,
        'collections': collections,
        'status': 'completed',
      };

      // حفظ النسخة الاحتياطية في Firestore
      final backupWithData = {
        ...backupInfo,
        'data': backupData,
      };

      // حساب الحجم
      final backupJson = jsonEncode(backupWithData);
      backupInfo['size'] = backupJson.length;

      await _firestore
          .collection(BackupConfig.backupCollectionName)
          .doc(backupId)
          .set(backupWithData);

      debugPrint('✅ تم إنشاء النسخة الاحتياطية بنجاح: $backupId');
      
      return {
        'success': true,
        'backupId': backupId,
        'totalRecords': totalRecords,
        'collections': collections.length,
        'size': backupJson.length,
      };

    } catch (e) {
      debugPrint('❌ خطأ في إنشاء النسخة الاحتياطية: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// تنظيف النسخ الاحتياطية القديمة (الاحتفاظ بآخر 10 نسخ)
  Future<void> _cleanupOldBackups() async {
    try {
      debugPrint('🧹 تنظيف النسخ الاحتياطية القديمة...');
      
      final snapshot = await _firestore
          .collection(BackupConfig.backupCollectionName)
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.length > BackupConfig.maxBackupsToKeep) {
        final oldBackups = snapshot.docs.skip(BackupConfig.maxBackupsToKeep).toList();
        
        for (final doc in oldBackups) {
          await doc.reference.delete();
          debugPrint('🗑️ تم حذف النسخة القديمة: ${doc.id}');
        }
        
        debugPrint('✅ تم تنظيف ${oldBackups.length} نسخة قديمة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف النسخ القديمة: $e');
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية
  Stream<List<Map<String, dynamic>>> getBackupsList() {
    return _firestore
        .collection(BackupConfig.backupCollectionName)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
        });
  }

  /// الحصول على إحصائيات النسخ الاحتياطي
  Future<Map<String, dynamic>> getBackupStatistics() async {
    try {
      final snapshot = await _firestore.collection(BackupConfig.backupCollectionName).get();
      final prefs = await SharedPreferences.getInstance();
      
      final totalBackups = snapshot.docs.length;
      final lastBackupString = prefs.getString(_lastBackupKey);
      final lastBackup = lastBackupString != null 
          ? DateTime.tryParse(lastBackupString) 
          : null;
      
      // حساب إجمالي حجم النسخ
      int totalSize = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalSize += (data['size'] as int?) ?? 0;
      }
      
      return {
        'totalBackups': totalBackups,
        'lastBackup': lastBackup,
        'totalSize': totalSize,
        'isAutoEnabled': _isAutoBackupEnabled,
      };
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على إحصائيات النسخ: $e');
      return {
        'totalBackups': 0,
        'lastBackup': null,
        'totalSize': 0,
        'isAutoEnabled': false,
      };
    }
  }

  /// تحديد فترة النسخ الاحتياطي التلقائي
  Future<void> setBackupInterval(int hours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_backupIntervalKey, hours);
      
      // إعادة تشغيل النسخ التلقائي بالفترة الجديدة
      if (_isAutoBackupEnabled) {
        await _startAutoBackup();
      }
      
      debugPrint('✅ تم تحديد فترة النسخ الاحتياطي إلى $hours ساعة');
    } catch (e) {
      debugPrint('❌ خطأ في تحديد فترة النسخ الاحتياطي: $e');
    }
  }

  /// الحصول على فترة النسخ الاحتياطي الحالية
  Future<int> getBackupInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_backupIntervalKey) ?? _defaultBackupIntervalHours;
  }

  /// تنظيف الموارد
  void dispose() {
    _stopAutoBackup();
  }
}
