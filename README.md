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
Create a workout -> Plan it -> Complete it -> Record the result -> Build momentum
```

## Supported sports

Each workout has shared information such as a title, sport, date, duration,
status, notes, and optional template. A workout can also contain data specific
to its sport:

- **Gym:** exercises, sets, repetitions, load, rest time, and per-exercise notes
- **Running:** duration, distance, perceived effort, route notes, and optional pace
- **Walking:** duration, distance, perceived effort, and route notes
- **Hockey:** duration, training or match type, position, perceived effort, and notes
- **Mobility:** movements, body areas, duration or repetitions, difficulty, and notes

Workout creation and editing must work for both reusable templates and individual
planned sessions. Completing a workout stores what was really performed without
changing the original template.

## Planning and history

The planning view provides a calendar and agenda of upcoming workouts. Sessions
can be created from scratch or from a template, moved to another date, edited,
skipped, or marked as complete.

When completing a session, the user can adjust its actual duration and details,
record gym loads and repetitions, and add a comment about the training. Completed
sessions remain available in a searchable and filterable history.

## Gamification philosophy

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

## Initial scope

The first useful version should provide:

- Local profile and preferences
- Workout templates for all five sports
- Creation, editing, duplication, and deletion of workouts
- Calendar planning and rescheduling
- Completion flow with actual results and a session comment
- Gym exercise sets with repetitions and loads
- Workout history and basic filters
- Weekly goal, streaks, experience, levels, and initial consistency badges
- Basic progress and consistency statistics
- Reliable local persistence in SQLite

The detailed implementation roadmap is maintained in [TODO](TODO).

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
│   ├── models/                     Workout and progression models
│   └── repositories/               Reads, writes, and domain queries
├── features/
│   ├── home/                       Dashboard and next workout
│   ├── workouts/                   Templates and workout editor
│   ├── planning/                   Calendar and agenda
│   ├── history/                    Completed sessions
│   ├── progress/                   Statistics and personal progress
│   └── profile/                    Goals and preferences
├── theme/                          Shared colors and dark theme
└── widgets/                        Shared interface components
```

Presentation code should not access SQLite directly. Repositories own data
access, while domain services calculate streaks, experience, goals, and relative
progress independently from the interface.

## Development

```bash
flutter pub get
flutter analyze
flutter run
```
