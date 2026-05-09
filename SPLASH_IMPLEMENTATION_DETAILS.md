# 🌙 Splash Screen - Détails d'implémentation

## Code Source - Structures Principales

### 1. **AnimationController (6s Breathing Cycle)**

```dart
_breathingController = AnimationController(
  duration: const Duration(seconds: 6),
  vsync: this,
)..repeat();
```

- Cycle continu de 6 secondes
- Contrôle les animations du halo et de l'onde
- Valeur animée: `_breathingController.value` (0.0 → 1.0)

### 2. **Halo de Respiration (Scale Animation)**

```dart
final scale = 0.8 + 0.4 * sin(_breathingController.value * 2 * pi);
```

**Mathématique** :
- Min scale: 0.8 (8:00 = 80% taille)
- Max scale: 1.2 (1:00 = 120% taille)
- Fonction: Sinusoïde lisse (sin wave)
- Durée cycle: 6 secondes

**Effet visuel** :
```
Temps    0s   1.5s   3s    4.5s   6s
         ├──────┼──────┼──────┼──────┤
Scale    0.8   1.0    1.2   1.0    0.8
           │     ╱╲    │    ╱╲     │
           └───╱  ╲───┘───╱  ╲────┘
               (doux et régulier)
```

### 3. **Logo Croissant de Lune (CustomPainter)**

```dart
class _MoonCrescentPainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    // Cercle principal (teal mist)
    canvas.drawCircle(center, radius, paint);
    
    // Overlay circle (nuit profonde) = crescent
    canvas.drawCircle(
      Offset(center.dx + radius * 0.3, center.dy),
      radius * 0.85,
      overlayPaint,
    );
  }
}
```

**Technique** :
- Deux cercles superposés
- L'overlay crée le "croissant"
- Gradient teal appliqué au conteneur parent

### 4. **Onde de Respiration (Wave Animation)**

```dart
const amplitude = 8.0;      // Hauteur de l'onde
const wavelength = 40.0;    // Largeur d'une vague

final phase = (x / wavelength + progress * 2 * pi) * 2 * pi;
final y = size.height / 2 + amplitude * sin(phase);
```

**Paramètres ondulaires** :
- **Amplitude** : 8px de mouvement vertical
- **Longueur d'onde** : 40px entre pics
- **Phase** : Avance continuellement avec `progress`
- **Style** : Trait transparent teal mist

**Pattern de l'onde** :
```
      ╱╲      ╱╲      ╱╲
────╱  ╲────╱  ╲────╱  ╲────
   ▲8px
   └─ Amplitude
←40px→ Wavelength
```

## Cycles temporels

### Timeline complète (3 secondes affichage)

```
Temps (ms)    Animation              Affichage              Navigation
─────────────────────────────────────────────────────────────────────
0             ├─ Halo pulse x0.33    ├─ SplashScreen        ├─ Timer start
              │  (0s → 6s cycle)     │  visible              │
1500          │  Halo scale 1.0      │  (milieu du pulse)    │
3000          │  Halo scale 1.2      ├─ Transition OUT       ├─ Navigate
              │  (milieu du pulse)   │  (opacité 1.0 → 0.0)  │
3000+         └─ (continue but...)   ├─ Next screen         └─ Auth check
              ...AnimationController │  appears
              se dispose             │
```

## États et conditionsde navigation

```
          ┌─────────────────┐
          │  Splash Screen  │
          │  (3 secondes)   │
          └────────┬────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
   Pas connecté         Connecté
        │                     │
   [AuthCheck]          ┌──────┴────────┐
        │               ▼               ▼
    Login      Rôle en cours    Rôle chargé
    Screen      d'attente
                    │           ├──────┬──────┐
                    │           ▼      ▼      ▼
                 (Retry)      Doctor Patient Profile
                  400ms      Dashboard Dashboard Fix
```

## Dimensioning & Spacing

### Layout vertical

```
┌─ Top margin: auto
│
│  "9:41"  ← DM Serif 24px, teal mist
│  padding: 40px
│
│  🌙 Moon Logo (100x100px)
│  with halo (280x280px max)
│  
│  padding: 32px
│
│  "Respirez. Nous veillons."  ← Inter 18px, ivoire
│  opacity: 0.9
│
│  padding: 48px
│
│  Wave ← 180x40px
│
└─ Bottom margin: auto
```

