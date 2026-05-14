# 🧪 Guide de Test - DoctorBot

## ✅ Checklist de vérification

### 1. **Compilation** ✅
```bash
flutter pub get
flutter analyze  # Doit compiler sans erreurs critiques
flutter build apk --debug  # ou ios pour iOS
```

### 2. **Configuration Groq** ⚠️ **REQUIS**
- [ ] Créer compte sur [console.groq.com](https://console.groq.com)
- [ ] Générer clé API
- [ ] Remplacer `'YOUR_GROQ_API_KEY_HERE'` dans:
  - `lib/screens/shared/chatbot_screen.dart` ligne 12

### 3. **Démarrage de l'app**
```bash
flutter run
```

### 4. **Tests d'accès**

#### Test 4.1: Accès Médecin ✅
- [ ] Se connecter avec compte **médecin** (rôle="doctor")
- [ ] Voir le FAB violet sur dashboard
- [ ] Tap sur FAB → Ouvre DoctorChatbotScreen
- [ ] Tester question: "Qu'est-ce que l'apnée du sommeil ?"
- [ ] Recevoir réponse en français

#### Test 4.2: Protection des routes 🔒
- [ ] Médecin: `context.push(RouteNames.chatbot('doctor'))` → Fonctionne ✅
- [ ] Patient: Essayer d'accéder à `/chatbot/doctor` → Redirection vers access-denied ✅

#### Test 4.3: FAB sur toutes les pages
- [ ] Dashboard → FAB visible ✅
- [ ] Patients → FAB visible ✅
- [ ] Alertes → FAB visible ✅
- [ ] Messages → FAB visible ✅
- [ ] Profil → FAB visible ✅
- [ ] Rapports → FAB visible ✅
- [ ] Paramètres → FAB visible ✅
- [ ] Ajouter patient → FAB visible ✅
- [ ] Profil patient (détail) → FAB visible ✅
- [ ] Analyse (détail) → FAB visible ✅

### 5. **Fonctionnalités du Chatbot**

#### Test 5.1: Conversation basique
```
Q: "Comment diagnostiquer l'apnée du sommeil ?"
Expected: Réponse structurée en français (>100 chars)
Timing: <5 secondes (Groq est très rapide)
```

#### Test 5.2: Suggestions rapides
- [ ] Voir 8 suggestions en haut (questions fréquentes)
- [ ] Tap sur suggestion → Envoie automatiquement
- [ ] Reçoit réponse pertinente

#### Test 5.3: Historique
- [ ] Envoyer 3-4 messages
- [ ] Fermer et rouvrir DoctorChatbot
- [ ] Historique effacé (comportement attendu: nouvelle session)
- [ ] OU click "Réinitialiser" → Chat vide ✅

#### Test 5.4: Copy-paste
- [ ] Long-press sur message utilisateur → "Message copié"
- [ ] Long-press sur réponse bot → "Réponse copiée"
- [ ] Coller dans Notes: texte complet présent ✅

#### Test 5.5: Dark mode
- [ ] Activer dark mode système
- [ ] ChatBot affiche couleurs sombres ✅
- [ ] Texte lisible en dark mode
- [ ] Bulles bleu/violet visibles
- [ ] Désactiver dark mode → Retour clair ✅

#### Test 5.6: Gestion d'erreurs
- [ ] Couper Internet → "Connexion impossible" ✅
- [ ] Attendre >30s → "Délai d'attente dépassé" ✅
- [ ] Clé API invalide → Message d'erreur ✅

#### Test 5.7: Performance
- [ ] Envoyer message long (>500 chars): < 10s
- [ ] Scroll liste messages: fluide (60fps)
- [ ] Pas de lag lors de la frappe

### 6. **Tests d'accessibilité**

#### Test 6.1: Navigation
- [ ] Flèche retour → Revient à page précédente
- [ ] ✅ Bouton "Plus" → Menu "Réinitialiser"
- [ ] FAB visible sur toutes les pages

#### Test 6.2: Responsive
- [ ] Portrait: Chat full-width
- [ ] Landscape: Chat adaptée
- [ ] Tablet: Suggestions sur 2+ lignes
- [ ] S'ajuste bien sur écrans petits/grands

### 7. **Tests de sécurité**

#### Test 7.1: Données
- [ ] Conversation = locale (pas d'enregistrement serveur)
- [ ] Pas de données sensibles exposées
- [ ] Clé API: variable, pas en dur

#### Test 7.2: Routes
- [ ] Patient ne peut **pas** accéder `/doctor-chatbot`
- [ ] Patient ne voit **pas** les FAB des pages médecin
- [ ] Médecin ne peut **pas** accéder routes patients

## 🐛 Dépannage rapide

### Problème: FAB n'apparaît pas
**Solution**:
```dart
// Vérifier que doctor_chatbot_fab.dart est importé
import 'package:apnea_project/widgets/doctor_chatbot_fab.dart';

// Vérifier que floatingActionButton est dans Scaffold
floatingActionButton: const DoctorChatbotFAB(),
```

### Problème: "Erreur 401" Groq
**Solution**:
- Vérifier clé API valide sur console.groq.com
- Vérifier format: commence par `gsk_`
- Vérifier pas d'espace avant/après

### Problème: Timeouts fréquents
**Solution**:
- Vérifier latence réseau (`ping api.groq.com`)
- Vérifier quotas Groq (console.groq.com)
- Vérifier modèle: `llama-3.3-70b-versatile` existe

### Problème: Réponses en anglais
**Solution**:
- Groq peut répondre en anglais si:
  - Clé Groq invalide
  - Modèle pas le bon
  - System prompt pas chargé
- Vérifier `const _systemPrompt` contient instruction français

## 📊 Métriques de succès

| Métrique | Target |
|----------|--------|
| Temps réponse API | < 5s |
| Temps UI refresh | < 100ms |
| FAB visible | 10/10 pages |
| Protection routes | 100% |
| Français | 90%+ des réponses |
| Disponibilité | 99%+ (Groq SLA) |

## 📝 Rapport de test

Créer un fichier `TEST_REPORT.txt`:
```
Date: YYYY-MM-DD
Testeur: [Nom]
Plateforme: [Android/iOS/Web]
Groq API: ✅/❌
FAB: ✅/❌
Routes: ✅/❌
French: ✅/❌
Errors: [Liste]
Notes: [Commentaires]
```

## 🚀 Prochaines étapes

1. ✅ Tester tous les points de cette checklist
2. ✅ Valider avec médecins (UX clinique)
3. ✅ Configurer clé API production Groq
4. ✅ Ajouter logs/analytics (Sentry, Mixpanel)
5. ✅ Déployer sur stores (iOS, Android)
6. ✅ Monitorer erreurs en production

---

**Note**: Tous les tests doivent passer avant production.  
**Support**: Voir `DOCTORBOT_SETUP.md` pour problèmes avancés.
