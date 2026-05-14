# Guide d'intégration du Splash Screen Apaisant

## Résumé des changements

Votre splash screen a été transformé en un écran respiratoire apaisant avec:

- ✅ Fond gradient bleu/teal
- ✅ Logo croissant de lune animé avec pulsation
- ✅ Onde de respiration horizontale animée (style EEG)
- ✅ Texte "Respirez. Nous veillons." en blanc gras
- ✅ Étoiles éparpillées en arrière-plan
- ✅ Footer avec version et copyright
- ✅ Durée 3 secondes avant navigation
- ✅ Même logique d'authentification préservée
- ✅ Polices via google_fonts (pas de fichiers TTF locaux)

## Fichiers modifiés

### 1. `lib/theme/app_colors.dart`
Couleurs teal du design system :
- `nightBg` : `#0E2326` (fond nuit profond - inutilisé actuellement)
- `warmIvory` : `#F4F0E8` (ivoire chaud pour card logo)
- `tealAccent` : `#1F6F73` (teal accent)
- `tealMist` : `#9BC4C0` (teal mist)

### 2. `pubspec.yaml`
Configuration des polices dynamiques :
```yaml
dependencies:
  google_fonts: ^6.2.1  # Polices téléchargées dynamiquement
```

### 3. `lib/theme/app_text_styles.dart`
Nouveaux styles pour le splash screen :
- `splashMessage` : Texte blanc gras pour "Respirez. Nous veillons."

### 4. `lib/screens/shared/splash_screen.dart`
Entièrement réécrit avec :
- Animation de respiration via `AnimationController` (6s cycle)
- Logo croissant de lune avec CustomPainter animé
- Onde de respiration horizontale (CustomPaint)
- Étoiles scattered avec Positioned widgets
- Navigation après 3 secondes (préservée)
- Même logique d'authentification

## Étapes d'installation

### Étape 1 : Polices (pas nécessaire)

Les polices sont automatiquement téléchargées la première utilisation via google_fonts package.

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
// Gradient de fond
const gradientStart = Color(0xFF5BBCB8);  // Changez la couleur start
const gradientEnd = Color(0xFF8ECFBF);    // Changez la couleur end

// Logo card
static const Color warmIvory = Color(0xFFF4F0E8); // Card background
```

### Modifier la durée de respiration

Dans `lib/screens/shared/splash_screen.dart` (ligne ~26):
```dart
_breathingController = AnimationController(
  duration: const Duration(seconds: 4), // Au lieu de 6
  vsync: this,
)..repeat();
```

### Modifier la durée du splash

Dans `_navigateAfterSplash()` (ligne ~33):
```dart
_navigationTimer = Timer(const Duration(seconds: 5), _navigateAfterSplash); // Au lieu de 3
```

### Modifier le texte

Dans `build()`, changez le texte "Respirez. Nous veillons." :
```dart
Text(
  'Votre texte personnalisé',
  // ...
);
```
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
