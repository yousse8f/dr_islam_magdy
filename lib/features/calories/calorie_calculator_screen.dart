import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'food_log_screen.dart';
import 'models/calorie_profile.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  final bool isArabic;

  const CalorieCalculatorScreen({super.key, required this.isArabic});

  @override
  State<CalorieCalculatorScreen> createState() =>
      _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  String _gender = 'male';
  String? _activityLevel;
  String? _goal;
  bool _isLoading = true;
  CalorieProfile? _existingProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _normalizeDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input;
    for (int i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], english[i]);
    }
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < persian.length; i++) {
      result = result.replaceAll(persian[i], english[i]);
    }
    return result.trim();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await CalorieProfile.load();
      if (profile != null) {
        _weightController.text = profile.weight.toString();
        _heightController.text = profile.height.toString();
        _ageController.text = profile.age.toString();
        setState(() {
          _gender = profile.gender;
          _activityLevel = profile.activityLevel;
          _goal = profile.goal;
          _existingProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error loading calorie profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_activityLevel == null || _goal == null) return;

    final weight = double.parse(_normalizeDigits(_weightController.text));
    final height = double.parse(_normalizeDigits(_heightController.text));
    final age = int.parse(_normalizeDigits(_ageController.text));

    final target = CalorieProfile.calculateTarget(
      weight: weight,
      height: height,
      age: age,
      gender: _gender,
      activityLevel: _activityLevel!,
      goal: _goal!,
    );

    final profile = CalorieProfile(
      weight: weight,
      height: height,
      age: age,
      gender: _gender,
      activityLevel: _activityLevel!,
      goal: _goal!,
      dailyTargetCalories: target,
    );

    await profile.save();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic
                ? 'تم حساب وحفظ هدفك اليومي بنجاح! 🎯'
                : 'Daily calorie goal calculated & saved successfully! 🎯',
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to Food Log Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FoodLogScreen(isArabic: widget.isArabic),
        ),
      );
    }
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
            widget.isArabic
                ? 'حساب الاحتياج اليومي'
                : 'Calculate Calorie Needs',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            if (_existingProfile != null)
              IconButton(
                icon: const Icon(Icons.restaurant_menu_rounded),
                tooltip: widget.isArabic ? 'سجل الوجبات' : 'Food Log',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FoodLogScreen(isArabic: widget.isArabic),
                    ),
                  );
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.forestGreen.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.forestGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                widget.isArabic
                                    ? 'أدخل بياناتك بدقة لنقوم بحساب السعرات الحرارية اليومية المناسبة لهدفك الصحي (تقديرية وليست تشخيصاً طبياً).'
                                    : 'Enter your details accurately to calculate your daily calorie target.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.mutedText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.isArabic
                            ? 'البيانات الشخصية'
                            : 'Personal Details',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Weight
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: widget.isArabic
                              ? 'الوزن (كجم) *'
                              : 'Weight (kg) *',
                          prefixIcon: const Icon(Icons.fitness_center_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return widget.isArabic
                                ? 'يرجى إدخال الوزن'
                                : 'Please enter weight';
                          }
                          final normalized = _normalizeDigits(v);
                          if (double.tryParse(normalized) == null ||
                              double.tryParse(normalized)! <= 0) {
                            return widget.isArabic
                                ? 'قيمة غير صالحة'
                                : 'Invalid value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Height
                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: widget.isArabic
                              ? 'الطول (سم) *'
                              : 'Height (cm) *',
                          prefixIcon: const Icon(Icons.height_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return widget.isArabic
                                ? 'يرجى إدخال الطول'
                                : 'Please enter height';
                          }
                          final normalized = _normalizeDigits(v);
                          if (double.tryParse(normalized) == null ||
                              double.tryParse(normalized)! <= 0) {
                            return widget.isArabic
                                ? 'قيمة غير صالحة'
                                : 'Invalid value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Age
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: widget.isArabic
                              ? 'العمر (سنة) *'
                              : 'Age *',
                          prefixIcon: const Icon(Icons.cake_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return widget.isArabic
                                ? 'يرجى إدخال العمر'
                                : 'Please enter age';
                          }
                          final normalized = _normalizeDigits(v);
                          if (int.tryParse(normalized) == null ||
                              int.tryParse(normalized)! <= 0) {
                            return widget.isArabic
                                ? 'قيمة غير صالحة'
                                : 'Invalid value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Gender
                      Text(
                        widget.isArabic ? 'النوع' : 'Gender',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _gender = 'male'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _gender == 'male'
                                      ? AppColors.forestGreen
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _gender == 'male'
                                        ? AppColors.forestGreen
                                        : AppColors.mutedText.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  widget.isArabic ? 'ذكر' : 'Male',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _gender == 'male'
                                        ? AppColors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _gender = 'female'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _gender == 'female'
                                      ? AppColors.forestGreen
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _gender == 'female'
                                        ? AppColors.forestGreen
                                        : AppColors.mutedText.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  widget.isArabic ? 'أنثى' : 'Female',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _gender == 'female'
                                        ? AppColors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Activity Level
                      Text(
                        widget.isArabic ? 'مستوى النشاط *' : 'Activity Level *',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _activityLevel,
                        hint: Text(
                          widget.isArabic
                              ? 'اختر مستوى النشاط *'
                              : 'Select Activity Level *',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedText,
                          ),
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return widget.isArabic
                                ? 'يرجى اختيار مستوى النشاط'
                                : 'Please select activity level';
                          }
                          return null;
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'sedentary',
                            child: Text(
                              widget.isArabic
                                  ? 'قليل الحركة (جالس غالباً)'
                                  : 'Sedentary (little or no exercise)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'light',
                            child: Text(
                              widget.isArabic
                                  ? 'خفيف النشاط (تمرين خفيف 1-3 أيام/أسبوع)'
                                  : 'Lightly active (light exercise 1-3 days/wk)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'moderate',
                            child: Text(
                              widget.isArabic
                                  ? 'متوسط النشاط (تمرين 3-5 أيام/أسبوع)'
                                  : 'Moderately active (moderate exercise 3-5 days/wk)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(
                              widget.isArabic
                                  ? 'نشيط جداً (تمرين مكثف يومياً)'
                                  : 'Very active (hard exercise daily)',
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _activityLevel = val),
                      ),
                      const SizedBox(height: 20),
                      // Goal
                      Text(
                        widget.isArabic ? 'الهدف الصحي *' : 'Health Goal *',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _goal,
                        hint: Text(
                          widget.isArabic
                              ? 'اختر الهدف الصحي *'
                              : 'Select Health Goal *',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedText,
                          ),
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return widget.isArabic
                                ? 'يرجى اختيار الهدف الصحي'
                                : 'Please select health goal';
                          }
                          return null;
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'maintain',
                            child: Text(
                              widget.isArabic
                                  ? 'الحفاظ على الوزن الثابت'
                                  : 'Maintain Weight',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'lose',
                            child: Text(
                              widget.isArabic
                                  ? 'خسارة الوزن (عجز آمن وصحي)'
                                  : 'Lose Weight (Safe Deficit)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'gain',
                            child: Text(
                              widget.isArabic
                                  ? 'زيادة الوزن وبناء العضلات'
                                  : 'Gain Weight & Muscle',
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _goal = val),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _calculateAndSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forestGreen,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.calculate_rounded),
                          label: Text(
                            widget.isArabic
                                ? 'احسب السعرات وابدأ'
                                : 'Calculate Calories & Start',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
