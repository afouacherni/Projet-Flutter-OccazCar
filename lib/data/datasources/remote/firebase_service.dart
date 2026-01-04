import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
// If you generated `firebase_options.dart` via FlutterFire CLI, import it here:
// import '../../firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/models/photo_data.dart';

class FirebaseService {
  FirebaseService() {
    // Initialiser directement les instances Firebase
    // Firebase.initializeApp() est appelé dans main.dart
    _initInstances();
  }

  FirebaseApp? app;
  FirebaseAuth? auth;
  FirebaseFirestore? firestore;
  FirebaseMessaging? messaging;
  FirebaseStorage? storage;

  void _initInstances() {
    try {
      // Firebase.initializeApp() est déjà appelé dans main.dart
      // On peut directement accéder aux instances
      app = Firebase.app();
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      messaging = FirebaseMessaging.instance;
      storage = FirebaseStorage.instance;
    } catch (e) {
      // Si Firebase n'est pas encore initialisé, les instances seront null
      // L'initialisation sera faite via init() si nécessaire
    }
  }

  /// Initialize Firebase. If you use FlutterFire CLI, generate `firebase_options.dart`
  /// and uncomment the import at top, then pass `DefaultFirebaseOptions.currentPlatform`.
  Future<void> init() async {
    try {
      app = await Firebase.initializeApp();
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      messaging = FirebaseMessaging.instance;
      storage = FirebaseStorage.instance;
    } catch (e) {
      // Initialization may fail if firebase_options.dart is missing — leave as TODO.
      // Caller should handle and provide proper Firebase configuration.
    }
  }

  /// Upload une image depuis bytes vers Firebase Storage et retourne l'URL
  Future<String> uploadImageBytes(Uint8List bytes, String path) async {
    if (storage == null) {
      _initInstances();
    }
    if (storage == null) throw Exception('Firebase Storage not initialized');

    final ref = storage!.ref().child(path);
    final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Upload plusieurs images depuis bytes et retourne les URLs
  Future<List<String>> uploadImagesBytes(List<PhotoData> photos, String basePath) async {
    final List<String> urls = [];
    for (int i = 0; i < photos.length; i++) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$basePath/${timestamp}_$i.jpg';
      final url = await uploadImageBytes(photos[i].bytes, path);
      urls.add(url);
    }
    return urls;
  }

  /// Demo: write an annonce document to `annonces` collection.
  Future<String> createAnnonce(Map<String, dynamic> data) async {
    // S'assurer que firestore est initialisé
    if (firestore == null) {
      _initInstances();
    }
    if (firestore == null) throw Exception('Firestore not initialized');
    final docRef = await firestore!.collection('annonces').add(data);
    return docRef.id;
  }

  /// Crée une annonce avec upload des photos (cross-platform avec bytes)
  Future<String> createAnnonceWithPhotoBytes(Map<String, dynamic> data, List<PhotoData> photos) async {
    print('🔄 createAnnonceWithPhotoBytes: début');
    
    if (firestore == null || storage == null) {
      _initInstances();
    }
    if (firestore == null) throw Exception('Firestore not initialized');
    if (storage == null) throw Exception('Firebase Storage not initialized');

    // 1. Créer d'abord l'annonce pour avoir l'ID
    print('📝 Création document annonce...');
    final docRef = await firestore!.collection('annonces').add(data);
    final annonceId = docRef.id;
    print('✅ Document créé avec ID: $annonceId');

    // 2. Upload les photos avec l'ID de l'annonce
    if (photos.isNotEmpty) {
      print('📤 Upload de ${photos.length} photos...');
      try {
        final photoUrls = await uploadImagesBytes(photos, 'annonces/$annonceId');
        print('✅ ${photoUrls.length} photos uploadées');
        
        // 3. Mettre à jour l'annonce avec les URLs des photos
        await docRef.update({'photoUrls': photoUrls});
        print('✅ Annonce mise à jour avec les URLs');
      } catch (e) {
        print('❌ Erreur upload photos: $e');
        // Continuer même si l'upload échoue
      }
    }

    print('🔄 createAnnonceWithPhotoBytes: fin, retour ID=$annonceId');
    return annonceId;
  }

  /// Demo: fetch annonces list (basic snapshot -> json mapping)
  Future<List<Map<String, dynamic>>> getAnnonces() async {
    // S'assurer que firestore est initialisé
    if (firestore == null) {
      _initInstances();
    }
    if (firestore == null) throw Exception('Firestore not initialized');
    final snap = await firestore!.collection('annonces').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Récupère les annonces d'un vendeur spécifique
  Future<List<Map<String, dynamic>>> getAnnoncesByVendeur(String vendeurId) async {
    if (firestore == null) {
      _initInstances();
    }
    if (firestore == null) throw Exception('Firestore not initialized');
    final snap = await firestore!
        .collection('annonces')
        .where('vendeurId', isEqualTo: vendeurId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Met à jour une annonce
  Future<void> updateAnnonce(String annonceId, Map<String, dynamic> data) async {
    if (firestore == null) {
      _initInstances();
    }
    if (firestore == null) throw Exception('Firestore not initialized');
    await firestore!.collection('annonces').doc(annonceId).update(data);
  }

  /// Supprime une annonce et ses photos
  Future<void> deleteAnnonce(String annonceId) async {
    if (firestore == null || storage == null) {
      _initInstances();
    }
    if (firestore == null) throw Exception('Firestore not initialized');

    // Supprimer les photos du storage
    try {
      final listResult = await storage!.ref('annonces/$annonceId').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Ignorer si pas de photos
    }

    // Supprimer le document
    await firestore!.collection('annonces').doc(annonceId).delete();
  }
}
