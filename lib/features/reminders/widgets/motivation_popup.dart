import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/motivation_repository.dart';
import '../services/notification_service.dart';

class MotivationPopupManager {
  static bool _isShowing = false;

  static Future<void> showMotivationPopup(
    BuildContext context, {
    required bool isArabic,
    String? overrideQuote,
  }) async {
    if (_isShowing) return;
    _isShowing = true;

    // Mark today as shown so it doesn't trigger again automatically
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      await prefs.setString('last_motivation_date', todayStr);
    } catch (e) {
      debugPrint('Error saving last motivation date: $e');
    }

    // 1. Get motivation quote (either override from notification payload or today's quote)
    String quote;
    if (overrideQuote != null && overrideQuote.isNotEmpty) {
      quote = overrideQuote;
    } else {
      try {
        quote = await MotivationRepository.getRandomQuote();
      } catch (_) {
        quote = isArabic
            ? 'استمر في تحقيق هدفك! خطوة صغيرة يومياً تصنع فرقاً كبيراً 💪'
            : 'Stay optimistic and start your day with energy.';
      }
    }

    // Play motivation sound effect once
    try {
      await NotificationService.playMotivationSoundEffect();
    } catch (e) {
      debugPrint('Error playing sound for motivation popup: $e');
    }

    if (!context.mounted) {
      _isShowing = false;
      return;
    }

    // Show Bottom Sheet containing Motivational Quote
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _NotificationCenterBottomSheet(
          quote: quote,
          isArabic: isArabic,
          onDismissed: () {
            _isShowing = false;
          },
        );
      },
    );
    _isShowing = false;
  }
}

class _NotificationCenterBottomSheet extends StatefulWidget {
  final String quote;
  final bool isArabic;
  final VoidCallback onDismissed;

  const _NotificationCenterBottomSheet({
    required this.quote,
    required this.isArabic,
    required this.onDismissed,
  });

  @override
  State<_NotificationCenterBottomSheet> createState() =>
      _NotificationCenterBottomSheetState();
}

class _NotificationCenterBottomSheetState
    extends State<_NotificationCenterBottomSheet> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto dismiss after 45 seconds if user is idle
    _timer = Timer(const Duration(seconds: 45), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.onDismissed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = widget.isArabic
        ? '${now.year}/${now.month}/${now.day}'
        : '${now.month}/${now.day}/${now.year}';

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Header row with Title, Date, and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.forestGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isArabic ? 'مركز الإشعارات' : 'Notification Center',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            color: Color(0xFF12382B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Daily Motivational Quote Section
            Text(
              widget.isArabic ? '🌟 الرسالة التحفيزية' : '🌟 Motivational Quote',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF12382B),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF13533C),
                    Color(0xFF0C3B2A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Color(0xFFFDE047),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.quote,
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

            // Close Button at Bottom
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                },
                child: Text(
                  widget.isArabic ? 'إغلاق' : 'Close',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
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
