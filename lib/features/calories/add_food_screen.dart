import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/food_item.dart';

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
  String _searchQuery = '';
  String _selectedCategory = 'all';
  FoodPresetItem? _selectedPreset;
  final _amountController = TextEditingController(text: '100');

  // Custom food controllers
  final _customNameController = TextEditingController();
  final _customCaloriesController = TextEditingController();
  bool _isCustomTab = false;

  @override
  void dispose() {
    _amountController.dispose();
    _customNameController.dispose();
    _customCaloriesController.dispose();
    super.dispose();
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
        setState(() {
          _selectedCategory = categoryKey;
        });
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
    final filteredFoods = FoodDatabase.commonFoods.where((f) {
      final name = f.getName(widget.isArabic).toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'all' || f.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

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
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isCustomTab = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: !_isCustomTab
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
                            color: !_isCustomTab
                                ? AppColors.forestGreen
                                : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isCustomTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _isCustomTab
                                  ? AppColors.forestGreen
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.isArabic
                              ? 'إدخال يدوي (عربي)'
                              : 'Custom Entry',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isCustomTab
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
        body: _isCustomTab
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
                          'all',
                          widget.isArabic ? 'الكل' : 'All',
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          'breakfast',
                          widget.isArabic ? 'الفطار' : 'Breakfast',
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          'snack',
                          widget.isArabic ? 'السناكس' : 'Snacks',
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          'lunch',
                          widget.isArabic ? 'الغداء' : 'Lunch',
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
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = filteredFoods[index];
                        final isSelected = _selectedPreset == food;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.forestGreen.withValues(alpha: 0.08)
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
                            onTap: () => setState(() => _selectedPreset = food),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
