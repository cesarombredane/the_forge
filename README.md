# The Forge

The Forge is a personal Android training companion for building a lasting sports
habit. It is being made for one user, not as a production service or commercial
product. It brings gym, running, walking, hockey, and mobility training into one
place so that every session can be created, planned, completed, and reviewed.

The application treats consistency as the main measure of progress. Performance
still matters, but only in relation to the athlete's own starting point. The
goal is not to compare users or reward unhealthy volume: it is to make showing
up visible, satisfying, and sustainable.

## Product vision

The Forge should help its user answer four simple questions:

1. What am I planning to do?
2. What did I actually do?
3. Am I training consistently?
4. How have I progressed since I started?

The core loop is:

```text
Create a template -> Add it to the calendar -> Complete it -> Review the result
```

## Supported sports

Each template has a title, sport, duration, and description. It also contains
parameters specific to its sport:

- **Gym:** a structured exercise list with sets, repetitions, and weight or
  additional weight
- **Running:** distance, target cadence, and pace, route, or effort notes
- **Walking:** distance, target cadence, and route or effort notes
- **Hockey:** championship game, friendly game, training, coaching, or tournament,
  plus position or session details
- **Mobility:** movements and body areas

Templates can be created, edited, deleted, and reused any number of times. Adding
a template to the calendar creates an independent snapshot, so later template
changes never rewrite an already planned or completed workout.

## Planning and history

The planning page can switch between a seven-day agenda and a monthly calendar.
The agenda groups upcoming workouts by day and explicitly labels empty days as
rest days. The calendar shows the workouts associated with a selected date. A
template can be added to an exact date and time, then rescheduled, deleted, or
marked as complete.

When completing a session, the user can adjust its actual duration and details,
record the gym sets, repetitions, and loads actually used, and add a comment
about the training. Completed sessions remain available in history.

## Gamification philosophy

Gamification is intentionally outside the current MVP. When it is added later,
it will follow these principles.

Gamification is designed to reward consistency rather than absolute performance.
It must remain encouraging when the user rests, gets sick, or returns after a
break.

The main progression systems are:

- Weekly consistency goals based on a chosen number of training days or sessions
- Current and longest streaks with configurable rest days
- Experience for completing planned sessions and maintaining regularity
- Levels, badges, and milestones tied mostly to attendance and variety
- A visual weekly and monthly activity map
- Personal-best improvements measured relative to the user's own baseline
- Recovery-friendly rewards for planned rest and for restarting after a break

Missed workouts should never remove earned experience or levels. Streak rules
must be transparent, attainable, and adjustable rather than creating guilt.
Performance-based rewards should be secondary and compare only the user with
their previous results.

## Current MVP

The current version focuses on the smallest complete training loop:

- Create reusable templates for gym, running, walking, hockey, and mobility
- Edit and permanently delete templates
- Add a template snapshot to an exact calendar date and time
- View planned workouts in a seven-day list or monthly calendar
- Record structured sport-specific parameters
- Mark a workout as complete with its actual duration and a comment
- Update exercises, sets, repetitions, and loads when completing a gym workout
- Review completed workout history
- Store everything locally and consistently in SQLite

Filters, statistics, profile preferences, and gamification are deliberately
deferred until the template and planning loop is useful in daily training.

## Local data

The Forge works entirely offline. SQLite is the single source of truth for
workouts, planning, history, preferences, and gamification progress. There is no
server, account system, API, analytics service, or cloud synchronization. All
application features must continue to work without a network connection.

Database writes that update several related records, such as completing a
workout and updating its progression data, must use transactions so the local
data remains consistent. Schema changes must use explicit migrations to preserve
existing training history.

## Technology

- Flutter and Dart for the application and interface
- Material 3 with a dark-only theme
- SQLite for local structured storage
- Gradle for Android builds and APK packaging

## Architecture

```text
lib/
├── main.dart                       Application entry point
├── app/                            Root application and app-wide state
├── data/
│   ├── local/                      SQLite database and migrations
│   ├── models/                     Template, workout, and exercise models
│   └── repositories/               Reads, writes, and domain queries
├── features/
│   ├── home/                       Drawer, calendar, templates, and history
│   ├── templates/                  Sport-specific template editor
│   └── workouts/                   Workout completion
├── theme/                          Shared colors and dark theme
└── widgets/                        Shared interface components
```

Presentation code does not access SQLite directly. Repositories own template and
workout persistence, including transactional exercise snapshots and completion.

## Development

```bash
flutter pub get
flutter analyze
flutter run
```

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
