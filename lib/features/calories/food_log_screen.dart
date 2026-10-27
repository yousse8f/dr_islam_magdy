import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'add_food_screen.dart';
import 'calorie_calculator_screen.dart';
import 'models/calorie_profile.dart';
import 'models/food_item.dart';
import 'services/calorie_storage.dart';

class FoodLogScreen extends StatefulWidget {
  final bool isArabic;

  const FoodLogScreen({super.key, required this.isArabic});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  CalorieProfile? _profile;
  final String _selectedDateStr = CalorieStorage.getTodayKey();
  List<LoggedFood> _loggedItems = [];
  bool _isLoading = true;

  final Map<String, String> _mealTitlesAr = {
    'breakfast': 'الإفطار',
    'morning_snack': 'وجبة خفيفة (صباحاً)',
    'lunch': 'الغداء',
    'evening_snack': 'وجبة خفيفة (مساءً)',
    'dinner': 'العشاء',
  };

  final Map<String, String> _mealTitlesEn = {
    'breakfast': 'Breakfast',
    'morning_snack': 'Morning Snack',
    'lunch': 'Lunch',
    'evening_snack': 'Evening Snack',
    'dinner': 'Dinner',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await CalorieProfile.load();
      final items = await CalorieStorage.getLogForDate(_selectedDateStr);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loggedItems = items;
        });
      }
    } catch (e) {
      debugPrint('Error loading food log data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToAddFood(String mealType) async {
    final result = await Navigator.push<LoggedFood>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddFoodScreen(isArabic: widget.isArabic, mealType: mealType),
      ),
    );

    if (result != null) {
      setState(() {
        _loggedItems.add(result);
      });
      await CalorieStorage.saveLogForDate(_selectedDateStr, _loggedItems);
    }
  }

  Future<void> _removeItem(String id) async {
    setState(() {
      _loggedItems.removeWhere((item) => item.id == id);
    });
    await CalorieStorage.saveLogForDate(_selectedDateStr, _loggedItems);
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CalorieCalculatorScreen(isArabic: widget.isArabic),
          ),
        );
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final dailyGoal = _profile?.dailyTargetCalories ?? 2000;
    final consumedCalories = _loggedItems.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );

    final remainingCalories = max(0, dailyGoal - consumedCalories);
    final exceededCalories = max(0, consumedCalories - dailyGoal);
    final progress = dailyGoal > 0
        ? (consumedCalories / dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded = consumedCalories > dailyGoal;

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          title: Text(
            widget.isArabic ? 'سجل السعرات اليومي' : 'Daily Calorie Tracker',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: widget.isArabic ? 'تعديل بيانات الجسم' : 'Edit Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CalorieCalculatorScreen(isArabic: widget.isArabic),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.forestGreen,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Modern Calorie Summary Dashboard Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.isArabic
                                    ? 'ملخص سعراتك اليوم'
                                    : 'Today\'s Calorie Summary',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isExceeded
                                      ? AppColors.accentOrange.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.forestGreen.withValues(
                                          alpha: 0.12,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isExceeded
                                      ? (widget.isArabic
                                            ? 'متجاوز'
                                            : 'Exceeded')
                                      : (widget.isArabic
                                            ? 'متوازن'
                                            : 'On Track'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isExceeded
                                        ? AppColors.accentOrange
                                        : AppColors.forestGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Prominent Remaining Calorie Hero Metric
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  widget.isArabic
                                      ? 'السعرات المتبقية'
                                      : 'Remaining Calories',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$remainingCalories',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: isExceeded
                                            ? Colors.red.shade600
                                            : AppColors.forestGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'kcal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Smooth Animated Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: AppColors.cream,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isExceeded
                                    ? AppColors.accentOrange
                                    : AppColors.forestGreen,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Metrics Row: Consumed vs Daily Goal
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.isArabic
                                            ? 'المستهلك'
                                            : 'Consumed',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$consumedCalories kcal',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.forestGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.isArabic
                                            ? 'الهدف اليومي'
                                            : 'Daily Goal',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$dailyGoal kcal',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (isExceeded) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.accentOrange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.isArabic
                                          ? 'تجاوزت هدفك اليومي بمقدار $exceededCalories kcal'
                                          : 'You exceeded your daily goal by $exceededCalories kcal',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Meal Sections
                    ...[
                      'breakfast',
                      'morning_snack',
                      'lunch',
                      'evening_snack',
                      'dinner',
                    ].map((mealType) => _buildMealSection(mealType)),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMealSection(String mealType) {
    final mealItems = _loggedItems
        .where((i) => i.mealType == mealType)
        .toList();
    final mealCalories = mealItems.fold<int>(0, (sum, i) => sum + i.calories);
    final title = widget.isArabic
        ? _mealTitlesAr[mealType]!
        : _mealTitlesEn[mealType]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.forestGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$mealCalories kcal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        color: AppColors.accentOrange,
                        size: 26,
                      ),
                      onPressed: () => _navigateToAddFood(mealType),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (mealItems.isNotEmpty) ...[
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mealItems.length,
              itemBuilder: (context, index) {
                final item = mealItems[index];
                return ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${item.amount} ${item.unit}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.calories} kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeItem(item.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
              child: InkWell(
                onTap: () => _navigateToAddFood(mealType),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.forestGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isArabic ? 'أضف وجبة' : 'Add Meal',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
