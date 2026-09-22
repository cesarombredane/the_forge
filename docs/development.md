# Development workflow

Start with [README](../README.md) for toolchain setup, running, APK builds, and
Android Wi-Fi debugging. Read [ARCHITECTURE](../ARCHITECTURE.md) before changing
component responsibilities. AI contributors must follow [AGENTS.md](../AGENTS.md).

## Working on a change

1. Read the relevant source and behavior documentation. Inspect existing changes
   without modifying them; `git status`, `git diff`, and `git log` are allowed.
2. Describe the intended behavior, affected files, implementation steps,
   documentation updates, and verification in a detailed plan.
3. Obtain the user's approval before editing. Approval covers the planned scope;
   a material expansion needs a revised plan and renewed approval.
4. Implement the approved change using the existing screen/controller/repository
   boundaries. Dependencies may be added when needed within the approved scope.
5. Update documentation alongside changes to behavior, architecture, or process.
6. Run `flutter analyze`, inspect the resulting diff, and report changes and
   verification honestly. Git commits and other repository-state changes belong
   to the user.

## Commands and checks

The documentation website has its own npm project. See the [website README](README.md)
for install/run commands. After website changes, run `npm run build` from `docs/`
and check navigation, search, and diagrams in preview, in addition to the Flutter
analysis required below.

```bash
flutter pub get
flutter analyze
```

Run dependency resolution when setting up the project or changing dependencies.
Keep `pubspec.yaml` and the generated `pubspec.lock` consistent. Do not edit
dependency sources or generated build files to implement application behavior.

Always run `flutter analyze` after changes, including documentation work. Fix
issues introduced by the approved change; report unrelated existing issues
without silently expanding scope. If tooling prevents the command from running,
report the actual blocker rather than claiming analysis passed.

The `test/` directory is empty and no automated test suite is configured. Do not
run nonexistent tests or describe analysis as testing. Revisit this instruction
and document test commands if tests are introduced in an approved task.

For Dart changes, format the affected files with `dart format <paths>` and avoid
unrelated formatting. For UI or persistence changes, use a relevant manual check
on an available emulator/device; say explicitly if no device verification was
performed. A build is useful when Android configuration changes, but is not a
mandatory check for every edit.

## Useful manual scenarios

Choose checks relevant to the change:

- Create each affected sport template and verify validation and exercise order.
- Schedule a template, edit the original, and confirm the workout snapshot stays
  unchanged. Complete it and verify its values in History after restarting.
- Edit completed workouts for all four sports in History. Check date/time,
  duration, comment, and sport-specific fields; add, rename, remove, and reorder
  exercises. Verify invalid values are rejected and cancel leaves data unchanged.
  Restart and confirm edits persist while source templates and other workouts
  remain unchanged. Check a workout whose template was deleted, and verify
  changing its training date updates History order and weekly matching.
- Complete a run with a different duration and distance (including decimal
  comma input). Check target/actual/difference values, faster/slower/equal pace,
  invalid and blank input, and cancel. Restart and edit actual results in History;
  targets must stay fixed even if the source template changes or is deleted.
  Check version-10 fresh creation and upgrades using disposable data: pending
  runs gain their own targets; old completed runs keep values with unknown targets.
- Create a weekly requirement and verify that both planned and completed matching
  workouts count within the current Monday-to-Sunday week.
- Enter steps, including zero, and verify the seven-day average and goal.
- Add/delete a weigh-in and verify history, chart, and in-app reminder display.
- Schedule a weigh-in for today and save a weight from Planning or the Weight
  page. Confirm the entire reminder disappears from the agenda and selected-day
  calendar list, including its calendar marker when no pending workout exists.
  Restart and confirm it stays hidden while next week's reminder remains.
  With multiple weigh-ins that day, deleting one must keep the reminder hidden;
  deleting the last must restore it. Canceling or failing to save must leave the
  reminder visible.

For schema changes, check both fresh creation and upgrade of a disposable copy
of an older database. Preserve the user's real local history; do not uninstall
the app, clear its data, or reset its database as a migration workaround.

## Gym progression verification

Use disposable databases for migration and persistence checks. Check version-10
upgrades and fresh version-11 creation, normalized-name linking, unit conflicts,
review resolution, historical bodyweight selection, set expansion, and foreign-key
integrity. Confirm unrelated sports, running targets, and existing history survive.

