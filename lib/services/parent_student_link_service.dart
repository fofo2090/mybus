import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/parent_student_link_model.dart';

class ParentStudentLinkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Link multiple students to parent at once (improved version)
  Future<void> linkMultipleStudentsToParent(List<String> studentIds, String parentId) async {
    try {
      // Get parent data
      final parentDoc = await _firestore.collection('users').doc(parentId).get();

      if (!parentDoc.exists) {
        throw Exception('ولي الأمر غير موجود');
      }

      final parentData = parentDoc.data()!;

      // Use batch to update all students at once
      final batch = _firestore.batch();

      // Update all students with parent info
      for (final studentId in studentIds) {
        final studentRef = _firestore.collection('students').doc(studentId);
        batch.update(studentRef, {
          'parentId': parentId,
          'parentName': parentData['name'] ?? '',
          'parentEmail': parentData['email'] ?? '',
          'parentPhone': parentData['phone'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create or update parent-student link document (one document per parent)
      final linkDocRef = _firestore.collection('parentStudentLinks').doc(parentId);
      final linkDoc = await linkDocRef.get();

      if (linkDoc.exists) {
        // Add all students to existing parent's student list
        batch.update(linkDocRef, {
          'studentIds': FieldValue.arrayUnion(studentIds),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new parent-student link document
        batch.set(linkDocRef, {
          'id': parentId,
          'parentId': parentId,
          'parentEmail': parentData['email'] ?? '',
          'parentPhone': parentData['phone'] ?? '',
          'studentIds': studentIds,
          'isLinked': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit all changes
      await batch.commit();

      debugPrint('✅ Multiple students linked to parent successfully');
    } catch (e) {
      debugPrint('❌ Error linking multiple students to parent: $e');
      throw Exception('فشل في ربط الطلاب بولي الأمر: $e');
    }
  }

  /// Link single student to parent (improved version)
  Future<void> linkStudentToParent(String studentId, String parentId) async {
    try {
      // Get student and parent data
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      final parentDoc = await _firestore.collection('users').doc(parentId).get();

      if (!studentDoc.exists || !parentDoc.exists) {
        throw Exception('الطالب أو ولي الأمر غير موجود');
      }

      final parentData = parentDoc.data()!;

      // Update student with parent info
      await _firestore.collection('students').doc(studentId).update({
        'parentId': parentId,
        'parentName': parentData['name'] ?? '',
        'parentEmail': parentData['email'] ?? '',
        'parentPhone': parentData['phone'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create or update parent-student link document (one document per parent)
      final linkDocRef = _firestore.collection('parentStudentLinks').doc(parentId);
      final linkDoc = await linkDocRef.get();

      if (linkDoc.exists) {
        // Add student to existing parent's student list
        await linkDocRef.update({
          'studentIds': FieldValue.arrayUnion([studentId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new parent-student link document
        await linkDocRef.set({
          'id': parentId,
          'parentId': parentId,
          'parentEmail': parentData['email'] ?? '',
          'parentPhone': parentData['phone'] ?? '',
          'studentIds': [studentId],
          'isLinked': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Student linked to parent successfully');
    } catch (e) {
      debugPrint('❌ Error linking student to parent: $e');
      throw Exception('فشل في ربط الطالب بولي الأمر: $e');
    }
  }

  /// Unlink student from parent
  Future<void> unlinkStudentFromParent(String studentId, String parentId) async {
    try {
      // Update student to remove parent info
      await _firestore.collection('students').doc(studentId).update({
        'parentId': '',
        'parentName': '',
        'parentEmail': '',
        'parentPhone': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove student from parent's student list
      final linkDocRef = _firestore.collection('parentStudentLinks').doc(parentId);
      final linkDoc = await linkDocRef.get();

      if (linkDoc.exists) {
        await linkDocRef.update({
          'studentIds': FieldValue.arrayRemove([studentId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Check if parent has no more students, then delete the link document
        final updatedDoc = await linkDocRef.get();
        final remainingStudents = List<String>.from(updatedDoc.data()!['studentIds'] ?? []);
        if (remainingStudents.isEmpty) {
          await linkDocRef.delete();
        }
      }

      debugPrint('✅ Student unlinked from parent successfully');
    } catch (e) {
      debugPrint('❌ Error unlinking student from parent: $e');
      throw Exception('فشل في إلغاء ربط الطالب من ولي الأمر: $e');
    }
  }

  /// Get students linked to a specific parent
  Stream<List<StudentModel>> getStudentsByParent(String parentId) {
    return _firestore
        .collection('students')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Get parent-student link information
  Future<ParentStudentLinkModel?> getParentStudentLink(String parentId) async {
    try {
      final linkDoc = await _firestore.collection('parentStudentLinks').doc(parentId).get();
      
      if (!linkDoc.exists) {
        return null;
      }

      return ParentStudentLinkModel.fromMap({
        'id': linkDoc.id,
        ...linkDoc.data()!,
      });
    } catch (e) {
      debugPrint('❌ Error getting parent-student link: $e');
      return null;
    }
  }

  /// Get all parent-student links
  Stream<List<ParentStudentLinkModel>> getAllParentStudentLinks() {
    return _firestore
        .collection('parentStudentLinks')
        .where('isLinked', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ParentStudentLinkModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Check if student is already linked to a parent
  Future<bool> isStudentLinked(String studentId) async {
    try {
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      
      if (!studentDoc.exists) {
        return false;
      }

      final parentId = studentDoc.data()!['parentId'] ?? '';
      return parentId.isNotEmpty && !parentId.startsWith('parent_'); // Mock data check
    } catch (e) {
      debugPrint('❌ Error checking if student is linked: $e');
      return false;
    }
  }

  /// Get count of students linked to a parent
  Future<int> getStudentCountForParent(String parentId) async {
    try {
      final linkDoc = await _firestore.collection('parentStudentLinks').doc(parentId).get();
      
      if (!linkDoc.exists) {
        return 0;
      }

      final studentIds = List<String>.from(linkDoc.data()!['studentIds'] ?? []);
      return studentIds.length;
    } catch (e) {
      debugPrint('❌ Error getting student count for parent: $e');
      return 0;
    }
  }
}