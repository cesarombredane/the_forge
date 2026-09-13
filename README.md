# The Forge

The Forge is a personal Android training planner and journal built with Flutter.
It keeps reusable gym, running, hockey, and mobility sessions, a workout calendar,
completed workout history, weekly planning targets, weigh-ins, and daily steps
on the device in SQLite.

```text
Create a template -> Schedule a workout -> Complete it -> Review history
```

## Features

- **Templates:** create, edit, delete, and reuse sport-specific sessions.
  Gym exercises support sets, repetitions or seconds, loads, and per-side options.
  Running uses duration and distance to calculate pace. Hockey records session
  type and details. Mobility repeats an ordered list of movements over cycles.
- **Planning:** schedule workouts at a date and time, view pending sessions in a
  seven-day agenda or monthly calendar, and reschedule or delete them.
- **Completion and history:** record actual duration, adjust existing gym or
  mobility exercise values, add a comment, and review completed workouts.
- **Weekly plan:** set Monday-to-Sunday targets accepting one template or a group
  of templates. Both scheduled and completed sessions count toward these targets.
- **Weight:** record weigh-ins, review history and a chart, and display a recurring
  weekly weigh-in reminder inside Planning.
- **Steps:** manually enter daily totals for the last seven days and compare their
  seven-day average with a configurable daily goal.

Scheduling creates an independent copy of a template and its exercises. Later
changes to or deletion of that template do not rewrite existing workouts.

The app works offline: there is no backend, account, analytics service, or cloud
synchronization. Steps are entered manually; weigh-in reminders do not generate
system notifications. See [behavior rules](docs/behavior.md) for precise details.

## Technology

- Flutter and Dart, with a dark-only Material 3 interface
- SQLite through `sqflite`, with `path` for database path construction
- Android host and Gradle build configuration

## Getting started

Run these commands from the project root.

### Prerequisites

- A Flutter SDK whose bundled Dart SDK satisfies `^3.12.2`, as declared in
  [pubspec.yaml](pubspec.yaml)
- Android SDK, platform tools (`adb`), and an Android emulator or physical device
- A Java toolchain compatible with the checked-in Android build configuration;
  the project's Java/Kotlin compilation target is 17

Check the local toolchain and resolve Android setup issues before running:

```bash
flutter doctor
flutter pub get
flutter devices
flutter analyze
flutter run -d <device-id>
```

With a single available target, `flutter run` can select it automatically.
Dependency installation and build tooling may need network access; app features
operate locally after installation.

### Build an APK

```bash
flutter build apk --release
```

The APK is normally written to `build/app/outputs/flutter-apk/app-release.apk`.
The current release build uses the debug signing configuration for personal
installation; a separate release signing setup is not present.

### Run on an Android device over Wi-Fi

Wireless debugging requires Android 11 or later. Connect the computer and phone
to the same Wi-Fi network, then enable **Developer options > Wireless debugging**
on the phone.

To pair the phone for the first time:

1. In **Wireless debugging**, select **Pair device with pairing code**.
2. Note the IP address, pairing port, and six-digit pairing code shown by the
   phone.
3. Run the following command and enter the pairing code when prompted:

   ```bash
   adb pair <phone-ip>:<pairing-port>
   ```

After pairing, return to the main **Wireless debugging** screen and note the IP
address and port shown there. This connection port is usually different from
the pairing port. Connect and verify the device with:

```bash
adb connect <phone-ip>:<connection-port>
adb devices
```

The phone should now appear in `flutter devices`. Start the application with:

```bash
flutter run -d <device-id>
```

The port can change when wireless debugging is restarted, so run `adb connect`
again with the current address shown on the phone when necessary. Pairing only
needs to be repeated if the saved pairing is removed or no longer recognized.

## Documentation

Browse the documentation locally as a VitePress website:

```bash
cd docs
npm ci
npm run dev
```

See the [website README](docs/README.md) for Node prerequisites, building,
previewing, and maintaining the site.

- [Architecture](ARCHITECTURE.md): current components, state flow, and persistence
- [Development](docs/development.md): workflow, validation, and Android build notes
- [Database](docs/database.md): tables, relationships, transactions, and migrations
- [Behavior rules](docs/behavior.md): exact screen behavior and calculations
- [Agent procedure](AGENTS.md): required workflow for AI contributors

There are currently no automated tests in `test/`. Always run `flutter analyze`
after changes and report its result.
