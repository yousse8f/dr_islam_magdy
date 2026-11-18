import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  int _waterConsumedMl = 0;
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
      final water = await CalorieStorage.getWaterForDate(_selectedDateStr);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loggedItems = items;
          _waterConsumedMl = water;
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

  Future<void> _addWater(int amountMl) async {
    setState(() {
      _waterConsumedMl += amountMl;
      if (_waterConsumedMl < 0) _waterConsumedMl = 0;
    });
    await CalorieStorage.saveWaterForDate(_selectedDateStr, _waterConsumedMl);
  }

  String _getBmiStatus(double bmi, bool isArabic) {
    if (bmi < 18.5) {
      return isArabic ? 'نقص في الوزن' : 'Underweight';
    } else if (bmi < 25.0) {
      return isArabic ? 'وزن مثالي' : 'Normal';
    } else if (bmi < 30.0) {
      return isArabic ? 'زيادة في الوزن' : 'Overweight';
    } else {
      return isArabic ? 'سمنة' : 'Obese';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyGoal = _profile?.dailyTargetCalories ?? 0;
    final consumedCalories = _loggedItems.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );

    final consumedProtein = _loggedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.protein,
    );
    final consumedCarbs = _loggedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.carbs,
    );
    final consumedFats = _loggedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.fats,
    );
    final hasIncompleteMacros = _loggedItems.any((i) => !i.hasCompleteMacros);

    final remainingCalories = max(0, dailyGoal - consumedCalories);
    final exceededCalories = max(0, consumedCalories - dailyGoal);
    final calorieProgress = dailyGoal > 0
        ? (consumedCalories / dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded = consumedCalories > dailyGoal && dailyGoal > 0;

    final proteinTarget = _profile?.proteinTarget ?? 120;
    final carbsTarget = _profile?.carbsTarget ?? 250;
    final fatsTarget = _profile?.fatsTarget ?? 70;
    final waterTarget = _profile?.waterTargetMl ?? 3000;

    final proteinProgress = proteinTarget > 0
        ? (consumedProtein / proteinTarget).clamp(0.0, 1.0)
        : 0.0;
    final carbsProgress = carbsTarget > 0
        ? (consumedCarbs / carbsTarget).clamp(0.0, 1.0)
        : 0.0;
    final fatsProgress = fatsTarget > 0
        ? (consumedFats / fatsTarget).clamp(0.0, 1.0)
        : 0.0;

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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  children: [
                    // If profile is not set, show setup prompt card ("أكمل بياناتك")
                    if (_profile == null)
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            const Icon(
                              Icons.calculate_rounded,
                              size: 42,
                              color: AppColors.forestGreen,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.isArabic
                                  ? 'أكمل بياناتك لحساب السعرات'
                                  : 'Complete Your Profile',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.isArabic
                                  ? 'يرجى إدخال بياناتك (الوزن، الطول، العمر، النشاط، والهدف) لعرض الحسابات (BMR, TDEE, BMI والهدف).'
                                  : 'Please enter your details to view your calorie calculations and targets.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CalorieCalculatorScreen(
                                      isArabic: widget.isArabic,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: Text(
                                widget.isArabic ? 'أكمل بياناتك الآن' : 'Complete Now',
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // 1. Compact Calorie Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.isArabic
                                      ? 'ملخص سعراتك اليوم'
                                      : 'Today\'s Summary',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isExceeded
                                        ? AppColors.accentOrange.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.forestGreen.withValues(
                                            alpha: 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isExceeded
                                          ? AppColors.accentOrange
                                          : AppColors.forestGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Remaining Calories & Progress Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isArabic
                                          ? 'السعرات المتبقية'
                                          : 'Remaining',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '$remainingCalories',
                                          style: TextStyle(
                                            fontSize: 28,
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
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${widget.isArabic ? 'المستهلك' : 'Consumed'}: $consumedCalories',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${widget.isArabic ? 'الهدف' : 'Goal'}: $dailyGoal',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Smooth Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: calorieProgress,
                                minHeight: 9,
                                backgroundColor: AppColors.cream,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isExceeded
                                      ? AppColors.accentOrange
                                      : AppColors.forestGreen,
                                ),
                              ),
                            ),

                            if (isExceeded) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.isArabic
                                    ? 'تجاوزت هدفك بمقدار $exceededCalories kcal'
                                    : 'Exceeded goal by $exceededCalories kcal',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentOrange,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 2. Direct Unified Small Cards Grid (BMR, TDEE, BMI, Target Calories, Protein, Carbs, Fats)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.15,
                        children: [
                          _buildSmallMetricCard(
                            value: 'kcal ${_profile!.bmr.round()}',
                            label: 'BMR',
                            sublabel: widget.isArabic ? 'معدل الحرق الأساسي' : 'Base Rate',
                            icon: Icons.bolt_rounded,
                            color: Colors.orange.shade800,
                          ),
                          _buildSmallMetricCard(
                            value: 'kcal ${_profile!.tdee.round()}',
                            label: 'TDEE',
                            sublabel: widget.isArabic ? 'الاحتياج اليومي' : 'Daily Needs',
                            icon: Icons.local_fire_department_rounded,
                            color: Colors.blue.shade700,
                          ),
                          _buildSmallMetricCard(
                            value: _profile!.bmi.toStringAsFixed(1),
                            label: 'BMI',
                            sublabel: _getBmiStatus(_profile!.bmi, widget.isArabic),
                            icon: Icons.monitor_weight_rounded,
                            color: Colors.purple.shade700,
                          ),
                          _buildSmallMetricCard(
                            value: 'kcal ${_profile!.dailyTargetCalories}',
                            label: widget.isArabic ? 'السعرات المستهدفة' : 'Target Calories',
                            sublabel: widget.isArabic ? 'الهدف اليومي' : 'Daily Goal',
                            icon: Icons.flag_rounded,
                            color: AppColors.forestGreen,
                          ),
                          _buildSmallMetricCard(
                            value: '$proteinTarget ${widget.isArabic ? 'جم' : 'g'}',
                            label: widget.isArabic ? 'بروتين' : 'Protein',
                            sublabel: widget.isArabic ? 'بناء العضلات' : 'Muscle',
                            icon: Icons.fitness_center_rounded,
                            color: Colors.blue.shade800,
                          ),
                          _buildSmallMetricCard(
                            value: '$carbsTarget ${widget.isArabic ? 'جم' : 'g'}',
                            label: widget.isArabic ? 'كربوهيدرات' : 'Carbs',
                            sublabel: widget.isArabic ? 'طاقة أساسية' : 'Energy',
                            icon: Icons.grain_rounded,
                            color: Colors.orange.shade900,
                          ),
                          _buildSmallMetricCard(
                            value: '$fatsTarget ${widget.isArabic ? 'جم' : 'g'}',
                            label: widget.isArabic ? 'دهون' : 'Fats',
                            sublabel: widget.isArabic ? 'دهون صحية' : 'Fats',
                            icon: Icons.opacity_rounded,
                            color: Colors.purple.shade800,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 3. Nutrients Card with Progress Bars (العناصر الغذائية)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 8,
                              offset: Offset(0, 3),
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
                                  widget.isArabic ? 'العناصر الغذائية' : 'Nutrients Progress',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (hasIncompleteMacros)
                                  Tooltip(
                                    message: widget.isArabic
                                        ? 'بعض الوجبات لا تحتوي على تفاصيل الماكروز'
                                        : 'Some meals have incomplete macro data',
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: AppColors.accentOrange,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildNutrientCardRow(
                              label: widget.isArabic ? 'بروتين' : 'Protein',
                              consumed: consumedProtein,
                              target: proteinTarget.toDouble(),
                              unit: widget.isArabic ? 'جم' : 'g',
                              progress: proteinProgress,
                              color: Colors.blue.shade700,
                              icon: Icons.fitness_center_rounded,
                            ),
                            const SizedBox(height: 10),
                            _buildNutrientCardRow(
                              label: widget.isArabic ? 'كربوهيدرات' : 'Carbs',
                              consumed: consumedCarbs,
                              target: carbsTarget.toDouble(),
                              unit: widget.isArabic ? 'جم' : 'g',
                              progress: carbsProgress,
                              color: Colors.orange.shade800,
                              icon: Icons.grain_rounded,
                            ),
                            const SizedBox(height: 10),
                            _buildNutrientCardRow(
                              label: widget.isArabic ? 'دهون' : 'Fats',
                              consumed: consumedFats,
                              target: fatsTarget.toDouble(),
                              unit: widget.isArabic ? 'جم' : 'g',
                              progress: fatsProgress,
                              color: Colors.purple.shade700,
                              icon: Icons.opacity_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 4. Water Row Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.water_drop_rounded,
                                    color: Colors.cyan.shade700,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isArabic ? 'المياه' : 'Water',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$_waterConsumedMl / $waterTarget ${widget.isArabic ? 'مل' : 'ml'}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _addWater(250),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyan.shade700,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text(
                                    '+250 مل',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                  tooltip: widget.isArabic ? 'خصم 250 مل' : 'Remove 250ml',
                                  onPressed: () => _addWater(-250),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

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

  Widget _buildSmallMetricCard({
    required String value,
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sublabel,
                  style: GoogleFonts.cairo(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCardRow({
    required String label,
    required double consumed,
    required double target,
    required String unit,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${consumed.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.white,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.forestGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        color: AppColors.accentOrange,
                        size: 24,
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
                final item = mealItems.length > index ? mealItems[index] : null;
                if (item == null) return const SizedBox.shrink();
                return ListTile(
                  dense: true,
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    '${item.amount} ${item.unit} • P: ${item.protein.toStringAsFixed(1)}g | C: ${item.carbs.toStringAsFixed(1)}g | F: ${item.fats.toStringAsFixed(1)}g',
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.calories} kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
              padding: const EdgeInsets.only(bottom: 12.0, left: 12, right: 12),
              child: InkWell(
                onTap: () => _navigateToAddFood(mealType),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.forestGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isArabic ? 'أضف وجبة' : 'Add Meal',
                        style: const TextStyle(
                          fontSize: 12,
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
