import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة إدارة عداد الإشعارات غير المقروءة
class NotificationBadgeService extends ChangeNotifier {
  static final NotificationBadgeService _instance = NotificationBadgeService._internal();
  factory NotificationBadgeService() => _instance;
  NotificationBadgeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// تحديث عداد الإشعارات غير المقروءة
  void updateUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// زيادة العداد
  void incrementCount() {
    _unreadCount++;
    notifyListeners();
  }

  /// تقليل العداد
  void decrementCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  /// إعادة تعيين العداد
  void resetCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// مراقبة الإشعارات غير المقروءة للمستخدم الحالي
  void startListening() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      updateUnreadCount(snapshot.docs.length);
    });
  }

  /// إيقاف المراقبة
  void stopListening() {
    resetCount();
  }
}
