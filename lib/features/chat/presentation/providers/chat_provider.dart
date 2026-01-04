import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/conversation_model.dart';
import '../../../../data/repositories/chat_repository.dart';

// Etat des conversations
class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier pour les conversations
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final ChatRepository? _repository;
  String? _currentUserId;
  StreamSubscription<List<ConversationModel>>? _conversationsSubscription;

  ConversationsNotifier(this._repository) : super(const ConversationsState()) {
    _initUserId();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initUserId() async {
    debugPrint('🔑 Initializing user ID...');
    
    // D'abord, essayer de récupérer le userId persisté
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('chat_user_id');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      // Persister le userId Firebase
      await prefs.setString('chat_user_id', _currentUserId!);
      debugPrint('✅ User already logged in: $_currentUserId');
      _startWatchingConversations();
    } else if (savedUserId != null) {
      // Utiliser le userId sauvegardé
      _currentUserId = savedUserId;
      debugPrint('✅ Using saved userId: $_currentUserId');
      _startWatchingConversations();
    } else {
      try {
        debugPrint('🔄 No user, signing in anonymously...');
        final result = await FirebaseAuth.instance.signInAnonymously();
        _currentUserId = result.user?.uid;
        if (_currentUserId != null) {
          await prefs.setString('chat_user_id', _currentUserId!);
        }
        debugPrint('✅ Anonymous sign in successful: $_currentUserId');
        _startWatchingConversations();
      } catch (e) {
        debugPrint('❌ Anonymous sign in failed: $e');
        // Créer un userId local et le persister
        _currentUserId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('chat_user_id', _currentUserId!);
        _startWatchingConversations();
      }
    }
  }

  /// Démarre l'écoute temps réel des conversations
  void _startWatchingConversations() {
    if (_currentUserId == null || _repository == null) {
      debugPrint('❌ Cannot watch conversations: userId=$_currentUserId, repo=$_repository');
      loadConversations(); // Fallback
      return;
    }

    debugPrint('👀 Starting real-time watch for user: $_currentUserId');
    state = state.copyWith(isLoading: true);
    
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _repository.watchConversations(_currentUserId!).listen(
      (conversations) {
        debugPrint('📥 Real-time update: ${conversations.length} conversations');
        state = ConversationsState(conversations: conversations);
      },
      onError: (e) {
        debugPrint('❌ Watch error: $e');
        state = ConversationsState(conversations: [], error: 'Erreur: $e');
      },
    );
  }

  Future<void> loadConversations() async {
    if (_currentUserId == null) {
      debugPrint('❌ loadConversations: _currentUserId is null');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    debugPrint('🔄 Loading conversations for user: $_currentUserId');

    try {
      if (_repository != null) {
        debugPrint('✅ Repository available, fetching from Firestore...');
        final conversations = await _repository.getConversations(
          _currentUserId!,
        );
        debugPrint(
          '📥 Loaded ${conversations.length} conversations from Firestore',
        );
        // Toujours afficher les vraies conversations (même si vide = pas de mock)
        state = ConversationsState(conversations: conversations);
      } else {
        debugPrint('⚠️ Repository is null, loading mock conversations');
        // Seulement afficher mock si pas de repository
        _loadMockConversations();
      }
    } catch (e) {
      debugPrint('❌ Error loading conversations: $e');
      // En cas d'erreur, afficher liste vide avec message d'erreur
      state = ConversationsState(conversations: [], error: 'Erreur: $e');
    }
  }

  void _loadMockConversations() {
    debugPrint(
      '⚠️ _loadMockConversations() called - this should NOT happen if Firestore works',
    );
    final mockConversations = [
      ConversationModel(
        id: 'conv1',
        participantIds: [_currentUserId ?? 'user1', 'seller1'],
        annonceTitre: 'Peugeot 308 - 2020',
        lastMessage:
            'Bonjour, est-ce que le vehicule est toujours disponible ?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        partnerName: 'Jean Dupont',
      ),
      ConversationModel(
        id: 'conv2',
        participantIds: [_currentUserId ?? 'user1', 'seller2'],
        annonceTitre: 'Volkswagen Golf GTI',
        lastMessage: 'Je peux venir voir la voiture samedi ?',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        partnerName: 'Marie Martin',
      ),
    ];
    state = ConversationsState(conversations: mockConversations);
  }

  Future<ConversationModel?> startConversation({
    required String sellerId,
    String? annonceId,
    String? annonceTitre,
  }) async {
    if (_currentUserId == null) {
      debugPrint('❌ startConversation: _currentUserId is null');
      state = state.copyWith(error: 'Utilisateur non connecté');
      return null;
    }

    debugPrint('🚀 startConversation: userId=$_currentUserId, sellerId=$sellerId');

    try {
      if (_repository != null) {
        final conversation = await _repository.getOrCreateConversation(
          participant1Id: _currentUserId!,
          participant2Id: sellerId,
          annonceId: annonceId,
          annonceTitre: annonceTitre,
        );

        debugPrint('✅ Conversation created/found: ${conversation.id}');
        
        // Recharger les conversations
        loadConversations();
        return conversation;
      } else {
        debugPrint('⚠️ Repository is null, using mock');
        // Mock
        final mockConv = ConversationModel(
          id: 'new_${DateTime.now().millisecondsSinceEpoch}',
          participantIds: [_currentUserId!, sellerId],
          annonceId: annonceId,
          annonceTitre: annonceTitre,
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          partnerName: 'Vendeur',
        );
        state = state.copyWith(
          conversations: [mockConv, ...state.conversations],
        );
        return mockConv;
      }
    } catch (e) {
      debugPrint('❌ startConversation error: $e');
      state = state.copyWith(
        error: 'Erreur lors de la creation de la conversation: $e',
      );
      return null;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      if (_repository != null) {
        await _repository.deleteConversation(conversationId);
      }
      state = state.copyWith(
        conversations:
            state.conversations.where((c) => c.id != conversationId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression');
    }
  }

  String? get currentUserId => _currentUserId;
}

// Etat des messages
class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

// Notifier pour les messages d'une conversation
class MessagesNotifier extends StateNotifier<MessagesState> {
  final ChatRepository? _repository;
  String conversationId;
  final String? currentUserId;
  final String receiverId;

  MessagesNotifier({
    required this.conversationId,
    required this.currentUserId,
    required this.receiverId,
    ChatRepository? repository,
  }) : _repository = repository,
       super(const MessagesState()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Toujours essayer de charger depuis Firestore si repository disponible
      if (_repository != null && !_isMockConversation()) {
        final messages = await _repository.getMessages(conversationId);
        if (messages.isEmpty) {
          _loadMockMessages();
        } else {
          state = MessagesState(messages: messages);
          if (currentUserId != null) {
            await _repository.markAsRead(
              conversationId: conversationId,
              userId: currentUserId!,
            );
          }
        }
      } else {
        _loadMockMessages();
      }
    } catch (e) {
      _loadMockMessages();
    }
  }

  bool _isMockConversation() {
    return conversationId.isEmpty ||
        conversationId.startsWith('conv') ||
        conversationId.startsWith('new_');
  }

  void _loadMockMessages() {
    final mockMessages = [
      MessageModel(
        id: 'm1',
        fromId: receiverId,
        toId: currentUserId ?? 'user1',
        text: 'Bonjour ! Le vehicule est toujours disponible.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      MessageModel(
        id: 'm2',
        fromId: currentUserId ?? 'user1',
        toId: receiverId,
        text: 'Super ! Quel est le prix final ?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MessageModel(
        id: 'm3',
        fromId: receiverId,
        toId: currentUserId ?? 'user1',
        text:
            'Le prix est negociable, on peut en discuter si vous venez voir la voiture.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
    state = MessagesState(messages: mockMessages);
  }

  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty || currentUserId == null) return false;

    state = state.copyWith(isSending: true, error: null);

    // Message temporaire pour affichage immediat
    final tempMessage = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      fromId: currentUserId!,
      toId: receiverId,
      text: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, tempMessage]);

    try {
      if (_repository != null) {
        // Si conversation mock, creer une vraie conversation d'abord
        if (_isMockConversation()) {
          final newConv = await _repository.getOrCreateConversation(
            participant1Id: currentUserId!,
            participant2Id: receiverId,
          );
          conversationId = newConv.id;
        }

        // Envoyer le message dans Firestore
        final sentMessage = await _repository.sendMessage(
          conversationId: conversationId,
          senderId: currentUserId!,
          receiverId: receiverId,
          text: text,
        );

        // Remplacer le message temporaire
        state = state.copyWith(
          messages:
              state.messages
                  .map((m) => m.id == tempMessage.id ? sentMessage : m)
                  .toList(),
          isSending: false,
        );
      } else {
        state = state.copyWith(isSending: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Erreur lors de l\'envoi',
      );
      return false;
    }
  }
}

