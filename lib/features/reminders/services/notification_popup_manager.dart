import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/navigation/app_navigator.dart';
import '../../../core/theme/app_colors.dart';
import '../models/reminder_settings.dart';
import 'app_notification_data.dart';
import 'latest_notification_service.dart';
import 'notification_history_service.dart';
import 'notification_service.dart';

class NotificationPopupManager {
  static final List<AppNotificationData> _queue = [];
  static final Set<String> _shownOccurrenceIds = {};
  static bool _shownIdsLoaded = false;
  static bool _isShowing = false;
  static Timer? _foregroundCheckTimer;
  static DateTime? _lastCheckTime;
  static DateTime? _lastScheduleActivationTime;
  static bool _isWatcherRunning = false;
  static const String _shownOccurrencesKey = 'shown_popup_occurrences_v2';

  /// Returns whether the foreground watcher timer is currently active.
  static bool get isWatcherRunning => _isWatcherRunning;

  /// Loads persisted shown occurrence IDs from SharedPreferences.
  static Future<void> _ensureShownIdsLoaded() async {
    if (_shownIdsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? list = prefs.getStringList(_shownOccurrencesKey);
      if (list != null) {
        _shownOccurrenceIds.addAll(list);
      }
      _shownIdsLoaded = true;
      debugPrint('[NotificationPopupManager] Loaded ${_shownOccurrenceIds.length} shown occurrence IDs.');
    } catch (e) {
      debugPrint('[NotificationPopupManager ERROR] Failed loading shown occurrence IDs: $e');
    }
  }

