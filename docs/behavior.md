# Behavior rules

This describes the current interface and calculations. It is the reference for
understanding existing behavior before changing code, not a roadmap.

## Templates and sports

Every template has a required name, a sport, a positive whole-minute duration,
and an optional description. Templates are listed by sport then title.

| Sport    | Editable sport fields                                                                             |
| -------- | ------------------------------------------------------------------------------------------------- |
| Gym      | Warm-up, ordered exercises, sets, repetitions or seconds, load, per-side flag                     |
| Running  | Positive distance in km; pace calculated from duration and distance                               |
| Hockey   | Warm-up; championship, friendly, training, coaching, or tournament type; position/session details |
| Mobility | Positive cycle count; ordered movements with repetitions or seconds and per-side flag             |

Gym and mobility templates require at least one exercise. Their exercises can
be added, edited, removed, and reordered. Gym exercises are selected from the
exercise library; mobility movements retain free-text names. Gym loads follow the
selected exercise’s weight mode: external load is
nonnegative; bodyweight adjustments may be negative for assistance. Mobility movements store one set and zero load; the template
cycle count represents repetition of the whole movement sequence. Switching
sports involving gym or mobility clears the editor's exercise list.

Running pace is `(durationMinutes * 60 / distanceKm)`, rounded to whole seconds,
then displayed as minutes and seconds per kilometre. Running and mobility do not
save warm-up instructions. Only hockey saves the free-text sport-details field.

## Scheduling and planning

A template must exist before scheduling. The scheduling dialog selects a
template, date, and time, initially 18:00. Date pickers allow dates from 2020 to
2100. Scheduling copies the template and its exercises into an independent
workout. There is no automatic recurring-workout generator or conflict checking.

The agenda shows **today through the next six days**, not a calendar week. The
monthly calendar selects a date and lists that day's pending workouts. Both
views filter to `planned` status. A day without pending workouts or a weigh-in
reminder is labeled “Rest day,” even if a completed workout exists in History.
Past pending workouts remain stored and can be reached through the calendar;
they are not automatically marked missed, completed, or deleted.

Rescheduling changes the scheduled date/time only. Template edits and deletion
do not alter previously scheduled or completed snapshots. Template and workout
deletion require confirmation and are permanent.

## Completion and history

Running completion accepts a positive actual duration and optional comment.
Gym and mobility use the start/resume workflows below; hockey has its own
session/game workflow. Runs also accept a
positive actual distance in km, with a decimal comma or dot. Duration remains
a positive whole number of minutes. Both inputs start from the scheduled values.

Saving sets status to `completed`, records the current completion timestamp, and
replaces the workout duration and exercise rows. For running it also saves actual
distance, while retaining separate original target duration and distance from
the scheduled snapshot. Gym keeps its exercise prescription alongside individual working-set results;
other non-running sports do not store separate planned and actual values.

Run completion, History, and History editing show Target, Actual, and Difference
for duration, distance, and pace. Pace is duration × 60 / distance, rounded to
seconds per kilometre. Duration and distance differences are actual minus target;
pace differences compare the displayed rounded paces and say faster, slower, or
on target. Distance is displayed to at most two decimal places. Blank or invalid
inputs have no actual pace or difference until corrected; saving requires valid
positive values.

Pending runs present during the version-10 upgrade retain their scheduled values
as targets. Previously completed runs retain their saved duration and distance,
but show “Original targets unavailable.” Their target duration was overwritten
on completion, and the saved distance may have been corrected in History;
the app does not invent targets from a current template. Their saved distance
remains editable as an actual result. A comparison cannot be recovered for those
older runs.

History displays completed workouts in descending **scheduled** date order, not
completion-time order. Select All, Gym, Running, Hockey, or Mobility to filter
the list. The selection stays while navigating in the app and defaults to All
after restarting. Empty results keep the filter available.
Every completed session has Edit and Delete actions in its
menu, including sessions whose source template was deleted. Edit opens the saved snapshot with
its name, sport, training date/time, duration, description, warm-up, comment,
and sport-specific fields. Gym and mobility exercises can be added, edited, removed, and reordered in
History. Gym entries use library identities, and each working set is editable
without flattening differing weights or amounts. Historical bodyweight snapshots
can be corrected here; these corrections do not create new weigh-ins.
The running editor calculates pace from the edited duration and distance.

