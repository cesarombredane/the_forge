# The Forge

A private Android application for tracking workouts, runs, and other sports.

The project is an empty Flutter scaffold ready for feature development. It
uses the same Android-only Flutter and Gradle configuration as `better_todo`.

## Structure

```text
lib/
├── main.dart       Application entry point
├── app/            Root application and app-wide state
├── data/
│   ├── local/      Local persistence
│   ├── models/     Domain models
│   └── repositories/
├── features/       Feature screens and logic
├── theme/          Shared colors and theme
└── widgets/        Shared widgets
```

## Development

```bash
flutter pub get
flutter analyze
flutter run
```