  /// Persists a new shown occurrence ID locally to prevent duplicate displays across app sessions.
  static Future<void> _persistShownOccurrenceId(String occurrenceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _shownOccurrenceIds.add(occurrenceId);
      final listToSave = _shownOccurrenceIds.length > 100
          ? _shownOccurrenceIds.toList().sublist(_shownOccurrenceIds.length - 100)
          : _shownOccurrenceIds.toList();
      await prefs.setStringList(_shownOccurrencesKey, listToSave);
    } catch (e) {
      debugPrint('[NotificationPopupManager ERROR] Failed saving shown occurrence ID: $e');
    }
  }

  /// Notifies the manager that reminder settings have been modified or saved by the user.
  /// Reloads schedule activation timestamp from saved settings without resetting it.
  static Future<void> notifySettingsUpdated({required bool isArabic, BuildContext? context}) async {
    final settings = await ReminderSettings.load();
    if (settings.scheduleActivatedAt != null) {
      _lastScheduleActivationTime = DateTime.fromMillisecondsSinceEpoch(settings.scheduleActivatedAt!);
    } else {
      _lastScheduleActivationTime = DateTime.now();
    }
    _lastCheckTime = DateTime.now();
    debugPrint('[ForegroundWatcher] Settings updated. Saved activation timestamp: ${_lastScheduleActivationTime?.toIso8601String()}');
  }

  /// Starts or resets the foreground schedule watcher timer watching for due reminders while app is open.
  static void startForegroundWatcher(BuildContext? context, {required bool isArabic}) {
    _foregroundCheckTimer?.cancel();
    _isWatcherRunning = true;

    final appState = WidgetsBinding.instance.lifecycleState?.name ?? 'unknown';
    debugPrint('[ForegroundWatcher] Started foreground watcher (interval: 15s, appLifecycleState: $appState, isArabic: $isArabic)');

    // Immediate check right after postFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndTriggerForegroundDueNotifications(context, isArabic: isArabic);
    });

    // Periodic check every 15 seconds while app is in foreground
    _foregroundCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final currentLifecycle = WidgetsBinding.instance.lifecycleState;
      if (currentLifecycle != null &&
          currentLifecycle != AppLifecycleState.resumed) {
        debugPrint('[ForegroundWatcher] Skipping periodic check: app state is ${currentLifecycle.name}');
        return;
      }
      await checkAndTriggerForegroundDueNotifications(context, isArabic: isArabic);
    });
  }

  /// Stops foreground watcher timer (e.g. when app goes to background/paused).
  static void stopForegroundWatcher() {
    debugPrint('[ForegroundWatcher] Stopped foreground watcher timer.');
    _foregroundCheckTimer?.cancel();
    _foregroundCheckTimer = null;
    _isWatcherRunning = false;
  }

  static void _logDiagnosticEvent({
    required String sourceEvent,
    required String reminderType,
    required String occurrenceId,
    required int? scheduleVersion,
    required DateTime scheduledAt,
    required DateTime? activatedAt,
    required bool isReadOrShown,
    required String decisionReason,
  }) {
    final now = DateTime.now();
    final tzName = tz.local.name;
    debugPrint(
      '[NotificationDiagnostic] sourceEvent: $sourceEvent | '
      'reminderId: $reminderType | '
      'occurrenceId: $occurrenceId | '
      'scheduleVersion: ${scheduleVersion ?? 'N/A'} | '
      'scheduledAt: ${scheduledAt.toIso8601String()} | '
      'activatedAt: ${activatedAt?.toIso8601String() ?? 'N/A'} | '
      'currentTime: ${now.toIso8601String()} (TZ: $tzName) | '
      'isReadOrShown: $isReadOrShown | '
      'decisionReason: $decisionReason'
    );
  }

  /// Evaluates active schedule and presents only the single latest due notification popup if unread/unshown.
  static Future<void> checkAndPresentLatestDuePopup(BuildContext? context, {required bool isArabic}) async {
    try {
      await _ensureShownIdsLoaded();
      final settings = await ReminderSettings.load();
      if (!settings.isRunning) return;

      if (_lastScheduleActivationTime == null && settings.scheduleActivatedAt != null) {
        _lastScheduleActivationTime = DateTime.fromMillisecondsSinceEpoch(settings.scheduleActivatedAt!);
      }

      final latestDue = await LatestNotificationService.evaluateAndGetLatestDueNotification(
        settings: settings,
        isArabic: isArabic,
        allowPastInspected: false,
        shownOccurrenceIds: _shownOccurrenceIds,
      );

      if (latestDue == null) {
        _logDiagnosticEvent(
          sourceEvent: 'app_open',
          reminderType: 'none',
          occurrenceId: 'none',
          scheduleVersion: settings.scheduleVersion,
          scheduledAt: DateTime.now(),
          activatedAt: _lastScheduleActivationTime,
          isReadOrShown: false,
          decisionReason: 'No latest due notification found or latest candidate already evaluated/shown.',
        );
        return;
      }

      final isAlreadyShown = _shownOccurrenceIds.contains(latestDue.occurrenceId);
      final isBeforeActivation = _lastScheduleActivationTime != null && latestDue.scheduledTime.isBefore(_lastScheduleActivationTime!);

      if (isAlreadyShown) {
        _logDiagnosticEvent(
          sourceEvent: 'app_open',
          reminderType: latestDue.type,
          occurrenceId: latestDue.occurrenceId,
          scheduleVersion: settings.scheduleVersion,
          scheduledAt: latestDue.scheduledTime,
          activatedAt: _lastScheduleActivationTime,
          isReadOrShown: true,
          decisionReason: 'Excluded: Already shown or dismissed today.',
        );
        return;
      }

      if (isBeforeActivation) {
        _logDiagnosticEvent(
          sourceEvent: 'app_open',
          reminderType: latestDue.type,
          occurrenceId: latestDue.occurrenceId,
          scheduleVersion: settings.scheduleVersion,
          scheduledAt: latestDue.scheduledTime,
          activatedAt: _lastScheduleActivationTime,
          isReadOrShown: false,
          decisionReason: 'Excluded: Scheduled before settings activation time.',
        );
        return;
      }

      _logDiagnosticEvent(
        sourceEvent: 'app_open',
        reminderType: latestDue.type,
        occurrenceId: latestDue.occurrenceId,
        scheduleVersion: settings.scheduleVersion,
        scheduledAt: latestDue.scheduledTime,
        activatedAt: _lastScheduleActivationTime,
        isReadOrShown: false,
        decisionReason: 'Displayed: Single latest unread due notification on app open.',
      );

      await LatestNotificationService.setLastAutoEvaluatedTime(latestDue.scheduledTime.millisecondsSinceEpoch);

      await showNotificationPopup(
        (context != null && context.mounted) ? context : null,
        data: latestDue,
        isArabic: isArabic,
        playSound: false,
      );
    } catch (e, st) {
      debugPrint('[NotificationPopupManager ERROR] checkAndPresentLatestDuePopup: $e\n$st');
    }
  }

  /// Evaluates active schedule against time window `(_lastCheckTime, now]`
  /// and triggers popups for any due notifications while app is active.
  static Future<void> checkAndTriggerForegroundDueNotifications(
    BuildContext? context, {
    required bool isArabic,
  }) async {
    try {
      await _ensureShownIdsLoaded();

      final settings = await ReminderSettings.load();
      if (!settings.isRunning) {
        return;
      }

      if (_lastScheduleActivationTime == null && settings.scheduleActivatedAt != null) {
        _lastScheduleActivationTime = DateTime.fromMillisecondsSinceEpoch(settings.scheduleActivatedAt!);
      }

      final now = DateTime.now();
      DateTime windowStart;
      if (_lastCheckTime == null) {
        windowStart = now.subtract(const Duration(seconds: 20));
      } else {
        windowStart = _lastCheckTime!;
      }

      final maxLookback = now.subtract(const Duration(seconds: 35));
      if (windowStart.isBefore(maxLookback)) {
        windowStart = maxLookback;
      }

      if (_lastScheduleActivationTime != null && _lastScheduleActivationTime!.isAfter(windowStart)) {
        windowStart = _lastScheduleActivationTime!;
      }

      _lastCheckTime = now;

      final dueCandidates = await LatestNotificationService.getDueNotificationsForWindow(
        windowStart: windowStart,
        windowEnd: now,
        settings: settings,
        isArabic: isArabic,
        scheduleActivationTime: _lastScheduleActivationTime,
      );

      if (dueCandidates.isEmpty) {
        return;
      }

      for (final candidate in dueCandidates) {
        final isAlreadyShown = _shownOccurrenceIds.contains(candidate.occurrenceId);
        if (isAlreadyShown) {
          _logDiagnosticEvent(
            sourceEvent: 'foreground_watcher',
            reminderType: candidate.type,
            occurrenceId: candidate.occurrenceId,
            scheduleVersion: settings.scheduleVersion,
            scheduledAt: candidate.scheduledTime,
            activatedAt: _lastScheduleActivationTime,
            isReadOrShown: true,
            decisionReason: 'Excluded: Already shown in foreground.',
          );
          continue;
        }

        _logDiagnosticEvent(
          sourceEvent: 'foreground_watcher',
          reminderType: candidate.type,
          occurrenceId: candidate.occurrenceId,
          scheduleVersion: settings.scheduleVersion,
          scheduledAt: candidate.scheduledTime,
          activatedAt: _lastScheduleActivationTime,
          isReadOrShown: false,
          decisionReason: 'Displayed: Live foreground due reminder.',
        );

        await LatestNotificationService.setLastAutoEvaluatedTime(candidate.scheduledTime.millisecondsSinceEpoch);

        await showNotificationPopup(
          (context != null && context.mounted) ? context : null,
          data: candidate,
          isArabic: isArabic,
          playSound: false,
        );
      }
    } catch (e, st) {
      debugPrint('[ForegroundWatcher ERROR] Error checking foreground notifications: $e\n$st');
    }
  }

  /// Displays notification popup for [data]. Queues sequentially if already showing.
  static Future<void> showNotificationPopup(
    BuildContext? context, {
    required AppNotificationData data,
    required bool isArabic,
    bool bypassDeduplication = false,
    bool playSound = true,
  }) async {
    await _ensureShownIdsLoaded();

    // Deduplication check
    if (!bypassDeduplication && _shownOccurrenceIds.contains(data.occurrenceId)) {
      debugPrint('[NotificationPopupManager Exclusion] Occurrence ID ${data.occurrenceId} already shown automatically. Skipping.');
      return;
    }

    // Queueing if popup is already displayed on screen
    if (!bypassDeduplication && _isShowing) {
      final isAlreadyQueued = _queue.any((item) => item.occurrenceId == data.occurrenceId);
      if (!isAlreadyQueued) {
        _queue.add(data);
        debugPrint('[NotificationPopupManager Queue] Popup active. Added to queue: type=${data.type}, occurrenceId=${data.occurrenceId} (Queue size: ${_queue.length})');
      }
      return;
    }

    // Resolve valid app-level context
    BuildContext? validContext;
    if (context != null && context.mounted) {
      validContext = context;
    } else {
      validContext = AppNavigator.currentContext;
    }

    if (validContext == null || !validContext.mounted) {
      debugPrint('[NotificationPopupManager Warning] App context not ready yet. Retaining event in queue: ${data.occurrenceId}');
      final isAlreadyQueued = _queue.any((item) => item.occurrenceId == data.occurrenceId);
      if (!isAlreadyQueued) {
        _queue.add(data);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processNextInQueue(null, isArabic: isArabic);
      });
      return;
    }

    _isShowing = true;
    debugPrint('[NotificationPopupManager Display] Attempting popup presentation for type=${data.type}, occurrenceId=${data.occurrenceId}');

    try {
      await LatestNotificationService.saveLatestNotification(data);

      if (playSound) {
        try {
          await _playTypeSound(data.type);
        } catch (e) {
          debugPrint('[NotificationPopupManager Sound Error]: $e');
        }
      }

      if (!validContext.mounted) {
        validContext = AppNavigator.currentContext;
      }

      if (validContext == null || !validContext.mounted) {
        debugPrint('[NotificationPopupManager Warning] Context no longer mounted after async save. Retaining event.');
        if (!_queue.any((item) => item.occurrenceId == data.occurrenceId)) {
          _queue.add(data);
        }
        return;
      }

      await showModalBottomSheet(
        context: validContext,
        isScrollControlled: true,
        useRootNavigator: true, // Display on top of root Navigator / screen
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return _NotificationDialogContent(
            data: data,
            isArabic: isArabic,
          );
        },
      );

      // Persist shown state ONLY after successful presentation / close
      if (!bypassDeduplication) {
        await _persistShownOccurrenceId(data.occurrenceId);
      }

      debugPrint('[NotificationPopupManager Success] Popup displayed & closed successfully for occurrenceId=${data.occurrenceId}');
    } catch (e, st) {
      debugPrint('[NotificationPopupManager ERROR] Error presenting popup for ${data.occurrenceId}: $e\n$st');
    } finally {
      // Resets _isShowing on all close paths (user close, back gesture, auto dismiss, exception)
      _isShowing = false;
      _processNextInQueue(
        (validContext != null && validContext.mounted) ? validContext : null,
        isArabic: isArabic,
      );
    }
  }

  static void _processNextInQueue(BuildContext? context, {required bool isArabic}) {
    if (_queue.isNotEmpty && !_isShowing) {
      final nextData = _queue.removeAt(0);
      debugPrint('[NotificationPopupManager Queue] Dequeuing next event: type=${nextData.type}, occurrenceId=${nextData.occurrenceId} (${_queue.length} left)');
      showNotificationPopup(
        (context != null && context.mounted) ? context : null,
        data: nextData,
        isArabic: isArabic,
      );
    }
  }

  static Future<void> _playTypeSound(String type) async {
    switch (type) {
      case 'motivation':
        await NotificationService.playMotivationSoundEffect();
        break;
      default:
        // System sounds are handled by system notification trigger
        break;
    }
  }

  /// Returns appropriate IconData for type
  static IconData getIconForType(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.egg_alt_rounded;
      case 'lunch':
        return Icons.restaurant_rounded;
      case 'dinner':
        return Icons.soup_kitchen_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'snack':
        return Icons.apple_rounded;
      case 'motivation':
        return Icons.auto_awesome_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'vitamins':
        return Icons.medication_rounded;
      case 'screen_off':
        return Icons.nightlight_round;
      case 'eye_rest':
        return Icons.remove_red_eye_rounded;
      case 'custom':
      default:
        return Icons.alarm_rounded;
    }
  }

  /// Returns appropriate color for type
  static Color getColorForType(String type) {
    switch (type) {
      case 'breakfast':
      case 'lunch':
      case 'dinner':
        return AppColors.forestGreen;
      case 'water':
        return const Color(0xFF0284C7);
      case 'snack':
        return const Color(0xFFE57C23);
      case 'motivation':
        return const Color(0xFFD97706);
      case 'workout':
        return const Color(0xFF7E22CE);
      case 'vitamins':
        return const Color(0xFFDC2626);
      case 'screen_off':
      case 'eye_rest':
        return const Color(0xFF1E293B);
      case 'custom':
      default:
        return AppColors.accentOrange;
    }
  }
}

