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

Gym and mobility require at least one exercise. Their exercises can be added,
edited, removed, and reordered. Gym loads accept zero (displayed as bodyweight)
and negative values. Mobility movements store one set and zero load; the template
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

Completion accepts a positive actual duration and optional comment. Existing
exercise values can be adjusted: gym sets, amount, load, unit, and per-side flag;
mobility amount, unit, and per-side flag. The dialog does not add/remove/rename
exercises, change hockey details, or change mobility cycles. Runs also accept a
positive actual distance in km, with a decimal comma or dot. Duration remains
a positive whole number of minutes. Both inputs start from the scheduled values.

Saving sets status to `completed`, records the current completion timestamp, and
replaces the workout duration and exercise rows. For running it also saves actual
distance, while retaining separate original target duration and distance from
the scheduled snapshot. Other sports do not store separate planned and actual
values.

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
completion-time order. Every completed session has Edit and Delete actions in its
menu, including sessions whose source template was deleted. Edit opens the saved snapshot with
its name, sport, training date/time, duration, description, warm-up, comment,
and sport-specific fields. Gym and mobility exercises can be added, renamed,
edited, removed, and reordered using the same validation as templates.
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
counting, GPS recording, background notifications, gamification, or general
training-statistics dashboard are implemented.
