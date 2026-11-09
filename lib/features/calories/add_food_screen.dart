import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../reminders/data/meal_suggestions_data.dart';
import '../reminders/models/meal_suggestion.dart';
import 'models/food_item.dart';

abstract class MergedFoodEntry {}

class PresetFoodEntry extends MergedFoodEntry {
  final FoodPresetItem food;
  PresetFoodEntry(this.food);
}

class MealSuggestionEntry extends MergedFoodEntry {
  final MealSuggestion meal;
  MealSuggestionEntry(this.meal);
}

class AddFoodScreen extends StatefulWidget {
  final bool isArabic;
  final String mealType;

  const AddFoodScreen({
    super.key,
    required this.isArabic,
    required this.mealType,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  int _selectedTab = 0; // 0: Food List (Merged), 1: Custom Entry
  late String _selectedCategory; // 'breakfast_dinner', 'lunch', 'snack'

  String _searchQuery = '';
  FoodPresetItem? _selectedPreset;
  final _amountController = TextEditingController(text: '100');

  // Custom food controllers
  final _customNameController = TextEditingController();
  final _customCaloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.mealType == 'lunch') {
      _selectedCategory = 'lunch';
    } else if (widget.mealType == 'snack' ||
        widget.mealType == 'morning_snack' ||
        widget.mealType == 'evening_snack') {
      _selectedCategory = 'snack';
    } else if (widget.mealType == 'dinner') {
      _selectedCategory = 'dinner';
    } else {
      _selectedCategory = 'breakfast';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customNameController.dispose();
    _customCaloriesController.dispose();
    super.dispose();
  }

  List<MergedFoodEntry> _getMergedFoodEntries() {
    final List<MergedFoodEntry> entries = [];
    final query = _searchQuery.toLowerCase().trim();

    // 1. Filter Preset Foods from FoodDatabase.commonFoods
    final presetFoods = FoodDatabase.commonFoods.where((f) {
      bool categoryMatch = false;
      if (_selectedCategory == 'breakfast' || _selectedCategory == 'dinner') {
        categoryMatch = f.category == 'breakfast' || f.category == 'dinner';
      } else if (_selectedCategory == 'lunch') {
        categoryMatch = f.category == 'lunch';
      } else if (_selectedCategory == 'snack') {
        categoryMatch = f.category == 'snack';
      }

      if (!categoryMatch) return false;

      if (query.isEmpty) return true;
      final name = f.getName(widget.isArabic).toLowerCase();
      return name.contains(query);
    });

    for (final f in presetFoods) {
      entries.add(PresetFoodEntry(f));
    }

    // 2. Filter Meal Suggestions from MealSuggestionsData
    List<MealSuggestion> rawSuggestions = [];
    if (_selectedCategory == 'breakfast' || _selectedCategory == 'dinner') {
      rawSuggestions = MealSuggestionsData.getBreakfastAndDinnerSuggestions();
    } else if (_selectedCategory == 'lunch') {
      rawSuggestions = MealSuggestionsData.getLunchSuggestions();
    }

    final filteredSuggestions = rawSuggestions.where((m) {
      if (query.isEmpty) return true;
      final title = (widget.isArabic ? m.titleAr : m.titleEn).toLowerCase();
      final notes = m.notesAr.toLowerCase();
      return title.contains(query) || notes.contains(query);
    });

    for (final m in filteredSuggestions) {
      entries.add(MealSuggestionEntry(m));
    }

    return entries;
  }

  void _addPresetFood() {
    if (_selectedPreset == null) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 100.0;
    if (amount <= 0) return;

    final calculatedCalories =
        (_selectedPreset!.caloriesPer100g * (amount / 100.0)).round();

    final item = LoggedFood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _selectedPreset!.getName(widget.isArabic),
      amount: amount,
      unit: widget.isArabic ? 'جرام' : 'g',
      calories: calculatedCalories,
      mealType: widget.mealType,
      isCustom: false,
    );

    Navigator.pop(context, item);
  }

  void _addMealSuggestion(MealSuggestion meal) {
    final item = LoggedFood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.isArabic ? meal.titleAr : meal.titleEn,
      amount: 1,
      unit: widget.isArabic ? 'وجبة كاملة' : 'full meal',
      calories: meal.totalCalories,
      mealType: widget.mealType,
      isCustom: false,
    );

