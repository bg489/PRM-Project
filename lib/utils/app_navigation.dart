import 'package:flutter/material.dart';

import '../data/mock_users.dart';
import '../data/mock_tasks.dart';
import '../data/mock_workspaces.dart';

import '../screens/board/project_board_screen.dart';
import '../screens/calendar/calendar_view_screen.dart';
import '../screens/analytics/productivity_analytics_screen.dart';
import '../screens/profile/profile_settings_screen.dart';

class AppNavigation {
  static void goHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  static void goBoard({
    required BuildContext context,
    required MockUser user,
    required MockProject project,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectBoardScreen(
          project: project,
          user: user,
        ),
      ),
          (route) => route.isFirst,
    );
  }

  static void goCalendar({
    required BuildContext context,
    required MockUser user,
    required MockProject project,
    required List<MockTask> tasks,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarViewScreen(
          user: user,
          project: project,
          tasks: tasks,
        ),
      ),
          (route) => route.isFirst,
    );
  }

  static void goAnalytics({
    required BuildContext context,
    required MockUser user,
    required MockProject project,
    required List<MockTask> tasks,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ProductivityAnalyticsScreen(
          user: user,
          project: project,
          tasks: tasks,
        ),
      ),
          (route) => route.isFirst,
    );
  }

  static void goProfile({
    required BuildContext context,
    required MockUser user,
    required MockProject project,
    required List<MockTask> tasks,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSettingsScreen(
          user: user,
          project: project,
          tasks: tasks,
        ),
      ),
          (route) => route.isFirst,
    );
  }
}