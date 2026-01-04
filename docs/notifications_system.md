# Système de Notifications OccazCar

## Vue d'ensemble

Le système de notifications automatique surveille les nouvelles annonces de véhicules et envoie des notifications push aux utilisateurs dont les alertes correspondent aux critères.

## Fonctionnalités Implémentées

### 1. Service de Matching Automatique (`AlertMatchingService`)

**Localisation :** `lib/features/notifications/services/alert_matching_service.dart`

- **Surveillance en temps réel :** Écoute les nouvelles annonces ajoutées dans Firebase
- **Matching intelligent :** Compare chaque nouvelle annonce avec toutes les alertes actives
- **Prévention des doublons :** Évite de notifier plusieurs fois pour la même annonce
- **Gestion de la fréquence :** Respecte les préférences de fréquence (immédiate, quotidienne, hebdomadaire)

**Critères de matching :**
- Marque du véhicule
- Modèle du véhicule
- Prix minimum/maximum
- Année minimum/maximum
- Kilométrage maximum
- Carburant
- Transmission
- Localisation

### 2. Types de Notifications

**Enum `NotificationType` :**
- `alerteMatch` : Notification quand une annonce correspond à une alerte
- `message` : Notifications de chat
- `offre` : Notifications d'offres reçues
- `system` : Notifications système et tests

### 3. Interface Utilisateur

#### Page des Alertes
- **Bouton de test** : Icône orange 🧧 pour tester le système
- **Gestion des alertes** : Créer, modifier, supprimer des alertes
- **Compteur de correspondances** : Affiche combien d'annonces ont matché

#### Notifications
- **Badge de compteur** : Nombre de notifications non lues
- **Navigation directe** : Clic sur l'icône pour voir toutes les notifications
- **Marquage comme lu** : Système de lecture des notifications

## Comment Tester

### 1. Test Manuel
1. Aller dans "Alertes" depuis la page d'accueil
2. Cliquer sur l'icône orange 🧧 "Tester notification"
3. Une notification de test sera créée
4. Vérifier le badge de notification dans la barre supérieure

### 2. Test Automatique
1. Créer une alerte avec des critères spécifiques (ex: BMW, prix max 30000€)
2. Publier une nouvelle annonce qui correspond (BMW à 25000€)
3. Une notification automatique sera envoyée

## Architecture Technique

### Flux de données
```
Nouvelle Annonce → AlertMatchingService → Vérification Critères → Création Notification → Interface Utilisateur
```

### Persistance
- **Alertes :** Collection `alertes` dans Firestore
- **Notifications :** Collection `notifications` dans Firestore
- **Annonces :** Collection `annonces` dans Firestore

### Providers Riverpod
- `notificationsProvider` : Gestion des notifications
- `alertesProvider` : Gestion des alertes
- `annoncesRecentesProvider` : Gestion des annonces

## Démarrage Automatique

Le service se lance automatiquement au démarrage de l'application dans `main.dart` :

```dart
AlertMatchingService().startMatching();
```

## Optimisations Futures

1. **Push Notifications** : Intégrer Firebase Cloud Messaging (FCM)
2. **Filtres avancés** : Ajouter plus de critères de matching
3. **Machine Learning** : Suggestions intelligentes d'alertes
4. **Géolocalisation** : Notifications basées sur la distance
5. **Planification** : Envoi différé selon les préférences utilisateur

## Dépannage

### Notifications non reçues
- Vérifier que l'utilisateur est connecté
- Vérifier que l'alerte est active
- Contrôler les critères de l'alerte
- Tester avec le bouton de test

### Performances
- Le service charge automatiquement les annonces existantes pour éviter les notifications en double
- Limitation à 50 notifications par utilisateur pour optimiser les performances

## Sécurité

- **Isolation utilisateur** : Chaque utilisateur ne voit que ses propres notifications
- **Validation** : Vérification des données avant création de notification
- **Anonymisation** : Support des utilisateurs anonymes pour les tests