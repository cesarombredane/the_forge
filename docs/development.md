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
- Create a weekly requirement and verify that both planned and completed matching
  workouts count within the current Monday-to-Sunday week.
- Enter steps, including zero, and verify the seven-day average and goal.
- Add/delete a weigh-in and verify history, chart, and in-app reminder display.

For schema changes, check both fresh creation and upgrade of a disposable copy
of an older database. Preserve the user's real local history; do not uninstall
the app, clear its data, or reset its database as a migration workaround.

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
