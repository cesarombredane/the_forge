import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'gym_session_page.dart';

/// Mobility shares queued saves, cancellation, and exit handling with gym.
class MobilitySessionPage extends StatelessWidget {
  const MobilitySessionPage({
    super.key,
    required this.controller,
    required this.workout,
  });
  final AppController controller;
  final Workout workout;
  @override
  Widget build(BuildContext context) =>
      GymSessionPage(controller: controller, workout: workout);
}
