import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/api_service.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/datasources/remote/firebase_service.dart';
import '../../data/datasources/remote/annonce_firestore_service.dart';
import '../../data/datasources/remote/favori_firestore_service.dart';
import '../../data/datasources/remote/chat_firestore_service.dart';
import '../../data/datasources/remote/reservation_firestore_service.dart';
import '../../data/datasources/local/hive_service.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../data/datasources/local/local_storage_service.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/annonce_repository.dart';
import '../../data/repositories/favori_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/alerte_matching_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/data/auth_repository_impl.dart';

// Services distants

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(ref.read(apiServiceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.read(apiServiceProvider));
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(ref.read(apiServiceProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(messageRepositoryProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

// Services Firestore pour l'Interface Acheteur
final annonceFirestoreServiceProvider = Provider<AnnonceFirestoreService>((
  ref,
) {
  return AnnonceFirestoreService();
});

final favoriFirestoreServiceProvider = Provider<FavoriFirestoreService>((ref) {
  return FavoriFirestoreService();
});

// Service de matching des alertes
final alerteMatchingServiceProvider = Provider<AlerteMatchingService>((ref) {
  return AlerteMatchingService();
});

// Provider pour LocalStorageService (async)
final localStorageServiceProvider = FutureProvider<LocalStorageService>((
  ref,
) async {
  return await LocalStorageService.init();
});

// Repositories pour l'Interface Acheteur
final annonceRepositoryProvider = Provider<AnnonceRepository>((ref) {
  final firestoreService = ref.read(annonceFirestoreServiceProvider);
  return AnnonceRepositoryImpl(firestoreService: firestoreService);
});

final favoriRepositoryProvider = Provider<FavoriRepository>((ref) {
  final firestoreService = ref.read(favoriFirestoreServiceProvider);
  return FavoriRepositoryImpl(firestoreService: firestoreService);
});

// Chat Firestore Service
final chatFirestoreServiceProvider = Provider<ChatFirestoreService>((ref) {
  return ChatFirestoreService();
});

// Chat Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final firestoreService = ref.read(chatFirestoreServiceProvider);
  return ChatRepositoryImpl(firestoreService: firestoreService);
});

// Reservation Firestore Service
final reservationFirestoreServiceProvider =
    Provider<ReservationFirestoreService>((ref) {
      return ReservationFirestoreService();
    });

// Reservation Repository
final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  final firestoreService = ref.read(reservationFirestoreServiceProvider);
  return ReservationRepositoryImpl(firestoreService: firestoreService);
});

// Auth repository & provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authServiceProvider));
});

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider(ref.read(authRepositoryProvider));
});
