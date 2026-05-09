# ⚡ Démarrage rapide - 5 minutes

## C'est quoi ?

Votre splash screen Flutter a été transformé en écran de respiration apaisant avec:
- Animation halo respirant (6 secondes)
- Logo croissant de lune stylisé
- Onde EEG horizontale
- Design teal nuit profond
- Polices élégantes (DM Serif + Inter)

## ✅ Prérequis (1 min)

Téléchargez **3 fichiers de polices** :

1. Allez sur https://fonts.google.com/specimen/DM+Serif+Display
2. Cliquez "Download family"
3. Extrayez et trouvez `DMSerifDisplay-Regular.ttf`
4. Placez dans: `assets/fonts/DMSerifDisplay-Regular.ttf`

Répétez pour **Inter** (https://fonts.google.com/specimen/Inter):
- `assets/fonts/Inter-Regular.ttf`
- `assets/fonts/Inter-Light.ttf`

**Ou lisez**: `assets/fonts/FONTS_README.md` (instructions détaillées)

## 🚀 Lancement (2 min)

```bash
# Terminal - dans le dossier du projet
cd c:/Users/admin/Desktop/app_PFE

flutter pub get
flutter clean
flutter run
```

## 🎯 Attendu (3 secondes)

```
Fond: Teal nuit (#0E2326)
  ↓
[Halo pulse doux]
  ↓
  9:41 (heure)
  ↓
  🌙 (logo croissant)
  ↓
  Respirez. Nous veillons. (texte apaisant)
  ↓
  ~~~onde~~~onde~~~ (animation EEG)
  ↓
[Après 3s: navigation automatique]
```

## 📁 Fichiers principaux modifiés

```
lib/
├── screens/shared/splash_screen.dart      ← ✏️ REFONTE COMPLÈTE
├── theme/
│   ├── app_colors.dart                    ← ✏️ +4 couleurs teal
│   └── app_text_styles.dart               ← ✏️ +2 styles splash
└── (autres fichiers inchangés)
```

## ✨ Nouveau

- `assets/fonts/` ← Dossier pour polices
- `SPLASH_SCREEN_README.md` ← Guide complet
- `SPLASH_SCREEN_INTEGRATION.md` ← Détails d'intégration
- `SPLASH_IMPLEMENTATION_DETAILS.md` ← Code technique
- `SPLASH_SCREEN_CHECKLIST.md` ← Vérification

## 🆘 Si ça ne marche pas

### Erreur: "fonts not found"
```bash
→ Vérifiez: assets/fonts/ contient les 3 TTF
→ Exécutez: flutter clean && flutter pub get
→ Redémarrez l'émulateur
```

### Animation saccade
```bash
→ Testez sur appareil réel
→ Émulateur peut être lent
```

### Compilation échoue
```bash
→ flutter clean
→ flutter pub get
→ flutter run -v (pour voir les erreurs)
```

### Fond pas teal/Texte pas bon
```bash
→ Vérifiez les couleurs dans: lib/theme/app_colors.dart
→ Vérifiez que pubspec.yaml a les polices
```

## 📞 Besoin de plus ?

- **Vue d'ensemble**: Lire `SPLASH_SCREEN_README.md`
- **Détails technique**: Lire `SPLASH_IMPLEMENTATION_DETAILS.md`
- **Personnalisation**: Lire `SPLASH_SCREEN_INTEGRATION.md`
- **Vérification**: Lire `SPLASH_SCREEN_CHECKLIST.md`

## 🎨 Personnalisations futures (optionnel)

### Modifier la couleur du halo
```dart
// File: lib/theme/app_colors.dart
static const Color tealMist = Color(0xFF9BC4C0);  // Changez cette valeur
```

### Modifier la durée de l'animation
```dart
// File: lib/screens/shared/splash_screen.dart ligne 29
const Duration(seconds: 6),  // Changez 6
```

### Modifier la durée avant navigation
```dart
// File: lib/screens/shared/splash_screen.dart ligne 33
const Duration(seconds: 3),  // Changez 3
```

### Afficher l'heure réelle
```dart
// File: lib/screens/shared/splash_screen.dart ligne 97
Text(DateTime.now().format('HH:mm'), ...)  // Au lieu de '9:41'
```

---

**C'est tout !** 🚀

1️⃣ Téléchargez les polices (3 fichiers TTF)
2️⃣ `flutter pub get && flutter clean && flutter run`
3️⃣ Observez le splash screen apaisant

**Après 3 secondes, l'app navigue automatiquement.**

Bon courage ! 🌙✨
