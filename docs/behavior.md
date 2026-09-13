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
exercises, change running distance or hockey details, or change mobility cycles.

Saving sets status to `completed`, records the current completion timestamp, and
replaces the workout duration and exercise rows. Planned and actual values are
not stored separately. Running pace displayed in History therefore uses the
updated duration and original distance, while retaining the “target pace” label.

History displays completed workouts in descending **scheduled** date order, not
completion-time order. The interface allows deletion, but not editing completed
sessions or changing them back to planned.

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
matching weekdays, with an entry button on today's reminder. It produces no
system notification and remains visible after a weigh-in; it has no completion
state.

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
