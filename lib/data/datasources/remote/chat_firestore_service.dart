import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/message_model.dart';
import '../../models/conversation_model.dart';

class ChatFirestoreService {
  final FirebaseFirestore _firestore;

  ChatFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String conversationId,
  ) => _conversationsRef.doc(conversationId).collection('messages');

  // Creer ou recuperer une conversation entre deux utilisateurs
  Future<ConversationModel> getOrCreateConversation({
    required String participant1Id,
    required String participant2Id,
    String? annonceId,
    String? annonceTitre,
  }) async {
    debugPrint('🔍 getOrCreateConversation START');
    debugPrint('  - participant1: $participant1Id');
    debugPrint('  - participant2: $participant2Id');
    debugPrint('  - annonceId: $annonceId');
    debugPrint('  - annonceTitre: $annonceTitre');
    
    // Validation: les IDs ne doivent pas être vides
    if (participant1Id.isEmpty || participant2Id.isEmpty) {
      throw Exception('Les IDs des participants ne peuvent pas être vides. participant1: "$participant1Id", participant2: "$participant2Id"');
    }
    
    try {
      // Chercher une conversation existante
      debugPrint('🔎 Searching for existing conversation...');
      final existing =
          await _conversationsRef
              .where('participantIds', arrayContains: participant1Id)
              .get();

      debugPrint('📄 Found ${existing.docs.length} conversations containing participant1');

      for (var doc in existing.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participantIds'] ?? []);
        if (participants.contains(participant2Id)) {
          debugPrint('✅ Found existing conversation: ${doc.id}');
          return ConversationModel.fromJson({...data, 'id': doc.id});
        }
      }

      debugPrint('📝 Creating new conversation...');
      
      // Creer une nouvelle conversation
      final conversationData = {
        'participantIds': [participant1Id, participant2Id],
        'annonceId': annonceId,
        'annonceTitre': annonceTitre,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {participant1Id: 0, participant2Id: 0},
      };

      final docRef = await _conversationsRef.add(conversationData);
      debugPrint('✅ Created conversation with id: ${docRef.id}');

      return ConversationModel(
        id: docRef.id,
        participantIds: [participant1Id, participant2Id],
        annonceId: annonceId,
        annonceTitre: annonceTitre,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getOrCreateConversation: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      throw Exception('Erreur lors de la creation de la conversation: $e');
    }
  }

  // Recuperer les conversations d'un utilisateur
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      debugPrint('🔍 Fetching conversations for userId: $userId');

      // Requête simple sans orderBy pour éviter les problèmes d'index
      final snapshot =
          await _conversationsRef
              .where('participantIds', arrayContains: userId)
              .get();

      debugPrint('📄 Found ${snapshot.docs.length} conversation documents');

      final conversations =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            debugPrint(
              '  - Conversation: ${doc.id}, lastMessage: ${data['lastMessage']}',
            );
            return ConversationModel.fromJson(data);
          }).toList();

      // Trier côté client par lastMessageTime
      conversations.sort((a, b) {
        final aTime = a.lastMessageTime ?? DateTime(2000);
        final bTime = b.lastMessageTime ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return conversations;
    } catch (e) {
      debugPrint('❌ Error in getConversations: $e');
      throw Exception('Erreur lors de la recuperation des conversations: $e');
    }
  }

  // Stream des conversations en temps reel
  Stream<List<ConversationModel>> watchConversations(String userId) {
    return _conversationsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final conversations =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return ConversationModel.fromJson(data);
              }).toList();

          // Trier côté client
          conversations.sort((a, b) {
            final aTime = a.lastMessageTime ?? DateTime(2000);
            final bTime = b.lastMessageTime ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return conversations;
        });
  }

  // Envoyer un message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final messageData = {
        'fromId': senderId,
        'toId': receiverId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      final docRef = await _messagesRef(conversationId).add(messageData);

      // Mettre a jour la conversation
      await _conversationsRef.doc(conversationId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      return MessageModel(
        id: docRef.id,
        fromId: senderId,
        toId: receiverId,
        text: text,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  // Recuperer les messages d'une conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final snapshot =
          await _messagesRef(
            conversationId,
          ).orderBy('timestamp', descending: false).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Convertir Timestamp en DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        return MessageModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recuperation des messages: $e');
    }
  }

  // Stream des messages en temps reel
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _messagesRef(conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                if (data['timestamp'] is Timestamp) {
                  data['timestamp'] =
                      (data['timestamp'] as Timestamp)
                          .toDate()
                          .toIso8601String();
                }
                return MessageModel.fromJson(data);
              }).toList(),
        );
  }

  // Marquer les messages comme lus
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Mettre a jour le compteur de non lus
      await _conversationsRef.doc(conversationId).update({
        'unreadCount.$userId': 0,
      });

      // Marquer tous les messages comme lus
      final messages =
          await _messagesRef(conversationId)
              .where('toId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du marquage comme lu: $e');
    }
  }

  // Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Supprimer tous les messages
      final messages = await _messagesRef(conversationId).get();
      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Supprimer la conversation
      await _conversationsRef.doc(conversationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}