    Navigator.pop(context, item);
  }

  void _addCustomFood() {
    final name = _customNameController.text.trim();
    final calories = int.tryParse(_customCaloriesController.text.trim());
    if (name.isEmpty || calories == null || calories < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic
                ? 'يرجى إدخال اسم الطعام وإجمالي السعرات بشكل صحيح'
                : 'Please enter food name and valid calories',
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    final item = LoggedFood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      amount: 1,
      unit: widget.isArabic ? 'وجبة / يدوي' : 'custom',
      calories: calories,
      mealType: widget.mealType,
      isCustom: true,
    );

    Navigator.pop(context, item);
  }

  Widget _buildCategoryChip(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = categoryKey;
            _selectedPreset = null;
          });
        }
      },
      selectedColor: AppColors.forestGreen,
      backgroundColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.textDark,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mergedEntries = _getMergedFoodEntries();

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          title: Text(
            widget.isArabic ? 'إضافة طعام' : 'Add Food',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              color: AppColors.white,
              child: Row(
                children: [
                  // Tab 0: Food List (Merged)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 0
                                  ? AppColors.forestGreen
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.isArabic ? 'قائمة الأطعمة' : 'Food List',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedTab == 0
                                ? AppColors.forestGreen
                                : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tab 1: Custom Entry
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 1
                                  ? AppColors.forestGreen
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.isArabic ? 'إدخال يدوي' : 'Custom Entry',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedTab == 1
                                ? AppColors.forestGreen
                                : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _selectedTab == 1
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isArabic
                          ? 'إدخال وجبة أو طعام باللغة العربية يدوياً'
                          : 'Enter food and calories manually in Arabic',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customNameController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: widget.isArabic
                            ? 'اسم الوجبة / الطعام (بالعربية)'
                            : 'Food Name',
                        hintText: widget.isArabic
                            ? 'مثال: طبق أرز وفراخ، سلطة خضراء، شوربة...'
                            : 'e.g., Chicken and rice plate, Salad...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customCaloriesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.isArabic
                            ? 'إجمالي السعرات (كالوري) *'
                            : 'Total Calories (kcal) *',
                        helperText: widget.isArabic
                            ? 'أدخل عدد السعرات التقريبية لهذه الوجبة'
                            : 'Enter approximate calories for this meal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addCustomFood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isArabic ? 'إضافة للسجل' : 'Add to Log',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: widget.isArabic
                            ? 'ابحث عن طعام باللغة العربية...'
                            : 'Search food...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                    ),
                  ),
                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          'breakfast',
                          widget.isArabic ? 'الفطار' : 'Breakfast',
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          'lunch',
                          widget.isArabic ? 'الغداء' : 'Lunch',
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          'snack',
                          widget.isArabic ? 'السناكس' : 'Snacks',
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          'dinner',
                          widget.isArabic ? 'العشاء' : 'Dinner',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedPreset != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.forestGreen),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.isArabic ? 'المحدد' : 'Selected'}: ${_selectedPreset!.getName(widget.isArabic)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedPreset!.caloriesPer100g} ${widget.isArabic ? 'كالوري لكل 100 جرام' : 'kcal per 100g'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: widget.isArabic
                                        ? 'الكمية (جرام)'
                                        : 'Amount (g)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _addPresetFood,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentOrange,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  widget.isArabic ? 'إضافة' : 'Add',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: mergedEntries.isEmpty
                        ? Center(
                            child: Text(
                              widget.isArabic
                                  ? 'لا توجد أطعمة مطابقة'
                                  : 'No matching food items',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedText,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: mergedEntries.length,
                            itemBuilder: (context, index) {
                              final entry = mergedEntries[index];
                              if (entry is PresetFoodEntry) {
                                final food = entry.food;
                                final isSelected = _selectedPreset == food;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.forestGreen.withValues(
                                            alpha: 0.08,
                                          )
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.forestGreen
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      food.getName(widget.isArabic),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${food.caloriesPer100g} ${widget.isArabic ? 'كالوري / 100 جم' : 'kcal / 100g'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: AppColors.mutedText,
                                    ),
                                    onTap: () => setState(
                                      () => _selectedPreset = food,
                                    ),
                                  ),
                                );
                              } else if (entry is MealSuggestionEntry) {
                                return _buildMealCard(entry.meal);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMealCard(MealSuggestion meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(
          color: AppColors.forestGreen.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.set_meal_rounded,
            color: Color(0xFFD97706),
            size: 22,
          ),
        ),
        title: Text(
          widget.isArabic ? meal.titleAr : meal.titleEn,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
            color: AppColors.textDark,
            height: 1.3,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🔥 ${meal.totalCalories} ${widget.isArabic ? 'سعرة' : 'kcal'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  meal.notesAr,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.shopping_basket_outlined, size: 16, color: AppColors.forestGreen),
              const SizedBox(width: 6),
              Text(
                widget.isArabic ? 'المكونات والحصص:' : 'Ingredients & Portions:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...meal.ingredients.map((ing) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isArabic ? ing.nameAr : ing.nameEn,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isArabic
                              ? '${ing.weightGrams.toInt()} جرام — ${ing.householdMeasureAr}'
                              : '${ing.weightGrams.toInt()}g — ${ing.householdMeasureEn}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'المصدر: ${ing.sourceId}',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      '${ing.calculatedCalories.round()} سعرة',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.soup_kitchen_outlined, size: 16, color: AppColors.forestGreen),
                    const SizedBox(width: 6),
                    Text(
                      widget.isArabic ? 'طريقة التحضير:' : 'Preparation Method:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isArabic ? meal.prepMethodAr : meal.prepMethodEn,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _addMealSuggestion(meal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                widget.isArabic ? 'إضافة للسجل' : 'Add to Log',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