Saving changes only that workout and its exercises; its original template link,
completed status, completion timestamp, and original running targets are preserved. Canceling or leaving
without saving does not write changes. Changing the training date changes the
scheduled timestamp used for History ordering and weekly requirement matching.
Changing sport applies the template editor's field rules, including clearing
exercises when switching to or from gym or mobility. Weekly matching continues
to use the original template ID, even if the workout name or sport changes.
Running targets remain read-only even if the sport is changed and later changed
back. A completed session changed from another sport to running has no original
running targets. Completed sessions cannot be changed back to planned.

## Exercise library and gym sessions

Create gym exercises in Exercises or from a template's exercise picker. Names
are unique after trimming, lowercasing, and collapsing whitespace. Each exercise
has a stable ID, a reps/seconds unit, and an external-load/bodyweight mode.
Library renaming and archiving preserve existing workout and template snapshots.
Archived exercises remain usable in existing sessions but cannot be newly picked.
Library edits supply defaults for subsequent selections; established snapshots
keep their units and modes until explicitly corrected.

Version-11 migration links matching gym names across all templates and workouts.
Imported entries require one-time weight-mode review in Exercises. Confirming a
mode resolves unclassified entries with the same unit. Conflicting units remain
unresolved: use **Review / correct links** to choose or create an exercise with
that unit. Link correction preserves recorded names and set values but applies
the selected identity and mode to that occurrence. Links in an in-progress
session can be corrected after finishing it. Mobility is not migrated.
Old aggregate entries become identical individual sets; past uneven sets and
unmarked warm-up sets cannot be reconstructed.

Planning offers Start workout for gym sessions and Resume workout after starting.
The seven-day list also exposes in-progress sessions outside its date window.
The exercise list and number of working sets are fixed from the scheduled
snapshot. Template changes do not affect it. Each set records a weight and
nonnegative reps or seconds. Zero means skipped and confirms the skip; other
sets must be checked explicitly. Prefilled values are not completed results.
Warm-up sets are not recorded. The existing per-side flag remains descriptive;
calculations do not apply an extra multiplier.

The screen shows the most recent earlier completed performance for the same
exercise ID and unit across all templates, sorted by training date, excluding
the current workout and wholly skipped performances. It shows individual sets
and the previous bodyweight where relevant. There are no overload suggestions,
effort ratings, or exercise-specific notes; the training comment remains available.

Valid edits save automatically in order. Leaving waits for writes and preserves
the session for resuming after an app restart. Invalid fields must be corrected;
write failures show Retry and block exit until saved. Finishing requires every
set to be confirmed or skipped and a positive actual duration. Only finishing
moves the workout into History; in-progress sessions still count as planned for
weekly requirements.

External-load weight is the entire entered load, including both dumbbells.
Bodyweight effective load is the session bodyweight plus the entered adjustment:
0 is unassisted, a negative number is assistance, and a positive number is added
load. Assistance cannot exceed bodyweight. Starting a session with bodyweight
exercises requires a weigh-in; if absent, the app prompts for one. The latest
weigh-in no later than start time is frozen on the session, so later weigh-ins
or deletion of that weigh-in do not change completed results.

Historical gym sessions receive the latest weigh-in on or before their training
timestamp during migration. If none exists, keep the record but supply its
bodyweight snapshot through History before calculating bodyweight performance.

## Automatic gym prescription updates

Finishing a gym workout copies each exercise’s first working-set amount and
entered weight to every matching gym template and planned gym workout that has
not started, even across different source templates. All prefilled sets of an
affected planned exercise receive that pair and remain unconfirmed. Set counts,
movement order, dates, and other workout details stay unchanged. Matching uses
the exercise library identity with compatible units and weight modes.

The first occurrence of a repeated exercise supplies the reference. A skipped
first set (zero amount) causes no update for that identity; later sets or
occurrences are not substituted. Timed exercises copy seconds. Bodyweight
exercises copy their entered adjustment, including negative assistance, rather
than total effective load or bodyweight.

