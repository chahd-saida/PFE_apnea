# 🌙 Splash Screen Apaisant - Résumé Complet

## ✅ Travail effectué

Votre splash screen Flutter a été complètement transformé en écran respiratoire apaisant respectant le design system teal.

### Spécifications implémentées

| Aspect | Spécification | ✅ Implémenté |
|--------|--------------|--------------|
| **Palette - Fond** | Gradient teal bleu | Oui |
| **Palette - Card** | Ivoire chaud #F4F0E8 | Oui |
| **Animation - Logo Moon** | Respiration pulsée | Oui |
| **Animation - Onde** | Sinusoïdale respiration | Oui |
| **Texte** | "Respirez. Nous veillons." | Oui |
| **Coins arrondis** | 22px card (BorderRadius) | Oui |
| **Ombres** | Teintées noires douces | Oui |
| **Mode nuit** | Par défaut | Oui |
| **Étoiles** | Scattered dots background | Oui |
| **Durée splash** | 3 secondes | Oui |
| **Version footer** | v1.0.0 • Apnea Detect | Oui |

## 📁 Fichiers modifiés / créés

### Modifiés
- `lib/theme/app_colors.dart` — Palette teal (warmIvory, tealAccent, etc.)
- `lib/theme/app_text_styles.dart` — Styles splash screen (splashMessage)
- `lib/screens/shared/splash_screen.dart` — Refonte complète avec animations
- `pubspec.yaml` — Configuration polices personnalisées (google_fonts)

## 🚀 Démarrage rapide

### 1. Vérifier les polices
Les polices sont chargées dynamiquement via `google_fonts` package (pas besoin de fichiers TTF locaux).

### 2. Synchroniser Flutter
```bash
cd path/to/app_PFE
flutter pub get
flutter clean
```

### 3. Lancer l'app
```bash
flutter run
```

## 🎨 Aperçu visuel (ce que vous verrez)

```
┌──────────────────────────────────┐
│ ✨ Étoiles scattered              │
│                                  │
│       [Logo Moon pulse]          │
│         ↓                        │
│    ┌──────────────────┐         │
│    │ 🌙 Croissant      │         │
│    │ (animation)      │         │
│    └──────────────────┘         │
│            ↓                    │
│  Respirez. Nous veillons.       │
│       (Blanc gras)              │
│            ↓                    │
│    ~~~onde~~onde~~~            │
│     (animation respiration)     │
│                                  │
│  Fond: Gradient bleu/teal       │
│  Durée: 3 sec → Navigation      │
│                                  │
│  v1.0.0 • Apnea Detect          │
│  © 2025 – All rights reserved   │
└──────────────────────────────────┘
```

## 🔧 Détails techniques

### Architecture composants

```dart
SplashScreen (StatefulWidget)
├── AnimationController (6s cycle respiration)
├── Stack
│   ├── Gradient background (bleu teal)
│   ├── Scattered star dots (Positioned)
│   └── Center Column
│       ├── Logo Card (Container ivoire)
│       │   └── MoonLogo (CustomPainter animé)
│       ├── Message Text ("Respirez. Nous veillons.")
│       └── BreathingWave (CustomPaint sinusoïde)
└── Footer (v1.0.0, copyright)
└── Timer (3s navigation)
```

### Animations

| Animation | Durée | Effet | Boucle |
|-----------|-------|-------|--------|
| Moon logo respiration | 6s | Scale pulse | ∞ |
| Onde EEG respiration | 6s | Phase shift sinusoïde | ∞ |
| Navigation | 3s | Timeout + navigation | 1x |

## ⚙️ Configuration

### Couleurs personnalisables

Fichier: `lib/theme/app_colors.dart`

```dart
// Changer les couleurs ici:
static const Color nightBg = Color(0xFF0E2326);        // Fond
static const Color tealMist = Color(0xFF9BC4C0);       // Halo/texte
static const Color tealAccent = Color(0xFF1F6F73);     // Accent
static const Color warmIvory = Color(0xFFF4F0E8);      // Texte message
```

### Timings personnalisables

Fichier: `lib/screens/shared/splash_screen.dart`

```dart
// Cycle de respiration (ligne ~28)
const Duration(seconds: 6)  // Changez 6 par autre durée

// Durée splash avant navigation (ligne ~30)
const Duration(seconds: 3)  // Changez 3 par autre durée

// Fallback d'attente role (ligne ~51)
const Duration(milliseconds: 400)  // Polling rate authentification
```

## 🐛 Dépannage

### Erreur: "fonts not found"
→ Vérifiez que les fichiers TTF sont dans `assets/fonts/`
→ Exécutez `flutter pub get`
→ Redémarrez l'émulateur

### Animation saccade/lag
→ Testez sur appareil réel (émulateur peut être lent)
→ Vérifiez que `SingleTickerProviderStateMixin` est présent

### Navigation ne se déclenche pas après 3s
→ Vérifiez AuthProvider et les routes
→ Consultez les logs: `flutter run -v`

### Polices affichées en défaut
→ Les polices ne sont pas téléchargées
→ Lisez `assets/fonts/FONTS_README.md`

## 📱 Compatibilité

- **Flutter** : 3.9.0 minimum
- **Plateforme** : iOS, Android, Web, macOS, Windows, Linux
- **Mode** : Fonctionne en mode jour/nuit (nuit par défaut ici)

## 🎯 Prochaines étapes optionnelles

1. **Afficher heure réelle** (au lieu de "9:41")
   - Remplacez `Text('9:41', ...)` par `Text(DateTime.now().format('HH:mm'), ...)`

2. **Afficher spinner de chargement**
   - Ajoutez `CircularProgressIndicator()` dans la Column

3. **Ajouter son d'ambiance**
   - Intégrez `just_audio` ou `audioplayers` package

4. **Personnaliser logo**
   - Modifiez `_MoonCrescentPainter` ou remplacez par SVG

5. **Mode jour**
   - Créez conditions basées sur `MediaQuery.of(context).platformBrightness`

## 📞 Support

- **Syntaxe/erreurs** : Consultez `flutter analyze` output
- **Polices** : Voir `assets/fonts/FONTS_README.md`
- **Design** : Tous les fichiers `lib/theme/*` centralisent le design
- **Navigation** : Vérifiez `lib/router/app_router.dart`

---

**Prêt à tester !** 🚀

1. Téléchargez les polices → `assets/fonts/FONTS_README.md`
2. Exécutez `flutter pub get`
3. Lancez `flutter run`
4. Observez la respiration apaisant pendant 3 secondes