// Providers
final _chatRepositoryProvider = Provider<ChatRepository?>((ref) {
  try {
    final repo = ref.read(chatRepositoryProvider);
    debugPrint('✅ ChatRepository loaded successfully');
    return repo;
  } catch (e) {
    debugPrint('❌ Error loading ChatRepository: $e');
    return null;
  }
});

final conversationsProvider = StateNotifierProvider<
  ConversationsNotifier,
  ConversationsState
>((ref) {
  final repository = ref.watch(_chatRepositoryProvider);
  debugPrint(
    '🔧 Creating ConversationsNotifier with repository: ${repository != null ? "OK" : "NULL"}',
  );
  return ConversationsNotifier(repository);
});

final messagesProvider = StateNotifierProvider.family<
  MessagesNotifier,
  MessagesState,
  Map<String, String>
>((ref, params) {
  final repository = ref.watch(_chatRepositoryProvider);
  final conversationsNotifier = ref.watch(conversationsProvider.notifier);

  return MessagesNotifier(
    conversationId: params['conversationId'] ?? '',
    currentUserId: conversationsNotifier.currentUserId,
    receiverId: params['receiverId'] ?? '',
    repository: repository,
  );
});

// Provider pour le nombre total de messages non lus
final unreadMessagesCountProvider = Provider<int>((ref) {
  final state = ref.watch(conversationsProvider);
  final userId = ref.watch(conversationsProvider.notifier).currentUserId;
  if (userId == null) return 0;

  return state.conversations.fold(
    0,
    (sum, conv) => sum + conv.getUnreadCount(userId),
  );
});

// Ancien controller pour compatibilite
class ChatController extends StateNotifier<List<MessageModel>> {
  final Ref ref;

  ChatController(this.ref) : super([]);

  Future<void> loadConversations(String userId) async {
    final svc = ref.read(chatServiceProvider);
    final list = await svc.getConversations(userId);
    state = list;
  }

  Future<void> sendMessage(MessageModel m) async {
    final svc = ref.read(chatServiceProvider);
    await svc.sendMessage(m);
    state = [...state, m];
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<MessageModel>>((ref) {
      return ChatController(ref);
    });