On a device, create/select library exercises, review imported identities, archive
an exercise, and correct a link. Start a gym session with and without a weigh-in;
verify bodyweight requirements, assistance validation, individual set values,
zero skips, and unconfirmed-set completion blocking. Leave/restart/resume and
confirm the comment, set values, and bodyweight snapshot persist. Change the
source template and record a new weigh-in; existing session snapshots must hold.

Check calculations with known examples: `60×10 + 60×9 + 55×10 = 1690`, maximum
weight 60; at 90 kg bodyweight, `-20×10` means 700 kg·reps. Check timed exercises,
entirely skipped entries, missing historical weights, and duplicate occurrences
in one workout. Verify tracked selections persist, graph point selection works,
and history edits/deletions refresh both gym and running charts.

No permanent automated test suite is included. Disposable validation harnesses
may exercise migration, repository, calculation, and widget behavior without
modifying production data or the repository's dependency manifests.

## Hockey verification

Use disposable data to check fresh version-12 creation and version-11 upgrades.
Existing history must keep its duration and unknown statistics. Check foreign
keys, normalized opponent names, global renaming, deletion with retained history,
and rejection of deleted opponents on new entries.

Complete games with signed plus-minus and explicit zeros; reject missing stats
and opponents. Save training both with and without statistics and an opponent.
Confirm coaching has no statistics. Save tournament games independently, leave,
restart, and resume; verify summed durations, per-game dates, editing/deletion,
and prevention of empty completion or deleting the last completed game.
Check saved games appear before tournament completion without double-counting
afterward. Verify History updates and workout deletion refresh Performance.

Check overall/per-opponent totals, goals/assists charts, negative plus-minus,
No opponent, deleted opponents, and August 31/September 1 season boundaries.
Device checks should include narrow-screen forms and chart/table scrolling.

## Cancellation, mobility, and History filtering checks

Check fresh version-13 creation and version-12 upgrades with disposable data.
Start a gym session, edit multiple sets/duration/comment, leave, resume, and
cancel. Confirm the original scheduled values return, the start state clears,
and restarting creates a new cancellation snapshot. Check already-started
version-12 sessions retain their current duration on cancellation.

Cancel with invalid input, pending writes, and a failed save; ensure queued
writes cannot overwrite the reset. Declining confirmation keeps progress.
Finishing and deleting sessions remove their backups. Check foreign-key integrity.

Start a multi-cycle mobility routine, record differing values and zero skips,
leave/restart/resume, finish, and edit individual cycle results in History.
Unconfirmed results must block finishing. Cancel restores the scheduled routine.
Existing aggregate-only history stays intact. Check fixed movement/cycle counts
during sessions and history validation after changing cycle counts.

Filter History by every sport and return to All. Verify empty results, ordering,
edit/delete actions, and filter retention across drawer navigation. Run Flutter
analysis, documentation build, and device checks where available.

## Android build notes

The checked-in Gradle wrapper specifies Gradle 9.1.0. Settings declare Android
Gradle Plugin 9.0.1 and Kotlin 2.3.20. Java/Kotlin compilation targets 17; Android
SDK values come from Flutter. These are project configuration values, not a
claim that every installed SDK/toolchain combination has been validated.

`android/local.properties` is machine-local and ignored. Release builds currently
use debug signing. Do not add signing secrets, machine paths, generated build
output, or dependency caches to project documentation or source control.

## Documentation ownership

| File                  | Keep current when                                                           |
| --------------------- | --------------------------------------------------------------------------- |
| `README.md`           | Overview, supported features, prerequisites, or startup commands change     |
| `ARCHITECTURE.md`     | Components, dependencies' roles, state flow, or platform integration change |
| `docs/database.md`    | Tables, mappings, transactions, or migrations change                        |
| `docs/behavior.md`    | User-visible rules, calculations, or limitations change                     |
| `docs/development.md` | Setup details, validation, or development process changes                   |
| `AGENTS.md`           | The user changes agent permissions or required procedure                    |
| `docs/README.md` | Website installation, commands, routes, or maintenance changes |

Document current behavior. Keep proposed features out of descriptions of the
implemented app, and avoid duplicating detailed rules across multiple pages.