Updates happen automatically only on finishing, with no extra controls. Saving,
resuming, canceling, and History edits do not propagate. The most recently
finished session supplies the values, regardless of its scheduled date. Started
sessions and completed history keep their values. Ordinary template editing
still does not propagate to scheduled workouts.

## Canceling a gym or mobility session

Cancel workout / Cancel routine asks for confirmation, then discards **all**
progress since starting, including earlier saved visits. It restores the
pre-start duration, comment, and exercise values and returns the session to not
started while keeping it scheduled. Cancel works even with invalid input and
waits for pending saves before resetting. Failed cancellation stays on screen
with an error. Back and Save and leave continue to preserve progress for later.
A separately recorded weigh-in remains in Weight.

Gym sessions already in progress before version 13 cannot recover their original
duration. Cancel resets their sets to the saved prescription, clears their
comment/start/bodyweight snapshot, and keeps their current duration. New sessions
restore exact pre-start values. Completed sessions cannot use this action.

## Mobility sessions

Planning offers Start routine and Resume routine. The session shows movements
in order within each cycle, with reps or seconds and the per-side description.
There are no load fields. Movement definitions and cycle counts remain fixed
while training. Edit each actual amount and confirm completion, or enter zero
to skip. Prefilled amounts are not confirmed results.

Valid edits save automatically, including duration and comment. Save and leave
or Back preserves progress across restarts; in-progress routines also appear
in the agenda resume list outside its date window. Invalid input blocks saving
and finishing, but Cancel routine can discard it. Finishing requires a positive
duration and every movement in every cycle confirmed or skipped. Only finishing
adds the routine to History.

History displays per-cycle amounts. Editing a movement offers Edit cycle results
or Edit movement details. Changing cycle count requires updating any recorded
cycle results to match; applying a cycle-results editor records the displayed
amounts. Older history keeps its aggregate values without invented cycle results.
Mobility remains excluded from Performance.

## Hockey sessions and opponents

Completing a friendly or championship game requires an opponent, goals, assists,
plus-minus, and a positive whole-game duration in minutes. Goals and assists
are whole numbers of zero or more; plus-minus is a signed whole number.
Training permits an optional opponent and a Record statistics switch. When on,
all three statistics are required; when off, statistics are unknown, not zero.
Coaching records duration and a training comment only.

Create, rename, or delete opponents inside the opponent picker. Opponents are
shared across training, games, and tournaments. Renaming updates displayed names
everywhere. Deletion hides an opponent from new selections while keeping its
historical records and performance filter. An existing link can be retained
when editing. Reusing a deleted name creates a separate identity.

Open a tournament from Planning and add games with individual opponents,
date/time, whole-game durations, and statistics. Save each game independently,
then leave and resume later. Saved games appear immediately in Performance, even
while the tournament is planned. The agenda exposes resumable tournaments with
saved games outside its current seven-day window. The comment saves when leaving
through Back or Save and leave; unsaved game-dialog edits can be canceled.

Finish requires at least one saved game. Duration and statistics are sums of
its games. Games remain editable/deletable afterward, but a completed tournament
must retain at least one game. The tournament parent adds no extra performance
point. Older tournaments retain their duration and unknown statistics until games
are entered; an empty game list shows zero recorded game minutes.

History offers hockey statistics/game editing separately from workout details.
Changing a workout date changes a standalone session’s performance date;
tournament games keep their own dates. Changing sport/type retains the saved
hockey data, but only records applicable to the current sport/type contribute.
Older sessions have no invented opponent or zero statistics.

## Performance

Performance has Gym, Running, and Hockey tabs; mobility is excluded. Gym and
running charts use completed sessions and chronological training dates.
Tapping a point or using the previous/next buttons shows the workout and exact
values. History edits/deletions update charts. Gym and running have no date-range filter.