### Halo dimensions

```
Base container:     280px (min) → 336px (max)
Moon logo:          100px
Wave element:       180px width × 40px height
```

## Codage des couleurs avec opacité

### Utilisation `.withValues(alpha:)`

**Ancien code (déprécié)** :
```dart
AppColors.tealMist.withOpacity(0.6)  ❌
```

**Nouveau code (correct)** :
```dart
AppColors.tealMist.withValues(alpha: 0.6)  ✅
```

**Valeurs opacité dans le code** :
- Halo background: `alpha: 0.15` (très doux)
- Halo shadow: `alpha: 0.2` (légèrement visible)
- Moon gradient start: `alpha: 0.9` (presque plein)
- Moon gradient end: `alpha: 0.8` (légèrement transparent)
- Moon shadow: `alpha: 0.3` (visible mais subtile)
- Wave line: `alpha: 0.6` (prominent)

## Performance considerations

### Optimisations appliquées

1. **SingleTickerProviderStateMixin** ✅
   - Une seule animation contrôlée
   - Plus efficient qu'une multiple AnimationController

2. **CustomPaint** ✅
   - Dessin vectoriel efficace
   - Rasterisé au GPU
   - Meilleure performance que Canvas

3. **AnimatedBuilder** ✅
   - Reconstruction uniquement du widget animé
   - Le reste reste inchangé

4. **Disposal proper** ✅
   - `_breathingController.dispose()` dans dispose()
   - `_navigationTimer?.cancel()` dans dispose()
   - Prévient memory leaks

### Impacts potentiels

- **Émulateur** : Peut avoir 60fps constant
- **Appareil faible** : Peut descendre à 30fps (toujours lisse)
- **Chaud/batterie** : Impact minimal (animation simple)

## Intégration avec l'authentification

### Flux de vérification

```dart
void _navigateAfterSplash() {
  final auth = context.read<AuthProvider>();
  
  // 1. Utilisateur connecté ?
  if (auth.user == null) → context.go(RouteNames.login);
  
  // 2. Rôle en cours de chargement ?
  if (auth.isLoadingRole) {
    _navigationTimer = Timer(400ms, _navigateAfterSplash);  // Retry
    return;
  }
  
  // 3. Naviguer selon le rôle
  if (role == 'doctor') → DoctorDashboard
  if (role == 'patient') → PatientDashboard
  else → FixProfile
}
```

### Points clés

- Aucune modification de la logique d'auth
- Simplement la même logique, nouveau UI
- Retry mécanique : attend 400ms si rôle charge

## Personnalisations fréquentes

### Changer la durée de respiration

**Fichier** : `splash_screen.dart:29`
```dart
duration: const Duration(seconds: 4),  // Au lieu de 6
```

### Changer les couleurs

**Fichier** : `app_colors.dart:59-62`
```dart
static const Color nightBg = Color(0xFF1a1a1a);  // Nouveau
static const Color tealMist = Color(0xFF00ffaa); // Nouveau
```

### Ajouter une animation fondu

**Dans `build()` après 3 secondes** :
```dart
// Avant: context.go(RouteNames.login);
// Après:
Future.delayed(const Duration(milliseconds: 300), () {
  if (mounted) context.go(RouteNames.login);
});
```

### Afficher l'heure réelle

**Fichier** : `splash_screen.dart:97`
```dart
Text(
  DateTime.now().format('HH:mm'),  // Au lieu de '9:41'
  style: AppTextStyles.splashTime,
),
```

## Debugging

### Logs útiles

```dart
// Pour debug l'animation
print('Animation value: ${_breathingController.value}');
print('Scale: ${0.8 + 0.4 * sin(_breathingController.value * 2 * pi)}');

// Pour debug l'authentification
print('User: ${auth.user}');
print('Loading: ${auth.isLoadingRole}');
print('Role: ${auth.role}');

// Pour debug la navigation
print('Navigating to: ${role == "doctor" ? "doctorDashboard" : "patientDashboard"}');
```

### Vérification visuelle

- [ ] Halo pulse doucement (6s)
- [ ] Onde ondule horizontalement
- [ ] Texte apparaît clairement
- [ ] Heure affichée (9:41)
- [ ] Transition lisse après 3s
- [ ] Navigation vers le bon écran

---

**Prêt pour customization !** 🎨
