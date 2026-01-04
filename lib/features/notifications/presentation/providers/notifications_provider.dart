import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/notification_model.dart';

/// État des notifications
class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notifier pour gérer les notifications en temps réel
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final FirebaseFirestore _firestore;
  String? _currentUserId;
  StreamSubscription? _subscription;

  NotificationsNotifier({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const NotificationsState()) {
    _initUserId();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('chat_user_id');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    } else if (savedUserId != null) {
      _currentUserId = savedUserId;
    }

    if (_currentUserId != null) {
      _startWatching();
    } else {
      // Charger toutes les notifications pour le debug
      _startWatchingAll();
    }
  }

  void _startWatching() {
    if (_currentUserId == null) return;

    debugPrint('👀 Démarrage écoute notifications pour: $_currentUserId');
    state = state.copyWith(isLoading: true);

    _subscription?.cancel();
    // Requête simple SANS orderBy pour éviter le besoin d'index composite
    _subscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('📥 ${snapshot.docs.length} notifications reçues');
            final notifications = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return NotificationModel.fromJson(data);
            }).toList();

            // Trier côté client par createdAt décroissant
            notifications.sort((a, b) {
              final aTime = a.createdAt ?? DateTime(2000);
              final bTime = b.createdAt ?? DateTime(2000);
              return bTime.compareTo(aTime);
            });

            // Limiter à 50 notifications
            final limitedNotifications = notifications.take(50).toList();

            final unreadCount = limitedNotifications.where((n) => !n.read).length;
            state = NotificationsState(
              notifications: limitedNotifications,
              unreadCount: unreadCount,
            );
          },
          onError: (e) {
            debugPrint('❌ Erreur stream notifications: $e');
            _startWatchingAll();
          },
        );
  }

  /// Fallback: écouter TOUTES les notifications (pour debug)
  void _startWatchingAll() {
    debugPrint('👀 Écoute de TOUTES les notifications (mode debug)');
    state = state.copyWith(isLoading: true);

    _subscription?.cancel();
    _subscription = _firestore
        .collection('notifications')
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('📥 ${snapshot.docs.length} notifications totales reçues');
            final notifications = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              debugPrint('  📋 Notif: ${data['title']} - userId: ${data['userId']}');
              return NotificationModel.fromJson(data);
            }).toList();

            // Trier par date
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            final unreadCount = notifications.where((n) => !n.read).length;
            state = NotificationsState(
              notifications: notifications,
              unreadCount: unreadCount,
            );
          },
          onError: (e) {
            debugPrint('❌ Erreur stream notifications: $e');
            state = NotificationsState(error: e.toString());
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Erreur marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      for (final notif in state.notifications.where((n) => !n.read)) {
        batch.update(
          _firestore.collection('notifications').doc(notif.id),
          {'read': true},
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Erreur marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Erreur suppression notification: $e');
    }
  }

  Future<void> refresh() async {
    if (_currentUserId != null) {
      _startWatching();
    } else {
      _startWatchingAll();
    }
  }

  /// Crée une nouvelle notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('notifications').add(notification);
      debugPrint('📧 Notification créée pour $userId: $title');
    } catch (e) {
      debugPrint('❌ Erreur création notification: $e');
    }
  }
}

/// Provider pour les notifications
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
