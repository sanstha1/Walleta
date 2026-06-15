import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      type: d['type'] ?? 'system',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(d['metadata'] ?? {}),
    );
  }
}

class NotificationViewModel extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  List<NotificationItem> _items = [];
  bool _isLoading = true;

  List<NotificationItem> get items => _items;
  bool get isLoading => _isLoading;

  int get unreadCount => _items.where((n) => !n.isRead).length;

  List<NotificationItem> get todayItems {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _items.where((n) => n.createdAt.isAfter(cutoff)).toList();
  }

  List<NotificationItem> get earlierItems {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _items.where((n) => n.createdAt.isBefore(cutoff)).toList();
  }

  CollectionReference? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('notifications').doc(uid).collection('items');
  }

  void startListening() {
    _sub?.cancel();

    final col = _col;
    if (col == null) {
      debugPrint(
        '⚠️ NotificationViewModel: no Firebase user — skipping listener',
      );
      _isLoading = false;
      notifyListeners();
      return;
    }

    _sub = col
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snap) {
            _items = snap.docs.map(NotificationItem.fromDoc).toList();
            _isLoading = false;
            notifyListeners();
            debugPrint(
              '🔔 Notifications updated: ${_items.length} items, $unreadCount unread',
            );
          },
          onError: (e) {
            debugPrint('❌ Notification stream error: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void restartListening() {
    stopListening();
    _isLoading = true;
    startListening();
  }

  Future<void> markRead(String id) async {
    try {
      await _col?.doc(id).update({'isRead': true});
    } catch (e) {
      debugPrint('❌ markRead error: $e');
    }
  }

  Future<void> markAllRead() async {
    final unread = _items.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final n in unread) {
        batch.update(_col!.doc(n.id), {'isRead': true});
      }
      await batch.commit();
      debugPrint('Marked ${unread.length} notifications as read');
    } catch (e) {
      debugPrint('markAllRead error: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _col?.doc(id).delete();
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  void clearNotifications() {
    stopListening();
    _items = [];
    _isLoading = false;
    notifyListeners();
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