Choose any library exercises to track in Gym; the selection is saved locally.
Each exercise has two lines with separately labelled axes: highest effective
working-set weight (kg), and the sum of effective weight × amount across working
sets (kg·reps or kg·seconds). One workout gives one point, including when the
same exercise appears multiple times in it. Skipped and unconfirmed sets do not
contribute. A wholly skipped exercise produces no point. Missing bodyweight,
unresolved modes, or invalid effective loads prevent a partial total from being
shown; entries with a unit different from the library's selected unit are excluded.
A 90 kg bodyweight exercise with 20 kg assistance and 10 reps contributes
`(90 - 20) × 10 = 700 kg·reps`.

Running has three aligned charts: actual pace (min/km), distance (km), and duration
(minutes), one point per completed run with valid duration and distance. These
show results, not targets. Pace derives from the recorded whole-minute duration;
there are no splits, GPS records, or additional timing precision.

Hockey combines recorded training, friendly games, championship games, and
tournament games. Coaching and unrecorded statistics are excluded. Explicit
zeros count as recorded performances. Totals show goals, assists, points
(goals + assists), and summed plus-minus. Goals/assists share a chart scale; a
second chart shows signed plus-minus. Each session or tournament game is one
chronological point. Filter totals/charts by opponent, including No opponent.
The comparison table always includes every opponent in the selected period.

All time includes every recorded result. This year means the current local
hockey season, September 1 inclusive through the following September 1
exclusive; the displayed dates clarify the range. Tournament games use their
own dates. Deleted opponents remain available for historical filtering.

## Weekly requirements

A requirement has a name, a positive target count, and one or more eligible
templates. Requirements persist across weeks; progress is calculated afresh for
the current local Monday-to-Sunday period.

A workout counts when its template ID belongs to the eligible set and its
scheduled timestamp falls between Monday at midnight (inclusive) and the next
Monday (exclusive). **Both planned and completed workouts count.** This measures
schedule coverage, not completed training attendance.

Missing count is `max(0, targetCount - matchingCount)`. Progress bars are capped
at 100%, but displayed counts may exceed the target. One workout can count toward
multiple requirements if their eligible-template groups overlap. The Planning
alert sums each requirement's missing count, so it is not necessarily a count
of distinct additional workouts needed.

Scheduling from a requirement offers its eligible templates and opens the normal
scheduling dialog; the chosen date is not restricted to the current week.
Deleting a template removes its eligibility links. Requirements with no remaining
templates are deleted; retained requirements no longer count the deleted template's
workouts, even though those workout snapshots remain.

## Weight

The interface records positive weights in kilograms at the current time. It
accepts a comma or dot decimal separator. Multiple entries per day are allowed.
The latest entry is shown as current weight; history sorts newest first and
entries can be deleted. There is no UI for editing or backdating a weigh-in.

Chart choices use rolling cutoffs of 62, 183, and 366 days, labeled two months,
six months, and one year. The chart connects recorded measurements; it does not
calculate a smoothed trend.

One optional weekly reminder stores weekday and time. Planning displays it on
matching weekdays only when no weigh-in exists for that local calendar date,
with an entry button on today's reminder. Saving a weight from Planning or the
Weight page hides the entire reminder for that date in both planning views.
The calendar marker also disappears unless a pending workout still needs it.
If the day has no other pending items, it displays “Rest day.”

This is derived from stored weigh-ins, so it survives an app restart and applies
to weights recorded before or after the reminder's scheduled time. Future weekly
reminders remain scheduled. Deleting all weigh-ins for a date makes its reminder
reappear. The recurring reminder setting is retained; there is no separate
completion record or system notification.

## Steps

Daily totals are entered manually. The screen displays today and the preceding
six days, and lets the user replace each day's value with an integer of zero or
more. Older entries remain stored but are not browsable in the current screen.

The seven-day total includes missing days as zero, and the average is always
`total / 7`, including today even when it is incomplete. A missing entry is
displayed as “Not entered,” distinct from an explicitly entered zero.

The optional daily goal must be a positive integer. Goal progress is
`average / dailyGoal`, equivalent to `total / (dailyGoal * 7)`. The progress bar
is capped at 100%, while the displayed percentage can exceed 100%. The interface
can set or edit the goal, but does not offer removal.

## Scope

All of these features use local storage. No accounts, cloud sync, automatic step
counting, GPS recording, background notifications, or gamification are implemented.