class _NotificationDialogContent extends StatelessWidget {
  final AppNotificationData data;
  final bool isArabic;

  const _NotificationDialogContent({
    required this.data,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = NotificationPopupManager.getColorForType(data.type);
    final iconData = NotificationPopupManager.getIconForType(data.type);

    final time = data.scheduledTime;
    final hourFormatted = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minuteFormatted = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12
        ? (isArabic ? 'مساءً' : 'PM')
        : (isArabic ? 'صباحاً' : 'AM');
    final timeString = '$hourFormatted:$minuteFormatted $period';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header with icon, title, and close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: themeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16.5,
                                color: Color(0xFF12382B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeString,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                  onPressed: () async {
                    await NotificationPopupManager._persistShownOccurrenceId(data.occurrenceId);
                    await NotificationHistoryService.markAsRead(data.occurrenceId);
                    await LatestNotificationService.setLastHandledTimestamp(data.scheduledTime);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Card Body Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor,
                    Color.lerp(themeColor, Colors.black, 0.3)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    iconData,
                    color: const Color(0xFFFDE047),
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Primary Button: "تمام" (Got it)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  await NotificationPopupManager._persistShownOccurrenceId(data.occurrenceId);
                  await NotificationHistoryService.markAsRead(data.occurrenceId);
                  await LatestNotificationService.setLastHandledTimestamp(data.scheduledTime);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  isArabic ? 'تمام' : 'Got it',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


