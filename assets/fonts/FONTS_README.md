# Polices requises pour le Splash Screen

Ce dossier doit contenir les fichiers de polices personnalisées pour le splash screen apaisant.

## Polices à télécharger

### 1. DM Serif Display (Regular)
- **Fichier**: `DMSerifDisplay-Regular.ttf`
- **Source**: https://fonts.google.com/specimen/DM+Serif+Display
- **Utilisation**: Affichage de l'heure "9:41" avec un style élégant et lisible

**Étapes** :
1. Allez sur https://fonts.google.com/specimen/DM+Serif+Display
2. Cliquez sur le bouton "Download family"
3. Extrayez le fichier et trouvez `DMSerifDisplay-Regular.ttf`
4. Placez-le dans ce dossier (`assets/fonts/`)

### 2. Inter (Regular + Light)
- **Fichiers**: 
  - `Inter-Regular.ttf` (poids 400)
  - `Inter-Light.ttf` (poids 300)
- **Source**: https://fonts.google.com/specimen/Inter
- **Utilisation**: Texte "Respirez. Nous veillons." avec une légèreté optique

**Étapes** :
1. Allez sur https://fonts.google.com/specimen/Inter
2. Cliquez sur le bouton "Download family"
3. Extrayez le fichier et trouvez `Inter-Regular.ttf` et `Inter-Light.ttf`
4. Placez-les dans ce dossier (`assets/fonts/`)

## Après téléchargement

Une fois les fichiers TTF placés dans ce dossier :

1. Exécutez `flutter pub get` pour synchroniser les ressources
2. Le splash screen utilisera automatiquement ces polices
3. L'animation de respiration devrait afficher correctement

## Alternative (si Google Fonts ne fonctionne pas)

Vous pouvez utiliser le package `google_fonts` de Flutter pour charger les polices dynamiquement sans les télécharger :

```dart
import 'package:google_fonts/google_fonts.dart';

// Dans app_text_styles.dart:
static TextStyle splashTime = GoogleFonts.dmSerifDisplay(
  fontSize: 24,
  fontWeight: FontWeight.w400,
  color: AppColors.tealMist,
);
```

N'oubliez pas d'ajouter `google_fonts: ^6.2.0` à `pubspec.yaml` si vous utilisez cette approche.
