# Specialist Finder

A Flutter mobile application that helps clients discover and choose professional service providers using a Multi-Criteria Decision Analysis (MCDA) algorithm. The app operates entirely offline using local SQLite storage.

## Features

- **Offline-First**: All data stored locally in SQLite database
- **MCDA Ranking**: Multi-criteria matching algorithm with 5 criteria:
  - Skills match (35% default)
  - Price (25% default)
  - Location/distance (15% default)
  - Rating (15% default)
  - Experience (10% default)
- **Search & Filter**: Search by keyword, filter by category, price, rating, experience, and distance
- **Score Breakdown**: Detailed explanation of matching scores with criterion-by-criterion breakdown
- **Adjustable Weights**: Customize matching weights in settings with real-time re-ranking
- **Developer Tools**: Import/export data, seed database with synthetic data
- **Location Services**: Optional "near me" search using device GPS
- **Accessibility**: Support for large text and screen readers

## Requirements

- Flutter SDK 3.10.4 or higher
- Dart SDK 3.10.4 or higher
- Android Studio / Xcode (for mobile development)
- Android SDK (for Android development)
- iOS SDK (for iOS development, optional)

## Installation

### 1. Check Flutter Installation

```bash
flutter doctor
```

Ensure all required components are installed and configured correctly.

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

For Android:
```bash
flutter run -d android
```

For iOS:
```bash
flutter run -d ios
```

## Project Structure

```
lib/
├── data/                    # Data layer
│   ├── database/           # SQLite database helper
│   ├── repositories/       # Repository implementations
│   └── services/           # Settings, logging services
├── domain/                  # Domain layer
│   ├── models/             # Domain models
│   ├── repositories/        # Repository interfaces
│   └── services/           # Business logic (MCDA, location)
└── presentation/           # Presentation layer
    ├── providers/          # State management (Provider)
    └── screens/            # UI screens
```

## Architecture

The app follows clean architecture principles with three layers:

1. **Presentation Layer**: UI screens and state management using Provider
2. **Domain Layer**: Business logic, models, and repository interfaces
3. **Data Layer**: SQLite implementation, services, and data sources

## Database Schema

### Specialists Table
- `id`: INTEGER PRIMARY KEY
- `name`: TEXT
- `category`: TEXT
- `skills`: TEXT (comma-separated)
- `price`: REAL
- `rating`: REAL (0-5)
- `experience_years`: INTEGER
- `lat`: REAL
- `lon`: REAL
- `address`: TEXT
- `bio`: TEXT
- `image_path`: TEXT
- `tags`: TEXT (comma-separated)
- `availability_notes`: TEXT
- `created_at`: DATETIME

### Settings Table
- `id`: INTEGER PRIMARY KEY
- `key`: TEXT UNIQUE
- `value`: TEXT
- `updated_at`: DATETIME

### Logs Table (dev mode)
- `id`: INTEGER PRIMARY KEY
- `level`: TEXT
- `message`: TEXT
- `timestamp`: DATETIME

## MCDA Algorithm

The matching algorithm calculates a normalized score (0-1) for each criterion:

1. **Skills Score**: Overlap between required skills and specialist skills
2. **Price Score**: Normalized inverse price (lower price = higher score)
3. **Location Score**: Normalized inverse distance (closer = higher score)
4. **Rating Score**: Rating / 5.0
5. **Experience Score**: Experience years / max experience (capped at 20)

Final score = Σ(weight_i × score_i)

## Usage

### First Launch

On first launch, the app shows an onboarding flow explaining:
- App purpose
- Offline operation
- Demo data disclaimer

### Seeding Data

To populate the database with test data:

1. Open the app
2. Go to Settings → Developer Tools
3. Tap "Seed Database" to generate 200 synthetic specialists

### Adjusting Weights

1. Go to Settings
2. Adjust sliders for each criterion
3. Weights automatically normalize to sum to 100%
4. Specialist list re-ranks immediately

### Exporting/Importing Data

**Export:**
1. Settings → Developer Tools
2. Tap "Export Data"
3. JSON file saved to app documents directory

**Import:**
1. Settings → Developer Tools
2. Tap "Import Data"
3. Select JSON file from device

## Testing

### Run Unit Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/domain/services/mcda_service_test.dart
```

### Test Coverage

```bash
flutter test --coverage
```

## Performance

The app is optimized for:
- **Dataset Size**: Supports 1000+ specialist records
- **Ranking Time**: ≤ 500ms for 1000 records on mid-range devices
- **UI Performance**: 60 FPS scrolling on target devices

### Performance Testing

Performance profiling can be done using:
- Android Studio Profiler
- Flutter DevTools
- Built-in logging service (dev mode)

## Privacy & Security

- **No Network Calls**: All operations are local by default
- **Private Storage**: SQLite database stored in app private directory
- **No Data Collection**: App uses simulated test data only
- **Location Permission**: Optional, only requested if user enables location features

## Known Limitations

- Image assets must be manually added to `assets/` directory
- Geocoding (address → coordinates) not implemented (future work)
- No real-time synchronization (offline-only)

## Future Enhancements

- [ ] Image asset management
- [ ] Optional geocoding service integration
- [ ] Database encryption
- [ ] CSV import support
- [ ] Advanced filtering options
- [ ] Favorite/bookmark specialists
- [ ] Search history

## Troubleshooting

### Database Issues

If the database becomes corrupted:
1. Clear app data (Android: Settings → Apps → Specialist Finder → Clear Data)
2. Reinstall the app
3. Re-seed data from Developer Tools

### Location Not Working

- Ensure location permissions are granted
- Check device location services are enabled
- App works without location (uses neutral score)

### Build Errors

```bash
flutter clean
flutter pub get
flutter run
```

## License

This project is for academic/dissertation purposes.

## Author

Developed for dissertation project on Multi-Criteria Decision Analysis in mobile applications.

## Acknowledgments

- Flutter team for the excellent framework
- SQLite for local database storage
- Provider package for state management
