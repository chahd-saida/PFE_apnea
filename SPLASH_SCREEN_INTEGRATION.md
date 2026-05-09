# Guide d'intégration du Splash Screen Apaisant

## Résumé des changements

Votre splash screen a été transformé en un écran de respiration apaisant suivant le design system exact spécifié :

- ✅ Fond teal nuit profond `#0E2326`
- ✅ Halo de respiration animé en `#9BC4C0` (cycle 6 secondes)
- ✅ Logo croissant de lune stylisé avec gradient teal
- ✅ Onde de respiration horizontale animée (style EEG)
- ✅ Texte "Respirez. Nous veillons." avec opacité 0.9
- ✅ Heure "9:41" en DM Serif Display
- ✅ Tous les coins arrondis à 14px (via BorderRadius)
- ✅ Ombres teintées teal
- ✅ Durée 3 secondes avant navigation
- ✅ Même logique d'authentification préservée

## Fichiers modifiés

### 1. `lib/theme/app_colors.dart`
Ajout des couleurs teal du design system :
- `nightBg` : `#0E2326` (fond nuit profond)
- `warmIvory` : `#F4F0E8` (ivoire chaud)
- `tealAccent` : `#1F6F73` (teal profond accent)
- `tealMist` : `#9BC4C0` (teal mist pour halos)
- `textNightPrimary` : `#0F2A2E` (encre nuit)

### 2. `pubspec.yaml`
Configuration des polices personnalisées :
```yaml
fonts:
  - family: DMSerifDisplay
    fonts:
      - asset: assets/fonts/DMSerifDisplay-Regular.ttf
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Regular.ttf
      - asset: assets/fonts/Inter-Light.ttf
        weight: 300
```

### 3. `lib/theme/app_text_styles.dart`
Nouveaux styles pour le splash screen :
- `splashTime` : DM Serif Display 24px, teal mist
- `splashMessage` : Inter Light 18px, ivoire chaud

### 4. `lib/screens/shared/splash_screen.dart`
Entièrement réécrit avec :
- Animation de respiration via `AnimationController` (6s cycle)
- Halo de respiration pulsant au centre
- Logo croissant de lune avec gradient teal
- Onde de respiration horizontale (CustomPaint)
- Navigation après 3 secondes (préservée)
- Même logique d'authentification

## Étapes d'installation

### Étape 1 : Télécharger les polices

Allez dans `assets/fonts/` et lisez `FONTS_README.md` pour les instructions détaillées.

**Résumé** :
1. Téléchargez `DMSerifDisplay-Regular.ttf` depuis https://fonts.google.com/specimen/DM+Serif+Display
2. Téléchargez `Inter-Regular.ttf` et `Inter-Light.ttf` depuis https://fonts.google.com/specimen/Inter
3. Placez les fichiers dans le dossier `assets/fonts/`

### Étape 2 : Synchroniser les dépendances

```bash
flutter pub get
```

### Étape 3 : Nettoyer le build

```bash
flutter clean
flutter pub get
```

### Étape 4 : Lancer l'application

```bash
flutter run
```

## Architecture du splash screen

### Composants principaux

**1. Halo de respiration**
- Conteneur circulaire avec gradient teal
- Animation sinusoïdale de 6 secondes
- Scale entre 0.8 et 1.2 pour l'effet de "respiration"
- Ombre teintée teal

**2. Logo croissant de lune**
- CustomPainter qui dessine un croissant
- Gradient teal (du teal mist au teal accent)
- Ombre portée teal
- Centré dans le halo

**3. Onde de respiration**
- CustomPaint dessinant une onde sinusoïdale
- Couleur teal mist semi-opaque
- Amplitude 8.0px, longueur d'onde 40.0px
- Synchronisée avec le cycle de respiration

**4. Texte et heure**
- "9:41" en DM Serif Display (couleur teal mist)
- "Respirez. Nous veillons." en Inter Light (couleur ivoire)
- Opacité 0.9 pour le texte

### Timing

- **Cycle de respiration** : 6 secondes (boucle infinie pendant l'écran)
- **Durée du splash** : 3 secondes avant navigation
- **Authentification** : Vérifiée en arrière-plan, navigation adaptée au rôle

## Personnalisations possibles

### Modifier les couleurs

Changez les valeurs dans `lib/theme/app_colors.dart` :
```dart
static const Color nightBg = Color(0xFF0E2326);        // Changez la couleur
static const Color tealMist = Color(0xFF9BC4C0);       // Changez la couleur
```

### Modifier la durée de respiration

Dans `lib/screens/shared/splash_screen.dart`, changez la `Duration` :
```dart
_breathingController = AnimationController(
  duration: const Duration(seconds: 4), // Au lieu de 6
  vsync: this,
)..repeat();
```

### Modifier la durée du splash

Dans `_navigateAfterSplash()`, changez la `Duration` :
```dart
_navigationTimer = Timer(const Duration(seconds: 5), _navigateAfterSplash); // Au lieu de 3
```

### Modifier l'heure affichée

Dans `build()`, changez le texte "9:41" pour afficher l'heure réelle :
```dart
Text(
  DateTime.now().format('HH:mm'), // Heure réelle
  style: AppTextStyles.splashTime,
),
```

## Dépannage

### Les polices ne s'affichent pas

1. Vérifiez que les fichiers TTF sont dans `assets/fonts/`
2. Vérifiez que `pubspec.yaml` référence correctement les chemins
3. Exécutez `flutter clean && flutter pub get`
4. Redémarrez l'émulateur/appareil

### L'animation saccade

1. Vérifiez que vous n'avez pas trop de widgets sur l'écran
2. Assurez-vous que `SingleTickerProviderStateMixin` est utilisé
3. Vérifiez les performances sur l'appareil réel

### Navigation incorrecte après 3 secondes

1. Vérifiez que `AuthProvider` fonctionne correctement
2. Vérifiez que `RouteNames` est correctement défini
3. Vérifiez les logs pour les erreurs de navigation

## Test recommandé

1. Lancez l'app
2. Observez le splash screen pendant 3 secondes
3. Vérifiez que :
   - Le halo pulse doucement
   - L'onde de respiration bouge horizontalement
   - Le logo croissant de lune est visible et stilisé
   - Le texte s'affiche avec les bonnes polices
   - Après 3 secondes, l'app navigue vers l'écran approprié

## Support et questions

Si vous avez besoin de modifier le design ou les animations, consultez les fichiers :
- `lib/screens/shared/splash_screen.dart` (logique et animations)
- `lib/theme/app_colors.dart` (couleurs)
- `lib/theme/app_text_styles.dart` (typographies)
- `pubspec.yaml` (dépendances et assets)
