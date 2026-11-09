import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/reminder_settings.dart';
import 'services/latest_notification_service.dart';
import 'services/notification_popup_manager.dart';
import 'services/notification_service.dart';

class MealRemindersScreen extends StatefulWidget {
  final bool isArabic;

  const MealRemindersScreen({super.key, required this.isArabic});

  @override
  State<MealRemindersScreen> createState() => _MealRemindersScreenState();
}

class _MealRemindersScreenState extends State<MealRemindersScreen> {
  ReminderSettings _settings = ReminderSettings();
  bool _isLoading = true;
  bool _hasNotificationPermission = true;
  bool _isAutoMealsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ReminderSettings.load();
      final hasPerm = await NotificationService.checkExactAlarmPermission();
      if (mounted) {
        setState(() {
          _settings = settings;
          _hasNotificationPermission = hasPerm;
        });
      }
    } catch (e) {
      debugPrint('Error loading reminder settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickTime({required bool isWake}) async {
    final currentHour = isWake ? _settings.wakeHour : _settings.sleepHour;
    final currentMinute = isWake ? _settings.wakeMinute : _settings.sleepMinute;

    final initialTime = (currentHour != null && currentMinute != null)
        ? TimeOfDay(hour: currentHour, minute: currentMinute)
        : (isWake ? const TimeOfDay(hour: 7, minute: 0) : const TimeOfDay(hour: 23, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forestGreen,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isWake) {
          _settings.wakeHour = picked.hour;
          _settings.wakeMinute = picked.minute;
        } else {
          _settings.sleepHour = picked.hour;
          _settings.sleepMinute = picked.minute;
        }
      });
      await _settings.save();

      // Automatically recalculate and apply if running and times are selected
      if (_settings.isRunning && _settings.hasSelectedWakeAndSleepTimes) {
        await _applyReminders(silent: true);
      }
    }
  }

  Future<void> _applyReminders({bool silent = false}) async {
    if (!_settings.hasSelectedWakeAndSleepTimes) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'برجاء اختيار موعد الاستيقاظ والنوم أولاً.'
                  : 'Please select wake and sleep times first.',
            ),
            backgroundColor: AppColors.accentOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final flowStopwatch = Stopwatch()..start();

    try {
      // 1. Measure Permission Dialog / Request Duration
      final permStopwatch = Stopwatch()..start();
      final hasPermission = await NotificationService.requestPermissions().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint('[Activation Flow] Permission request timed out.');
          return false;
        },
      );
      permStopwatch.stop();
      debugPrint('[Activation Flow] Notification permissions result: $hasPermission (took ${permStopwatch.elapsedMilliseconds} ms)');

      if (!hasPermission) {
        _settings.isRunning = false;
        await _settings.save();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'يرجى السماح بإرسال الإشعارات من إعدادات الهاتف لتفعيل المنبهات.'
                    : 'Please allow notification permissions in settings to enable alarms.',
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: widget.isArabic ? 'إعادة المحاولة' : 'Retry',
                textColor: AppColors.white,
                onPressed: () => _applyReminders(silent: false),
              ),
            ),
          );
        }
        return;
      }

      // 2. Measure Settings Save Duration
      final saveStopwatch = Stopwatch()..start();
      _settings.isRunning = true;
      _settings.scheduleActivatedAt = DateTime.now().millisecondsSinceEpoch;
      _settings.scheduleVersion = DateTime.now().millisecondsSinceEpoch;
      await _settings.save();
      await LatestNotificationService.setLastAutoEvaluatedTime(DateTime.now().millisecondsSinceEpoch);
      saveStopwatch.stop();
      debugPrint('[Activation Flow] Settings saved in ${saveStopwatch.elapsedMilliseconds} ms.');

      // 3. Measure Schedule Duration & Handle Timeout
      final scheduleStopwatch = Stopwatch()..start();
      final result = await NotificationService.scheduleReminders(
        _settings,
        widget.isArabic,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => SchedulingResult(
          success: false,
          scheduledCount: 0,
          failedCount: 1,
          isExact: true,
          hitIosCeiling: false,
          messageAr: 'تأخرت عملية تفعيل المنبهات، يرجى إعادة المحاولة.',
          messageEn: 'Activation timed out, please retry.',
        ),
      );
      scheduleStopwatch.stop();
      flowStopwatch.stop();

      if (mounted) {
        await NotificationPopupManager.notifySettingsUpdated(
          isArabic: widget.isArabic,
          context: context,
        );
      }

      debugPrint(
        '[Activation Flow Summary] Total execution time: ${flowStopwatch.elapsedMilliseconds} ms '
        '(Permissions: ${permStopwatch.elapsedMilliseconds} ms, Save: ${saveStopwatch.elapsedMilliseconds} ms, '
        'Schedule: ${scheduleStopwatch.elapsedMilliseconds} ms). Scheduled: ${result.scheduledCount}, Success: ${result.success}.',
      );

      if (mounted && !silent) {
        final message = result.success
            ? (widget.isArabic ? 'التنبيه شغّال' : 'Reminders Active')
            : result.getMessage(widget.isArabic);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.success
                ? AppColors.forestGreen
                : (result.scheduledCount > 0 ? AppColors.accentOrange : Colors.red.shade600),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: !result.success
                ? SnackBarAction(
                    label: widget.isArabic ? 'إعادة المحاولة' : 'Retry',
                    textColor: AppColors.white,
                    onPressed: () => _applyReminders(silent: false),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _applyReminders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'حدث خطأ غير متوقع أثناء تفعيل المنبهات.'
                  : 'An unexpected error occurred while activating reminders.',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: widget.isArabic ? 'إعادة المحاولة' : 'Retry',
              textColor: AppColors.white,
              onPressed: () => _applyReminders(silent: false),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _stopReminders() async {
    setState(() => _isLoading = true);
    final stopwatch = Stopwatch()..start();
    try {
      _settings.isRunning = false;
      _settings.scheduleActivatedAt = null;
      _settings.scheduleVersion = DateTime.now().millisecondsSinceEpoch;
      await _settings.save();
      await LatestNotificationService.clearLatestNotification();
      await NotificationService.cancelAutoReminders().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[Stop Reminders] cancelAutoReminders timed out.');
        },
      );
      stopwatch.stop();
      debugPrint('[Stop Reminders] All reminders stopped in ${stopwatch.elapsedMilliseconds} ms.');

      if (mounted) {
        await NotificationPopupManager.notifySettingsUpdated(
          isArabic: widget.isArabic,
          context: context,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'التنبيه اتقفل'
                  : 'Reminders Turned Off',
            ),
            backgroundColor: AppColors.accentOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _stopReminders: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12
        ? (widget.isArabic ? 'مساءً' : 'PM')
        : (widget.isArabic ? 'صباحاً' : 'AM');
    return '$h:$m $period';
  }

  String _formatHourMinute(int? hour, int? minute) {
    if (hour == null || minute == null) {
      return widget.isArabic ? 'لم يتم التحديد' : 'Not specified';
    }
    return _formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
  }

  // --- CUSTOM ALARMS METHODS ---
  Future<void> _showCustomAlarmDialog({CustomAlarm? alarmToEdit}) async {
    final isEditing = alarmToEdit != null;
    final titleController = TextEditingController(
      text: isEditing ? alarmToEdit.title : '',
    );
    TimeOfDay selectedTime = isEditing
        ? TimeOfDay(hour: alarmToEdit.hour, minute: alarmToEdit.minute)
        : const TimeOfDay(hour: 12, minute: 0);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEditing
                    ? (widget.isArabic ? 'تعديل التنبيه المخصص' : 'Edit Custom Alarm')
                    : (widget.isArabic ? 'إضافة تنبيه مخصص جديد' : 'Add Custom Alarm'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: widget.isArabic
                            ? 'اسم التنبيه (مثال: الشاي الأخضر، المشي...)'
                            : 'Alarm Name (e.g. Green Tea, Walk)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      title: Text(
                        widget.isArabic ? 'وقت التنبيه' : 'Alarm Time',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _formatTimeOfDay(selectedTime),
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.forestGreen,
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    widget.isArabic ? 'إلغاء' : 'Cancel',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    setState(() {
                      if (isEditing) {
                        alarmToEdit.title = title;
                        alarmToEdit.hour = selectedTime.hour;
                        alarmToEdit.minute = selectedTime.minute;
                      } else {
                        _settings.customAlarms.add(
                          CustomAlarm(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            hour: selectedTime.hour,
                            minute: selectedTime.minute,
                          ),
                        );
                      }
                    });

                    await _settings.save();
                    if (context.mounted) Navigator.pop(context);

                    if (_settings.isRunning) {
                      await _applyReminders(silent: true);
                    }
                  },
                  child: Text(
                    isEditing
                        ? (widget.isArabic ? 'حفظ' : 'Save')
                        : (widget.isArabic ? 'إضافة' : 'Add'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCustomAlarm(CustomAlarm alarm) async {
    setState(() {
      _settings.customAlarms.removeWhere((a) => a.id == alarm.id);
    });
    await _settings.save();
    if (_settings.isRunning) {
      await _applyReminders(silent: true);
    }
  }

  Future<void> _toggleCustomAlarm(CustomAlarm alarm, bool enabled) async {
    setState(() {
      alarm.isEnabled = enabled;
    });
    await _settings.save();
    if (_settings.isRunning) {
      await _applyReminders(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conflictMsg = _settings.getScheduleConflictMessage(widget.isArabic);

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          title: Text(
            widget.isArabic ? 'منبهات الوجبات والصحة' : 'Meal & Health Reminders',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // 1. Status Banner Card
                  Builder(
                    builder: (context) {
                      final isRunning = _settings.isRunning;
                      final hasTimes = _settings.hasSelectedWakeAndSleepTimes;
                      final hasPerm = _hasNotificationPermission;

                      String title;
                      String subtitle;
                      Color bgColor;
                      Color textColor;
                      IconData icon;

                      if (!isRunning) {
                        title = widget.isArabic ? 'التنبيه اتقفل' : 'Reminders Paused';
                        subtitle = widget.isArabic
                            ? 'اضغط على زر شغل التنبيه للبدء'
                            : 'Tap Turn On Reminders to start';
                        bgColor = AppColors.white;
                        textColor = AppColors.textDark;
                        icon = Icons.notifications_off_rounded;
                      } else if (!hasTimes) {
                        title = widget.isArabic ? 'في انتظار تحديد المواعيد' : 'Awaiting Schedule Selection';
                        subtitle = widget.isArabic
                            ? 'اختار ميعاد الصحيان والنوم عشان التنبيهات تبدأ'
                            : 'Select wake & sleep times for reminders to start';
                        bgColor = const Color(0xFFFFFBEB);
                        textColor = const Color(0xFF92400E);
                        icon = Icons.schedule_rounded;
                      } else if (!hasPerm) {
                        title = widget.isArabic ? 'إذن الإشعارات مطلوب' : 'Permission Required';
                        subtitle = widget.isArabic
                            ? 'يرجى إعطاء الإذن للتطبيق من إعدادات الهاتف لتصلك المنبهات'
                            : 'Please grant notification permission in phone settings';
                        bgColor = const Color(0xFFFEF2F2);
                        textColor = const Color(0xFF991B1B);
                        icon = Icons.notification_important_rounded;
                      } else {
                        title = widget.isArabic ? 'التنبيه شغّال' : 'Reminders Active';
                        subtitle = widget.isArabic
                            ? 'تصلك التنبيهات تلقائياً في المواعيد المحسوبة'
                            : 'Notifications scheduled automatically';
                        bgColor = AppColors.forestGreen;
                        textColor = AppColors.white;
                        icon = Icons.notifications_active_rounded;
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isRunning && hasTimes && hasPerm
                                ? AppColors.forestGreen
                                : AppColors.forestGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: isRunning && hasTimes && hasPerm
                                  ? AppColors.white
                                  : textColor,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isRunning && hasTimes && hasPerm
                                          ? AppColors.white
                                          : textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRunning && hasTimes && hasPerm
                                          ? AppColors.white.withValues(alpha: 0.85)
                                          : textColor.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 2. Start / Stop Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _settings.isRunning
                          ? _stopReminders
                          : () => _applyReminders(silent: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _settings.isRunning
                            ? Colors.red.shade700
                            : AppColors.accentOrange,
                        foregroundColor: AppColors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        _settings.isRunning
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_active_rounded,
                      ),
                      label: Text(
                        _settings.isRunning
                            ? (widget.isArabic
                                  ? 'اقفل التنبيه'
                                  : 'Turn Off Reminders')
                            : (widget.isArabic
                                  ? 'شغل التنبيه'
                                  : 'Turn On Reminders'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Schedule Conflict Warning Card (if any)
                  if (conflictMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              conflictMsg,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. Wake & Sleep Inputs
                  Text(
                    widget.isArabic
                        ? 'مواعيد الاستيقاظ والنوم'
                        : 'Wake & Sleep Hours',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFFBEB),
                            child: Icon(
                              Icons.wb_sunny_rounded,
                              color: AppColors.accentOrange,
                            ),
                          ),
                          title: Text(
                            widget.isArabic ? 'موعد الاستيقاظ' : 'Wake-up Time',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _formatHourMinute(
                              _settings.wakeHour,
                              _settings.wakeMinute,
                            ),
                            style: const TextStyle(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () => _pickTime(isWake: true),
                            child: Text(
                              widget.isArabic ? 'تعديل' : 'Edit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentOrange,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFECFDF5),
                            child: Icon(
                              Icons.nightlight_round,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          title: Text(
                            widget.isArabic ? 'موعد النوم' : 'Bedtime',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _formatHourMinute(
                              _settings.sleepHour,
                              _settings.sleepMinute,
                            ),
                            style: const TextStyle(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () => _pickTime(isWake: false),
                            child: Text(
                              widget.isArabic ? 'تعديل' : 'Edit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentOrange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Primary Calculated Alarms Header with Hamburger Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isAutoMealsExpanded = !_isAutoMealsExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.menu_rounded,
                                  color: AppColors.forestGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.isArabic
                                    ? 'الوجبات والمواعيد المحسوبة تلقائياً'
                                    : 'Auto-Calculated Schedules',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _isAutoMealsExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.forestGreen,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.isArabic ? 'تلقائي' : 'Auto',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_isAutoMealsExpanded) ...[
                    if (!_settings.hasSelectedWakeAndSleepTimes) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.isArabic
                                    ? 'اختار ميعاد الصحيان والنوم عشان التنبيهات والمواعيد تبدأ تتحدد وتتجدول تلقائياً.'
                                    : 'Select wake & sleep times for meal schedules to be auto-calculated.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFEF3C7),
                                child: Text('🍳', style: TextStyle(fontSize: 18)),
                              ),
                              title: Text(
                                widget.isArabic ? 'تنبيه الإفطار' : 'Breakfast',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                widget.isArabic
                                    ? 'بعد الاستيقاظ بـ ٣٠ دقيقة'
                                    : '30 mins after wake-up',
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                              ),
                              trailing: Text(
                                _formatTimeOfDay(_settings.getBreakfastTime()!),
                                style: const TextStyle(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFECFDF5),
                                child: Text('🥗', style: TextStyle(fontSize: 18)),
                              ),
                              title: Text(
                                widget.isArabic ? 'تنبيه الغداء' : 'Lunch',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                widget.isArabic
                                    ? 'بعد الإفطار بـ ٧ ساعات'
                                    : '7 hours after breakfast',
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                              ),
                              trailing: Text(
                                _formatTimeOfDay(_settings.getLunchTime()!),
                                style: const TextStyle(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFF7ED),
                                child: Text('🍲', style: TextStyle(fontSize: 18)),
                              ),
                              title: Text(
                                widget.isArabic ? 'تنبيه العشاء' : 'Dinner',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                widget.isArabic
                                    ? 'قبل النوم بـ ساعة واحدة'
                                    : '1 hour before bedtime',
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                              ),
                              trailing: Text(
                                _formatTimeOfDay(_settings.getDinnerTime()!),
                                style: const TextStyle(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // 5. Unified Optional & Custom Reminders Section (اختياري — تقدر تسيبه أو تفعّله + إضافة تنبيه)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: AppColors.accentOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isArabic
                                ? 'اختياري — تقدر تسيبه أو تفعّله'
                                : 'Optional Reminders',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _showCustomAlarmDialog(),
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 18,
                          color: AppColors.forestGreen,
                        ),
                        label: Text(
                          widget.isArabic ? 'إضافة تنبيه' : 'Add Alarm',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // A. Motivation & Support (التحفيز والدعم - موعد ثابت بعد الإفطار بساعة)
                  _buildOptionalReminderCard(
                    title: widget.isArabic ? 'التحفيز والدعم' : 'Motivation & Support',
                    subtitle: widget.isArabic
                        ? 'رسائل تحفيزية تصلك بعد الإفطار بساعة واحدة'
                        : 'Motivational quote 1 hour after breakfast',
                    icon: Icons.auto_awesome_rounded,
                    enabled: _settings.motivationEnabled,
                    onToggle: (val) async {
                      setState(() => _settings.motivationEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) {
                        await _applyReminders(silent: true);
                      }
                    },
                    timeText: _settings.hasSelectedWakeAndSleepTimes
                        ? _formatTimeOfDay(_settings.getMotivationTime()!)
                        : (widget.isArabic ? 'لم يتم التحديد' : 'Not specified'),
                    onTimeTap: null, // Fixed time, no manual editing needed
                  ),

                  // B. Workout Reminder (تنبيه التمارين اليومية)
                  _buildOptionalReminderCard(
                    title: widget.isArabic ? 'التمارين اليومية' : 'Daily Workouts',
                    subtitle: widget.isArabic
                        ? 'تذكير بالميعاد المحدد للتمارين الرياضية'
                        : 'Daily workout schedule reminder',
                    icon: Icons.fitness_center_rounded,
                    enabled: _settings.workoutEnabled,
                    onToggle: (val) async {
                      setState(() => _settings.workoutEnabled = val);
                      if (val && _settings.workoutHour == null) {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            _settings.workoutHour = picked.hour;
                            _settings.workoutMinute = picked.minute;
                          });
                        } else {
                          setState(() => _settings.workoutEnabled = false);
                        }
                      }
                      await _settings.save();
                      if (_settings.isRunning) {
                        await _applyReminders(silent: true);
                      }
                    },
                    timeText: _formatHourMinute(
                      _settings.workoutHour,
                      _settings.workoutMinute,
                    ),
                    onTimeTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _settings.workoutHour ?? 17,
                          minute: _settings.workoutMinute ?? 0,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _settings.workoutHour = picked.hour;
                          _settings.workoutMinute = picked.minute;
                        });
                        await _settings.save();
                        if (_settings.isRunning) {
                          await _applyReminders(silent: true);
                        }
                      }
                    },
                  ),

                  // C. Vitamins (الفيتامينات)
                  _buildOptionalReminderCard(
                    title: widget.isArabic ? 'الفيتامينات' : 'Vitamins',
                    subtitle: widget.isArabic
                        ? 'تذكير بتناول الفيتامينات في الوقت المحدد'
                        : 'Reminder to take prescribed vitamins',
                    icon: Icons.medication_rounded,
                    enabled: _settings.vitaminsEnabled,
                    onToggle: (val) async {
                      setState(() => _settings.vitaminsEnabled = val);
                      if (val && _settings.vitaminsHour == null) {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            _settings.vitaminsHour = picked.hour;
                            _settings.vitaminsMinute = picked.minute;
                          });
                        } else {
                          setState(() => _settings.vitaminsEnabled = false);
                        }
                      }
                      await _settings.save();
                      if (_settings.isRunning) {
                        await _applyReminders(silent: true);
                      }
                    },
                    timeText: _formatHourMinute(
                      _settings.vitaminsHour,
                      _settings.vitaminsMinute,
                    ),
                    onTimeTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _settings.vitaminsHour ?? 9,
                          minute: _settings.vitaminsMinute ?? 0,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _settings.vitaminsHour = picked.hour;
                          _settings.vitaminsMinute = picked.minute;
                        });
                        await _settings.save();
                        if (_settings.isRunning) {
                          await _applyReminders(silent: true);
                        }
                      }
                    },
                  ),

                  // D. Screen Off & Bedtime (الابتعاد عن الشاشة والاستعداد للنوم)
                  _buildOptionalReminderCard(
                    title: widget.isArabic
                        ? 'الابتعاد عن الشاشة والاستعداد للنوم'
                        : 'Screen Off & Bedtime',
                    subtitle: widget.isArabic
                        ? 'إيقاف الشاشات وراحة العين قبل النوم'
                        : 'Rest your eyes before bedtime',
                    icon: Icons.phone_android_rounded,
                    enabled: _settings.screenOffEnabled,
                    onToggle: (val) async {
                      setState(() => _settings.screenOffEnabled = val);
                      if (val && _settings.screenOffHour == null) {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 22, minute: 30),
                        );
                        if (picked != null) {
                          setState(() {
                            _settings.screenOffHour = picked.hour;
                            _settings.screenOffMinute = picked.minute;
                          });
                        } else {
                          setState(() => _settings.screenOffEnabled = false);
                        }
                      }
                      await _settings.save();
                      if (_settings.isRunning) {
                        await _applyReminders(silent: true);
                      }
                    },
                    timeText: _formatHourMinute(
                      _settings.screenOffHour,
                      _settings.screenOffMinute,
                    ),
                    onTimeTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _settings.screenOffHour ?? 22,
                          minute: _settings.screenOffMinute ?? 30,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _settings.screenOffHour = picked.hour;
                          _settings.screenOffMinute = picked.minute;
                        });
                        await _settings.save();
                        if (_settings.isRunning) {
                          await _applyReminders(silent: true);
                        }
                      }
                    },
                  ),

                  // E. User Custom Added Alarms List under Optional Section
                  if (_settings.customAlarms.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._settings.customAlarms.map((alarm) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: alarm.isEnabled
                                ? AppColors.forestGreen.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: alarm.isEnabled
                                ? AppColors.forestGreen.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            child: Icon(
                              Icons.alarm_rounded,
                              color: alarm.isEnabled
                                  ? AppColors.forestGreen
                                  : Colors.grey,
                            ),
                          ),
                          title: Text(
                            alarm.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: alarm.isEnabled
                                  ? AppColors.textDark
                                  : AppColors.mutedText,
                            ),
                          ),
                          subtitle: Text(
                            _formatHourMinute(alarm.hour, alarm.minute),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: alarm.isEnabled,
                                activeThumbColor: AppColors.forestGreen,
                                onChanged: (val) =>
                                    _toggleCustomAlarm(alarm, val),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showCustomAlarmDialog(alarmToEdit: alarm),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteCustomAlarm(alarm),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // 6. Section 3: Healthy Meal Suggestions (Removed from Reminders screen, moved to Calorie/Add Food screen)
                ],
              ),
      ),
    );
  }

  Widget _buildOptionalReminderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required String timeText,
    required VoidCallback? onTimeTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: enabled
              ? AppColors.forestGreen.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.forestGreen.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.forestGreen : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: enabled ? AppColors.textDark : AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: AppColors.forestGreen,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isArabic ? 'الوقت' : 'Time',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: onTimeTap,
                  icon: const Icon(Icons.access_time_rounded, size: 16),
                  label: Text(
                    timeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

