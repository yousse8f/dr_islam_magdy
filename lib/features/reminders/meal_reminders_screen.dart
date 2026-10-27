import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/reminder_settings.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ReminderSettings.load();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickTime({
    required bool isWake,
    bool isWorkout = false,
    bool isVitamins = false,
  }) async {
    int initialHour = 7;
    int initialMinute = 0;

    if (isWake) {
      initialHour = _settings.wakeHour;
      initialMinute = _settings.wakeMinute;
    } else if (isWorkout) {
      initialHour = _settings.workoutHour;
      initialMinute = _settings.workoutMinute;
    } else if (isVitamins) {
      initialHour = _settings.vitaminsHour;
      initialMinute = _settings.vitaminsMinute;
    } else {
      initialHour = _settings.sleepHour;
      initialMinute = _settings.sleepMinute;
    }

    final initialTime = TimeOfDay(hour: initialHour, minute: initialMinute);

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
        } else if (isWorkout) {
          _settings.workoutHour = picked.hour;
          _settings.workoutMinute = picked.minute;
        } else if (isVitamins) {
          _settings.vitaminsHour = picked.hour;
          _settings.vitaminsMinute = picked.minute;
        } else {
          _settings.sleepHour = picked.hour;
          _settings.sleepMinute = picked.minute;
        }
      });
      await _settings.save();
      if (_settings.isRunning) {
        await _applyReminders();
      }
    }
  }

  Future<void> _applyReminders() async {
    setState(() => _isLoading = true);

    // Request permission first
    final hasPermission = await NotificationService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'يرجى السماح بإرسال الإشعارات من إعدادات الهاتف لتفعيل المنبهات.'
                  : 'Please allow notifications in phone settings to enable reminders.',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _settings.isRunning = true;
    await _settings.save();

    final success = await NotificationService.scheduleReminders(
      _settings,
      widget.isArabic,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (widget.isArabic
                      ? 'تم تشغيل وتفعيل المنبهات والإشعارات بنجاح! 🔔'
                      : 'Reminders activated successfully! 🔔')
                : (widget.isArabic
                      ? 'حدث خطأ أثناء جدولة المنبهات.'
                      : 'Error scheduling reminders.'),
          ),
          backgroundColor: success
              ? AppColors.forestGreen
              : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopReminders() async {
    setState(() => _isLoading = true);
    _settings.isRunning = false;
    await _settings.save();
    await NotificationService.cancelAll();

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic
                ? 'تم إيقاف جميع المنبهات وإلغاء إشعاراتها.'
                : 'All reminders stopped and notifications cancelled.',
          ),
          backgroundColor: AppColors.accentOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12
        ? (widget.isArabic ? 'مساءً' : 'PM')
        : (widget.isArabic ? 'صباحاً' : 'AM');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Status Banner Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _settings.isRunning
                          ? AppColors.forestGreen
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: _settings.isRunning
                            ? AppColors.forestGreen
                            : AppColors.forestGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _settings.isRunning
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: _settings.isRunning
                              ? AppColors.white
                              : AppColors.mutedText,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _settings.isRunning
                                    ? (widget.isArabic
                                          ? 'المنبهات والإشعارات مفعّلة'
                                          : 'Reminders & Notifications Active')
                                    : (widget.isArabic
                                          ? 'المنبهات متوقفة'
                                          : 'Reminders are Paused'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _settings.isRunning
                                      ? AppColors.white
                                      : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _settings.isRunning
                                    ? (widget.isArabic
                                          ? 'تصلك الإشعارات في المواعيد المحددة بدقة'
                                          : 'Notifications will arrive at scheduled times')
                                    : (widget.isArabic
                                          ? 'اضغط على زر تشغيل المنبهات أدناه للبدء'
                                          : 'Tap activate button below to start'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _settings.isRunning
                                      ? AppColors.white.withValues(alpha: 0.85)
                                      : AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Start / Stop Main Toggle Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _settings.isRunning
                          ? _stopReminders
                          : _applyReminders,
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
                                  ? 'إيقاف جميع المنبهات والإشعارات'
                                  : 'Stop All Reminders')
                            : (widget.isArabic
                                  ? 'تشغيل وتفعيل المنبهات والإشعارات 🔔'
                                  : 'Activate Reminders & Notifications 🔔'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sleep & Wake Time Section
                  Text(
                    widget.isArabic
                        ? 'فترة الاستيقاظ والنشاط'
                        : 'Wake & Sleep Period',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.cream,
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
                            _formatTime(
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
                            backgroundColor: AppColors.cream,
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
                            _formatTime(
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

                  // Reminders Configuration Section
                  Text(
                    widget.isArabic
                        ? 'إعدادات التذكيرات والإشعارات'
                        : 'Individual Reminder Settings',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // A. Meal Reminder
                  _buildReminderConfigCard(
                    title: widget.isArabic ? 'منبه الوجبات' : 'Meal Reminder',
                    subtitle: widget.isArabic
                        ? 'تذكير دوري بوجباتك الصحية'
                        : 'Regular healthy meal reminders',
                    icon: Icons.restaurant_menu_rounded,
                    enabled: _settings.mealEnabled,
                    onChanged: (val) async {
                      setState(() => _settings.mealEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) await _applyReminders();
                    },
                    intervalWidget: Row(
                      children: [
                        Text(
                          widget.isArabic ? 'الفاصل: ' : 'Interval: ',
                          style: const TextStyle(fontSize: 12),
                        ),
                        DropdownButton<int>(
                          value: _settings.mealIntervalHours,
                          items: [1, 2, 3, 4]
                              .map(
                                (h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(
                                    widget.isArabic
                                        ? 'كل $h ساعة'
                                        : 'Every $h hr',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => _settings.mealIntervalHours = val);
                              await _settings.save();
                              if (_settings.isRunning) await _applyReminders();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // B. Water Reminder
                  _buildReminderConfigCard(
                    title: widget.isArabic ? 'منبه الماء' : 'Water Reminder',
                    subtitle: widget.isArabic
                        ? 'تذكير لشرب الماء وترطيب الجسم'
                        : 'Reminder to stay hydrated',
                    icon: Icons.water_drop_rounded,
                    enabled: _settings.waterEnabled,
                    onChanged: (val) async {
                      setState(() => _settings.waterEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) await _applyReminders();
                    },
                    intervalWidget: Row(
                      children: [
                        Text(
                          widget.isArabic ? 'الفاصل: ' : 'Interval: ',
                          style: const TextStyle(fontSize: 12),
                        ),
                        DropdownButton<int>(
                          value: _settings.waterIntervalHours,
                          items: [1, 2, 3, 4]
                              .map(
                                (h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(
                                    widget.isArabic
                                        ? 'كل $h ساعة'
                                        : 'Every $h hr',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(
                                () => _settings.waterIntervalHours = val,
                              );
                              await _settings.save();
                              if (_settings.isRunning) await _applyReminders();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // C. Vegetables / Snack Reminder
                  _buildReminderConfigCard(
                    title: widget.isArabic
                        ? 'منبه الخضروات البينية'
                        : 'Vegetables & Snack Reminder',
                    subtitle: widget.isArabic
                        ? 'تذكير بتناول حصص الخضروات والفيتامينات'
                        : 'Reminder for fresh veggies & vitamins',
                    icon: Icons.eco_rounded,
                    enabled: _settings.veggiesEnabled,
                    onChanged: (val) async {
                      setState(() => _settings.veggiesEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) await _applyReminders();
                    },
                    intervalWidget: Row(
                      children: [
                        Text(
                          widget.isArabic ? 'الفاصل: ' : 'Interval: ',
                          style: const TextStyle(fontSize: 12),
                        ),
                        DropdownButton<int>(
                          value: _settings.veggiesIntervalHours,
                          items: [2, 3, 4, 5]
                              .map(
                                (h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(
                                    widget.isArabic
                                        ? 'كل $h ساعة'
                                        : 'Every $h hr',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(
                                () => _settings.veggiesIntervalHours = val,
                              );
                              await _settings.save();
                              if (_settings.isRunning) await _applyReminders();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // D. Screen Off / Bedtime Eye Rest (إيقاف الشاشات / راحة للعين قبل النوم)
                  _buildReminderConfigCard(
                    title: widget.isArabic
                        ? 'إيقاف الشاشات / راحة للعين قبل النوم'
                        : 'Screen Off / Eye Rest Before Sleep',
                    subtitle: widget.isArabic
                        ? 'تنبيه قبل موعد النوم لإيقاف الشاشات وإراحة العين'
                        : 'Alert before bedtime to stop screens and rest eyes',
                    icon: Icons.phone_android_rounded,
                    enabled: _settings.screenOffEnabled,
                    onChanged: (val) async {
                      setState(() => _settings.screenOffEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) await _applyReminders();
                    },
                    intervalWidget: Row(
                      children: [
                        Text(
                          widget.isArabic ? 'قبل النوم بـ: ' : 'Before sleep: ',
                          style: const TextStyle(fontSize: 12),
                        ),
                        DropdownButton<int>(
                          value: _settings.screenOffMinutesBeforeSleep,
                          items: [15, 30, 45, 60]
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    widget.isArabic
                                        ? '$m دقيقة'
                                        : '$m mins',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(
                                () =>
                                    _settings.screenOffMinutesBeforeSleep =
                                        val,
                              );
                              await _settings.save();
                              if (_settings.isRunning) await _applyReminders();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // E. Workout Reminder (تنبيه التمارين - اختياري)
                  _buildReminderConfigCard(
                    title: widget.isArabic
                        ? 'تنبيه التمارين (اختياري)'
                        : 'Workout Reminder (Optional)',
                    subtitle: widget.isArabic
                        ? 'تذكير بميعاد التمرين اليومي'
                        : 'Daily workout schedule reminder',
                    icon: Icons.fitness_center_rounded,
                    enabled: _settings.workoutEnabled,
                    onChanged: (val) async {
                      setState(() => _settings.workoutEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) await _applyReminders();
                    },
                    intervalWidget: TextButton(
                      onPressed: () => _pickTime(isWake: false, isWorkout: true),
                      child: Text(
                        _formatTime(
                          _settings.workoutHour,
                          _settings.workoutMinute,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // F. Vitamins Reminder (الفيتامينات)
                  _buildReminderConfigCard(
                    title: widget.isArabic
                        ? 'تذكير الفيتامينات'
                        : 'Vitamins Reminder',
                    subtitle: widget.isArabic
                        ? 'تذكير بتناول الفيتامينات إن وصفت لك'
                        : 'Reminder to take prescribed vitamins',
                    icon: Icons.medication_rounded,
                    enabled: _settings.vitaminsEnabled,
                    onChanged: (val) async {
                      setState(() => _settings.vitaminsEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) await _applyReminders();
                    },
                    intervalWidget: TextButton(
                      onPressed: () =>
                          _pickTime(isWake: false, isVitamins: true),
                      child: Text(
                        _formatTime(
                          _settings.vitaminsHour,
                          _settings.vitaminsMinute,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // G. Eye Strain / Screen Rest (إجهاد العين / راحة للعين من الشاشات)
                  _buildReminderConfigCard(
                    title: widget.isArabic
                        ? 'إجهاد العين / راحة للعين من الشاشات'
                        : 'Eye Strain & Screen Rest',
                    subtitle: widget.isArabic
                        ? 'راحة دورية للعين من الموبايل والشاشات'
                        : 'Periodic eye rest from mobile & screens',
                    icon: Icons.remove_red_eye_rounded,
                    enabled: _settings.eyeRestEnabled,
                    onChanged: (val) async {
                      setState(() => _settings.eyeRestEnabled = val);
                      await _settings.save();
                      if (_settings.isRunning) await _applyReminders();
                    },
                    intervalWidget: Row(
                      children: [
                        Text(
                          widget.isArabic ? 'الفاصل: ' : 'Interval: ',
                          style: const TextStyle(fontSize: 12),
                        ),
                        DropdownButton<int>(
                          value: _settings.eyeRestIntervalHours,
                          items: [1, 2, 3]
                              .map(
                                (h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(
                                    widget.isArabic
                                        ? 'كل $h ساعة'
                                        : 'Every $h hr',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(
                                () => _settings.eyeRestIntervalHours = val,
                              );
                              await _settings.save();
                              if (_settings.isRunning) await _applyReminders();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildReminderConfigCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required Widget intervalWidget,
  }) {
    return Container(
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
                        color: enabled
                            ? AppColors.textDark
                            : AppColors.mutedText,
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
                onChanged: onChanged,
                activeThumbColor: AppColors.forestGreen,
              ),
            ],
          ),
          if (enabled) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [intervalWidget],
            ),
          ],
        ],
      ),
    );
  }
}
