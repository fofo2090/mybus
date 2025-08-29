import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';

import '../../models/student_model.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/curved_app_bar.dart';
import '../../widgets/student_avatar.dart';

class UpdateStudentPhotoScreen extends StatefulWidget {
  final StudentModel student;

  const UpdateStudentPhotoScreen({
    super.key,
    required this.student,
  });

  @override
  State<UpdateStudentPhotoScreen> createState() => _UpdateStudentPhotoScreenState();
}

class _UpdateStudentPhotoScreenState extends State<UpdateStudentPhotoScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: EnhancedCurvedAppBar(
        title: 'تحديث صورة الطالب',
        subtitle: Text('تحديث صورة ${widget.student.name}'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current Photo Section
            _buildCurrentPhotoSection(),
            const SizedBox(height: 24),
            
            // New Photo Section
            _buildNewPhotoSection(),
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الصورة الحالية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          StudentAvatar(
            photoUrl: widget.student.photoUrl,
            studentName: widget.student.name,
            radius: 60,
          ),
          const SizedBox(height: 12),
          Text(
            widget.student.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'الصف: ${widget.student.grade}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الصورة الجديدة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_selectedImage != null) ...[
            CircleAvatar(
              radius: 60,
              backgroundImage: FileImage(_selectedImage!),
            ),
            const SizedBox(height: 16),
            Text(
              'تم اختيار صورة جديدة',
              style: TextStyle(
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add_a_photo,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لم يتم اختيار صورة جديدة',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
          
          const SizedBox(height: 20),

          // Photo Selection Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('من المعرض'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('التقاط صورة'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info about compression
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيتم ضغط الصورة تلقائياً لتوفير مساحة التخزين',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_selectedImage != null) ...[
          CustomButton(
            text: _isUploading ? 'جاري ضغط وحفظ الصورة...' : 'حفظ الصورة الجديدة',
            onPressed: _isUploading ? null : _updateStudentPhoto,
            icon: _isUploading ? null : Icons.save,
            backgroundColor: const Color(0xFF1E88E5),
            isLoading: _isUploading,
          ),
          const SizedBox(height: 12),
        ],

        CustomButton(
          text: 'إلغاء',
          onPressed: _isUploading ? null : () => context.pop(),
          icon: Icons.cancel,
          backgroundColor: Colors.grey[600],
        ),
      ],
    );
  }



  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        setState(() {
          _selectedImage = imageFile;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم اختيار الصورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStudentPhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      debugPrint('🔄 Starting photo update for student: ${widget.student.id}');

      // Read and validate image
      final imageBytes = await _selectedImage!.readAsBytes();
      if (imageBytes.isEmpty) {
        throw Exception('ملف الصورة فارغ');
      }

      debugPrint('📊 Original image size: ${imageBytes.length} bytes');

      // Compress and save photo as base64 in Firestore
      final fileName = 'student_${widget.student.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl = await _storageService.updateStudentPhoto(
        imageBytes,
        fileName,
        widget.student.photoUrl,
      );

      debugPrint('✅ Photo compressed and saved successfully');

      // Update student record in database
      final updatedStudent = widget.student.copyWith(
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

      debugPrint('🔄 Updating student in database...');
      debugPrint('📊 Student ID: ${updatedStudent.id}');
      debugPrint('📊 Photo URL length: ${photoUrl.length} characters');
      debugPrint('📊 Photo URL preview: ${photoUrl.substring(0, 50)}...');

      await _databaseService.updateStudent(updatedStudent);

      debugPrint('✅ Student record updated successfully in Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث صورة الطالب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen with success result
        context.pop(true);
      }

    } catch (e) {
      debugPrint('❌ Error updating student photo: $e');

      String errorMessage = 'خطأ في تحديث الصورة';
      if (e.toString().contains('كبيرة جداً')) {
        errorMessage = 'الصورة كبيرة جداً\nيرجى اختيار صورة أصغر';
      } else if (e.toString().contains('فارغ')) {
        errorMessage = 'ملف الصورة تالف أو فارغ\nيرجى اختيار صورة أخرى';
      } else {
        errorMessage = 'فشل في حفظ الصورة\nيرجى المحاولة مرة أخرى';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


}
