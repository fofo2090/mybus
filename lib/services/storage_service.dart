import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compress image to reduce file size
  /// Returns compressed image data as Uint8List
  Uint8List compressImage(Uint8List imageData, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) {
    try {
      debugPrint('🔄 Starting image compression...');
      debugPrint('📊 Original size: ${imageData.length} bytes');

      // Decode the image
      img.Image? image = img.decodeImage(imageData);
      if (image == null) {
        debugPrint('❌ Failed to decode image');
        return imageData; // Return original if can't decode
      }

      debugPrint('📐 Original dimensions: ${image.width}x${image.height}');

      // Resize image if it's too large
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
        );
        debugPrint('📐 Resized to: ${image.width}x${image.height}');
      }

      // Compress as JPEG with specified quality
      final compressedData = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      debugPrint('📊 Compressed size: ${compressedData.length} bytes');
      final compressionRatio = ((imageData.length - compressedData.length) / imageData.length * 100);
      debugPrint('📉 Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');

      return compressedData;
    } catch (e) {
      debugPrint('❌ Image compression failed: $e');
      return imageData; // Return original if compression fails
    }
  }

  /// Compress image for profile photos (smaller size)
  Uint8List compressProfileImage(Uint8List imageData) {
    return compressImage(
      imageData,
      maxWidth: 400,
      maxHeight: 400,
      quality: 80,
    );
  }

  /// Compress image for student photos with enhanced error handling
  Uint8List compressStudentImage(Uint8List imageData) {
    try {
      debugPrint('📊 Original student image size: ${imageData.length} bytes');

      final compressed = compressImage(
        imageData,
        maxWidth: 800,
        maxHeight: 800,
        quality: 85,
      );

      debugPrint('📊 Compressed student image size: ${compressed.length} bytes');
      debugPrint('📊 Compression ratio: ${((1 - compressed.length / imageData.length) * 100).toStringAsFixed(1)}%');

      return compressed;
    } catch (e) {
      debugPrint('❌ Error compressing student image: $e');
      // Return original image if compression fails
      return imageData;
    }
  }

  /// Compress image for bus photos
  Uint8List compressBusImage(Uint8List imageData) {
    return compressImage(
      imageData,
      maxWidth: 800,
      maxHeight: 600,
      quality: 90,
    );
  }

  /// Test Firebase Storage connection with enhanced checks
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing Firebase Storage connection...');

      // First, try a simple operation to check if Storage is enabled
      try {
        final ref = _storage.ref();

        // Try to get the root reference metadata instead of listing
        // This is less likely to fail if Storage is enabled but empty
        await ref.getMetadata().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Connection timeout');
          },
        );

        debugPrint('✅ Firebase Storage is accessible via metadata check');
      } catch (metadataError) {
        debugPrint('⚠️ Metadata check failed, trying alternative method: $metadataError');

        // If metadata fails, try to create a simple test file
        // This will work even if the bucket is empty
        final testRef = _storage.ref().child('test/connection_test_${DateTime.now().millisecondsSinceEpoch}.txt');
        final testData = Uint8List.fromList('connection_test'.codeUnits);

        try {
          await testRef.putData(testData).timeout(const Duration(seconds: 15));
          debugPrint('✅ Test file uploaded successfully');

          // Try to delete the test file
          try {
            await testRef.delete();
            debugPrint('✅ Test file deleted successfully');
          } catch (deleteError) {
            debugPrint('⚠️ Test file uploaded but deletion failed: $deleteError');
          }

        } catch (uploadError) {
          debugPrint('❌ Test file upload failed: $uploadError');
          rethrow;
        }
      }

      debugPrint('✅ Firebase Storage connection verified');
      return true;

    } catch (e) {
      debugPrint('❌ Firebase Storage connection failed: $e');

      // Enhanced error detection
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('object-not-found')) {
        debugPrint('🚨 Firebase Storage may not be enabled for this project');
      } else if (errorString.contains('permission-denied')) {
        debugPrint('🔒 Permission denied - check Storage rules');
      } else if (errorString.contains('network')) {
        debugPrint('🌐 Network connectivity issue detected');
      } else if (errorString.contains('timeout')) {
        debugPrint('⏰ Connection timeout detected');
      } else if (errorString.contains('unauthenticated')) {
        debugPrint('🔐 User not authenticated');
      } else {
        debugPrint('❓ Unknown storage error: $e');
      }

      return false;
    }
  }

  /// Upload student photo to Firebase Storage with compression and enhanced error handling
  /// Returns the download URL of the uploaded image
  Future<String> uploadStudentPhoto(Uint8List imageData, String fileName) async {
    try {
      debugPrint('🔄 Starting student photo upload: $fileName');
      debugPrint('📊 Original image size: ${imageData.length} bytes');

      // Test connection first with detailed error handling
      final isConnected = await testConnection();
      if (!isConnected) {
        // Provide more specific error message based on the type of failure
        throw Exception('Firebase Storage غير متاح حالي<|im_start|>. يرجى التأكد من:\n'
            '1. تفعيل Firebase Storage في المشروع\n'
            '2. إعداد قواعد الأمان بشكل صحيح\n'
            '3. الاتصال بالإنترنت');
      }

      // Compress the image to save storage space
      final compressedData = compressStudentImage(imageData);
      debugPrint('📊 Compressed image size: ${compressedData.length} bytes');

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      // Create a reference to the student photos folder
      final Reference ref = _storage.ref().child('student_photos/$uniqueFileName');
      debugPrint('📁 Storage reference created: ${ref.fullPath}');

      // Set metadata for the image
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'student_photo',
          'originalSize': imageData.length.toString(),
          'compressedSize': compressedData.length.toString(),
        },
      );

      debugPrint('⬆️ Starting upload task...');

      // Upload the compressed image with timeout
      final UploadTask uploadTask = ref.putData(compressedData, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('📈 Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload to complete with timeout
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('انتهت مهلة رفع الصورة. يرجى المحاولة مرة أخرى.');
        },
      );

      debugPrint('✅ Upload completed successfully');

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🔗 Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      debugPrint('📋 Error details: ${e.toString()}');

      // Enhanced error handling with specific messages
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحية لرفع الصور. يرجى التواصل مع الإدارة.');
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.');
      } else if (e.toString().contains('storage/object-not-found')) {
        throw Exception('مجلد الصور غير موجود. يرجى التواصل مع الدعم التقني.');
      } else if (e.toString().contains('storage/quota-exceeded')) {
        throw Exception('تم تجاوز حد التخزين المسموح. يرجى التواصل مع الإدارة.');
      } else if (e.toString().contains('storage/unauthenticated')) {
        throw Exception('يجب تسجيل الدخول أولاً لرفع الصور.');
      } else if (e.toString().contains('storage/unauthorized')) {
        throw Exception('ليس لديك صلاحية لرفع الصور في هذا المجلد.');
      } else if (e.toString().contains('storage/retry-limit-exceeded')) {
        throw Exception('تم تجاوز عدد المحاولات المسموح. يرجى المحاولة لاحق<|im_start|>.');
      } else {
        throw Exception('فشل في رفع الصورة: ${e.toString()}');
      }
    }
  }

  /// Upload bus photo to Firebase Storage with compression
  /// Returns the download URL of the uploaded image
  Future<String> uploadBusPhoto(Uint8List imageData, String fileName) async {
    try {
      debugPrint('🔄 Starting bus photo upload: $fileName');

      // Test connection first
      final isConnected = await testConnection();
      if (!isConnected) {
        throw Exception('لا يمكن الاتصال بخدمة تخزين الصور.');
      }

      // Compress the image
      final compressedData = compressBusImage(imageData);
      debugPrint('📊 Bus image compressed: ${imageData.length} → ${compressedData.length} bytes');

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      final Reference ref = _storage.ref().child('bus_photos/$uniqueFileName');

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'bus_photo',
          'originalSize': imageData.length.toString(),
          'compressedSize': compressedData.length.toString(),
        },
      );

      final UploadTask uploadTask = ref.putData(compressedData, metadata);
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw Exception('انتهت مهلة رفع صورة السيارة'),
      );

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Bus photo uploaded successfully');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Bus photo upload failed: $e');
      throw Exception('فشل في رفع صورة السيارة: $e');
    }
  }

  /// Upload profile photo to Firebase Storage with compression
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfilePhoto(Uint8List imageData, String fileName) async {
    try {
      debugPrint('🔄 Starting profile photo upload: $fileName');

      // Test connection first
      final isConnected = await testConnection();
      if (!isConnected) {
        throw Exception('لا يمكن الاتصال بخدمة تخزين الصور.');
      }

      // Compress the image (smaller size for profiles)
      final compressedData = compressProfileImage(imageData);
      debugPrint('📊 Profile image compressed: ${imageData.length} → ${compressedData.length} bytes');

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      final Reference ref = _storage.ref().child('profile_photos/$uniqueFileName');

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'profile_photo',
          'originalSize': imageData.length.toString(),
          'compressedSize': compressedData.length.toString(),
        },
      );

      final UploadTask uploadTask = ref.putData(compressedData, metadata);
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw Exception('انتهت مهلة رفع صورة الملف الشخصي'),
      );

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Profile photo uploaded successfully');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Profile photo upload failed: $e');
      throw Exception('فشل في رفع صورة الملف الشخصي: $e');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('فشل في حذف الملف: $e');
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('فشل في الحصول على معلومات الملف: $e');
    }
  }

  /// List all files in a specific folder
  Future<List<Reference>> listFiles(String folderPath) async {
    try {
      final Reference ref = _storage.ref().child(folderPath);
      final ListResult result = await ref.listAll();
      return result.items;
    } catch (e) {
      throw Exception('فشل في الحصول على قائمة الملفات: $e');
    }
  }

  /// Get download URL for a file
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('فشل في الحصول على رابط التحميل: $e');
    }
  }

  /// Upload any file to Firebase Storage
  Future<String> uploadFile(
    Uint8List fileData,
    String fileName,
    String folderPath, {
    String? contentType,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final Reference ref = _storage.ref().child('$folderPath/$fileName');

      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          ...?customMetadata,
        },
      );

      final UploadTask uploadTask = ref.putData(fileData, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الملف: $e');
    }
  }

  /// Delete file from Firebase Storage using URL
  Future<void> deleteFileByUrl(String fileUrl) async {
    try {
      if (fileUrl.isEmpty) return;

      debugPrint('🗑️ Attempting to delete file: $fileUrl');

      // Extract the file path from the URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after 'o/' in the URL
      int oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex + 1 >= pathSegments.length) {
        debugPrint('❌ Invalid file URL format');
        return;
      }

      // Get the file path and decode it
      final encodedPath = pathSegments[oIndex + 1];
      final filePath = Uri.decodeComponent(encodedPath);

      debugPrint('📁 Extracted file path: $filePath');

      // Create reference and delete
      final Reference ref = _storage.ref().child(filePath);
      await ref.delete();

      debugPrint('✅ File deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      // Don't throw error as this is not critical
    }
  }

  /// Update student photo - Save compressed image as base64 in Firestore
  Future<String> updateStudentPhoto(
    Uint8List imageData,
    String fileName,
    String? oldPhotoUrl,
  ) async {
    try {
      debugPrint('🔄 Updating student photo...');
      debugPrint('📊 Original image size: ${imageData.length} bytes');

      // Always save as base64 in Firestore (more reliable)
      return await _savePhotoAsBase64(imageData, fileName);
    } catch (e) {
      debugPrint('❌ Error updating student photo: $e');
      throw Exception('فشل في تحديث صورة الطالب: $e');
    }
  }

  /// Save photo as compressed base64 string for Firestore storage
  Future<String> _savePhotoAsBase64(Uint8List imageData, String fileName) async {
    try {
      debugPrint('💾 Compressing and saving photo as base64...');

      // Compress the image for optimal storage in Firestore
      final compressedData = compressImage(
        imageData,
        maxWidth: 600,
        maxHeight: 600,
        quality: 80,
      );

      debugPrint('📊 Compressed size: ${imageData.length} → ${compressedData.length} bytes');
      debugPrint('📊 Compression ratio: ${((1 - compressedData.length / imageData.length) * 100).toStringAsFixed(1)}%');

      // Convert to base64
      final base64String = base64Encode(compressedData);
      final dataUrl = 'data:image/jpeg;base64,$base64String';

      // Validate base64 size (Firestore has 1MB limit per field)
      if (base64String.length > 800000) { // ~800KB limit to be safe
        debugPrint('⚠️ Image too large, compressing further...');

        // Compress more aggressively
        final smallerData = compressImage(
          imageData,
          maxWidth: 400,
          maxHeight: 400,
          quality: 60,
        );

        final smallerBase64 = base64Encode(smallerData);
        debugPrint('📊 Further compressed: ${smallerData.length} bytes');

        if (smallerBase64.length > 800000) {
          throw Exception('الصورة كبيرة جداً حتى بعد الضغط');
        }

        return 'data:image/jpeg;base64,$smallerBase64';
      }

      debugPrint('✅ Photo compressed and converted to base64 successfully');
      debugPrint('📊 Final base64 size: ${base64String.length} characters');

      return dataUrl;
    } catch (e) {
      debugPrint('❌ Error saving photo as base64: $e');
      throw Exception('فشل في ضغط وحفظ الصورة: $e');
    }
  }



  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final List<String> folders = [
        'student_photos',
        'bus_photos',
        'profile_photos',
      ];

      Map<String, dynamic> stats = {
        'totalFiles': 0,
        'folderStats': <String, int>{},
      };

      for (String folder in folders) {
        try {
          final List<Reference> files = await listFiles(folder);
          stats['folderStats'][folder] = files.length;
          stats['totalFiles'] += files.length;
        } catch (e) {
          stats['folderStats'][folder] = 0;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('فشل في الحصول على إحصائيات التخزين: $e');
    }
  }

  /// Clean up old files (older than specified days)
  Future<List<String>> cleanupOldFiles(String folderPath, int daysOld) async {
    try {
      final List<Reference> files = await listFiles(folderPath);
      final List<String> deletedFiles = [];
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      for (Reference file in files) {
        try {
          final FullMetadata metadata = await file.getMetadata();
          if (metadata.timeCreated != null && 
              metadata.timeCreated!.isBefore(cutoffDate)) {
            await file.delete();
            deletedFiles.add(file.name);
          }
        } catch (e) {
          // Skip files that can't be processed
          continue;
        }
      }

      return deletedFiles;
    } catch (e) {
      throw Exception('فشل في تنظيف الملفات القديمة: $e');
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      final FullMetadata metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      throw Exception('فشل في الحصول على حجم الملف: $e');
    }
  }

  /// Initialize Firebase Storage by creating necessary folders
  Future<bool> initializeStorage() async {
    try {
      debugPrint('🔄 Initializing Firebase Storage...');

      // Create necessary folders by uploading placeholder files
      final folders = ['student_photos', 'bus_photos', 'profile_photos'];
      final placeholderData = Uint8List.fromList('placeholder'.codeUnits);

      for (String folder in folders) {
        try {
          final ref = _storage.ref().child('$folder/.placeholder');
          await ref.putData(placeholderData);
          debugPrint('✅ Created folder: $folder');
        } catch (e) {
          debugPrint('⚠️ Failed to create folder $folder: $e');
        }
      }

      debugPrint('✅ Firebase Storage initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Firebase Storage: $e');
      return false;
    }
  }

  /// Check if Firebase Storage is properly configured
  Future<Map<String, dynamic>> checkStorageStatus() async {
    try {
      debugPrint('🔍 Checking Firebase Storage status...');

      final status = <String, dynamic>{
        'isEnabled': false,
        'canRead': false,
        'canWrite': false,
        'folders': <String, bool>{},
        'error': null,
      };

      // Test basic connectivity
      try {
        final ref = _storage.ref();
        await ref.getMetadata().timeout(const Duration(seconds: 10));
        status['isEnabled'] = true;
        status['canRead'] = true;
      } catch (e) {
        status['error'] = e.toString();
        return status;
      }

      // Test write permissions
      try {
        final testRef = _storage.ref().child('test/status_check_${DateTime.now().millisecondsSinceEpoch}.txt');
        final testData = Uint8List.fromList('status_check'.codeUnits);
        await testRef.putData(testData);
        await testRef.delete();
        status['canWrite'] = true;
      } catch (e) {
        debugPrint('⚠️ Write test failed: $e');
      }

      // Check folder accessibility
      final folders = ['student_photos', 'bus_photos', 'profile_photos'];
      for (String folder in folders) {
        try {
          final ref = _storage.ref().child(folder);
          await ref.listAll();
          status['folders'][folder] = true;
        } catch (e) {
          status['folders'][folder] = false;
        }
      }

      debugPrint('📊 Storage status: $status');
      return status;
    } catch (e) {
      debugPrint('❌ Storage status check failed: $e');
      return {
        'isEnabled': false,
        'canRead': false,
        'canWrite': false,
        'folders': <String, bool>{},
        'error': e.toString(),
      };
    }
  }
}
