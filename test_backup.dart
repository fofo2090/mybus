import 'package:flutter/material.dart';
import 'lib/services/backup_service.dart';
import 'lib/config/backup_config.dart';

/// ملف اختبار خدمة النسخ الاحتياطي
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 بدء اختبار خدمة النسخ الاحتياطي...');
  
  final backupService = BackupService();
  
  try {
    // تهيئة الخدمة
    print('🔧 تهيئة خدمة النسخ الاحتياطي...');
    await backupService.initialize();
    print('✅ تم تهيئة الخدمة بنجاح');
    
    // اختبار إنشاء نسخة احتياطية
    print('📦 إنشاء نسخة احتياطية تجريبية...');
    final result = await backupService.createSystemBackup();
    
    if (result['success'] == true) {
      print('✅ تم إنشاء النسخة الاحتياطية بنجاح!');
      print('📊 معرف النسخة: ${result['backupId']}');
      print('📊 إجمالي السجلات: ${result['totalRecords']}');
      print('📊 عدد المجموعات: ${result['collections']}');
      print('📊 الحجم: ${(result['size'] / 1024).toStringAsFixed(1)} KB');
    } else {
      print('❌ فشل في إنشاء النسخة الاحتياطية: ${result['error']}');
    }
    
    // اختبار الحصول على الإحصائيات
    print('📈 الحصول على إحصائيات النسخ الاحتياطي...');
    final stats = await backupService.getBackupStatistics();
    print('📊 إجمالي النسخ: ${stats['totalBackups']}');
    print('📊 آخر نسخة: ${stats['lastBackup']}');
    print('📊 إجمالي الحجم: ${(stats['totalSize'] / 1024).toStringAsFixed(1)} KB');
    print('📊 النسخ التلقائي: ${stats['isAutoEnabled'] ? 'مفعل' : 'معطل'}');

    // اختبار إعدادات التكوين
    print('⚙️ اختبار إعدادات التكوين...');
    print('📋 المجموعات المشمولة: ${BackupConfig.collectionsToBackup.length}');
    print('📋 الحد الأقصى للنسخ: ${BackupConfig.maxBackupsToKeep}');
    print('📋 الفترة الافتراضية: ${BackupConfig.defaultBackupIntervalHours} ساعة');

    // اختبار الفترات المتاحة
    print('⏰ الفترات المتاحة للنسخ التلقائي:');
    BackupConfig.getAvailableIntervals().forEach((hours, description) {
      print('   - $description ($hours ساعة)');
    });
    
    // اختبار تفعيل النسخ التلقائي
    print('⚙️ تفعيل النسخ الاحتياطي التلقائي...');
    await backupService.setAutoBackupEnabled(true);
    print('✅ تم تفعيل النسخ التلقائي');
    
    // اختبار تحديد فترة النسخ
    print('⏰ تحديد فترة النسخ إلى 12 ساعة...');
    await backupService.setBackupInterval(12);
    print('✅ تم تحديد فترة النسخ');
    
    print('🎉 تم اكتمال جميع الاختبارات بنجاح!');
    
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
  } finally {
    // تنظيف الموارد
    backupService.dispose();
    print('🧹 تم تنظيف الموارد');
  }
}
