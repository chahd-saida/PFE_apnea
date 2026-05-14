# Configuration DoctorBot - Chatbot IA pour Médecins

## 🔧 Configuration requise

### 1. Clé API Groq

Pour utiliser DoctorBot avec le modèle **LLaMA 3.3-70B-Versatile**, vous devez:

1. **Obtenir une clé API Groq**:
   - Accédez à [console.groq.com](https://console.groq.com)
   - Créez un compte gratuit
   - Générez une clé API dans les paramètres

2. **Configurer la clé**:
   - Ouvrez `lib/screens/shared/chatbot_screen.dart`
   - Remplacez `'YOUR_GROQ_API_KEY_HERE'` par votre clé réelle
   - **OU** stockez-la dans une variable d'environnement `.env`

### 2. Variables d'environnement (Recommandé)

Créez un fichier `.env` à la racine du projet:
```
GROQ_API_KEY=gsk_votre_clé_ici
```

Puis modifiez `lib/screens/shared/chatbot_screen.dart`:
```dart
import 'dart:io';
const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');
```

## 🤖 Modèle IA utilisé

- **Modèle**: `llama-3.3-70b-versatile`
- **Provider**: [Groq](https://www.groq.com/)
- **Domaine**: Médecine générale, pneumologie, médecine du sommeil
- **Tokens**: 2048 max par réponse

## 📱 Utilisation

### Accès à DoctorBot

1. **Via FAB** (Floating Action Button):
   - Disponible sur toutes les pages du médecin
   - Bouton violet avec icône chatbot
   - Tap pour ouvrir le chatbot

2. **Via Route**:
   ```dart
   context.push(RouteNames.chatbot('doctor'));
   ```

### Fonctionnalités

- **Questions cliniques**: Diagnostic, traitement, guidelines
- **Analyse de données**: Polysomnographie, monitoring
- **Recommandations**: Escalade thérapeutique, suivi
- **Références**: Citations des guidelines AASM, ESC, etc.
- **Historique**: Conversation conservée pendant la session

### Suggestions rapides

8 suggestions pré-configurées pour questions courantes:
- Critères d'initiation PPC
- Analyse IAH (Index d'Apnée-Hypopnée)
- Suivi cardiologique
- Interactions médicamenteuses
- Formes génétiques
- Chirurgie bariatrique
- Escalade thérapeutique
- Guidelines AASM 2023

## 📊 Architecture

```
lib/
├── screens/shared/
│   └── chatbot_screen.dart             # Écran principal (role='doctor')
├── widgets/
│   └── chatbot_fab.dart                # DoctorChatbotFAB button
└── router/
    └── app_router.dart                 # Route /chatbot/:role
```

## ⚙️ Configuration avancée

### Personnaliser le system prompt

Modifiez `_promptDoctor` dans `lib/screens/shared/chatbot_screen.dart` pour adapter:
- Langue et ton
- Domaines d'expertise
- Limitations et responsabilités
- Format des réponses

### Ajuster les paramètres LLM

```dart
// Dans lib/screens/shared/chatbot_screen.dart:
const _maxTokens = 2048;                // Pour doctor, max tokens des réponses
const _temperature = 0.7;               // Créativité (0-1)
const _modelDoctor = 'llama-3.3-70b-versatile';
```

## 🔒 Sécurité

- ⚠️ **NE stockez jamais votre clé API dans le code source**
- Utilisez des variables d'environnement ou des secrets
- Les réponses du chatbot ne remplacent jamais le jugement clinique
- Toujours consulter les sources officielles (AMM, AASM, etc.)

## 📝 Utilisation clinique responsable

1. **Jamais de diagnostic définitif** - Le bot guide, le médecin décide
2. **Evidence-based** - Les recommandations s'appuient sur la littérature
3. **Limitations claires** - Le bot indique ses limitations
4. **Escalade appropriée** - Recommande consultation si nécessaire

## 🐛 Dépannage

### Erreur: "Connexion impossible"
- Vérifiez votre connexion Internet
- Vérifiez votre clé API Groq
- Vérifiez les quotas Groq dans console.groq.com

### Erreur: "Délai d'attente dépassé"
- Groq peut être surchargé
- Réessayez après quelques secondes
- Vérifiez votre latence réseau

### Réponses de mauvaise qualité
- Reformulez votre question
- Fournissez plus de contexte clinique
- Vérifiez le system prompt

## 📚 Ressources

- [Documentation Groq](https://console.groq.com/docs)
- [LLaMA 3.3 Specs](https://www.meta.com/research/publications/llama-3-3-70b/)
- [AASM Guidelines](https://aasm.org/)
- [ESC Sleep Medicine](https://www.escardio.org/)

---

**Version**: 1.0  
**Dernière mise à jour**: 2024  
**Auteur**: Apnea Detect Team
